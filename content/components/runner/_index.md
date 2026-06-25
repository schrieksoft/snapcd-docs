---
title: Runner
weight: 2
sidebar:
  open: false
---

## What it does

The **Runner** is the self-hosted process that executes the work the [Server]({{< relref "components/server" >}}) hands out. When a [Module]({{< relref "resources/stack-namespace-module#module" >}}) [Job]({{< relref "how-it-works/orchestration" >}}) is dispatched, a Runner picks it up over its SignalR connection, fetches the Module source, materialises [Inputs]({{< relref "resources/module-inputs" >}}) and [Extra Files]({{< relref "resources/extra-files" >}}) into the working directory, executes the configured [engine]({{< relref "resources/engine" >}}) commands (`init`, `plan`, `apply`, `destroy`, `output`), streams logs back to the Server in real time, and reports the final status.

The Runner is where credentials with real blast radius live: cloud provider keys, Kubernetes service accounts, on-prem API tokens. By deploying Runners with narrowly scoped permissions and binding Modules to them via [Runner Supplies]({{< relref "resources/runner#allowing-a-module-to-use-a-runner" >}}), you control which Modules can act on which infrastructure. The Server itself never holds these credentials.

The Runner is bundled with Snap CD in both editions and is not license-gated — Cloud-edition customers run their own Runners against `snapcd.io`, and Self-Hosted customers run them against their own Server.

## Prerequisite Server Resources

The following resources must exist on the Server before a Runner can connect and pick up Jobs:

| Resource | Notes |
|----------|-------|
| [Service Principal]({{< relref "resources/identity-access-management#service-principal" >}}) | The identity the Runner authenticates as. The Runner uses its `ClientId` and `ClientSecret` to obtain JWTs from `/connect/token` |
| [Runner record]({{< relref "resources/runner" >}}) | The Runner binds to this record. Its `Id` is what the Runner reports via `Runner.Id`, and its `ServicePrincipalId` must reference the Service Principal above |
| [Runner Supply]({{< relref "resources/runner#allowing-a-module-to-use-a-runner" >}}) | At least one, covering every Module the Runner is to handle. Created at Stack / Namespace / Module scope, or shortcut via `is_supplied_to_all_modules` on the Runner record |

## Other Prerequisites

What must be present on the Runner host or its network:

| Prerequisite | Notes |
|--------------|-------|
| Engine binary | `terraform`, `tofu` or `pulumi` must be present on `PATH` (or via `Engine.AdditionalBinaryPaths`) for whichever Engines you intend to use |
| Network egress to the Server | A long-lived outbound HTTPS / Websocket connection to the Server's `/runnerhub`. No inbound ports are required on the Runner host |
| Provider credentials | Whatever the Modules running on this Runner need — cloud credentials, kubeconfig, on-prem tokens. Bound to the host (env vars, instance metadata, mounted kubeconfig) |
| Writable working directory | Path for fetched Module source and engine state. Defaults to `~/.snapcd/runner` |

## Deployment

See [Deployment > Guide > Runner]({{< relref "deployment/guide#runner" >}}) for the reference deployment repositories (Docker, Kubernetes, local) and the minimum Compose shape.

## Connection model

A Runner connects to the Server's `/runnerhub` with a JWT obtained via `client_credentials` against `/connect/token`. The connection is long-lived and bidirectional:

- **Server → Runner.** Job dispatches, cancellation signals, and configuration updates
- **Runner → Server.** Log envelopes, step status updates, terminal Job results

When the Runner connects, it announces its `Runner.Instance` name. The Server records the connection in the database. Job dispatch then targets either:

- **Any available Runner** against this record (the default — first to respond handles the Job)
- **A specific Runner**, when the Module sets `runner_instance_name` to pin to one by name

### Reconnect and outages

The SignalR client reconnects automatically. While disconnected:

- Outgoing log envelopes buffer in-process; on reconnect, the buffer flushes
- The Runner does not pull new Jobs (it can't — dispatch is push-based)
- Jobs already in-flight continue executing locally; their terminal status posts on reconnect

The Server treats a Runner as offline once its `RunnerConnection` row is gone. A Runner that crashes hard mid-Job will resume reporting on its next start; the Server reconciles by treating any Job whose owning Runner has disconnected as eligible for the next available one.

### Multiple Runners per record

When the Runner record has `allow_multiple_instances = true`, you can run replicas (for example a Kubernetes StatefulSet with `replicas: 3`). Job dispatch follows the [Runner Selection]({{< relref "resources/runner#runner-selection" >}}) model — by default the Server broadcasts each Job to all connected Runners and the first to respond handles it. Each replica must report a distinct `Runner.Instance` name.

## Operations & observability

The Runner emits two kinds of logs:

- **Runtime / diagnostic logs** — standard MEL `ILogger` output to stdout, filtered by the `Logging.LogLevel` section. These cover Runner startup, connection events, Job pickup and so on
- **Job logs** — the engine output for each Job step, shipped to the Server in batches over the `/runnerhub` connection and visible in the Dashboard's Jobs view. These are *not* written to stdout

Job-log shipping is batched: the Runner accumulates events for `JobLogStream.PeriodSeconds` (default `5`) or up to `JobLogStream.BatchSizeLimit` (default `50`), whichever comes first, then ships a single batch. The first event of each batch ships immediately when `JobLogStream.EagerlyEmitFirstEvent` is true (default), keeping initial Job output responsive on the Dashboard.

The Runner has no built-in dashboard. Operator-facing visibility is the Server's Dashboard:

- The **Runners** page shows each Runner record with its connected processes and a live online / offline badge
- The **Jobs** view shows in-flight Jobs and streams their logs as they arrive

For the Runner host itself, treat it as a standard container workload: stdout to your log aggregator, container metrics to your usual collector.

## Settings

The Runner reads its settings from the standard layered pipeline described in [Deployment > Settings]({{< relref "deployment/settings" >}}). Production deployments typically source `Runner.Credentials.ClientSecret` from a vault via the [External Settings provider]({{< relref "deployment/settings#external-settings-provider" >}}) rather than placing it in plain-text settings.

Generated from the Runner's published JSON Schema — the same schema operators reference via `"$schema"` in their `appsettings.json` to get editor IntelliSense. Click any section to expand its fields.

{{< settings component="runner" >}}

See the [Resources]({{< relref "resources" >}}) area for per-resource semantics (Hooks, Engine, and so on).