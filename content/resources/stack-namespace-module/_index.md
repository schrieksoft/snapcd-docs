---
title: Stacks, Namespaces and Modules
weight: 1
sidebar:
  open: false
---


## Stack

A **Stack** is the highest level hierarchical grouping in Snap CD and is used to draw a hard line between different sets of infrastructure that do not need to be kept in sync (Snap CD will only attempt to keep infrastructure in sync that is within the same **Stack**). This may be the case for example between "prod" and "pre-prod" / "qa" instructure stacks. Or you might be managing multiple sites, each with the same or similar (but largely independent) infrastructure definitions.

In these cases it might make sense to separate into different **Stack**. 

We do not recommend separating different functional areas within an infrastructure ecosystem into separate **Stacks**. For example, if your production infrastructure consists of large sub-projects dealing with networking, storage, applications etc., place all of these in the same **Stack**, but organise them into different **Namespaces** instead.

**Modules** can references the [outputs]({{< relref "how-it-works/outputs" >}}) from any other **Modules** within the same **Stack**

You can see the full **Stack** specification [here](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/stack).


## Namespace

A **Namespace** is a logical grouping of **Modules**. Typically you'll want to organize into a single **Namespace** those **Modules** that make sense to always roll out together. As an example, let's say we are currently concerned with defining our networking infrastructure. Let's assume that this is complicated enough to split into smaller **Modules**, such as for example for example a "VWAN", "VPN" and various "VPC" **Modules**. Here it would make sense to have a single "Networking" **Namespace**, with separate **Modules** for each of "VWAN", "VPN", etc.

**Namespaces** can easily be expanded with additional **Modules**. (For example if you wish to add another "VPC" to your networking **Namespace** at a later time.)

Organizing **Modules** into a **Namespace** allows you to set various defaults (which can be overriden on the **Module** spec), as well as allowing you to run special **Namespace**-scoped [Jobs]({{< relref "how-it-works/orchestration" >}}), such as "Execute Namespace", which will apply all **Modules** in the **Namespace** in the order dictated by the dependencies between them.

You can see the full **Namespace** specification [here](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace).

Default [Extra Files]({{< relref "resources/extra-files" >}}), **Parameters** and **Environment Variables** can also be set on the **Namespace's** child resource.


## Module

A **Module** represents a single OpenTofu/Terraform/Pulumi deployment spec that will be deployed in isolation. In other words, each **Module** will have its own state file, and it will have commands such as `init`, `plan`, `apply` and `output` called in the root of the folder where the code lives. A Snap CD **Module** defines (among other things) where the code to execute can be found (repository, revision, path to folder); which [Runner(s)]({{< relref "components/runner" >}}) to use for **Jobs** from this **Module** and how those runners should be select; [hooks]({{< relref "resources/hooks" >}}) that should be run before/after the `init`, `plan`, `apply`, `output` or `destroy` steps.

You can see the full **Module** specification [here](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module).

**Extra Files**,  **Parameters** and **Environment Variables** can also be set on the **Modules's** child resource.