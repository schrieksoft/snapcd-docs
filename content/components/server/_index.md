---
title: Server
weight: 1
sidebar:
  open: false
---

## What it does

The **Server** is the centralised service that every other piece of Snap CD talks to. It hosts the Dashboard, the Web API, the MCP server, the SignalR hubs for [Runners]({{< relref "components/runner" >}}) and [Agents]({{< relref "components/agent" >}}), and the token endpoint. It owns the [resource catalogue]({{< relref "resources" >}}) ([Stacks]({{< relref "resources/stack-namespace-module#stack" >}}), [Namespaces]({{< relref "resources/stack-namespace-module#namespace" >}}), [Modules]({{< relref "resources/stack-namespace-module#module" >}}), Inputs, [Secrets]({{< relref "resources/secrets" >}}), Runners, Agents, [Missions]({{< relref "resources/mission" >}}), role assignments) and the durable record of every [Job]({{< relref "how-it-works/orchestration" >}}) that has run.

The Server does **not** execute Terraform, OpenTofu or Pulumi commands itself. It does not hold cloud credentials. Job execution is delegated to **Runners**, and AI-driven event handling is delegated to **Agents**. The Server's job is to authenticate callers, store resources and history, decide which Runner or Agent should handle a given piece of work, and dispatch that work over a hub connection.

## Deployment Models

Snap CD is offered in two editions, sharing the same Server codebase:

