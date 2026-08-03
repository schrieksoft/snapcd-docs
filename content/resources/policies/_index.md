---
title: Policies
weight: 16
sidebar:
  open: false
---

**Policies** validate what a plan is allowed to contain before it is applied — or destroyed. A policy that finds a **hard violation** refuses the job before anything reaches the infrastructure; a **soft violation** records a warning and lets the job continue. Policies are evaluated on the [Runner]({{< relref "resources/runner" >}}), against the plan the job actually produced: the plan document never leaves the Runner.

Each engine uses its ecosystem-native policy framework:

- **Terraform / OpenTofu**: [OPA/Rego](https://www.openpolicyagent.org/docs/latest/policy-language/) policies evaluated with [conftest](https://www.conftest.dev/) against the JSON export of the plan. Existing conftest policy repos work unchanged, and Snap CD policies remain runnable under plain conftest in CI.
- **Pulumi**: [CrossGuard](https://www.pulumi.com/docs/using-pulumi/crossguard/) policy packs, enforced inside the preview via `--policy-pack`.

## Attaching policies

Policies attach to a [Module]({{< relref "resources/stack-namespace-module#module" >}}) or to a [Namespace]({{< relref "resources/stack-namespace-module#namespace" >}}) (applying to every Module in the Namespace, additively — there is no Module-level override of Namespace policies). The engine and the source kind are part of the resource type:

| Engine | Kind | Module-level | Namespace-level |
|---|---|---|---|
| Terraform/OpenTofu | inline | [snapcd_module_terraform_inline_policy](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_terraform_inline_policy) | [snapcd_namespace_terraform_inline_policy](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_terraform_inline_policy) |
| Terraform/OpenTofu | remote | [snapcd_module_terraform_remote_policy](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_terraform_remote_policy) | [snapcd_namespace_terraform_remote_policy](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_terraform_remote_policy) |
| Terraform/OpenTofu | local | [snapcd_module_terraform_local_policy](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_terraform_local_policy) | [snapcd_namespace_terraform_local_policy](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_terraform_local_policy) |
| Pulumi | inline | [snapcd_module_pulumi_inline_policy](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_pulumi_inline_policy) | [snapcd_namespace_pulumi_inline_policy](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_pulumi_inline_policy) |
| Pulumi | remote | [snapcd_module_pulumi_remote_policy](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_pulumi_remote_policy) | [snapcd_namespace_pulumi_remote_policy](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_pulumi_remote_policy) |
| Pulumi | local | [snapcd_module_pulumi_local_policy](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_pulumi_local_policy) | [snapcd_namespace_pulumi_local_policy](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_pulumi_local_policy) |

Each resource has a matching data source under the same name.

| Kind | Fields | Semantics |
|---|---|---|
| `inline` | `policy_content` | A single self-contained policy document, stored in Snap CD. For Pulumi additionally `runtime` (`Python` or `NodeJS`) and optional `additional_dependencies`. |
| `remote` | `repo_url`, `revision`, `path` | A directory in a git repository, fetched at the pinned revision (tag, branch or commit SHA) when the job is dispatched. The whole tree is evaluated as one bundle: files can share helper packages, ship their own `opa test`/`conftest verify` tests, and be code-reviewed in their own repo. |
| `local` | `path` | A directory on the Runner host, operator-managed. Cheapest to set up, weakest pinning: the contents at evaluation time are whatever the folder holds. |

Shared fields on every policy: `name` (unique per parent), `enabled` (default `true`), and `evaluate_on`. For Terraform/OpenTofu policies `evaluate_on` is `ApplyAndDestroy` (default), `ApplyOnly` or `DestroyOnly` — destroy jobs evaluate policies exactly like apply jobs, and preventing deletion of protected resources is a first-class use case. For Pulumi policies the only value is `ApplyOnly` (see the CrossGuard limitation below).

A policy only ever applies to jobs of its engine: a Terraform policy is never evaluated for a Pulumi Module, and vice versa.

## Severity lives in the policy content

There is no enforcement-level setting on the policy resource — severity follows each framework's own convention:

- **Rego/conftest**: rules named `deny*` or `violation*` are **hard** (refuse the job); rules named `warn*` are **soft** (warn and continue). Names are prefix-matched, so one file can carry many attributed rules (`deny_public_buckets`, `warn_large_instances`). `violation` rules differ from `deny` only in payload: they can return structured objects (`msg` plus a `details` map) which land in the job logs — use them when you want machine-readable detail such as severity grades or remediation hints. conftest's `exception` rules provide exemptions.
- **CrossGuard**: each policy in a pack declares `mandatory` (hard) or `advisory` (soft) in the pack itself.

Job outcome: any hard violation across all evaluated policies refuses the job — it finalizes as **Policy Denied** (a refusal, distinct from a failure); otherwise any soft violation lets the job continue with a recorded warning, visible on the job and on the approvals screen before anyone approves.

## Writing Terraform/OpenTofu policies

The evaluation input is the [JSON representation](https://developer.hashicorp.com/terraform/internals/json-format) of the plan (`resource_changes` and friends). All Rego namespaces are evaluated — there is no required package name. Rego v1 syntax is the supported contract (`import rego.v1` recommended for portability).

```rego
package terraform.security

import rego.v1

deny contains msg if {
    some r in input.resource_changes

    r.type == "aws_s3_bucket_public_access_block"
    r.change.after != null

    not r.change.after.block_public_acls

    msg := sprintf("%s allows public ACLs", [r.address])
}
```

Two things every policy author should know:

- **Your input can be a destroy plan.** On a delete, `r.change.after` is `null` — a bare `not r.change.after.some_flag` is *true* for every deleted resource and would fire on destroy plans. Guard with `r.change.after != null` (as above) unless deletions are exactly what you want to catch.
- **A policy that defines no `deny`/`violation`/`warn` rules faults the job** instead of silently passing. conftest itself reports success for such a policy (a typo like `denny` gates nothing while looking green); Snap CD detects the zero-rule case and fails closed with a clear error.

Evaluation details: each policy resource is evaluated independently (two inline policies can reuse a package name or helper without conflicting; package discipline *within* one remote/local bundle is the bundle author's job), a broken file anywhere in a bundle faults that whole bundle, and evaluation is bounded by a configurable timeout — Rego itself has no execution limit.

## Writing Pulumi policies

CrossGuard policies are code (Python or TypeScript/JavaScript) using the [pulumi-policy SDK](https://www.pulumi.com/docs/using-pulumi/crossguard/get-started/), and they run **inside the preview** — there is no separate policy step for Pulumi jobs. A `mandatory` violation fails the preview itself; the job finalizes as Policy Denied. `advisory` violations are recorded and the job continues. Because evaluation happens in the preview, a denied Pulumi job has no plan artifact or change counts, and its policy output appears in the **plan step's** logs.

For **inline** Pulumi policies, `policy_content` holds only the pack's entry module (e.g. the `__main__.py` defining a `PolicyPack`); the Runner synthesizes the surrounding pack scaffold (`PulumiPolicy.yaml`, pinned-SDK requirements) and provisions the environment:

- By default the Runner creates **cached virtualenvs** keyed on the dependency set, installing the `pulumi-policy` SDK plus any `additional_dependencies` (one per line, `requirements.txt` semantics). NodeJS packs get an `npm install`.
- On air-gapped Runners, set `PolicyEvaluation:PackProvisioningEnabled` to `false`: packs then run on the ambient interpreter with the policy SDK preinstalled by the operator, and inline policies declaring `additional_dependencies` fail loudly.

**Remote** and **local** Pulumi policies reference a complete, self-describing pack (its own `PulumiPolicy.yaml` declares the runtime; dependencies vendored or preinstalled by the operator). The Runner never rewrites a pack's own configuration.

One engine-inherent limitation: **CrossGuard evaluates apply-side previews only** — the pulumi CLI has no policy support on `destroy`, so destroy jobs run without Pulumi policy enforcement and `evaluate_on` destroy settings have no effect on Pulumi policies. Destroy protection is a Terraform/OpenTofu policy capability.

## What the Runner needs

Same contract as the engine binaries — operator-provided, no download-on-demand, fail-closed when missing:

- **conftest** ≥ 0.68 on `PATH` for Terraform/OpenTofu policies (the standard Runner image ships it). conftest embeds the OPA engine; no separate `opa` binary is needed.
- **python3 with `venv`** for Python CrossGuard packs (the standard Runner image ships it). `node`/`npm` for NodeJS packs are operator-provided.
- The Pulumi CLI requirement is unchanged: CrossGuard's enforcement engine ships inside the `pulumi` CLI a Pulumi-running Runner already has.

Runner settings under `PolicyEvaluation`: `ConftestBinaryPath`, `EvaluationTimeoutSeconds` (default 300), `MaterializeTimeoutSeconds`, `PackProvisioningEnabled`, `PythonPath`, `NpmPath`, `VenvCacheRoot`.

Git access for `remote` policies uses the Runner environment's git configuration, exactly like Module sources.

## Security notes

Policy violation **messages are composed by policy authors** from plan values and stream into job logs. The plan document itself never leaves the Runner, but what a policy `sprintf`s into a message is under the author's control — including sensitive values.

## Validation

There is no create-time policy validation: a policy that fails to parse or evaluate faults the job loudly at runtime, with the evaluator's error in the logs. Test policies before attaching them — `conftest verify` / `opa test` for Rego bundles, and CrossGuard's own unit-test patterns for packs.
