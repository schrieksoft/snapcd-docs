---
title: Extra Files
weight: 10
sidebar:
  open: false
---

An **Extra File** is a file that the [Runner]({{< relref "components/runner" >}}) should additionally add to the root of the [Module]({{< relref "resources/stack-namespace-module#module" >}}) after it fetches the source module. You can define either a **Namespace Extra File** (which will be added for all **Modules** in the [Namespace]({{< relref "resources/stack-namespace-module#namespace" >}})) or a **Module Extra File**.

You can see the full specifications here:
- [Namespace Extra File](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_extra_file)
- [Module Extra File](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_extra_file)

## Example Usage: Provider Initialization

One case where **Extra Files** are particularly useful is when the referenced module does not have a `providers.tf` file. This is often the case, since providers are normally initialized from the root project, and pure modules are normally referenced from there, with the providers being passed in. In this case you could use two **Extra Files** to create the following two files. I.e., one to define how the providers should be initialized, and one to allow you to pass additional variables the providers might need.

`extra_providers.tf`:
```hcl
provider "azurerm" {
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  features {}
}
```

`extra_providers_vars.tf`:
```hcl
variable "subscription_id" {}
variable "tenant_id" {}
```

## Example Usage: Backend Configuration

In Terraform / OpenTofu the `backend` _must_ be defined in the `terraform` block. It cannot be set from the command line. Typically in a pure module the `root.tf` looks like this (i.e. there is no `backend` block), so a local backend will be used. The backend is normally defined in the root project that references the module.

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.20.0"
    }
  }
}
```

In this case you can create an **Extra File** as follows in order to define which backend should be used:


`extra_backend.tf`:
```hcl
terraform {
  backend "azurerm" {}
}
```

How the backend should be _configured_ is something you can control either by passing in relevant Env Vars, or by using [Flags & Array Flags]({{< relref "resources/flags" >}}) (specifically a **Terraform Array Flag** with `flag = "BackendConfig"` and `task = "Init"`).




  