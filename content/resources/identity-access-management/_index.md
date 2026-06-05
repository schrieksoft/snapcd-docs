---
title: IAM
weight: 4
sidebar:
  open: false
---

# Overview

An **Identity** on Snap CD can be either a **User** or a **Service Principal**. Access for both is controlled by an integrated OIDC Identity Provider.

**Identities** can be assigned to **Groups**.

**Roles** can be assigned either to a **Group**, or directly to an **Identity**.

# Principals

## User

A **User** represents a human identity authenticated via the integrated OIDC Identity Provider. Users sign in interactively using a browser and are typically associated with an individual person within your organization. Sign-in can be federated to an external login provider. Snap CD supports the following external login providers: Microsoft Entra, Okta, Auth0, Google and GitHub.

You can see the full **User** specification [here](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/data-sources/user).

> NOTE: The Terraform provider only provides a **User** data source; creation must be done via the Dashboard.

## Service Principal

A **Service Principal** is also known as an OIDC "Application" or "Client", and is identified by "Client Id / Client Secret" credentials. **Service Principals** can exchange their Client Id / Client Secret for an **Access Token**, which can be used as a "Bearer" token in the authorization header when making requests to the [Server]({{< relref "components/server" >}})'s Web API.

[Runners]({{< relref "components/runner" >}}) need to have a **Service Principal** attached to them. You can also use a **Service Principal** to authenticate the [Snap CD Terraform Provider](https://registry.terraform.io/providers/schrieksoft/snapcd/latest).

You can see the full **Service Principal** specification [here](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/data-sources/service_principal).

> NOTE: The Terraform provider only provides a **Service Principal** data source; creation must be done via the Dashboard or Web API.

## Group

**Identities** can be assigned to **Groups**. Note that nesting of **Groups** is currently not supported.

You can see the full **Group** specification [here](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/group).

# Role Assignments

Roles are assigned at specific scopes using role assignment resources. Each scope has its own Terraform resource and set of available roles.

## Common Fields

All role assignment resources share these fields:

| Field | Description |
|-------|-------------|
| `principal_id` | ID of the User, Service Principal, or Group |
| `principal_discriminator` | Type of principal: `User`, `ServicePrincipal`, or `Group` |
| `role_name` | Name of the role to assign (varies by scope) |

## Organization Roles

Organization roles apply system-wide.

**Terraform Resource:** [snapcd_organization_role_assignment](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/organization_role_assignment)

| Role | Description |
|------|-------------|
| `Owner` | Full control over the entire organization |
| `Contributor` | Can read and create resources |
| `Reader` | Read-only access across the organization |
| `StackCreator` | Can create new Stacks |
| `IdentityAccessManager` | Can manage role assignments |
| `JobManager` | Can manage job execution |
| `SourceChangeNotifier` | Can trigger source change notifications |
| `Runner` | Can execute jobs as a runner |

## Stack Roles

Stack roles apply to a specific Stack and its child Namespaces and Modules.

**Terraform Resource:** [snapcd_stack_role_assignment](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/stack_role_assignment)

**Additional Field:** `stack_id` - ID of the Stack

| Role | Description |
|------|-------------|
| `Owner` | Full control over the Stack and all child resources |
| `Contributor` | Can read Stack and create child resources |
| `Reader` | Read-only access to Stack and child resources |
| `NamespaceCreator` | Can create new Namespaces in this Stack |
| `IdentityAccessManager` | Can manage role assignments on the Stack |
| `SourceChangeNotifier` | Can trigger source change notifications |
| `JobManager` | Can manage job execution |
| `Runner` | Can execute jobs as a runner |

## Namespace Roles

Namespace roles apply to a specific Namespace and its child Modules.

**Terraform Resource:** [snapcd_namespace_role_assignment](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_role_assignment)

**Additional Field:** `namespace_id` - ID of the Namespace

| Role | Description |
|------|-------------|
| `Owner` | Full control over the Namespace and all child Modules |
| `Contributor` | Can read Namespace and create Modules |
| `Reader` | Read-only access to Namespace and child Modules |
| `ModuleCreator` | Can create new Modules in this Namespace |
| `IdentityAccessManager` | Can manage role assignments on the Namespace |
| `SourceChangeNotifier` | Can trigger source change notifications |
| `JobManager` | Can manage job execution |
| `Runner` | Can execute jobs as a runner |

## Module Roles

Module roles apply to a specific Module.

**Terraform Resource:** [snapcd_module_role_assignment](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_role_assignment)

**Additional Field:** `module_id` - ID of the Module

| Role | Description |
|------|-------------|
| `Owner` | Full control over the Module |
| `Contributor` | Can read and modify the Module |
| `Reader` | Read-only access to the Module |
| `IdentityAccessManager` | Can manage role assignments on the Module |
| `SourceChangeNotifier` | Can trigger source change notifications |
| `Runner` | Can execute jobs as a runner |
| `JobManager` | Can manage job execution |

## Runner Roles

Runner roles apply to a specific Runner.

**Terraform Resource:** [snapcd_runner_role_assignment](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/runner_role_assignment)

**Additional Field:** `runner_id` - ID of the Runner

| Role | Description |
|------|-------------|
| `Owner` | Full control over the Runner |
| `Contributor` | Can read and modify the Runner |
| `Reader` | Read-only access to the Runner |
| `IdentityAccessManager` | Can manage role assignments on the Runner |

# Examples

## Assign a Service Principal as Module Owner

```hcl
resource "snapcd_module_role_assignment" "deployer" {
  module_id               = snapcd_module.my_module.id
  principal_id            = data.snapcd_service_principal.deployer.id
  principal_discriminator = "ServicePrincipal"
  role_name               = "Owner"
}
```

## Assign a User as Stack Reader

```hcl
resource "snapcd_stack_role_assignment" "viewer" {
  stack_id                = snapcd_stack.production.id
  principal_id            = data.snapcd_user.viewer.id
  principal_discriminator = "User"
  role_name               = "Reader"
}
```

## Assign a Group as Namespace Contributor

```hcl
resource "snapcd_namespace_role_assignment" "dev_team" {
  namespace_id            = snapcd_namespace.backend.id
  principal_id            = snapcd_group.developers.id
  principal_discriminator = "Group"
  role_name               = "Contributor"
}
```
