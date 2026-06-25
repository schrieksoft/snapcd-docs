---
title: Secrets
weight: 9
sidebar:
  open: false
---

**Secrets** store sensitive values that can be used as inputs to your [Modules]({{< relref "resources/stack-namespace-module#module" >}}). Secrets are scoped to different levels of the resource hierarchy, controlling which Modules can access them. You can define Secrets on [Stacks]({{< relref "resources/stack-namespace-module#stack" >}}), [Namespaces]({{< relref "resources/stack-namespace-module#namespace" >}}) or **Modules**. 

**Secrets** must be created via the Dashboard ([snapcd.io](https://snapcd.io) on the Cloud edition, or your own Server on [self-hosted]({{< relref "components/server" >}})) or **Web API**. They can be referenced from the teraform provider a `data` sources, but this will only return their metadata. The actual secret values cannot be read like this.

## Using Secrets as Inputs

The purpose of **Secrets" are to use that as either **Module Inputs** or **Namespace Inputs**. A **Module Input** can use any **Module Secret** from the same **Module** or any **Namespace Secret** or **Stack Secret** from its parent **Namespace** or **Stack**. Similarly a **Namespace Input** can select a **Namespace Secret** or **Stack Secret** as longs as they are from the same **Namespace**/**Stack** 

- [Module Input (From Secret)](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_input_from_secret)
- [Namespace Input (From Secret)](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_input_from_secret)


## Sensitive Outputs

When a **Module** produces sensitive outputs (marked with `sensitive = true` in Terraform/OpenTofu), these are automatically stored as secrets scoped to the [Output Set]({{< relref "how-it-works/outputs" >}}). This ensures sensitive values are encrypted at rest and access-controlled.

For more details on how outputs are stored, see the [Outputs]({{< relref "how-it-works/outputs" >}}) section.

## Access Control

Access to secrets follows the resource hierarchy:

- **Stack Secret**: Accessible by principals with appropriate roles on the Stack
- **Namespace Secret**: Accessible by principals with appropriate roles on the Namespace or parent Stack
- **Module Secret**: Accessible by principals with appropriate roles on the Module, parent Namespace, or parent Stack

Roles like **Owner** and **Contributor** on a resource grant access to secrets scoped to that resource or its children.
