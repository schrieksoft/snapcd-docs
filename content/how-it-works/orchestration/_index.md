---
title: Orchestration
weight: 2
sidebar:
  open: false
---

A Snap CD [Module]({{< relref "resources/stack-namespace-module#module" >}}) can be set up to automatically sync (i.e. trigger a **Job**) based on of three events:

- The definition of the **Module** resource itself has changed. This behaviour can be toggled with the [Trigger On Definition Changed](#trigger-on-definition-changed) setting.
- The [Output]({{< relref "how-it-works/outputs" >}}) of an upstream **Module** has changed. This behaviour can be toggled with the [Trigger On Upstream Output Changed](#trigger-on-definition-changed) setting.
- The **Source** code the **Module** referes to has changed (e.g. a new commit has been pushed, or a new semantic version has been released). Snap CD can either discover this internally, or its can be informed externally via a notification. This behaviour can be controlled via the [Trigger On Source Changed](#trigger-on-source-changed) and [Trigger On Source Changed Notification](#trigger-on-source-changed-notification)

A **Module** can also be made to sync manually at any time by:
- Calling the `/api/job/apply/{id}` or `api/job/destroy/{id}` API endpoints.
- Navigating to the **Module** in the **Dashboard** and clicking the appropriate buttons.


## Trigger On Definition Changed

> More details on toggling this behaviour can be found [here](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module#trigger_on_definition_changed-1).

A "definition change" is triggered by (create, delete or update) to any of the following resources:

- [Module](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module)
- [Module Env Var From Definition](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_env_var_from_definition)
- [Module Env Var From Literal](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_env_var_from_literal)
- [Module Env Var From Namespace](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_env_var_from_namespace)
- [Module Env Var From Output](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_env_var_from_output)
- [Module Env Var From OutputSet](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_env_var_from_output_set)
- [Module Env Var From Secret](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_env_var_from_secret)
- [Module Param From Definition](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_param_from_definition)
- [Module Param From Literal](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_param_from_literal)
- [Module Param From Namespace](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_param_from_namespace)
- [Module Param From Output](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_param_from_output)
- [Module Param From OutputSet](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_param_from_output_set)
- [Module Param From Secret](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_param_from_secret)
- [Module Extra File](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_extra_file)

On the following resources, but _only_ if additionally the [trigger_behaviour_on_modified](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace#trigger_behaviour_on_modified-1) has been set to `TriggerAllImmediately`. We generally don't recommend enabling this trigger since it can lead to an unexpected flooding of **Jobs**. Use with care:

- [Namespace](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace)
- [Namespace Env Var From Definition](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_env_var_from_definition)
- [Namespace Env Var From Literal](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_env_var_from_literal)
- [Namespace Env Var From Secret](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_env_var_from_secret)
- [Namespace Param From Definition](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_param_from_definition)
- [Namespace Param From Literal](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_param_from_literal)
- [Namespace Param From Secret](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_param_from_secret)
- [Namespace Extra File](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_extra_file)


On the following resources, but _only_ if additionally the [trigger_behaviour_on_modified](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/stack#trigger_behaviour_on_modified-1) has been set to `TriggerAllImmediately`. We generally don't recommend enabling this trigger since it can lead to an unexpected flooding of **Jobs**. Use with care:

- [Stack](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/Stack)


## Trigger On Upstream Output Changed

> More details on toggling this behaviour can be found [here](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module#trigger_on_upstream_output_changed-1).

An "upstream output change" is triggered when a new **OutputSet** is created on a **Module** that is referenced by a [Module Input From Output](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_input_from_output) or [Module Input From OutputSet](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_input_from_output_set).


## Trigger On Source Changed

> More details on toggling this behaviour can be found [here](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module#trigger_on_source_changed-1).

A "source change" occurs when the source code that the **Module** definition refers to has been updated with a new revision (e.g. new commit or new semantic version). This is a "polling" approach, meaning that on a specific schedule, Snap CD will query the defined sources for their latest definitive revision (typically a commit SHA). If the resulting definitive revision differs from the one that was used in the most recent **Job**, a new one will be triggered.

The [Server]({{< relref "components/server" >}}) is responsible for scheduling the tasks to determine the most recent definitive revision, but the actual query is done by the [Runners]({{< relref "components/runner" >}}). You can specify which **Runner** should be used for which **Source Url** by creating a **Source Refresher Preselection** resource. If you do not specify this, then a random **Runner** from a **Module** that references that specific source will be selected.

The defitive revision is determined by the **Runner** in one for the following manners.

#### Definitive revision: `Git` source type with `Default` revision type

The "SourceRevision" field is resolved to the Git SHA that it refers to. Typically if "SourceRevision" refers to a branch, this finds most recent commit of that branch. If it refers to a tag, it finds the commit that the tag is assigned to.


#### Definitive revision: `Git` source type with `SemanticVersionRange` revision type


When using a "SemanticVersionRange" revision type, the latest semantic version tag within the specified range is resolved. Thereafter the Git SHA for that tag is return.

For example "v2.*" is resolved to the tag "v2.10.7", and then the SHA for that tag is discoverd and returned.


#### Definitive revision: `Registry` source type with `Default` revision type

When using a "Registry" source type, the **Runner** will query the registry for the passthrough URL where the source code is located, determining the revision from there. Using that information, it will then follow the same approach as ["Git" source type with "Default" revision type](#git-source-type-with-default-revision-type).

> Note that the "Registry" source type current only works if it resolves to a Git revision (S3, Https, Mercurial etc. are currently not supported). Furthermore, due to limitations in the OpenTofu / Terraform registries' API specifications, it is not possible to support the "SemanticVersionRange" revision type at this time.


## Trigger On Source Changed Notification

> More details on toggling this behaviour can be found [here](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module#trigger_on_source_changed_notification-1).

As an alternative to the polling approach used in the [Trigger On Source Changed](#trigger-on-source-changed) behaviour, it is also possible to instead trigger on externally notified changes. This is a "push" approach, where the **Server** accepts notifications on the `api/SourceChangedNotification` API endpoints. This approach makes could be useful if you plan for example to integrate with a CI/CD pipeline on the source repo. For example, on pushing a new commit to a branch, a step in your CI/CD pipeline could POST a request to `api/SourceChangedNotification`, informing that a new revision is available. Here is an example payload:

```json
{
  "SourceUrl": "https://github.com/myorg/myrepo.git",
  "SourceRevision": "feature/mybranch",
  "SourceType": "Git"
}
```

Note that the fields `SourceUrl`, `SourceRevision` and `SourceType` must be matched exactly to how those fields are defined on the **Module**. So for example, if the **Module** was set up with an SSH source URL instead, i.e. `git@github.com:myorg/myrepo.git` then the above request will _not_ lead to a source change being triggered.


> Nothing prevents you from using both **Trigger On Source Changed** and **Trigger On Source Changed Notification** at the same time, but it would likely only make sense in very specific scenarios.