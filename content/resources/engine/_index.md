---
title: Engine
weight: 8
sidebar:
  open: false
---



The Snap CD [Runner]({{< relref "components/runner" >}}) requires the appropriate binary for whichever **Engine** you wish to use. The available engines are:

- **OpenTofu** (`tofu`) — the default engine
- **Terraform** (`terraform`)
- **Pulumi** (`pulumi`) — available as a **Preview Feature** (see below)

You can use one or more of these on your **Runner**. Which **Engine** should be used is defined on the [Module]({{< relref "resources/stack-namespace-module#module" >}}) spec. You must provide your own binaries.

> Note that Snap CD has only been tested with `terraform` binaries up to release [1.5.7](https://github.com/hashicorp/terraform/releases/tag/v1.5.7), which was the final release under the [Mozilla Public License 2.0](https://github.com/hashicorp/terraform/blob/v1.5.7/LICENSE). It was not developed for later versions, such as those published under the [Business Source License 1.1 (BSL 1.1)](https://github.com/hashicorp/terraform/blob/v1.6.0/LICENSE).

## Pulumi (Preview)

Pulumi is available as a **Preview Feature**. An **Organization Owner** must first opt in via the **Preview Features** page before Pulumi can be selected as an engine on any [Namespace]({{< relref "resources/stack-namespace-module#namespace" >}}) or **Module**.


## Examples

A default **Engine** can be configured for every **Namespace**, and/or can be set (overridden) on each **Module** individually.

#### Set **Engine** on **Namespace**


```hcl
resource "snapcd_namespace" "mynamespace" {
  name            = "mynamespace"
  stack_id        = snapcd_stack.mystack.id
  ...
  default_engine  = "OpenTofu"
}
```


#### Set **Engine** on **Module**

```hcl
resource "snapcd_module" "mymodule" {
  name          = "mymodule"
  namespace_id  = snapcd_namespace.mynamespace.id
  ...
  engine        = "OpenTofu"
}
```

#### Set **Engine** to Pulumi on **Module** (requires Preview Feature opt-in)

```hcl
resource "snapcd_module" "mymodule" {
  name          = "mymodule"
  namespace_id  = snapcd_namespace.mynamespace.id
  ...
  engine        = "Pulumi"
}
```

The full **Module** spec can be found [here](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module).

The full **Namespace** spec can be found [here](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace).