- **Cloud** — hosted by Schrieksoft at [snapcd.io](https://snapcd.io). You don't operate the Server; sign up and start configuring your organization.
- **Self-Hosted** — you run the Server yourself, on infrastructure you control. Source-available under the [Snap CD Source-Available License](https://github.com/schrieksoft/snapcd/blob/main/applications/snapcd/LICENSE.md), with tiering covered in the [Licensing](#licensing) section below.

The remainder of this page is relevant primarily to Self-Hosted operators. Cloud users do not need to deploy, configure, or license the Server.

## Hosted surfaces

The Server exposes the following surfaces over HTTP:

| Surface | Purpose |
|---------|---------|
| `/` (Dashboard) | The Blazor-based web UI for managing organizations, Stacks, Modules, Jobs, Runners, Agents and so on |
| `/api/**` | REST Web API — consumed by the Terraform provider, the Runner, the Agent, and any custom integration |
| `/mcp` | Model Context Protocol endpoint — consumed by the Agent's Sidecar and by interactive AI clients such as Claude Code |
| `/connect/token` | OpenIddict token endpoint — issues JWTs for Users and Service Principals via `client_credentials` |
| `/runnerhub` | SignalR hub — long-lived bidirectional connection used by Runners |
| `/agenthub` | SignalR hub — long-lived bidirectional connection used by Agent Instances |
| `/swagger` | OpenAPI documentation for the Web API |
| `/health` | Liveness / readiness probe |

## Self-Deployment Dependencies

The Server connects to a small set of external systems at runtime. One is required; the rest are optional and enabled via [settings]({{< relref "deployment/settings" >}}).

### Required

| Dependency | Notes |
|------------|-------|
| SQL Server (2019 or newer) | The Server's primary store. Used both for application data and as the default service-bus transport. Configured via `ConnectionString` |

### Optional

| Dependency                                                                 | When to use it |
|----------------------------------------------------------------------------|----------------|
| **Redis**                                                                  | Distributed cache and SignalR backplane when running multiple Server replicas. Configured via `Caching` |
| **Azure Service Bus**                                                      | Alternative service-bus transport for higher-throughput deployments. Configured via `ServiceBus` |
| **Secret Store** (Azure Key Vault)                                         | Backing store for Snap CD [Secrets]({{< relref "resources/secrets" >}}) — where Stack / Namespace / Module Secret values and sensitive Output Sets live encrypted at rest. Configured via `SecretStore`. Defaults to the Server's SQL Server database; AKV is a paid feature |
| **External Login** Provider (GitHub, Google, Microsoft, Okta, Auth0)       | SSO sign-in providers. Configured via `OpenIdConnect.ExternalLoginProviders`. Paid feature — gated by license tier. The Server runs an embedded OpenIddict instance for User and Service Principal authentication regardless |
| **Email Provider** (Amazon SES, SendGrid, Mailgun, Postmark, generic SMTP) | Outbound email for password resets and invitations. Configured via `EmailSender`. When unset (or set to `NoOp`), the Server runs in `NoOp` mode and email-driven flows are admin-mediated |
| **External Settings Vault** (Azure Key Vault, AWS Secrets Manager)         | Source of sensitive setting values loaded at startup via the [External Settings provider]({{< relref "deployment/settings#external-settings-provider" >}}) |

## Deployment

For Self-Hosted operators, see [Deployment > Guide > Server]({{< relref "deployment/guide#server" >}}) for the reference deployment repositories and the minimum Compose shape. Cloud users do not deploy the Server.

## Operations & observability

The Server emits logs to stdout via the standard MEL pipeline. Filter levels are controlled by the `Logging.LogLevel` section.

For runtime visibility:

- `/health` returns a basic liveness response and is suitable as a Kubernetes probe target
- The Dashboard's Jobs view shows real-time Job status and per-Job logs (logs come from Runners; see the [Runner page]({{< relref "components/runner" >}}))
- The Dashboard's Runners and Agents pages show real-time connection status for each connected Instance

Operational notes specific to Self-Hosted:

- **License caching** — resolved license state is cached in-process for 8 hours; the background refresh job pulls fresh tokens from Cloud more frequently. Restarting the Server forces a fresh resolution
- **Default Organization** — a Self-Hosted Server is single-organization by design. On first start, a default organization is pre-seeded; users register against it. There is no "platform" organization or multi-tenant separation on Self-Host
- **Scaling** — the Server is stateless. To scale horizontally, run multiple replicas with Redis configured as both the cache provider and the SignalR backplane. SQL Server remains a single shared store across replicas

## Licensing

Self-Hosted Snap CD is distributed under the [Snap CD Source-Available License](https://github.com/schrieksoft/snapcd/blob/main/applications/snapcd/LICENSE.md), derived from the Elastic License 2.0. The source code is available, but you may not provide Snap CD to third parties as a hosted or managed service.

### Tiers

The Self-Hosted Server runs in one of three modes, gated by a license token:

| Tier | License token | Notes |
|------|---------------|-------|
| **Community** | None | Free. A complete, supported configuration that you can run in production; it is not crippleware. Higher quotas and some features (SSO, bot protection) are reserved for higher tiers |
| **Community Plus** | Free | Same feature set as Community, raised quotas. Claim a free token by registering an organization on [snapcd.io](https://snapcd.io) |
| **Paid** | Subscription | Higher quotas still, plus additional features (SSO providers, the [Agent]({{< relref "components/agent" >}}) and Missions). Subscriptions managed on [snapcd.io](https://snapcd.io) |

For the current tier comparison and quotas, see the [Pricing page](https://snapcd.io/Pricing).

### Obtaining a license

License tokens are issued by the Cloud instance to organizations on snapcd.io. To get one:

1. Sign up on [snapcd.io](https://snapcd.io) and create (or log in to) the organization that owns the Self-Hosted deployment.
2. Claim a free **Community Plus** token, or visit the [Pricing page](https://snapcd.io/Pricing) and select a paid tier appropriate to your usage.
3. Copy the resulting license key (format: `shsk_…`) from the Cloud portal.
4. In your Self-Hosted Server's Dashboard, navigate to the **License** page under your organization, paste the key, and save.

The Server round-trips the key through Cloud to obtain a signed JWT license token, then caches it locally. A background job periodically refreshes the token so that Cloud-side subscription state (cancellation, plan changes, expiry) propagates to the Self-Host. Brief network outages between the Self-Host and Cloud do not affect availability — the cached token continues to be honoured until its expiry.

## Settings

The Server reads its settings from the standard layered pipeline described in [Deployment > Settings]({{< relref "deployment/settings" >}}) — `appsettings.json`, environment-specific overrides, environment variables, command-line arguments, and the External Settings provider.

Generated from the Server's published JSON Schema — the same schema operators reference via `"$schema"` in their `appsettings.json` to get editor IntelliSense. Click any section to expand its fields.

{{< settings component="server" exclude="Debugging,DebugDataSeeder" >}}
