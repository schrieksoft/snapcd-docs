---
title: Flags & Array Flags
weight: 11
sidebar:
  open: false
---

**Flags** and **Array Flags** allow you to customise the command-line arguments passed to engine commands (`init`, `plan`, `apply`, `destroy`, `output`). They are available for both **Terraform** and **Pulumi** engines, and can be set at the [Namespace]({{< relref "resources/stack-namespace-module#namespace" >}}) level (applying to all [Modules]({{< relref "resources/stack-namespace-module#module" >}}) in the **Namespace**) or at the **Module** level.

- A **Flag** is a single-value argument (e.g. `--lock-timeout=10m`)
- An **Array Flag** is an argument that can appear multiple times (e.g. `-target=...`, `-backend-config=...`)

## Terraform Flags

You can see the full specifications here:
- [Module Terraform Flag](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_terraform_flag)
- [Module Terraform Array Flag](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_terraform_array_flag)
- [Namespace Terraform Flag](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_terraform_flag)
- [Namespace Terraform Array Flag](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_terraform_array_flag)

## Pulumi Flags

Pulumi flags are only available when the **Pulumi** preview feature has been enabled for your organization. See [Engine]({{< relref "resources/engine" >}}) for details.

You can see the full specifications here:
- [Module Pulumi Flag](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_pulumi_flag)
- [Module Pulumi Array Flag](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_pulumi_array_flag)
- [Namespace Pulumi Flag](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_pulumi_flag)
- [Namespace Pulumi Array Flag](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_pulumi_array_flag)


## Example: Backend Configuration

Backend configuration for Terraform / OpenTofu is handled via **Terraform Array Flags** with `flag = "BackendConfig"` and `task = "Init"`.

For example, to initialize Terraform with:

```bash
terraform init \
  -backend-config="bucket=my-terraform-state-bucket" \
  -backend-config="key=state/myproject.tfstate" \
  -backend-config="region=us-east-1"
```

Create three **Terraform Array Flag** resources:

```hcl
resource "snapcd_module_terraform_array_flag" "backend_bucket" {
  module_id = snapcd_module.mymodule.id
  task      = "Init"
  flag      = "BackendConfig"
  value     = "bucket=my-terraform-state-bucket"
}

resource "snapcd_module_terraform_array_flag" "backend_key" {
  module_id = snapcd_module.mymodule.id
  task      = "Init"
  flag      = "BackendConfig"
  value     = "key=state/myproject.tfstate"
}

resource "snapcd_module_terraform_array_flag" "backend_region" {
  module_id = snapcd_module.mymodule.id
  task      = "Init"
  flag      = "BackendConfig"
  value     = "region=us-east-1"
}
```

## Example: Targeting Specific Resources

Use the `Target` array flag to limit operations to specific resources:

```hcl
resource "snapcd_module_terraform_array_flag" "target" {
  module_id = snapcd_module.mymodule.id
  task      = "Apply"
  flag      = "Target"
  value     = "azurerm_resource_group.example"
}
```

## Migrating from Backend Configs

The `snapcd_module_backend_config` and `snapcd_namespace_backend_config` resources are **deprecated**. Replace them with `snapcd_module_terraform_array_flag` / `snapcd_namespace_terraform_array_flag` using `flag = "BackendConfig"` and `task = "Init"`.
