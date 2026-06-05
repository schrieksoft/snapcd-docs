---
title: Self-Hosted Quickstart
weight: 1
sidebar:
  open: true
---

This guide walks you through getting started with a **self-hosted** Snap CD Server. For background on the licensing model and operational concerns, see the [Server]({{< relref "components/server" >}}) page.

If you'd prefer the hosted experience instead, follow the [Cloud Quickstart]({{< relref "quickstart/cloud" >}}).

## Deploy Snap CD Locally

In order to get up and running with Snap CD within a few minutes, we recommend using the pre-configured [Docker deployment](https://github.com/schrieksoft/snapcd-deployment-docker). It brings up all three Snap CD components (Server, Runner, Agent) together via Docker Compose.

> Note that we strongly recommend switching out pre-configured keys and credentials for your own ones once you are ready to start using Snap CD in production!

## Get to Know the Basics

Before continuing, please read [the basics]({{< relref "basics" >}}) for an overview of Stacks, Namespaces, Modules and Runners.

## Deploy the Sample Project

In order to see in practice what a typical Snap CD project might look like, deploy [this](https://github.com/schrieksoft/snapcd-sample-deployment) sample project.

