---
title: State Migrations
weight: 4
sidebar:
  open: false
---

Most of what Snap CD runs is a plan and an apply: the code says what should exist, the engine works out the difference, and the state follows. A state migration is the other kind of change. It rewrites the state directly and leaves the infrastructure alone.

Use one when the state has drifted from how you want things described, rather than from what is deployed: an address needs renaming, a resource that already exists needs bringing under management, something needs to stop being managed without being destroyed, or a whole root needs splitting up.

These cannot be undone by running them again, so Snap CD holds the Module still while they run.

## Pausing

A state migration is only offered on a [Module]({{< relref "resources/stack-namespace-module#module" >}}) that is paused. A paused Module takes no part in the lifecycle: nothing triggers it, nothing dependency-driven dispatches to it, and apply and destroy are unavailable. One migration runs at a time.

Pausing is not managed by the Terraform provider. You pause a Module from its page or through the API, often mid-incident, which is exactly when its definition should not be changing. A provider-managed field would be reverted by the next apply, or show up as drift.

Every step can be cancelled, the write included. Stopping a migration half way is no worse than stopping an apply half way, and the decision is yours.

## The jobs

Four run the engine's own state commands against a single Module. Each takes a list of addresses and handles them one at a time, so if some work and some do not, you can see which:

| job | what it runs |
|---|---|
| **import** | brings a resource that already exists under this Module's management |
| **move** | renames an address within the state |
| **remove** | drops an address, leaving the resource itself running |
| **lookup addresses** | reports which of the addresses you give it are in the state |

Two are [demonolith](https://github.com/schrieksoft/demonolith) operations that rewrite more than one Module's state at once:

| job | what it does |
|---|---|
| **split** | a monolith becomes several Modules, each with its own state carved out of the original |
| **transfer** | resources move between two existing Modules, each with its own repository, runner and backend |

## Proving, and approval

Split and transfer prove before they write. The plan is built against the state as it will look afterwards, each affected Module is checked to have nothing left to change, and only then is approval asked for. Nothing is written until someone answers.

How many approvals it takes is set per Module, or inherited from its Namespace. It defaults to one rather than zero, because you cannot undo the write.

## Consent, for a transfer

A transfer also needs the other Module to agree. This is the only job that writes to a Module's state on another Module's behalf, so the receiving side grants it explicitly. Either side refusing ends the transfer with nothing written.

The two halves are separate jobs on separate runners that never see each other's working directory. So the state the giving side cuts out, and the output values the other needs to plan with, travel through the server. They are encrypted the same way state is, and deleted once neither job is still running.

## Where to go next

[Running a State Migration]({{< relref "guides/running-a-state-migration" >}}) walks through one from the Dashboard. [Splitting a Monolith]({{< relref "guides/splitting-a-monolith" >}}) covers the demonolith CLI workflow, which produces the code change that a split or transfer then migrates the state for.
