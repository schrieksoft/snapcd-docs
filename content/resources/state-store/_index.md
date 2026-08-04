---
title: State Store
weight: 14
sidebar:
  open: false
---

## Overview

A **State Store** provides encrypted, centrally managed Terraform / OpenTofu state via the [HTTP backend](https://developer.hashicorp.com/terraform/language/backend/http). Instead of managing remote state in a separate cloud storage bucket (S3, Azure Blob, GCS), you can store state directly in Snap CD alongside the Modules that produce it.

Every Organization is pre-seeded with a **default** State Store. You can create additional State Stores to isolate state for different environments or teams.

State is encrypted at rest (AES-256-GCM) and access-controlled via role assignments on the State Store.

## State Store

| Field | Description |
|-------|-------------|
| `name` | Unique name of the State Store within the Organization |

You can find the full **State Store** specification [here](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/data-sources/state_store).

## State Files

Each State Store contains one or more **State Files**. A State File is created automatically the first time a Module writes state to the State Store. Each Module gets its own State File, keyed by the Module's name.

State Files support locking: when a Module is applying, it holds an exclusive lock on its State File. Concurrent applies to the same State File are blocked until the lock is released. Locks auto-expire after a configurable timeout (default 30 minutes).

## Backend Configuration

To configure the HTTP backend for all Modules in a Namespace, you need the following resources:

### 1. Backend block

A [Namespace Extra File]({{< relref "resources/extra-files" >}}) that injects the `backend "http" {}` block:

```hcl
resource "snapcd_namespace_extra_file" "http_backend" {
  file_name    = "extra_root.tf"
  contents     = <<EOT
terraform {
  backend "http" {}
}
  EOT
  namespace_id = snapcd_namespace.example.id
  overwrite    = false
}
```

### 2. Module name as environment variable

A [Namespace Input from Definition]({{< relref "resources/namespace-inputs" >}}) that injects the current Module's name as an environment variable, so each Module's state is stored under its own path:

```hcl
resource "snapcd_namespace_input_from_definition" "module_name" {
  name            = "SNAPCD_MODULE_NAME"
  definition_name = "ModuleName"
  usage_mode      = "UseByDefault"
  namespace_id    = snapcd_namespace.example.id
  input_kind      = "EnvVar"
}
```

### 3. Backend config flags

[Namespace Terraform Array Flags]({{< relref "resources/flags" >}}) that pass the backend configuration to `terraform init`:

```hcl
data "snapcd_state_store" "default" {
  name = "default"
}

resource "snapcd_namespace_terraform_array_flag" "http_backend" {
  for_each = {
    address        = "${var.snapcd_server_url}/api/${var.organization_id}/state/${data.snapcd_state_store.default.id}/$${SNAPCD_MODULE_NAME}"
    lock_address   = "${var.snapcd_server_url}/api/${var.organization_id}/state/${data.snapcd_state_store.default.id}/$${SNAPCD_MODULE_NAME}/lock"
    unlock_address = "${var.snapcd_server_url}/api/${var.organization_id}/state/${data.snapcd_state_store.default.id}/$${SNAPCD_MODULE_NAME}/unlock"
    lock_method    = "POST"
    unlock_method  = "POST"
    username       = "$${SNAPCD_CLIENT_ID}"
    password       = "$${SNAPCD_CLIENT_SECRET}"
  }
  namespace_id = snapcd_namespace.example.id
  task         = "Init"
  flag         = "BackendConfig"
  value        = "${each.key}=${each.value}"
}
```

`$${SNAPCD_MODULE_NAME}` is resolved from the Namespace Input above. `$${SNAPCD_CLIENT_ID}` and `$${SNAPCD_CLIENT_SECRET}` come from the Runner's [RunnerEnvVars]({{< relref "components/runner#runner-environment-variables" >}}) configuration. The double-dollar (`$$`) escapes Terraform interpolation so the literal `${...}` is preserved for the Runner to resolve at deploy time.

## Endpoint and Authentication

The backend endpoint is:

```
/api/{organizationId}/state/{stateStoreId}/{stateFileName}
```

with `/lock` and `/unlock` appended for the locking endpoints.

The HTTP backend authenticates via HTTP Basic auth. The username is the Service Principal's client id (`clientId`) and the password is its client secret. The `SNAPCD_CLIENT_ID` and `SNAPCD_CLIENT_SECRET` environment variables are configured on the Runner and made available to the engine process.

> NOTE: an older form of this endpoint omits the organization from the path (`/api/state/{stateStoreId}/{stateFileName}`) and instead expects the username to be `{organizationId}:{clientId}`. It still works, so existing backend configurations keep functioning, but it is deprecated — the Server logs a warning on every request that uses it. Move the organization id into the path and reduce the username to the bare client id.

## Access Control

Access to a State Store is controlled via role assignments, following the same pattern as [Stacks]({{< relref "resources/stack-namespace-module#stack" >}}):

| Role | Permissions |
|------|-------------|
| **Owner** | Full access including delete and force-unlock |
| **Contributor** | Read/write state, acquire and release locks |
| **Reader** | Read-only access to state |
| **IdentityAccessManager** | Manage role assignments on the State Store |

Roles are assigned via the [State Store Role Assignment](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/state_store_role_assignment) resource.
