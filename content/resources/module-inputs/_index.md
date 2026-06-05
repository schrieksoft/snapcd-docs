---
title: Module Inputs
weight: 6
sidebar:
  open: false
---


A **Module Input** refers to either a parameter (i.e. something that in a `.tf` file can be referenced with `var.`) or an environment variable. 

For **Module Parameters**, the name of the resource is matched to a Terraform / OpenTofu input variable. For example, defining a **Module Parameter" with the name "myvar", will result in the value of that paramter being called into the `var.myvar` variable.

For **Module Env Vars**, the name of the resource is prefixed with "SNAPCD_ENV_" and then made available on the [Runner]({{< relref "components/runner" >}}). For example, if you define a **Module Env Var** with the name "MY_ENV_VAR", then this will be made available on the **Runner** as "SNAPCD_ENV_MY_ENV_VAR". 


## From Literal

The most straightforward way to define a **Module Input** is as a literal value. You can find the full specifications for how to use these here:
- [Module Input (From Literal)](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_input_from_literal)


## From Output

**Module Inputs** can reference [Outputs]({{< relref "how-it-works/outputs" >}}) from any [Module]({{< relref "resources/stack-namespace-module#module" >}}) within the same [Stack]({{< relref "resources/stack-namespace-module#stack" >}}).

You can find the full specifications for how to use these here:
- [Module Input (From Output)](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_input_from_output)


See the [Outputs]({{< relref "how-it-works/outputs" >}}) section for more information on how **Outputs** are managed in Snap CD.

## From Output Set

**Module Inputs** can reference an **Output Set** from any **Module** within the same **Stack**. This will pull in all **Outputs** within the **Output Set**, mapping them to inputs with the same name as the **Output**. Let's that for example a **Module** with the following `outputs.tf`

```hcl
output my_first_output {
  value = "first"
}

output my_second_output {
  value = "second"
}
```

Setting up a **Module Param (From Output Set)** referencing the above **Module** would result in the variable `var.my_first_output` and `var.my_second_output` being set.

Setting up a **Module Env Var (From Output Set)** referencing the above **Module** would result in the environment variables `SNAPCD_ENV_my_first_output` and `SNAPCD_ENV_my_second_output` being set.

You can find the full specifications for how to use these here:
- [Module Input (From Output Set)](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_input_from_output_set)

> NOTE that Snap CD puts **Paramters** in a `.tfvars` file. The default Terraform / OpenTofu behaviour is to ignore a variables defined therein that have not been defined as actual terraform input variables, making it possible to use this feature without needing to worry about **Outputs** that are not wanted as inputs.


See the [Outputs]({{< relref "how-it-works/outputs" >}}) section for more information on how **Output Sets** are managed in Snap CD.

## From Secret

**Module Inputs** can reference secrets that have been scoped either the **Module** itself or to its parent **Stack**.

You can find the full specifications for how to use these here:
- [Module Input (From Definition)](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_input_from_secret)

See the [Secrets]({{< relref "resources/secrets" >}}) section for more information on how **Secrets** are managed in Snap CD.

## From Definition

**Module Inputs** can be derived from the values that are defined for the **Module** that is being executed:
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
- [Module Input (From Definition)](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_input_from_definition)

> NOTE that in the case of "Environment Variables", you can also access all of the above using the special "SNAPCD_DEF_" environment variables. For example, you can access the name of the **Module** with "SNAPCD_DEF_ModuleName".

## From Namespace

You can reference **Namesapce Input** with a **Module Input (From Namespace)**, mapping it to a specific environment variable or parameter. You can do this irrespective of whether the **Namespace Input** was created as `UseIfSelected` or `UseByDefault`. In the case of `UseByDefault` _both_ the **Namesapce Input** itself and the **Module Input (From Namespace)** (mapping it to a new parameter or environment variable) will show up on the runner.

You can find the full specifications for how to use these here:
- [Module Input (From Namespace)](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_input_from_namespace)
