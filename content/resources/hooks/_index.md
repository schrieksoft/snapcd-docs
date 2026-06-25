---
title: Hooks
weight: 13
sidebar:
  open: false
---

**Hooks** are shell scripts that execute at specific stages during a [Job]({{< relref "how-it-works/orchestration" >}}). They allow you to run custom logic before or after Terraform/OpenTofu operations.

## Hook Tasks and Phases

A hook is identified by a `task` (the lifecycle stage it attaches to) and a `phase` (whether it runs before or after that stage).

| Task           | Description                          |
|----------------|--------------------------------------|
| `Init`         | Terraform/OpenTofu initialization    |
| `Plan`         | Planning changes                     |
| `PlanDestroy`  | Planning destruction                 |
| `Apply`        | Applying changes                     |
| `Destroy`      | Destroying infrastructure            |
| `Output`       | Retrieving outputs                   |
| `Validate`     | Validating configuration             |

| Phase    | Description                          |
|----------|--------------------------------------|
| `Before` | Runs immediately before the task     |
| `After`  | Runs immediately after the task      |

For example, a hook with `task = "Apply"` and `phase = "Before"` runs before the apply step.

## Hook Resources

Hooks are first-class resources, attached either to a single **Module** or to an entire **Namespace**:

- [`snapcd_module_hook`](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_hook) — attached to one **Module**.
- [`snapcd_namespace_hook`](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_hook) — attached to a **Namespace** and applied as a default to every **Module** in it.

Each `(parent, task, phase)` triple is unique: a given **Module** can have at most one `Apply.Before` hook, and a given **Namespace** can have at most one `Apply.Before` default hook.

```hcl
resource "snapcd_namespace_hook" "default_plan_before" {
  namespace_id = snapcd_namespace.networking.id
  task         = "Plan"
  phase        = "Before"
  script       = "echo 'About to plan a module in the networking namespace'"
}

resource "snapcd_module_hook" "cluster_apply_before" {
  module_id = snapcd_module.cluster.id
  task      = "Apply"
  phase     = "Before"
  script    = "echo 'About to apply the cluster module'"
}
```

## Inheritance

Hooks are resolved with the following precedence, from highest to lowest:

1. A `snapcd_module_hook` defined directly on the **Module**.
2. A `snapcd_namespace_hook` defined on the parent **Namespace** (the default for that task/phase).

A **Module** can opt out of all inherited namespace hooks by setting `ignore_namespace_hooks = true`. When set, only hooks defined directly on the **Module** itself will run, and namespace defaults are skipped entirely.

## Deprecated Inline Hook Fields

Earlier versions of Snap CD exposed hooks as inline scalar string fields on the **Module** and **Namespace** resources (e.g. `apply_before_hook` on **Module** and `default_apply_before_hook` on **Namespace**). These fields are now **deprecated** in favour of the `snapcd_module_hook` / `snapcd_namespace_hook` resources, which support proper lifecycle management and richer attributes.

The old fields continue to work for backwards compatibility — when a hook with the matching task/phase is not defined as a resource, the inline scalar value is still consulted — but new configurations should use the resources. A future major release will remove the inline fields.

## Hook Pre-approval

For security-sensitive environments, **Runners** can be configured to only execute pre-approved hooks. When enabled, every hook must match (by SHA256 hash) a file in the pre-approved hooks directory.

### Configuration

On the Runner, set the following in `appsettings.json`:

```json
{
  "HooksPreapproval": {
    "Enabled": true,
    "PreapprovedHooksDirectory": "/path/to/approved-hooks"
  }
}
```

### How It Works

1. Place approved hook scripts as files in the `PreapprovedHooksDirectory`
2. The Runner loads and hashes all files in this directory at startup
3. When a Job runs, each hook is validated against the pre-approved hashes
4. If a hook doesn't match any pre-approved hash, the Job fails

This ensures that only vetted scripts can execute on your infrastructure, preventing arbitrary code execution from the control plane.

> **Note**: Empty hooks are always allowed. Line endings are normalized before hashing, so the same script will match regardless of platform.
