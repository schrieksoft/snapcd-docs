---
title: Monorepos
weight: 15
sidebar:
  open: false
---

When many [Modules]({{< relref "resources/stack-namespace-module#module" >}}) track the same branch of one repository, `trigger_on_source_changed` fires for **every** Module on **every** commit — a change to `modules/frontend` re-runs the backend, the network stack, and everything else on that branch. The **Trigger Path Filter** scopes the gitops trigger to the directories a Module actually depends on.

## Enabling the filter

Set `trigger_path_filter_enabled` on a Module (or `default_trigger_path_filter_enabled` on its Namespace to cover all its Modules; the Module-level setting overrides the Namespace default). It defaults to `false` — without it, behaviour is unchanged: any commit to the tracked source triggers the Module.

With the filter enabled, a commit only triggers the Module when it changes the Module's **watched directories**:

- the Module's `source_subdirectory`,
- any **Additional Trigger Paths** declared on the Module or its Namespace, and
- every directory those directories **reference through local module calls**, discovered automatically (see below).

Namespace-level paths join the watch set of every filter-enabled Module in the Namespace — useful for a directory all of them depend on, such as shared configuration.

You can see the full specifications here:

- [Module Additional Trigger Path](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_additional_trigger_path)
- [Namespace Additional Trigger Path](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_additional_trigger_path)

## Example Usage

```hcl
resource "snapcd_module" "frontend" {
  name                        = "frontend"
  namespace_id                = snapcd_namespace.apps.id
  source_url                  = "https://github.com/example/monorepo.git"
  source_revision             = "main"
  source_subdirectory         = "modules/frontend"
  runner_id                   = data.snapcd_runner.default.id
  trigger_on_source_changed   = true
  trigger_path_filter_enabled = true
}

resource "snapcd_module_additional_trigger_path" "frontend_shared" {
  module_id = snapcd_module.frontend.id
  path      = "shared/design-tokens"
}
```

A commit that only touches `modules/backend` no longer triggers the `frontend` Module. A commit touching `modules/frontend` or `shared/design-tokens` does.

Paths are repo-root-relative, normalized directories: forward slashes, no leading slash, no `.` or `..` segments.

## How change is detected

Snap CD does not diff commits or match glob patterns. On every refresh the Runner reads the git **tree hash** of each watched directory straight from a bare clone (no working tree is ever checked out) — git has already computed a content hash of every folder at every commit. The server combines the hashes of a Module's watched directories into a single fingerprint and triggers the Module exactly when that fingerprint changes.

This has two properties worth knowing:

- **History does not matter.** The decision compares content fingerprints, not commit ranges, so force-pushes, rebases and squashes cannot confuse it: if the rewritten branch has byte-identical content in your watched directories, nothing triggers.
- **Changing the watch set counts as a change.** Adding or removing an Additional Trigger Path (or enabling the filter for the first time) changes the Module's effective definition, so the Module triggers once at the next refresh even without a new commit. This is intended: it gives you one run whose state reflects the new watch set.

## Automatic discovery of referenced folders

Terraform requires a `module` block's `source` argument to be a **literal string** — it is resolved before any expression evaluation exists. That makes local module topology statically knowable, and Snap CD exploits it: at every refresh, the Runner walks the local module calls of each watched directory (`source = "../shared/network"` style) and pulls the **transitive closure** of referenced directories into the watch set automatically. A shared module referencing another shared module is followed all the way down; `.tf.json` syntax is understood; registry and git-URL module sources are ignored (they do not live in your repository); diamond and repeated references are deduplicated.

You do not declare these — if `modules/frontend` calls `../../shared/network`, and `shared/network` calls `../naming`, a commit to `shared/naming` triggers the frontend Module with no configuration at all. Discovery runs against the commit being evaluated, so a commit that *introduces* a new module reference and changes the referenced directory in the same push is caught immediately.

## Notifications converge on the same primitive

