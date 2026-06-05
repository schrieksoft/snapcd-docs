---
title: Agent
weight: 3
sidebar:
  open: false
---

## What it does

The **Agent** is the self-hosted process that consumes Snap CD events and runs AI-driven [Missions]({{< relref "resources/mission" >}}) in response. When a [Module]({{< relref "resources/stack-namespace-module#module" >}}) [Job]({{< relref "how-it-works/orchestration" >}}) fails, reaches an approval-required state, or succeeds, the [Server]({{< relref "components/server" >}}) matches the event against active Mission rows, picks an Agent that covers the Module, and pushes a per-Mission dispatch instruction to a connected Agent Instance.

The Agent itself does no AI work directly. It supervises one or more **Sidecar** subprocesses (the bundled `claude-sidecar` runs Anthropic's Claude with your API key) and routes each Mission to the appropriate Sidecar. Output from the Sidecar — diagnoses, approval recommendations, Job summaries — is posted back to the Server, attached to the Module Job, and rendered in the Dashboard.

The Agent is provider-agnostic: it ships no AI SDK and holds no AI provider keys. Those live on the Sidecar.

## Edition Availability

The Agent is an **Enterprise**-tier feature. The corresponding management surfaces (the `/Agents` page, the Mission resources, the `/agenthub` connection) are gated by the `Autonomous Agent` license entitlement and are hidden on Community and Cloud-Free tiers.

## Prerequisite Server Resources

The following resources must exist on the Server before an Agent can connect and start running Missions:

| Resource | Notes |
|----------|-------|
| [Service Principal]({{< relref "resources/identity-access-management#service-principal" >}}) | The identity the Agent authenticates as. The Agent uses its `ClientId` and `ClientSecret` to obtain JWTs from `/connect/token` |
| [Agent record]({{< relref "resources/agent" >}}) | The Agent binds to this record. Its `Id` is what the Agent reports via `Agent.Id`, and its `ServicePrincipalId` must reference the Service Principal above |
| [Operational role assignments]({{< relref "resources/identity-access-management" >}}) on the Service Principal | The Service Principal needs the role grants its configured Missions require — typically `OrganizationRole.Reader`, plus `JobManager` if any Mission needs to record approval decisions |
| [Agent Assignment]({{< relref "resources/agent#allowing-an-agent-to-serve-a-module" >}}) | At least one, covering every Module the Agent is to serve. Created at Stack / Namespace / Module scope, or shortcut via `is_assigned_to_all_modules` on the Agent record |
| [Mission]({{< relref "resources/mission" >}}) | At least one Mission at some scope covering the target Modules. Until one exists, the Agent will connect but receive no work |

## Other Prerequisites

What must be present on the Agent host or its network:

| Prerequisite | Notes |
|--------------|-------|
| Network egress to the Server | A long-lived outbound HTTPS / Websocket connection to the Server's `/agenthub`, plus HTTPS to `/mcp` and `/connect/token`. No inbound ports are required on the Agent host |
| Sidecar AI provider credentials | Each Sidecar needs its own provider key (for `claude-sidecar`, an Anthropic API key). Supplied via the Sidecar's environment, not the Agent's |

## Deployment

See [Deployment > Guide > Agent]({{< relref "deployment/guide#agent" >}}) for the reference deployment repositories (Docker, Kubernetes) and the minimum Compose shape — Agent process plus its Sidecar sibling(s).

## Connection model

An Agent Instance connects to the Server's `/agenthub` with a JWT obtained via `client_credentials` against `/connect/token`, augmented with an `agent_id` claim that identifies it as acting on behalf of the Agent record (rather than as the bare Service Principal).

The connection is long-lived and bidirectional:

- **Server → Agent.** Per-Mission dispatch instructions and domain events the SP's role visibility allows it to see
- **Agent → Server.** Per-Mission log envelopes and terminal result postings

The hub validates the connect attempt against three things at once: the JWT's `agent_id` claim must match the `agent_id` query parameter, the JWT's `sub` claim must match `Agent.ServicePrincipalId`, and the Agent record must not be disabled.

### Reconnect, parking and outages

The SignalR client reconnects automatically. While disconnected, the Server treats Missions that match this Agent as **parked** rather than failed — a parked Mission resumes dispatch as soon as any Instance of the Agent reconnects. The Server also parks Missions when an Agent is online but lacks an Agent Assignment covering the Module; those dispatch automatically once a covering assignment is added.

### Multiple instances

When the Agent record has `allow_multiple_instances = true`, you can run replicas. Each Instance connects with a distinct `Agent.Instance` name. Mission dispatch goes to one connected Instance; a server-side run lock ensures that exactly one Instance handles a given `(Module Job, Mission Type)` pair even if dispatch races.

## Sidecars

A **Sidecar** is the process on the Agent host that actually produces AI output. The Agent itself is provider-agnostic and never makes AI calls; it dispatches each Mission to a Sidecar over `localhost` HTTP.

The bundled `claude-sidecar` runs Anthropic's Claude via the `claude-agent-sdk` and exposes:

- `POST /invoke` — receives a Mission dispatch (Mission type, scope context, rendered skill prompt, fresh Snap CD MCP token) and runs the Mission session
- `GET /health` — used by the Agent's supervisor to detect crashes and restart

Each Mission's `sidecar_name` field selects which Sidecar handles it. When `sidecar_name` is unset (the typical case), the Agent's single configured Sidecar handles the Mission.

You can run multiple Sidecars per Agent — for example a Claude-based Sidecar for diagnosis Missions and a different-provider Sidecar for summary Missions — by configuring more than one entry in the Agent's `Sidecars` array and setting `sidecar_name` on each Mission. Each Sidecar holds its own provider credentials and its own MCP-client configuration.

## Operations & observability

The Agent emits MEL log output to stdout, filtered by the `Logging.LogLevel` section. Sidecar processes log to their own stdout as separate containers; aggregate both alongside your other workload logs.

For runtime visibility:

- The Dashboard's **Agents** page shows each Agent with its connected Instances and a live online / offline badge
- Each Module Job's **Missions** sub-view shows the Missions that fired for that Job, their per-Mission status, and the AI output / log buffer produced by each Mission
- The Dashboard's audit views render attribution for any action taken by an Agent as "Agent X operating as Service Principal Y"

A Mission whose run hangs or fails is visible per-Job rather than per-Agent — the Agent's own logs cover supervisor and dispatch events, while Mission output lives on the Server with the Job it ran against.

## Settings

The Agent reads its settings from the standard layered pipeline described in [Deployment > Settings]({{< relref "deployment/settings" >}}). Production deployments typically source `Agent.Credentials.ClientSecret` from a vault via the [External Settings provider]({{< relref "deployment/settings#external-settings-provider" >}}).

Generated from the Agent's published JSON Schema — the same schema operators reference via `"$schema"` in their `appsettings.json` to get editor IntelliSense. Click any section to expand its fields.

{{< settings component="agent" >}}

## Per-Sidecar settings

Sidecar processes run alongside the Agent and read their own configuration — typically environment variables on the Sidecar container, not the Agent's `appsettings.json`. The fields vary per Sidecar; for the bundled `claude-sidecar`:

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_API_KEY` | The Anthropic API key the Sidecar uses (BYOK) |
| `SNAPCD_BASE_URL` | Base URL of the Snap CD Server's MCP endpoint |
| `SKILL_SOURCE` | Where Mission skills come from — `mcp` (default; pulls from Snap CD's MCP server), `local`, or `local-then-mcp` |
