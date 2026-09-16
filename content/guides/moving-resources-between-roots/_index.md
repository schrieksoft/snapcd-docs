---
title: Moving Resources Between Roots
weight: 5
sidebar:
  open: false
---

Even a well-split landscape drifts: sooner or later a resource is sitting in the wrong root - the database that grew up inside the app root, the DNS zone that belongs with networking. Moving it means moving both the code and the tracked state, without destroying or recreating anything, between two roots that each keep living. [demonolith](https://github.com/schrieksoft/demonolith)'s `transfer` commands (experimental) automate that move end to end: the code move, the state move, proofs that both roots still plan to zero changes, and the Snap CD wiring updated along the way.

Where the [split]({{< relref "guides/splitting-a-monolith" >}}) carves one root into new directories that demonolith owns outright, a transfer edits two roots that already exist and are hand-maintained - so the tool appends into their own files, refuses name collisions, and writes both states under guards. A transfer has exactly **one source and one receiver**; moving blocks into two roots is two transfers, run one after the other, each proven and landed on its own.

## Two halves

The same line the split draws: changing **code** (offline, reviewable, reversible with git) versus moving **state** (touches real backends). Each half pauses for approval before its write step:

```
demonolith transfer refactor   # the code move - no credentials, no state touched
  transfer refactor map        #   analyze the source, write the transfer map (the file you review)
  transfer refactor run        #   move the blocks into the receiver's files, wire the references
  transfer refactor diff       #   CI gate: this root's code matches its map copy
demonolith transfer migrate    # the state move - one root at a time
  transfer migrate map         #   pull this root's state read-only, back up, pin
  transfer migrate prove       #   this root plans to zero changes against its moved copy
  transfer migrate run         #   write this root's state (guarded, never forced)
  transfer migrate verify      #   replan this root against its real backend
```

## Mark the blocks, name the receiver

Mark each block to move with a bare comment, and give the receiver once, on the command line - a directory relative to the source root, in the same repo or a neighboring checkout:

```hcl
# @demono:transfer
resource "aws_route53_zone" "internal" { ... }
```

```bash
demonolith transfer refactor --transfer-target ../networking
```

## Move the code

`transfer refactor` analyzes the source, shows the map - what moves, and the wiring the move creates - and, after your approval, edits the roots' own files: the marked blocks (and any `variable`/`locals` declarations only they use) are appended into the receiver's `main.tf`/`variables.tf`/`outputs.tf`, created only when missing. A name the receiver already declares is refused - merging declarations is a human decision.

References that now cross between the roots are rewired on both sides. A moved block still read by the source becomes an `output` on the receiver and a `variable` in the source, whose remaining code is rewritten in place; a dropped cross-root `depends_on` becomes an ordering dependency. And when a root wiring your Modules into Snap CD sits next to the source (`--snapcd-root`, default: a sibling directory named `snapcd`), the run appends the runtime form there too: a [`snapcd_module_input_from_output`]({{< relref "resources/module-inputs" >}}) per moved value, a `snapcd_depends_on_module` per ordering dependency.

A byte-identical copy of the finalized map lands in every touched root. That copy is what makes the move reviewable per repo: `transfer refactor diff`, run in any touched root, checks that root's files against its own map copy with nothing else checked out - in a multi-repo landscape, each repo's whole merge gate.

## The window to respect

From the code move landing until the state move completes, source and receiver plan dirty - the source would destroy the moved resources, the receiver would create duplicates. Freeze both roots' pipelines when the code move merges, run the state move immediately after, and let `transfer migrate verify` reopen the world. Keep that window minutes long, not days.

## Move the state

```bash
demonolith transfer migrate --both --engine tofu
```

The state move works one root at a time: every step pulls, proves, or writes exactly one root's state, with only that root's checkout and credentials. What must cross between the roots travels as files in each root's `.demono-transfer/` directory - the moved resources' state (extracted by the source's `map`, applied by the receiver's), output values for the proofs (the same value-passing Snap CD does at runtime), and run receipts: the source's own state is refused its write until the receiver's write is receipted, so the moved resources are never orphaned. States are pinned when pulled - a pin that no longer matches refuses, unless that root's move already completed - and nothing is ever force-pushed. A crashed run is retried by just re-running: finished roots skip.

When both roots share one filesystem, `--both` runs the two sides in order from the source root. Roots on different machines each run `demonolith transfer migrate` themselves and pass the `.demono-transfer/` files between them; a root missing a file refuses by name and says which side produces it.

After `verify` comes back clean on both sides, re-apply the Snap CD root: the appended wiring makes Snap CD pass the moved value into the source's new input at runtime - the same threading the proofs performed locally.

## In a team

The same lanes as the split, with the map copy doing the per-repo work:

- A developer runs `transfer refactor` locally and opens a PR - one per touched repo, each carrying its files plus the map copy. `transfer refactor diff` is each repo's standing CI gate.
- CI can rehearse the state move read-only: `transfer migrate map --both` and `transfer migrate prove --both` pull nothing but state copies and push nothing.
- The state move itself is not a PR job: merge first, then run it once, inside the freeze. The pins and receipts make re-running safe and running stale impossible.

## Limits and a working example

A data source read by both sides is refused (it follows its consumers - give it one side, or duplicate it by hand), `count`/`for_each` instances move only as whole blocks, and both roots must use the same backend type. For a complete runnable walkthrough - the landscape a split left behind, with two transfers run through it and the Snap CD wiring applied - see [sample-deployment-demonolith-transfer](https://github.com/snapcd-samples/sample-deployment-demonolith-transfer).
