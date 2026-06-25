---
title: Integration Events
weight: 5
sidebar:
  open: false
---

## Overview

An **Integration Event** is the demand side of the [Integration]({{< relref "resources/integration" >}}) model. It subscribes a trigger on a scope to a target integration, with an optional message template and filter. A notification is delivered only when **both** an Integration Event exists **and** the target integration is [supplied]({{< relref "resources/integration#supply" >}}) to the scope.

## Per-scope resources

Each scope has its own resource type:

| Resource | Scope | Scope field |
|----------|-------|-------------|
| [`snapcd_organization_integration_event`](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/organization_integration_event) | Organization | _(none)_ |
| [`snapcd_stack_integration_event`](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/stack_integration_event) | Stack | `stack_id` |
| [`snapcd_namespace_integration_event`](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_integration_event) | Namespace | `namespace_id` |
| [`snapcd_module_integration_event`](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_integration_event) | Module | `module_id` |

All share these common fields:

| Field | Description |
|-------|-------------|
| `integration_id` | Target integration |
| `trigger` | What to fire on (see [trigger catalog](#trigger-catalog)) |
| `template` | Optional message template; omit for the built-in default |
| `filter` | Optional filter expression |
| `is_disabled` | When `true`, the subscription is inert |

## Trigger catalog

| Group | Triggers |
|-------|----------|
| Job lifecycle | `JobSucceeded`, `JobFailed`, `JobAwaitingApproval`, `JobCancelled` |
| Mission | `MissionMilestoneReported` |

`JobApproved` and `JobDeclined` are defined in the enum but not yet wired to a consumer.

A mission's milestones for a single mission are threaded under one Slack message.

## Templates

Templates use `{{ token }}` substitution (no code execution). Unknown tokens render empty; omit `template` to use the built-in default for the trigger.

| Token | Available for |
|-------|---------------|
| `{{trigger}}`, `{{moduleName}}`, `{{moduleId}}`, `{{organizationId}}` | all |
| `{{stackName}}`, `{{namespaceName}}` | all |
| `{{jobId}}`, `{{jobUrl}}` | job and milestone triggers |
| `{{jobType}}` | job triggers (`Apply` / `Destroy`) |
| `{{missionType}}`, `{{kind}}`, `{{message}}` | mission triggers |

Example: `❌ {{jobType}} failed on *{{moduleName}}* ({{stackName}}/{{namespaceName}})\n{{jobUrl}}`
