---
title: Components
weight: 3
sidebar:
  open: false
---

Snap CD is made up of three components:

- **[Server]({{< relref "components/server" >}})** — the centralised service that hosts the Dashboard, Web API, MCP server, hubs for Runners and Agents, and the resource catalogue
- **[Runner]({{< relref "components/runner" >}})** — the self-hosted process that picks up [Jobs]({{< relref "how-it-works/orchestration" >}}) from the Server and executes Terraform / OpenTofu / Pulumi commands against your infrastructure
- **[Agent]({{< relref "components/agent" >}})** — the self-hosted process that consumes Snap CD events and runs AI-driven [Missions]({{< relref "resources/mission" >}}) in response. Enterprise-tier only

Each page covers what the component does, what must exist for it to start, how it's deployed, what settings it reads, how it behaves operationally, and where to look when something is wrong.

For the conceptual overview, see [The Basics]({{< relref "basics" >}}). For the resource catalogue (Stacks, Modules, Hooks, Secrets, Missions and so on) see [Resources]({{< relref "resources" >}}).
