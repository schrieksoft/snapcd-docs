---
title: Platform Team on Azure
weight: 6
sidebar:
  open: false
---

This guide deploys a realistic Snap CD setup on Azure. A platform team runs Snap CD on AKS. It owns a [Runner]({{< relref "resources/runner" >}}) and two namespaces. It gives an application team a tenancy. The tenancy has its own Runner, and that Runner can change only the tenancy.

## Repositories

| Repository | Role |
|---|---|
| [snapcd-deployment-docker](https://github.com/schrieksoft/snapcd-deployment-docker) | The bootstrap: a Snap CD Server, Runner and Agent on your machine, in Docker Compose |
| [snapcd-deployment-azure](https://github.com/schrieksoft/snapcd-deployment-azure) | The platform (AKS, Istio, cert-manager) and the Snap CD installation on it. The bootstrap applies it |
| [sample-azure-realistic](https://github.com/snapcd-samples/sample-azure-realistic) | The platform team, the app-x tenancy and the sample app. The Azure Snap CD applies it |

You apply four OpenTofu configurations by hand:

- the root of snapcd-deployment-azure
- `namespaces/platform-core` in sample-azure-realistic
- `namespaces/platform-tenancies` in sample-azure-realistic
- `namespaces/app-x` in sample-azure-realistic

These configurations create only Snap CD objects, for example a namespace, Modules and Runners. A Runner then applies the Modules.

Each of the four configurations keeps its state in a local `terraform.tfstate`. Git ignores these files. Keep them, because you need them to change or destroy what you created.

## The bootstrap, and why you need it

The Azure Snap CD runs on an AKS cluster. The cluster must exist before Snap CD can run on it. So a different installation must create the cluster and install Snap CD on it. This installation is the bootstrap. It is a second, temporary Snap CD installation on your machine.

A plain `tofu apply` could also do this. The bootstrap uses Snap CD for these reasons:

- **The deployment has many Modules that depend on each other.** There are 16 Modules: the network, the cluster, Istio, cert-manager, the Server, the Runner, the Agent and their Azure resources. Snap CD runs them in dependency order. It also passes [outputs]({{< relref "how-it-works/outputs" >}}) between them, for example the OIDC issuer of the cluster to the workload identities.
- **You approve each Module, and Snap CD logs it.** The Dashboard shows the plan of each Module before it applies. The rest of the guide works the same way.
- **Later changes use the same path.** A commit to snapcd-deployment-azure starts jobs only for the Modules whose directories it changes. For example, an upgrade of the Server chart is one job. See [Monorepos]({{< relref "guides/monorepos" >}}).
- **The bootstrap keeps the state.** The Modules of the Azure installation keep their state in the `default` [State Store]({{< relref "resources/state-store" >}}) of the bootstrap. To change or destroy the Azure installation later, you need the bootstrap again, with the same database.

The bootstrap Runner signs in to Azure as you, with `az login`. Its home directory is in memory. After the container restarts, you must sign in again.

You must be a member of the administrator Entra group. The bootstrap Runner creates the database user of the Server on the SQL server, and it does this as your user.

After the Azure installation is up, everything else in this guide runs on the Azure Snap CD. You need the bootstrap again only to change or destroy the Azure installation.

## What you have at the end

### On Azure

All resources are in one subscription.

- The `<name>` resource group, from snapcd-deployment-azure. It contains:
  - a virtual network and the AKS cluster
  - the public IP address of the gateway, with the DNS label `<label>.<location>.cloudapp.azure.com`
  - Azure SQL for the Server
  - Key Vaults and workload identities for the Server, the Runner and the Agent
  - optionally, a Service Bus namespace
- The `platform` resource group. It contains the workload identity and the Key Vault of the platform Runner. A custom role, `tenancy_creator`, lets the platform Runner create tenancies. An ABAC condition limits the roles that it can assign.
- The `app-x-team` resource group. It contains:
  - the workload identity and the Key Vault of the app-x Runner
  - the SQL server and database, the Key Vault and the workload identity of the sample app

### On the cluster

- Istio with a public gateway, cert-manager with Let's Encrypt issuers, and the Azure Workload Identity webhook.
- The Snap CD Server, the `default` Runner and the Agent. Each one has its own Kubernetes namespace. The Server is at `https://<label>.<location>.cloudapp.azure.com`.
- The `platform` Kubernetes namespace, with the platform Runner. Its ClusterRole lets it create tenancies and nothing more.
- The `app-x` Kubernetes namespace, with the app-x Runner and the sample app. The app-x Runner has no rights outside this namespace. The app has no ingress. You reach it with `kubectl port-forward`.

### On the Azure Snap CD

All [namespaces]({{< relref "resources/stack-namespace-module" >}}) are in the `default` stack.

| Namespace | Runner | State Store | Its Modules deploy |
|---|---|---|---|
| `platform-core` | `default` | `platform` | The platform Runner |
| `platform-tenancies` | `platform` | `platform` | The app-x tenancy, which includes the `app-x` namespace and Runner |
| `app-x` | `app-x` | `app-x` | The sample app |

No Runner uses a client secret. Each Runner signs in to Snap CD with its Kubernetes ServiceAccount token, through a Federated Credential. See [Identity and Access Management]({{< relref "resources/identity-access-management" >}}). Each Runner signs in to Azure with its workload identity.

## Steps

### 1. Start the bootstrap

In snapcd-deployment-docker, run:

```bash
docker compose up -d && docker compose exec snapcd-runner sh -c 'az config set core.login_experience_v2=off && az login && az account set --subscription <subscription-id>'
```

Open the URL that `az login` shows, and enter the code. The bootstrap Dashboard is at `http://localhost:5000`.

Make sure that:

- the bootstrap has a licence. The deployment has more than 10 Modules, which is the Community limit.
- the bootstrap Runner can clone snapcd-deployment-azure over SSH.

### 2. Deploy Snap CD on Azure

In snapcd-deployment-azure:

1. Copy `terraform.tfvars.example` to `terraform.tfvars`.
2. In `terraform.tfvars`, set the bootstrap credentials, `tenant_id`, `subscription_id`, `location`, `administrator_object_id` and `name`.
3. Run `tofu init` and `tofu apply`. This creates the `bootstrap` stack, the `azure` namespace and the Modules on the bootstrap.
4. In the bootstrap Dashboard, approve the job of each Module. The cluster takes 15 to 20 minutes.
5. Open the URL in the `url` output of `snapcd_server_app`.
6. Sign in as `admin@preseeded.io`. The password is in the secret `snapcd-server-admin-password`, in the Server Key Vault.
7. On the License page, apply a licence. The Agent needs an Enterprise licence.

### 3. Prepare your machine for the Azure Snap CD

1. Get the public SSH key of the `default` Runner. It is the `snapcd_runner_ssh_public_key_openssh` output of `snapcd_runner_infra_config`.
2. Add this key to your copy of sample-azure-realistic as a read-only deploy key.
3. Sign the snapcd CLI in to the Azure Server:

   ```bash
   snapcd context add azure --url https://<label>.<location>.cloudapp.azure.com
   snapcd login
   ```

### 4. Apply `platform-core`

In `namespaces/platform-core` of sample-azure-realistic:

1. Copy `terraform.tfvars.example` to `terraform.tfvars`.
2. In `terraform.tfvars`, set the Azure values, the cluster name, the cluster resource group and the OIDC issuer URL of the cluster. The cluster name and resource group are the `name` from step 2.
3. Run `tofu init` and `tofu apply`.
4. In the Azure Dashboard, approve the jobs in the `platform-core` namespace. The `default` Runner deploys the platform Runner.
5. Add the public SSH key of the platform Runner as a deploy key. The key is the `platform_runner_ssh_public_key_openssh` output of `platform_azure_config`.

### 5. Apply `platform-tenancies`

In `namespaces/platform-tenancies`:

1. Copy `terraform.tfvars.example` to `terraform.tfvars`. Use the same Azure and cluster values as in step 4.
2. Run `tofu init` and `tofu apply`.
3. Approve the jobs in the `platform-tenancies` namespace. The platform Runner creates the app-x tenancy and its Runner.
4. Add the public SSH key of the app-x Runner as a deploy key. The key is the `app_runner_ssh_public_key_openssh` output of `app_tenancy_azure_config`.

### 6. Apply `app-x`

In `namespaces/app-x`:

1. Run `tofu init` and `tofu apply`. You do not need a tfvars file.
2. Approve the jobs in the `app-x` namespace. The app-x Runner deploys the sample app.
3. Forward a local port to the app:

   ```bash
   az aks get-credentials --subscription <subscription-id> --resource-group <name> --name <name>
   kubelogin convert-kubeconfig -l azurecli
   kubectl --context <name> -n app-x port-forward service/sample-app 8080:80
   ```

4. Open `http://localhost:8080`. The page shows if the app can reach its database and its Key Vault.

## Destroy

Destroy in the reverse order. The Modules of each step run on a Runner that the step before it deployed.

1. `app-x`: in the Dashboard, use "destroy all" on the namespace. Then run `tofu destroy` in `namespaces/app-x`.
2. `platform-tenancies`: do the same.
3. `platform-core`: do the same.
4. The Azure installation: in the bootstrap Dashboard, use "destroy all" on the `azure` namespace. Then run `tofu destroy` in snapcd-deployment-azure. The bootstrap must still have its database.

The app-x Runner cannot purge deleted Key Vaults. So the Key Vaults in `app-x-team` stay soft-deleted for their retention period. Until then, their names are not available again. A user with purge rights can purge them earlier.
