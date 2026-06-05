---
title: Namespace Inputs
weight: 5
sidebar:
  open: false
---


A **Namespace Input** refers to either a parameter (i.e. something that in a `.tf` file can be referenced with `var.`) or an environment variable. **Namespace Inputs** are inherited by all [Modules]({{< relref "resources/stack-namespace-module#module" >}}) within the namespace. A **Namespace Input** can be created either as `UseByDefault`, in which case it will always be inherited, or `UseIfSelected` in which case it is available, but must be explicitly selected using a [Module Input (From Namespace)]({{< relref "resources/module-inputs" >}}).

For **Namespace Parameters**, the name of the resource is matched to a Terraform / OpenTofu input variable. For example, defining a **Namespace Parameter" with the name "myvar", will result in the value of that paramter being called into the `var.myvar` variable.

For **Namespace Env Vars**, the name of the resource is prefixed with "SNAPCD_ENV_" and then made available on the [Runner]({{< relref "components/runner" >}}). For example, if you define a **Namespace Env Var** with the name "MY_ENV_VAR", then this will be made available on the **Runner** as "SNAPCD_ENV_MY_ENV_VAR". 

## From Literal

The most straightforward way to define a **Namespace Input** is as a literal value. You can find the full specifications for how to use these here:
- [Namespace Input (From Literal)](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_input_from_literal)

## From Secret

**Namespace Inputs** can reference secrets that have been scoped either the **Namespace** itself or to its parent **Stack**.

You can find the full specifications for how to use these here:
- [Namespace Input (From Secret)](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_input_from_secret)

See the [Secrets]({{< relref "resources/secrets" >}}) section for more information on how **Secrets** are managed in Snap CD.

## From Definition

**Namespace Inputs** can be derived from the values that are defined for the **Module** that is being executed:
- ModuleName
- ModuleId
- NamespaceName
- NamespaceId
- StackName
- StackId
- SourceUrl
- SourceRevision
- SourceSubdirectory

You can find the full specifications for how to use these here:
- [Namespace Input (From Definition)](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_input_from_definition)

> NOTE that in the case of "Environment Variables", you can also access all of the above using the special "SNAPCD_DEF_" environment variables. For example, you can access the name of the **Module** with "SNAPCD_DEF_ModuleName".
