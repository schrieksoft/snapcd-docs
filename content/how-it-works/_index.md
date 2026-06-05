---
title: How it Works
weight: 6
sidebar:
  open: false
---



## High-Level Components


The two high-level components that Snap CD consists of are the [Server]({{< relref "components/server" >}}) and the [Runner(s)]({{< relref "components/runner" >}}). In addition, Snap CD depends on external services in the form of **Database**, **Logstore** and **Service Bus**. In addition, a **Terraform / OpenTofu Provider** is offered which interacts with the **Server's** Web API. We'll define each of these in turn below.

