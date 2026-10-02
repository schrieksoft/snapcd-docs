---
title: Running a State Migration
weight: 5
sidebar:
  open: false
---

A state migration rewrites a [Module]({{< relref "resources/stack-namespace-module#module" >}})'s state without changing what is deployed. For what each job does and why they are held, see [State Migrations]({{< relref "how-it-works/state-migrations" >}}).

They live on the Module's page, under **State Migrations**.

## Pause the Module first

The panel offers nothing until the Module is paused. Pause it from the same page.

If a job is still finishing, pausing waits for it: the Module shows as pausing, the job in flight runs to completion, and nothing new is dispatched. The jobs become available once it is quiet.

Resuming is on the notice at the top of the Module's page, which shows on any of its tabs.

## Choose a job and run it

Each job shows the command it approximately runs, and opens to say what it does step by step. Pick one, press **Run**, and fill in the dialog.

**import** takes an address and the id the resource already has. **move** takes each address and the address it should become. **remove** takes addresses only. All three accept several at a time, one per row, and handle them one at a time, so if some work and some do not, you can see which.

**lookup addresses** writes nothing. Give it the addresses you are asking about and it reports which are in the state. Run it before a move or a remove if you are not sure the addresses are what you think.

The job appears in the list below the panel. Open it for its log, and for the addresses it managed.

## Split and transfer

These two rewrite more than one Module's state, so they ask for more.

Both run against a ref carrying the code change - the branch or tag where [demonolith](https://github.com/schrieksoft/demonolith) has already split or moved the code. The dialog pre-fills the Module's configured revision; override it if the change is on a branch.

Both also prove before they write. The job plans every affected Module against the state as it will look afterwards, checks each has nothing left to change, and then waits for approval. Approve it from the job's **Approvals** tab. Nothing is written until you do.

A **transfer** needs the other Module to agree before anything starts. Start it from one Module and pick the counterparty; the other Module's page then shows the request with **agree** and **refuse**. Both sides must be paused. If the other side refuses, this side's job fails and nothing is written.

## When something goes wrong

A job that fails shows its reason on the row, with the detail in its log. A transfer that failed because the other Module refused says so on the row.

Nothing is rolled back, because there is nothing to roll back to: a migration either wrote or it did not. Re-running is the way forward, and the engine's own commands are safe to repeat - an address already moved is already moved. A failed split or transfer is re-run as a new one, proved again from the state as it then stands.

You can cancel at every step, the write included. **Cancel after current** lets the step in flight finish; **Kill current step** stops it where it is.
