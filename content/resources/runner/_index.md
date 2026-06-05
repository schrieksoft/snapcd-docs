---
title: Runners
weight: 2
sidebar:
  open: false
---

## Overview

A **Runner** is a resource that defines a target for [Module]({{< relref "resources/stack-namespace-module#module" >}}) [job]({{< relref "how-it-works/orchestration" >}}) execution. One or more Runner processes connect to a Runner record to pick up and execute **Jobs**.

## Runner

A **Runner** defines the configuration for job execution, including which [Service Principal]({{< relref "resources/identity-access-management" >}}) is used for authentication and whether the runner is available to all modules.

| Field | Description |
|-------|-------------|
| `name` | Unique name of the Runner |
| `service_principal_id` | ID of the Service Principal used by connected Runners to authenticate |
| `is_assigned_to_all_modules` | When `true`, any Module can use this Runner |
| `is_disabled` | When `true`, the Runner will not accept new Jobs |
| `allow_multiple_instances` | When `true`, multiple Runner processes can connect against this record simultaneously |

You can find the full **Runner** specification [here](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/runner).

## Multiple Runners against one record

By default a Runner record accepts a single connected process. When `allow_multiple_instances` is `true`, multiple processes (for example a Kubernetes StatefulSet with multiple replicas) can connect against the same Runner record simultaneously. Each process must report a distinct name when it connects.

## Runner Selection

When a **Job** starts, Snap CD must select a specific Runner to execute all steps of that Job. There are two selection methods:

### Automatic Selection (Default)

The Snap CD Server broadcasts a request to all connected Runners. The first to respond is selected and handles all subsequent steps (`init`, `plan`, `apply`, etc.) for that Job.

### Explicit Selection

You can set the `runner_instance_name` field on a **Module** to always use a Runner with a specific name. When set, requests go directly to that Runner without broadcasting.

## Allowing a Module to use a Runner

Before a **Module** can submit Jobs to a **Runner**, an assignment must exist. Assignments can be configured at different scopes:

| Method | Description |
|--------|-------------|
| `is_assigned_to_all_modules` on Runner | Allows any Module to use this Runner |
| [Runner Stack Assignment](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/runner_stack_assignment) | All Modules within the Stack can use the Runner |
| [Runner Namespace Assignment](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/runner_namespace_assignment) | All Modules within the Namespace can use the Runner |
| [Runner Module Assignment](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/runner_module_assignment) | Only the specified Module can use the Runner |

## Security Model

Runners execute Terraform/OpenTofu commands with the permissions granted to the underlying infrastructure (e.g., cloud credentials, Kubernetes service accounts). By restricting which Modules can use which Runners, you can enforce least-privilege access:

- Create Runners with narrowly scoped permissions
- Assign Runners only to Modules that require those specific permissions
- Use separate Runners for different environments (dev, staging, production)