For Modules using `trigger_on_source_changed_notification` (external CI calling the SourceChanged endpoint), enabling the trigger path filter changes what a notification means: instead of triggering the Module directly, the notification dispatches an immediate refresh of the source, and the same tree-hash comparison decides which Modules actually run. A notification about a commit that did not touch a Module's watched directories therefore no longer runs it. Modules without the filter keep the existing behaviour — the notification is the trigger — so existing CI callers are unaffected. A notification-only Module (with `trigger_on_source_changed` disabled) is still never triggered by the polling schedule; it is only ever evaluated when a notification arrives.

## What is not watched: exclusions

Discovery covers **literal, statically-known paths only**. The following are never discovered automatically and must be declared as Additional Trigger Paths if the Module depends on them:

- **Dynamically computed paths** — e.g. `file("${var.config_dir}/policy.json")`. The value of `var.config_dir` does not exist at refresh time (Module inputs are resolved when a Job runs, and may come from secrets or other Modules' outputs), so no static analysis can know which directory to watch. Guessing would risk *silently missed* triggers — worse than asking you to declare the path.
- **Variable-interpolated paths in general** — the same reasoning applies to any path whose value requires evaluating expressions.
- **External data-source programs** — a `data "external"` program can read any file it likes; its true dependency set is unknowable without executing it, and the refresh loop never executes repository code.
- **`local-exec` provisioners** — arbitrary shell commands, same reasoning, with the addition that their inputs are only resolved at apply time.
- **Symlinked directories** — a symlink's git tree entry is the link *target path*, not the target's content, so changes behind a symlink never alter the watched directory's tree hash. Declare the target directory itself.

The rule of thumb: **if the path is written literally in your configuration, it is watched; if it is computed, executed, or symlinked, declare it.**

## Tag-tracking Modules: component version tags

Path scoping covers branch-tracking Modules; Modules tracking version tags have their own monorepo story. Monorepos version components independently, so tags carry a component discriminator — `ui-v1.2.3`, `backend/v2.0.0`, `1.2.3-ui`. With `source_revision_type = "SemanticVersionRange"`, the range expression can anchor a literal prefix and/or suffix around the wildcard:

```hcl
resource "snapcd_module" "frontend" {
  name                 = "frontend"
  namespace_id         = snapcd_namespace.apps.id
  source_url           = "https://github.com/example/monorepo.git"
  source_revision      = "ui-v1.*"
  source_revision_type = "SemanticVersionRange"
  source_subdirectory  = "modules/frontend"
  runner_id            = data.snapcd_runner.default.id
}
```

This Module resolves to the highest `ui-v1.x.y` tag and is entirely unaffected by `backend-v2.0.0` being pushed — the tag names the component, so no path filter is needed at all. Rules worth knowing:

- The `v` is optional on both the range and the tags: `ui-1.*` matches `ui-v1.2.3` and `ui-1.2.3` alike.
- The prefix and suffix are literal anchors, matched exactly; the wildcard core is `X.Y.*` (patch range), `X.*` (minor range) or a bare `*` (any version, later majors included) — so `ui-*` tracks the component's latest release across major versions.
- Pre-release tags (`ui-v1.3.0-rc.1`) are never matched unless the suffix spells the pre-release part out (`ui-v1.*-rc.1`).
- A fully spelled-out tag (`ui-v1.2.3`) works too and is used verbatim — no range resolution happens for it.

Range resolution and path scoping solve the same problem for the two trigger styles: tag-tracking Modules scope by tag name, branch-tracking Modules scope by watched directories.

## Roadmap

Statically-resolvable file references — `file()`, `templatefile()` and `fileset()` arguments where `${path.module}`/`${path.root}` are the only interpolations — are compile-time constants and are planned as a discovery extension. Until then, declare their target directories as Additional Trigger Paths. The evaluation-dependent exclusions above remain excluded by design.
