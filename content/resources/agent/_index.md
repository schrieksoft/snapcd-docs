---
title: Agents
weight: 3
sidebar:
  open: false
---

## Overview

An **Agent** is a resource that defines a target for [Mission]({{< relref "resources/mission" >}}) execution. One or more **Agent Instances** connect to an **Agent** to receive event-triggered missions and run AI-driven work in response. Agents are an Enterprise-tier feature.

## Agent

An **Agent** defines the configuration for mission execution, including which [Service Principal]({{< relref "resources/identity-access-management" >}}) is used for authentication and whether the agent is available to all modules.

| Field | Description |
|-------|-------------|
| `name` | Unique name of the Agent |
| `service_principal_id` | ID of the Service Principal used by Agent Instances to authenticate |
| `is_supplied_to_all_modules` | When `true`, any Module can be served by this Agent |
| `is_disabled` | When `true`, the Agent will not receive new Missions |
| `allow_multiple_instances` | When `true`, multiple Agent Instances can connect simultaneously |

You can find the full **Agent** specification [here](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/agent).

## Agent Instance

An **Agent Instance** is the actual process that supervises **Sidecar** subprocesses and executes Missions. Each instance identifies itself with an instance name when it connects.

- When `allow_multiple_instances` is `false` (default), only one instance can connect to the Agent at a time
- When `allow_multiple_instances` is `true`, multiple instances (e.g. a Kubernetes StatefulSet with multiple replicas) can connect simultaneously

## Allowing an Agent to serve a Module

Before an **Agent** can pick up Missions for a **Module**, a supply must exist. Supplies can be configured at different scopes:

| Method | Description |
|--------|-------------|
| `is_supplied_to_all_modules` on Agent | Allows the Agent to serve any Module |
| [Agent Stack Supply](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/agent_stack_supply) | All Modules within the Stack can be served by the Agent |
| [Agent Namespace Supply](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/agent_namespace_supply) | All Modules within the Namespace can be served by the Agent |
| [Agent Module Supply](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/agent_module_supply) | Only the specified Module can be served by the Agent |

## Security Model

Two independent permission axes apply to every Agent:

| Axis | Mechanism |
|------|-----------|
| **Management** — who can administer the Agent record | `User`, `Service Principal` or `Group` Agent Role Assignments granting `Owner`, `Contributor`, `Reader` or `IdentityAccessManager` |
| **Operational** — what the Agent's Service Principal can actually do | The Service Principal's existing organization, stack, namespace and module role assignments |

The Agent record is governed by the management axis. The work the Agent performs against Snap CD (reading jobs, posting approval recommendations, fetching logs) is governed by the Service Principal's operational permissions — exactly as for any other Service Principal call.

Grant the Service Principal only the operational permissions the configured Missions require. Use narrow Agent Supplies to scope which Modules an Agent serves. Use separate Agents for different environments (dev, staging, production) where the underlying permissions differ.

## Edition Availability

Agents are available on the **Enterprise** tier only. You can manage Agents from the Dashboard, the Web API, or the Terraform provider once your organization's license includes the Autonomous Agent feature.
