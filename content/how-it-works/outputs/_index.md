---
title: Output Storage
weight: 2
sidebar:
  open: false
---


Snap CD stores the outputs from your Terraform / OpenTofu [modules]({{< relref "resources/stack-namespace-module#module" >}}). For this it creates an **Output Set** each time the result of `terraform ouput` / `tofu output` changes. Each **Output Set** has one or more **Outputs**.

An output can either by a **Literal Output** or it can be **Secret Scoped to Output Set**.


## Non-sensitive Outputs (**Literal Outputs**)

Non-sensitive outputs are stored as literal values in the **Outputs** table.


## Sensitive Outputs (**Secrets Scoped to Output Set**)

Sensitive outputs are stored in a [Secret Store]({{< relref "resources/secrets" >}}) and a reference to **Secret** is stored in the **Outputs** table.

The **Secret Store** that will be used in order to store the **Outputs** is defined by the "Output Secret Store Id" field on the **Module** (or if that is not set, then on the "Default Output Secret Store Id" field set on either the [Namespace]({{< relref "resources/stack-namespace-module#namespace" >}}) or the [Stack]({{< relref "resources/stack-namespace-module#stack" >}}); if nothing is set then storage of sensitive outputs will fail).

> Please note that if you are using an **Azure Key Vault Secret Store**, then the [Server]({{< relref "components/server" >}}) must have Azure Credentials attached to it that provide both read and write access to the backing Azure Key Vault.

## Example

Consider te below `outputs.tf` file:

```hcl
output "first_output" {
  value = 100
}

output "second_output" {
  value     = 200
  sensivite = true
}
```

When a [Job]({{< relref "how-it-works/orchestration" >}})'s output step runs for the first time it will create a new **Output Set**, with two **Outputs** ("first_output" as a **Literal Output** and "second__output"as a **Secret Scoped to Output Set**).

If this **Job** runs a second time it will recognize that the **Outputs** have not changed, and will therefore do nothing further.

Now let's say we modify  `outputs.tf` as follows:

```hcl
output "first_output" {
  value = 999
}

output "second_output" {
  value     = 200
  sensivite = true
}
```

Since the value of "first_output" has changed, the next time a **Job** runs it will create a new **Output Set**, with two new **Outputs** for each of "first_output" and "second_output".