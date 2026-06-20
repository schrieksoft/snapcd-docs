---
title: Integrations
weight: 4
sidebar:
  open: false
---

## Overview

An **Integration** sends SnapCd events — job lifecycle transitions and [Mission]({{< relref "resources/mission" >}}) milestones — to an external system. **Slack** is the first supported type; chat / alerting / ticketing sinks follow. Integrations are an Enterprise-tier feature.

Whether a given event reaches a given integration is decided by a **supply ∩ demand** model (the same shape used for Agents and Missions):

- **Supply** — which scopes an integration *serves* (supplies, or the org-wide flag).
- **Demand** — which trigger on which scope *should* notify an integration (an **Integration Event**).

A notification is delivered only when **both** hold: an Integration Event subscribes a trigger→integration on a scope, **and** that integration is supplied to that scope.

## Integration

The connection itself. Credentials and config are stored encrypted in the secret backend, never on the row — the API returns secret fields masked.

Because it carries a **write-only bot token**, an Integration is **created and managed in the SnapCd UI**, not by Terraform. In Terraform it is a **data source** (like Service Principal) — look one up by name and reference its `id`:

```hcl
data "snapcd_integration" "alerts" {
  name = "alerts"
}
```

Data source attributes:

| Field | Description |
|-------|-------------|
| `name` | Unique name (within type, per organization) — the lookup key |
| `id` | The integration's id — reference it from supplies, role assignments, and events |
| `integration_type` | e.g. `Slack` |
| `enabled` | When `false`, no deliveries are sent |
| `is_supplied_to_all_modules` | Org-wide supply — the integration serves every module |

The **connection (credentials)** — for Slack the bot token and default channel — is set in the UI and stored encrypted in the secret backend. It is **never exposed by this data source** (not even masked) and never lands in Terraform state.

Full specification: [`snapcd_integration` data source](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/data-sources/integration).

### Slack setup

1. Create a Slack app and add a **Bot Token Scope** of `chat:write`.
2. Install the app to the workspace and copy the **Bot User OAuth Token** (`xoxb-…`).
3. Invite the bot to the target channel.
4. Set `bot_token` + `default_channel` on the integration. Use **Test connection** in the UI (or the `POST {id}/test` endpoint) to verify.

## Supply

Before an integration can be notified for a Module, it must be **supplied** to that module's scope:

| Method | Description |
|--------|-------------|
| `is_supplied_to_all_modules` on the Integration | Serves every module in the org |
| `snapcd_integration_supply` (scope = Stack) | Serves every module under the stack |
| `snapcd_integration_supply` (scope = Namespace) | Serves every module in the namespace |
| `snapcd_integration_supply` (scope = Module) | Serves that single module |

There is deliberately no organization-scope supply — org-wide supply is the flag.

## Demand — Integration Events

An **Integration Event** subscribes a [trigger](#trigger-catalog) on a scope to a target integration, with an optional message template and filter.

| Field | Description |
|-------|-------------|
| `scope` | `Organization`, `Stack`, `Namespace`, or `Module` |
| `scope_id` | Id of the stack/namespace/module (omit for `Organization`) |
| `integration_id` | Target integration |
| `trigger` | What to fire on (see catalog) |
| `template` | Optional message template; omit for the built-in default |
| `filter` | Optional filter expression |
| `is_disabled` | When `true`, the subscription is inert |

Full specification: [`snapcd_integration_event`](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/integration_event).

### Trigger catalog

| Group | Triggers |
|-------|----------|
| Job lifecycle | `JobSucceeded`, `JobFailed`, `JobAwaitingApproval`, `JobApproved`, `JobDeclined`, `JobCancelled` |
| Mission | `MissionStarted`, `MissionMilestoneReported`, `MissionCompleted`, `MissionFaulted` |

A mission's milestones for a single mission are threaded under one Slack message.

### Templates

Templates use `{{ token }}` substitution (no code execution). Unknown tokens render empty; omit `template` to use the built-in default for the trigger.

| Token | Available for |
|-------|---------------|
| `{{trigger}}`, `{{moduleName}}`, `{{moduleId}}`, `{{jobId}}`, `{{organizationId}}` | all |
| `{{jobType}}` | job triggers (`Apply` / `Destroy`) |
| `{{missionType}}`, `{{kind}}`, `{{message}}` | mission triggers |

Example: `❌ {{jobType}} failed on *{{moduleName}}* (job {{jobId}}).`

## Access control (RBAC)

Integration management mirrors the Agent permission model exactly:

- **Organization roles** `IntegrationCreator` / `IntegrationContributor` / `IntegrationReader` govern the integration entity (alongside `Owner` / `Contributor` / `Reader`).
- **Per-integration roles** `IntegrationRole` (`Owner` / `Contributor` / `Reader` / `IdentityAccessManager`) — granted to a user, group, or service principal via `snapcd_integration_role_assignment` — govern the integration's child resources (its role assignments), resolved directly or transitively through group membership.

Full specification: [`snapcd_integration_role_assignment`](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/integration_role_assignment).

## Operator notes

- **Secrets** — each integration's connection is one encrypted blob in the org's input vault at `integration--{organizationId}--{id}`. The integration row holds only identity/routing; deletes remove the blob too.
- **Credential cache** — the send path caches each integration's connection (credentials) in a per-instance in-memory cache (15-minute TTL) so it doesn't read the secret backend on every event. It is invalidated cross-instance by a fanout consumer on integration CRUD, so a rotated token is never served stale.
- **Dispatch** — a single competing consumer per server pool turns saga/mission events into deliveries; delivery is idempotent per (occurrence, subscription). Each attempt is recorded as an `IntegrationDelivery` audit row (status, error, sink message id).
