---
title: Splitting a Monolith
weight: 4
sidebar:
  open: false
---

A long-lived Terraform or OpenTofu project tends to grow into a monolith: one root module, one state file, everything applied together. Every plan walks every resource, every apply locks everyone out, and one bad change can touch anything. The way out is to split it into independent modules with their own state — and [demonolith](https://github.com/schrieksoft/demonolith), a companion CLI, automates that split end to end: it splits the code, migrates the state, proves the result changes nothing, and generates the Snap CD wiring to adopt the new modules.

This guide covers the demonolith workflow and the adoption step. For the underlying procedure — what you would do entirely by hand, and why each step exists — see [Splitting a Terraform Monolith](https://snapcd.io/Blog/splitting-terraform-monolith) on the blog.

## Two command families

demonolith is split at its most important line: changing **code** (offline, no credentials, reversible with git) versus migrating **state** (touches real backends). Each family runs map → run → verify in order, pausing for approval before anything is executed:

```
demonolith refactor            # the code split — no credentials, no state touched
  refactor map                 #   analyze → write the map (the file you review)
  refactor run                 #   execute the map: write the new module directories
  refactor validate            #   ask the engine whether it accepts what was written
  refactor diff                #   CI gate: output on disk still matches the source

demonolith migrate             # the state migration
  migrate map                  #   pull read-only, back up, split into local state copies
  migrate prove                #   prove the split changes nothing (plans over the local copies)
  migrate run                  #   push each module's state to its new backend (guarded, never forced)
  migrate verify               #   judge the result against the real backends
```

Everything hinges on the **map** (`demonolith-refactor-map.yaml`): a reviewable file recording which block goes to which module, every state move, the values that will flow between modules, and where each module's state will live. `refactor map` writes it, you review it, and every later step executes or checks against it.

## Mark the seams

Placement is driven by comments in the monolith's source. Put one above each `resource` or `module` block, naming the module it should end up in:

```hcl
# @demono:move networking
resource "aws_vpc" "main" { ... }
```

Blocks with no comment fall into a catchall module (default name `legacy`). Data sources are never annotated — they automatically follow the modules that read them. `demonolith refactor map -i` walks you through the unassigned blocks interactively and writes your choices back into the source as comments, so the decisions are reviewable in git.

## Split the code

```bash
demonolith refactor
```

This analyzes the monolith, shows the map — including a dependency graph with the order the new modules must be deployed in — and, after your approval, writes the new module directories (default `modules/`). Each one is plain Terraform: the moved blocks, the variables and locals they reference, a `root.tf` with the required providers and a backend derived from the monolith's (the state location gets a per-module suffix), and generated `variable`/`output` pairs wherever a value crosses a module boundary. If your dependencies form a cycle, the split is impossible and demonolith refuses with the cycle named — before anything is written.

The target directories belong to demonolith: `refactor run` refuses when they already exist, and `--overwrite` deletes and rewrites them entirely — anything added to them by hand does not survive a run.

`refactor validate` then asks the engine itself whether the written directories are valid — providers installed, references resolved, types checked — without touching any state, so it needs no credentials (only the provider registry is contacted). It is the check to run before committing; the bare `refactor` runs it inline when given `--engine`, and otherwise prints the command to run it.

`refactor diff` re-runs the analysis and diffs the directories on disk against what the source produces; it is designed to run in CI as the gate that the split stays honest as the source evolves. It compares files only — validity is `refactor validate`'s job — so it stays offline and needs no engine.

For a monorepo layout — the new modules staying in the same repository as shared child modules — pass `--monorepo`: local module calls are referenced by relative path instead of copied.

## Migrate the state

```bash
demonolith migrate --engine tofu
```

Four steps, each safe to re-run after a crash:

1. **map** — pulls the monolith's state read-only, backs it up, and splits it into local per-module copies. The monolith's own state is never written.
2. **prove** — plans every new module against its local state copy, feeding each producer's outputs into its consumers (the role Snap CD plays at runtime), and requires **zero changes** — no creates, no destroys, and no in-place updates either, since a wrong value that forces no replacement is still a wrong value.
3. **run** — pushes each module's state to its new backend. A destination must be empty or already hold this module's state; a push is never forced (`--force` is the explicit, loudly-warned exception).
4. **verify** — plans every module against the pushed state in its real backend and requires zero changes again. No demonolith step refreshes: managed-resource drift is out of scope — it is ruled out by the prerequisite clean plan of the monolith, and after adoption it is Snap CD's own plans that watch the world. (Data sources are the one exception: every plan reads them live, so their answers must hold still across the migration too.)

Along the way demonolith reconstructs the inputs the monolith resolved silently: each module gets a `demono.root.tfvars` (its variable values), a `demono.graph.tfvars` (the values it receives from other modules), and a gitignored `demono.env` (backend credentials, as environment variables) — so each module can also be planned entirely on its own.

Retiring the monolith — its pipelines and its old state — is deliberately left as a human step, taken only after every module verifies clean.

There is also an **unproven path** for when you want the mechanical split and migration without the checks: skip `--engine` on `refactor` (no validate), don't run `refactor diff` or `migrate verify`, and pass `--unproven` to `migrate run` to waive its proof precondition. The push guards still hold — empty or matching destinations only, never forced, backup taken — but a wrong split then surfaces after adoption instead of before the push, and the per-module tfvars files that prove writes are missing, so plan modules detached only with values passed by hand.

## Adopt into Snap CD

Alongside the modules, `refactor` generates a **bootstrap module** (`modules/snapcd/`) from the map alone: a [Namespace]({{< relref "resources/stack-namespace-module#namespace" >}}), one [Module]({{< relref "resources/stack-namespace-module#module" >}}) per new directory, every cross-module value as a [`snapcd_module_input_from_output`]({{< relref "resources/module-inputs" >}}) wiring, and every ordering dependency as a `snapcd_depends_on_module`. Apply it against your server (with `source_url` pointing at the repository holding the new modules) and Snap CD takes over what the monolith did implicitly: applying modules in dependency order, passing values between them, and cascading changes when an upstream output changes.

With `--monorepo`, the generated Namespace also sets `default_trigger_path_filter_enabled = true`, so each Module only redeploys when a commit touches its own directory — see [Monorepos]({{< relref "guides/monorepos" >}}) for how that filter works.

## Running it locally vs in CI

**Locally**, the whole journey fits in one terminal, and for a solo operator that is the simplest way to run it: in the shell session where the monolith inits and plans cleanly — a refreshed, zero-change plan, which is also where drift is ruled out (demonolith's one prerequisite), run `demonolith refactor --engine …` (the validate step runs inline), review the map, run `demonolith migrate --engine …`, then apply the bootstrap. Every step pauses for approval before anything is executed, and `-i` walks you through the inputs interactively.

**In a team**, the two halves land differently, because one is reversible and one is not:

- A developer runs `refactor` **locally**, then `refactor validate` — the engine's own check on the new directories, credential-free — and opens a PR. The map and the new module directories are ordinary files, so the PR is the review — and rejecting it undoes everything.
- CI runs `refactor diff` on **every PR and push**: the standing gate that the committed module directories still match the source. Offline, no engine, no credentials.
- CI can also **rehearse** the migration on the PR: `migrate map` pulls the monolith's state read-only and `migrate prove` plans every module to zero changes. Nothing is pushed, so a rejected PR leaves the world untouched. This lane needs the working-session inputs as CI secrets — backend credentials, `TF_VAR_*` values, and any value that was only ever a `-var` flag.
- `migrate run` is **not a PR job**: pushing state from an unmerged branch means the world has already changed if the PR is rejected. Merge first, then run the migration once — behind a manual trigger, or a person at a terminal — during a change freeze on the monolith. A crashed run is retried by just re-running, and every step writes a receipt file recording what happened.
- Applying the bootstrap and retiring the monolith stay human steps, taken after every module verifies clean.

The [sample's GitHub Actions workflow](https://github.com/snapcd-samples/sample-deployment-demonolith/blob/main/.github/workflows/split.yml) is a runnable version of exactly these lanes: verify on every PR, a read-only rehearsal on every PR, and the migration behind a manual `workflow_dispatch`.

## Limits and a working example

Some things a tool cannot decide for you — sensitive values crossing a module boundary, paths resolved relative to the root, workspace-dependent configuration. demonolith's [LIMITATIONS.md](https://github.com/schrieksoft/demonolith/blob/main/LIMITATIONS.md) lists each one with the manual handling; the prove and verify steps are the net that catches them as a plan error or a diff rather than silent corruption.

For a complete, runnable walkthrough — a deliberately knotted monolith split, migrated, and bootstrapped into a local Snap CD server — see [sample-deployment-demonolith](https://github.com/snapcd-samples/sample-deployment-demonolith).
