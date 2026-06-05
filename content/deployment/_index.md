---
title: Deployment
weight: 4
sidebar:
  open: false
---

This section covers the cross-cutting operational concerns that apply to all three Snap CD [components]({{< relref "components" >}}) — Server, Runner and Agent. The per-component pages cover what each binary does and the settings sections it reads; this section covers the mechanisms behind those settings and the reference deployments that wire it all together.

- **[Settings]({{< relref "deployment/settings" >}})** — how `appsettings.json`, environment variables and the External Settings provider compose into the runtime configuration each component process reads
- **[Guide]({{< relref "deployment/guide" >}})** — pointers to the standalone reference-deployment repositories (Docker / Compose, Kubernetes, local) for each component, with the minimum shape for orienting yourself
