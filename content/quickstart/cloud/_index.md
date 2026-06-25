---
title: Cloud Quickstart
weight: 2
sidebar:
  open: true
---

This guide walks you through getting started with the **Cloud** edition of Snap CD, hosted by Schrieksoft at [snapcd.io](https://snapcd.io).

If you'd prefer to host the [Server]({{< relref "components/server" >}}) yourself, follow the [Self-Hosted Quickstart]({{< relref "quickstart/self-hosted" >}}) instead.

## Create a User Account

Create a free user account on [snapcd.io](https://snapcd.io).

## Create an Organization

On your first login you will be asked to create an organization. Pick a unique name. Your user will automatically be set as an `Owner` on the organization.

## Pick a Subscription

Snap CD Cloud requires a paid subscription. Seer the [Pricing page](https://snapcd.io/Pricing) for available editions.

## (Optional) Invite Users to Your Organization

A single Snap CD user account can belong to any number of **Organizations**. You may invite new or existing users to join your organization and assign roles to them as needed. For example: you are the technical owner but someone else at your organization handles billing? Invite them and give them the `SubscriptionManager` role!

## Get to Know the Basics

We provide extensive documentation on how to get the best out of **Snap CD**. Before you continue with the rest of this quickstart guide, please read [the basics]({{< relref "basics" >}}).

## Start using the Terraform Provider

To start using the Terraform provider you must either:

- Generate a personal access token for your (`Organization.Owner`) user via the [snapcd.io](https://snapcd.io) portal.

OR

- Create a [Service Principal]({{< relref "resources/identity-access-management" >}}) (via the [snapcd.io](https://snapcd.io) portal) and grant it sufficient permissions (For getting started we recommend `Organization.Owner`).

Then configure the provider like [this](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs).

## Register a Runner

To register a [Runner]({{< relref "components/runner" >}}) you must:

1. Create a **Service Principal**. You may do this via the portal at [snapcd.io/ServicePrincipals](https://snapcd.io/ServicePrincipals). Pick a unique (within your organization) "Client ID" and set a "Client Secret". This **Service Principal** does not need any additional role assignments.
2. Create a **Runner** by associating your **Service Principal**. This can be done via the portal at [snapcd.io/Runners](https://snapcd.io/Runners). Make the Runner available to [Modules]({{< relref "resources/stack-namespace-module#module" >}}) within your organization by setting the `is_supplied_to_all_modules` flag to `true`. More granular supply approaches are discussed [here]({{< relref "resources/runner#allowing-a-module-to-use-a-runner" >}}).

## Deploy a Runner

> **Snap CD** orchestrates all infrastructure deployments via **Runners** that you host yourself. This means that **Snap CD** never needs to gain direct access to any of your infrastructure; it is responsible only for configuration, orchestration, providing inputs, and storing outputs and logs.

The **Runner** lives alongside the Server in the [schrieksoft/snapcd](https://github.com/schrieksoft/snapcd) repo, under [`applications/snapcd/SnapCd.Runner/`](https://github.com/schrieksoft/snapcd/tree/main/applications/snapcd/SnapCd.Runner). Binaries are published as zip archives on [GitHub Releases](https://github.com/schrieksoft/snapcd/releases) and official Docker images are published [here](https://github.com/schrieksoft/snapcd/pkgs/container/snapcd%2Fsnapcd-runner) (and an Azure-CLI-bundled flavour [here](https://github.com/schrieksoft/snapcd/pkgs/container/snapcd%2Fsnapcd-runner-azure)).

The Runner can be deployed via any of the following reference repositories. Each is substrate-specific and contains a self-contained `components/runner/` sub-deployment you can bring up on its own:

- Directly on your local machine: [github.com/schrieksoft/snapcd-deployment-local](https://github.com/schrieksoft/snapcd-deployment-local)
- Using Docker Compose: [github.com/schrieksoft/snapcd-deployment-docker](https://github.com/schrieksoft/snapcd-deployment-docker)
- On Kubernetes using Kustomize: [github.com/schrieksoft/snapcd-deployment-kubernetes](https://github.com/schrieksoft/snapcd-deployment-kubernetes)

For the purposes of this guide we recommend using the Docker Compose approach.

The Runner needs to know which Server to connect to — for Cloud, this is the default `https://snapcd.io`, so no override is required.

## Create a Stack

Create a [Stack]({{< relref "resources/stack-namespace-module#stack" >}}) called "samples" via the portal at [snapcd.io/Stacks](https://snapcd.io/Stacks). We'll use this Stack for the sample project.

## Create a Secret

Snap CD allows you to create [Secrets]({{< relref "resources/secrets" >}}) that can be passed into Modules as inputs. Create a Secret on your "samples" Stack via the portal at [snapcd.io/Stacks/samples?action=Secrets](https://snapcd.io/Stacks/samples?action=Secrets). Name the secret "quickstart-secret" and give it any text value.

## Deploy the Sample Project

In order to see in practice what a typical Snap CD project might look like, deploy [this](https://github.com/snapcd-samples/sample-deployment) sample project.
