---
title: Maintenance Mode
weight: 1
sidebar:
  open: false
---

Maintenance Mode brings the [Server]({{< relref "components/server" >}}) to a controlled stop so you can change the infrastructure underneath it — restart the Server, migrate the database, resize a cluster, or [switch the service bus]({{< relref "guides/switching-service-bus" >}}) — without losing work that is in flight.

The problem it solves is that a **Job** is not atomic. A running [Job]({{< relref "how-it-works/orchestration" >}}) has a task executing on a [Runner]({{< relref "components/runner" >}}), messages on the bus, and a saga mid-state in the database. Stopping the Server at an arbitrary moment strands all three. Maintenance Mode holds new work at a gate, lets what is already running play out, and then re-drives everything that was held once you are finished.

Find it in the Dashboard under **Admin Center → Maintenance**.

## The gate

Opening a window raises a gate. Work that would have started is not rejected and not lost — it is *queued*, marked with the reason `Maintenance`, and left in the database. Jobs that were already dispatched are untouched and allowed to finish.

This is why the window cannot simply be closed once work has parked behind it: something has to wake the parked jobs and re-drive the queued modules. That is what the Resuming phase does, and the panel will not let you skip it.

## The four phases

A window moves through four phases in order. Two of them are **waiting** phases that converge on their own, and two are **acting** phases that perform work.

| Phase | Kind | What is happening |
| --- | --- | --- |
| **Draining** | waiting | New jobs are held while tasks already running on a Runner play out and the last messages clear the bus. |
| **Ready for maintenance** | waiting | Nothing is executing and the bus is empty. This is where you do the disruptive work. |
| **Reconciling** | acting | Timers are re-derived from the database. |
| **Resuming** | acting | Parked jobs are woken and queued modules are re-driven. |

Each phase lists the criteria that must be met before it can be left, under **Before leaving _phase_**. Where a criterion is not met, the panel names the specific items holding it back — the job, its module, its state and its Runner — so "why can I not proceed" is answerable on the page rather than in the database.

### Draining

Four criteria have to go green:

- **No job mid-step** — every running task has finished and its job has parked.
- **No cancellation outstanding** — cancellations resolve in seconds, so one still open is stranded rather than slow.
- **No mission mid-run** — a [Mission]({{< relref "resources/mission" >}}) runs on an [Agent]({{< relref "components/agent" >}}) and writes its result back; interrupting it loses the run. Missions that are merely waiting for an Agent are excluded, since like a parked job they survive the window untouched.
- **Transport idle** — no active messages outside the diagnostic queues.

Scheduled messages are deliberately *not* drained. They are re-derived from the database during Reconciling, so a timer that was due to fire during the window is not lost.

### Ready for maintenance

Nothing is executing and the bus is empty. This is the only phase where it is safe to restart the Server or change infrastructure it depends on.

Its single criterion — *disruptive work complete* — never turns green on its own, because only you know whether the work this window was opened for is finished. Advance it by hand when you are done.

### Reconciling and Resuming

These two run actions rather than wait for conditions. Reconciling re-derives the transport timers from the database. Resuming lowers the gate, then sweeps: it wakes parked jobs by Runner group and re-drives the modules that were queued.

Both record what they did, so the panel reports the outcome — "woke 3 runner group(s), re-drove 12 queued module(s)" — rather than just claiming success. Both are idempotent; re-running the sweep is harmless.

Order matters in Resuming: the gate has to be down *before* the sweep publishes, because the events it sends land in activities that drop them while a window is open. Sweeping first would recover nothing. The panel handles this for you.

## Closing a window

Closing behaves differently depending on where you are:

- From **Draining**, nothing has parked yet, so the window can simply be closed.
- From **Resuming**, the sweep has already run, so closing is the normal way to finish.
- From **Ready for maintenance** or **Reconciling**, jobs are parked and modules are queued with nothing scheduled to wake them. The window cannot just be closed — take it through Reconciling and Resuming instead.

Finishing the Resuming phase closes the maintenance window but leaves the page open, so you can confirm every phase went green before navigating away.

## When something will not drain

Two escape hatches sit on the panel, and both are failsafes rather than routine steps.

**Cancel all jobs** stops everything non-terminal. Three cancellation types are offered:

- `ImmediateGraceful` — let the current step stop cleanly.
- `AfterCurrent` — wait for the current step to finish.
- `ImmediateKill` — stop now. May leave state locked, so treat it as a last resort.

**Cancel holding missions** deals with a mission whose Agent will never answer. A mission run keeps the connection id it was dispatched on, so that id outlives the Agent that held it; only a live connection record proves the Agent is still there to be asked. Runs with no live Agent behind them are marked cancelled directly rather than waiting on a reply that cannot come.

A mission whose Agent has gone will not time out on its own. If a drain is not progressing and the mission monitor shows runs that are not advancing, this is the tool for it.

## System monitors

Below the phase panel, three monitors show the same state the criteria are computed from. They poll while the page is open, so you can watch a drain tick down rather than refreshing by hand.

- **Jobs** — where every job currently rests: in flight, cancelling, parked, awaiting approval, queued by maintenance, queued for other reasons, and active missions. A **stuck jobs** table calls out jobs resting far longer than expected, since those are what will hold a drain up.
- **Missions** — unfinished mission runs grouped by type and status, with an explicit column for whether each group holds the drain open.
- **Transport** — queue depths, with active, scheduled, error and dead-letter counts per queue.

The monitors are worth watching before you open a window as well as during one: a drain that is going to be slow is usually visible in the stuck-jobs table beforehand.
