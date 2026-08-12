---
title: Guides
weight: 7
sidebar:
  open: false
---

Operational procedures for running a self-hosted [Server]({{< relref "components/server" >}}). Where the [How it Works]({{< relref "how-it-works" >}}) section explains the mechanisms, this section gives the steps.

- **[Maintenance Mode]({{< relref "guides/maintenance-mode" >}})** — bringing the Server to a safe stop so infrastructure underneath it can be changed, without losing in-flight work
- **[Switching Service Bus]({{< relref "guides/switching-service-bus" >}})** — moving between the SQL Server and Azure Service Bus transports, or to a different Azure Service Bus namespace
- **[Monorepos]({{< relref "guides/monorepos" >}})** — scoping gitops triggers to the directories a Module depends on, and versioning components independently with tag prefixes
