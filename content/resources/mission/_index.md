---
title: Missions
weight: 6
sidebar:
  open: false
---

## Overview

A **Mission** is a binding that tells Snap CD which kind of AI work should run, on which [Agent]({{< relref "components/agent" >}}), and at which scope. When a triggering event occurs on a [Module]({{< relref "resources/stack-namespace-module#module" >}}) [Job]({{< relref "how-it-works/orchestration" >}}) that falls within a Mission's scope, Snap CD dispatches the Mission to the named Agent. Missions are an Enterprise-tier feature and require at least one **Agent** to be configured.

## Mission Types

The set of Mission Types is fixed. Each type is bound to a triggering Snap CD event and a specific kind of AI output.

| Mission Type | Trigger | What it does |
|--------------|---------|--------------|
| `AutoDiagnose` | Module Job fails | Posts a diagnosis of the failure (root cause hypothesis, relevant log excerpts, suggested next steps) |
| `ApprovalRecommend` | Module Job reaches approval-required state | Posts a recommendation on whether to approve the plan, based on the plan output and the Module's history |
| `SummarizeJob` | Module Job succeeds | Posts a plain-language summary of what the Job changed |
| `AutoFix` | Module Job fails | Attempts an automated fix based on the failure diagnosis, then retries the Job |

## Mission Resources

A Mission is declared at one of four scopes. Choose the scope at which you want the trigger to apply: an `OrganizationMission` fires for every Module Job in the organization, a `ModuleMission` only for the named Module.

| Resource | Scope | Description |
|----------|-------|-------------|
| [Organization Mission](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/organization_mission) | Organization-wide | Mission fires for any Module Job in the organization |
| [Stack Mission](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/stack_mission) | One Stack | Mission fires for Module Jobs in any Module under the Stack |
| [Namespace Mission](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_mission) | One Namespace | Mission fires for Module Jobs in any Module under the Namespace |
| [Module Mission](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_mission) | One Module | Mission fires for Module Jobs on the named Module |

Each Mission resource carries the same configuration fields, plus the scope reference appropriate to its level (`stack_id`, `namespace_id`, or `module_id`):

| Field | Description |
|-------|-------------|
| `agent_id` | The Agent that runs this Mission |
| `mission_type` | One of `AutoDiagnose`, `ApprovalRecommend`, `SummarizeJob`, `AutoFix` |
| `sidecar_name` | Optional. Selects which Sidecar on the Agent handles this Mission. When unset, the Agent's default Sidecar is used |
| `is_disabled` | When `true`, the Mission is registered but will not be dispatched |

## Dispatch

When a triggering event occurs, Snap CD evaluates the active set of Mission rows that cover the affected Module Job. For each match, Snap CD checks that the named Agent has an Agent Supply covering the Module (or has `is_supplied_to_all_modules` set), then dispatches the Mission directly to a connected Agent Instance.

A Mission whose Agent is online but lacks a supply covering the Module is parked and will dispatch automatically once a covering supply is added (or once the Agent's `is_supplied_to_all_modules` flag is enabled).

A Mission whose Agent has no connected Instances at dispatch time is parked and will dispatch automatically once any Instance of that Agent reconnects.

Each `(Module Job, Mission Type)` pair runs at most one Mission at a time. Snap CD enforces this lock server-side: if two Instances of the same Agent both pick up the event, exactly one wins and the other defers cleanly.

## Sidecars

A **Sidecar** is the process on the Agent host that actually produces AI output for a Mission. The bundled `claude-sidecar` runs Anthropic's Claude with your organization's API key.

The Sidecar to use for a given Mission is selected by the Mission's `sidecar_name` field. Leave it unset to fall back to the Agent's default Sidecar (the typical configuration when an Agent host runs a single Sidecar).

You can run multiple Sidecars per Agent — for example a Claude-based Sidecar for diagnosis Missions and a different-provider Sidecar for summary Missions — by configuring more than one Sidecar on the Agent host and routing each Mission Type to the appropriate one via `sidecar_name`.

## Edition Availability

Missions are available on the **Enterprise** tier only and require a configured **Agent**.
