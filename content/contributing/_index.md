---
title: Contributing
weight: 7
sidebar:
  open: false
---

Snap CD is built in the open. The repositories that house the [Server]({{< relref "components/server" >}}), the [Runner]({{< relref "components/runner" >}}), the [Agent]({{< relref "components/agent" >}}), the Terraform provider, the reference deployments, the public samples, and this documentation site are all **public**, and contributions are welcome from anyone.

If you're considering a non-trivial change, please open an issue on the relevant repository first so we can talk through the approach before you invest time. Small fixes (typos, broken links, clarifications, contained bug fixes) can go straight to a pull request.

## Repositories

### Core

| Repository | What's in it |
|------------|--------------|
| [schrieksoft/snapcd](https://github.com/schrieksoft/snapcd) | The main Snap CD monorepo — Server, Runner, Agent, contracts, and the source-available license |

### Terraform Provider

| Repository | What's in it |
|------------|--------------|
| [schrieksoft/terraform-provider-snapcd](https://github.com/schrieksoft/terraform-provider-snapcd) | The official [Terraform / OpenTofu provider](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs) for declaring Snap CD resources as code |

### Reference deployments

These ship reference deployments for running Snap CD components in your environment — one repository per substrate, each covering Server + Runner + Agent in a self-contained `components/` layout. They are the easiest place to start if you want a working setup to point at:

| Repository | What's in it |
|------------|--------------|
| [schrieksoft/snapcd-deployment-docker](https://github.com/schrieksoft/snapcd-deployment-docker) | Reference Docker Compose stack for Server + Runner + Agent (modular — each component is independently deployable) |
| [schrieksoft/snapcd-deployment-kubernetes](https://github.com/schrieksoft/snapcd-deployment-kubernetes) | Reference Kubernetes manifests (Kustomize) for Server + Runner + Agent, each in its own namespace |
| [schrieksoft/snapcd-deployment-local](https://github.com/schrieksoft/snapcd-deployment-local) | Reference local-binary setup — downloads release zips from GitHub and runs them as native processes |

### Samples

| Repository | What's in it |
|------------|--------------|
| [snapcd-samples/sample-deployment](https://github.com/snapcd-samples/sample-deployment) | A worked example using the Terraform provider — walks through Namespaces, Inputs, Secrets, Output Sets and so on, with extensively commented `snapcd_*` resources. The recommended starting point for new users learning the resource model |

### Documentation

| Repository | What's in it |
|------------|--------------|
| [schrieksoft/snapcd-docs](https://github.com/schrieksoft/snapcd-docs) | The Hugo source for this documentation site. Doc-only PRs (typos, clarifications, new sections) are merged here and republished automatically. See the repo's README for the local-preview flow |

## How to contribute

1. **Open an issue first** for anything beyond a small fix — describe the problem, your intended approach, and any context we'd need to evaluate it. This avoids surprises on both sides.
2. **Fork and branch** from `main` on the relevant repository. Keep the branch focused on one change.
3. **Match the existing style.** Each repository has its own conventions — formatter config, test patterns, commit-message shape. The simplest rule is to look at recent commits and PRs and follow that lead.
4. **Run the tests** locally before opening the PR. Each repo's README documents how.
5. **Open the PR** with a description that covers the *why* of the change as much as the *what*. Link the issue.
6. **Sign off** that the contribution is yours to make. By submitting a PR you confirm you agree to the licensing terms of the target repository.

## Reporting bugs and security issues

- **General bugs and feature requests** — file an issue on the repository in question.
- **Security issues** — please do **not** open a public issue. Email `info@snapcd.io` with the details, and we'll respond before any public disclosure.

## Licensing

The main Snap CD repository is distributed under the [Snap CD Source-Available License](https://github.com/schrieksoft/snapcd/blob/main/applications/snapcd/LICENSE.md). The reference-deployment repositories, the Terraform provider, and the public samples are under more permissive open-source licenses appropriate to their content; see each repository's `LICENSE` file for the specific terms.

Contributions are accepted under the licence of the repository you're contributing to. If a change you have in mind would touch the source-available license terms themselves, please reach out at `info@snapcd.io` before opening a PR.
