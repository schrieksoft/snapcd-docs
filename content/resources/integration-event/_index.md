---
title: Integration Events
weight: 5
sidebar:
  open: false
---

## Overview

An **Integration Event** is the demand side of the [Integration]({{< relref "resources/integration" >}}) model. It subscribes a trigger on a scope to a target integration, with an optional message template and filter. A notification is delivered only when **both** an Integration Event exists **and** the target integration is [supplied]({{< relref "resources/integration#supply" >}}) to the scope.

## Integration Event

| Field | Description |
|-------|-------------|
| `scope` | `Organization`, `Stack`, `Namespace`, or `Module` |
| `scope_id` | Id of the stack/namespace/module (omit for `Organization`) |
| `integration_id` | Target integration |
| `trigger` | What to fire on (see [trigger catalog](#trigger-catalog)) |
| `template` | Optional message template; omit for the built-in default |
| `filter` | Optional filter expression |
| `is_disabled` | When `true`, the subscription is inert |

Full specification: [`snapcd_integration_event`](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/integration_event).

## Trigger catalog

| Group | Triggers |
|-------|----------|
| Job lifecycle | `JobSucceeded`, `JobFailed`, `JobAwaitingApproval`, `JobApproved`, `JobDeclined`, `JobCancelled` |
| Mission | `MissionStarted`, `MissionMilestoneReported`, `MissionCompleted`, `MissionFaulted` |

A mission's milestones for a single mission are threaded under one Slack message.

## Templates

Templates use `{{ token }}` substitution (no code execution). Unknown tokens render empty; omit `template` to use the built-in default for the trigger.

| Token | Available for |
|-------|---------------|
| `{{trigger}}`, `{{moduleName}}`, `{{moduleId}}`, `{{jobId}}`, `{{organizationId}}` | all |
| `{{jobType}}` | job triggers (`Apply` / `Destroy`) |
| `{{missionType}}`, `{{kind}}`, `{{message}}` | mission triggers |

Example: `❌ {{jobType}} failed on *{{moduleName}}* (job {{jobId}}).`
