---
title: Output Restrictions and Supplies
weight: 15
sidebar:
  open: false
---

By default any [Module]({{< relref "resources/stack-namespace-module#module" >}}) in a [Stack]({{< relref "resources/stack-namespace-module#stack" >}}) can read any other Module's [Outputs]({{< relref "how-it-works/outputs" >}}). A **restriction** turns that default off for a producing Module, and a **supply** hands its Outputs to named Modules or [Namespaces]({{< relref "resources/stack-namespace-module#namespace" >}}).

Both are declared by the Module that produces the Outputs, not by the one reading them. A supply always wins over a restriction.

There is no Stack-level supply, because supplying back to the whole Stack is the same as not restricting in the first place.

## Restricting the whole Output Set

The `output_set_downstream_restriction` field on a **Module** takes one of two values:

- `All` - nothing in the Output Set can be read downstream without a supply
- `SensitiveOnly` - only the sensitive Outputs are withheld, and the literal ones stay readable

Leave it unset for no restriction, which is how every Module behaves today.

Sensitivity comes from the Output's type rather than a separate flag, so `SensitiveOnly` withholds exactly the Outputs that were marked `sensitive = true` in Terraform / OpenTofu and stored as [Secrets]({{< relref "resources/secrets" >}}).

```hcl
resource "snapcd_module" "producer" {
  name         = "producer"
  namespace_id = snapcd_namespace.producers.id

  # Nothing downstream reads these Outputs unless they are supplied explicitly.
  output_set_downstream_restriction = "All"
}
```

## Restricting one Output by name

A **Module Output Downstream Restriction** withholds a single Output, whether or not it is sensitive. Use it where most of the Output Set is fine to share and one value is not.

```hcl
resource "snapcd_module_output_downstream_restriction" "internal_subnet_id" {
  module_id   = snapcd_module.producer.id
  output_name = "internal_subnet_id"
}
```

You can find the full specifications here:
- [Module Output Downstream Restriction](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_output_downstream_restriction)

## Supplying Outputs

A supply names who may read what the producer has restricted. There are four, one for each combination of "whole Output Set" or "one Output" with "to a Module" or "to a Namespace".

Supplying to a Namespace covers every Module in it, including Modules added later.

```hcl
# The whole Output Set, to every Module in a Namespace
resource "snapcd_output_set_namespace_supply" "producer_to_consumers" {
  module_id              = snapcd_module.producer.id
  consuming_namespace_id = snapcd_namespace.consumers.id
}

# One Output, to one Module
resource "snapcd_output_module_supply" "vpc_id_to_consumer" {
  module_id           = snapcd_module.producer.id
  output_name         = "vpc_id"
  consuming_module_id = snapcd_module.consumer.id
}
```

You can find the full specifications here:
- [Output Set Module Supply](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/output_set_module_supply)
- [Output Set Namespace Supply](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/output_set_namespace_supply)
- [Output Module Supply](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/output_module_supply)
- [Output Namespace Supply](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/output_namespace_supply)

## How the two combine

A supply overrides every restriction on what it covers. So an Output Set supply makes the whole set readable even where an individual Output was restricted by name, and an Output supply makes that one Output readable even where the whole set is set to `All`.

Working through it for a consuming Module:

1. Has the producer supplied its whole Output Set to this Module, or to the Module's Namespace? If so, everything is readable.
2. Has the producer supplied this particular Output to the Module or its Namespace? If so, that Output is readable.
3. Otherwise the restrictions apply: `All` withholds everything, `SensitiveOnly` withholds the sensitive Outputs, and a named restriction withholds that Output.

## What happens when a Module reads something it may not

Where a [Module Input]({{< relref "resources/module-inputs" >}}) names a specific Output, the [Job]({{< relref "how-it-works/orchestration" >}}) fails and says which Output was refused, which Module produces it, and why:

```
Module "consumer" cannot read:
- "vpc_id" from Module "producer" (in Namespace "platform"), which withholds all its Outputs.
Supply the mentioned Outputs (or full OutputSets) to this Module or its Namespace to allow it.
```

A Module refused several Outputs at once gets one message listing all of them, not just the first.

Where an input pulls in a whole **Output Set**, the withheld Outputs are left out of the set and the rest are passed through. A sensitive Output that is withheld is never fetched from the Secret Store at all.

> Adding a restriction does not check whether anything already reads the Output. The next Job on the consuming Module is where it surfaces.

## What a restriction does not cover

A restriction applies to input resolution only. A restricted Output still appears in the dependency graph, in the Dashboard, and anywhere else Outputs are read, so this is a rule about what a Module can consume rather than a way to hide a value.
