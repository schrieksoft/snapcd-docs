---
title: The Basics
weight: 1
sidebar:
  open: false
---


### The Server
The **Server** is the centralised service responsible for the [resource catalogue]({{< relref "resources" >}}), [orchestration]({{< relref "how-it-works/orchestration" >}}), [output storage]({{< relref "how-it-works/outputs" >}}) and [log storage]({{< relref "how-it-works/logs" >}}).

Snap CD is offered in two editions:

- **Cloud** — hosted by Schrieksoft at [snapcd.io](https://snapcd.io). The fastest way to get going; no infrastructure to operate.
- **Self-hosted** — you run the Server yourself, on infrastructure you control. See [Server]({{< relref "components/server" >}}) for the deployment guide and the licensing model.

In both editions, the Server's responsibilities are the same. The two editions also share the same [Terraform Provider](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs), [Runner](https://github.com/schrieksoft/snapcd/tree/main/SnapCd.Runner) and Web API.

### The Runner
[Runners]({{< relref "components/runner" >}}) are self-hosted execution agents, that you deploy in a manner and place of your choosing. Runners use bearer tokens to establish a long-lived, authenticated Websocket connection with the **Server**. Runners pick up jobs and report back via this connection. A **Runner** is associated with a **Service Principal** on your **Organization**.

### The Agent
[Agents]({{< relref "components/agent" >}}) are self-hosted AI workers that respond to events on your **Modules** by running [Missions]({{< relref "resources/mission" >}}) — diagnosing failed jobs, recommending whether to approve a plan, or summarising what a successful job changed. Like Runners, Agents are deployed wherever you choose and connect to the **Server** over a long-lived, authenticated Websocket using bearer tokens, and each **Agent** is associated with a **Service Principal** on your **Organization**. Agents are an **Enterprise**-tier feature.

### Terraform Provider
We are an IaC-first enterprise, so almost everything you can do via the **Server's** Dashboard can also be managed via our [Terraform Provider](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs). The Server's API can be interacted with by **Users** or **Service Principals**. **Users** can generate access tokens via the Dashboard. **Service Principals** make use of "Client Id"/"Client Secret" pairs in order to obtain an access token. The Terraform Provider authenticates against the API via the same mechanisms.

### Modules
On **Snap CD** a single unit of infrastructure is referred to as a [Module]({{< relref "resources/stack-namespace-module#module" >}}). A **Module** points to Terraform/OpenTofu/Pulumi code (e.g Git reference); can have [Inputs]({{< relref "resources/module-inputs" >}}) from various sources; has its own state file; and is deployed by a **Runner**. Its [Outputs]({{< relref "how-it-works/outputs" >}}) are securely stored on the **Server**, which can in turn be used as **Inputs** for other **Modules**, thereby creating a dependency graph.

### Namespaces
**Modules** are organized into [Namespaces]({{< relref "resources/stack-namespace-module#namespace" >}}).

### Stacks
**Namespaces** are organized into [Stacks]({{< relref "resources/stack-namespace-module#stack" >}}). A **Stack** represents a hard delineation. **Modules** in different **Stacks** do not influence one another. 

> We recommend having only a handful of **Stacks** (e.g. "dev", "test" and "prod") and using **Namespaces** to delineate functional component groupings (e.g. "Networking", "Storage", "Customer Portal" or whatever the case may be).
