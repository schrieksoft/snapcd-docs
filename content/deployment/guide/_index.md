---
title: Guide
weight: 2
sidebar:
  open: false
---

The Snap CD components ship as Docker images and as zipped binaries published on [GitHub Releases](https://github.com/schrieksoft/snapcd/releases). The day-to-day "what files do I write, what manifests do I apply" details live in standalone reference-deployment repositories — **one per substrate**, each covering all three components (Server, Runner, Agent) in a single, modular layout.

## Reference deployment repositories

Each of the repositories below contains a `components/` directory with one self-contained sub-deployment per component. You can bring up all three together, or just the component you care about (the Runner against Cloud, an Agent attached to a remote Server, etc.). Each repo's README walks through both shapes.

| Substrate | Reference repository |
|-----------|----------------------|
| Docker / Compose | [schrieksoft/snapcd-deployment-docker](https://github.com/schrieksoft/snapcd-deployment-docker) |
| Kubernetes (Helm or Kustomize) | [schrieksoft/snapcd-deployment-kubernetes](https://github.com/schrieksoft/snapcd-deployment-kubernetes) |

Each repo tracks the matching Snap CD release. The sections below give you a sense of the minimum shape per component so you know what you're looking at when you open one of the reference repos.

## Kubernetes with Helm

The Kubernetes repository publishes Helm charts to `oci://ghcr.io/schrieksoft/charts` with each of its releases, signed with cosign:

| Chart | Installs |
|-------|----------|
| `snapcd` | The Server, a Runner and optionally the Agent, in one namespace and wired to each other |
| `snapcd-server` | The Server, with SQL Server and Redis bundled for trials |
| `snapcd-runner` | A Runner |
| `snapcd-agent` | The Agent and its Claude Sidecar |

```bash
helm install snapcd oci://ghcr.io/schrieksoft/charts/snapcd --namespace snapcd --create-namespace
kubectl -n snapcd port-forward svc/snapcd-server 5000:5000
```

This comes up with the Dashboard at `http://localhost:5000` and a connected Runner, using the same sample settings as the Docker reference deployment. Those settings are public, so replace the keys, passwords and credentials before the Server holds anything that matters. For anything beyond a trial, turn the bundled SQL Server and Redis off and point the Server at managed services with `server.database.*` and `server.cache.*`.

A chart's version is the release of the Kubernetes repository; its app version is the Snap CD release it deploys. Every value is listed in the chart's README in the repository, under `charts/`. The repository's Kustomize manifests are rendered from the same charts, so the two stay identical.

To install a Runner against Snap CD Cloud or a Server you do not host, use the `snapcd-runner` chart on its own with your Runner's settings in `config.appsettings` and its client secret in `credentials`.

## Server

The Server is deployed only when running **Self-Hosted**; Cloud users do not deploy the Server themselves.

Minimum Compose shape:

```yaml
services:
  snapcd-server:
    image: ghcr.io/schrieksoft/snapcd/snapcd-server:latest
    ports:
      - "5000:5000"
    environment:
      - ConnectionString=Server=sqlserver,1433;Database=SnapCd;User Id=sa;Password=...;TrustServerCertificate=True
      - AllowHttp=false
    volumes:
      - ./appsettings.External.json:/app/appsettings.External.json:ro
```

The Server is stateless; all durable state lives in SQL Server. On Kubernetes the recommended pattern is a single Deployment behind a TLS-terminating Ingress. Database schema migrations apply automatically on startup.

## Runner

A Runner is the process described on the [Runner]({{< relref "components/runner" >}}) page — it picks up Jobs from the Server and executes them.

Minimum Compose shape:

```yaml
services:
  snapcd-runner:
    image: ghcr.io/schrieksoft/snapcd/snapcd-runner-azure:latest
    environment:
      - Server__Url=https://snapcd.example.com
      - Runner__Id=10000000-0000-0000-0000-000000000000
      - Runner__OrganizationId=10000000-0000-0000-0000-000000000000
      - Runner__Instance=runner-1
      - Runner__Credentials__ClientId=<sp-client-id>
      - Runner__Credentials__ClientSecret=<sp-client-secret>
    volumes:
      - runner-data:/app/runnerdata
```

On Kubernetes the recommended pattern is a StatefulSet: the working-directory volume persists per Pod, and if the Runner record's `allow_multiple_instances` is set you can scale replicas horizontally. The Runner image ships OpenTofu and Terraform; the Helm chart's `engines.download` setting downloads other versions when the Pod starts.

## Agent

An Agent runs alongside one or more [Sidecars]({{< relref "components/agent#sidecars" >}}). The Agent supervises Sidecars over `localhost` HTTP, so they must run on the same Docker network — or, on Kubernetes, in the same namespace.

Minimum Compose shape — Agent process plus a Claude Sidecar sibling:

```yaml
services:
  snapcd-agent:
    image: ghcr.io/schrieksoft/snapcd/snapcd-agent:latest
    environment:
      - Server__Url=https://snapcd.example.com
      - Agent__AgentId=20000000-0000-0000-0000-000000000000
      - Agent__OrganizationId=10000000-0000-0000-0000-000000000000
      - Agent__InstanceName=agent-1
      - Agent__ClientId=<sp-client-id>
      - Agent__ClientSecret=<sp-client-secret>
      - Agent__Sidecars__0__Name=claude
      - Agent__Sidecars__0__BaseUrl=http://snapcd-agent-sidecar-claude:7001
    depends_on:
      - snapcd-agent-sidecar-claude

  snapcd-agent-sidecar-claude:
    image: ghcr.io/schrieksoft/snapcd/snapcd-agent-sidecar-claude:latest
    environment:
      - ANTHROPIC_API_KEY=<your-anthropic-key>
      - SNAPCD_SERVER_URL=https://snapcd.example.com
```

On Kubernetes the recommended pattern is a Deployment per process (orchestrator + one per sidecar), with the sidecars exposed as ClusterIP Services so the orchestrator can reach them by name.
