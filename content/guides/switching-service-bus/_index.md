---
title: Switching Service Bus
weight: 2
sidebar:
  open: false
---

The [Server]({{< relref "components/server" >}}) carries its internal events — saga endpoints, Runner and Agent dispatch, log fanout — over a message bus. Two transports are supported, and moving between them, or to a different Azure Service Bus namespace, is an operation that must be done inside a [maintenance window]({{< relref "guides/maintenance-mode" >}}).

The reason is simple: messages live on the bus, not in the Server. Any message still in flight when you switch is on the old bus, and the new one will never see it. The **Transport idle** criterion in the Draining phase is exactly the check that this cannot happen.

## The two transports

| Transport | When to use it |
| --- | --- |
| **SqlServer** | The default. Routes events through tables in the application database. No additional infrastructure; suitable for single-region deployments up to moderate scale. |
| **AzureServiceBus** | Routes events through an Azure Service Bus namespace. For higher-throughput deployments, and any topology that wants the bus on managed infrastructure separate from SQL Server. |

Both are configured under the `ServiceBus` section. `BusType` selects the transport, and only the matching block under `TransportOptions` is read — the other is ignored, so you can leave both populated while switching.

### SQL Server

```json
{
  "ServiceBus": {
    "BusType": "SqlServer",
    "TransportOptions": {
      "SqlServer": {
        "ConnectionString": null,
        "Schema": "transport"
      }
    }
  }
}
```

Leaving `ConnectionString` as `null` falls back to the application's top-level `ConnectionString`, which is the usual arrangement — the bus then shares the application database, under its own schema.

### Azure Service Bus

The connection string accepts two forms, and the Server picks the authentication mode from the string itself.

A bare `sb://` URI authenticates with an Azure credential — a workload identity, a managed identity, or your local Azure CLI login, whichever the environment provides. This is the form to prefer, since no secret is stored:

```json
{
  "ServiceBus": {
    "BusType": "AzureServiceBus",
    "TransportOptions": {
      "AzureServiceBus": {
        "ConnectionString": "sb://example-namespace.servicebus.windows.net"
      }
    }
  }
}
```

A full `Endpoint=` string carries its own shared access key. This is convenient for a local or throwaway namespace where no identity is set up:

```json
{
  "ServiceBus": {
    "BusType": "AzureServiceBus",
    "TransportOptions": {
      "AzureServiceBus": {
        "ConnectionString": "Endpoint=sb://example-namespace.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=<shared-access-key>"
      }
    }
  }
}
```

A shared access key of `RootManageSharedAccessKey` grants full rights over the namespace. Treat it as a secret: supply it through your configuration provider rather than committing it, and prefer the `sb://` form wherever an identity is available.

## Sharing one namespace

`EndpointsPrefix` is prepended to every consumer queue name, which lets several Snap CD deployments share a single bus without colliding. If two deployments will point at the same namespace, give each a distinct prefix before either starts.

Changing `EndpointsPrefix` on an existing deployment renames every queue, so it is the same kind of operation as switching transport and belongs in the same window.

## Making the switch

Only the Server talks to the bus. Runners and Agents reach the Server over their own long-lived authenticated connections and hold no bus configuration, so they need no changes and no restart — they will reconnect on their own once the Server is back.

1. **Open a maintenance window** and let it drain. Watch the **Transport idle** criterion in particular: it goes green when every non-diagnostic queue is empty. Until it does, there are messages on the current bus that will be abandoned by the switch.

2. **Advance to Ready for maintenance.** Nothing is executing and the bus is empty.

3. **Stop the Server.**

4. **Change the configuration** — set `BusType`, and fill in the block for the transport you are moving to.

5. **Provision access if you are moving to Azure Service Bus.** The Server creates queues, topics and subscriptions at startup rather than expecting them to exist, so whichever credential it uses needs rights to manage the namespace's topology — not just to send and receive. For the `sb://` form that means the identity's role assignment on the namespace; for the `Endpoint=` form, a shared access policy with **Manage**.

6. **Start the Server.** It creates the queues, topics and subscriptions it needs on the new bus during startup. Confirm the Transport monitor on the maintenance page lists queues on the new bus before continuing.

7. **Advance through Reconciling and Resuming.** Reconciling re-derives the scheduled timers from the database onto the new bus — this is what makes it safe that scheduled messages were never drained from the old one. Resuming then wakes the parked jobs and re-drives the queued modules.

8. **Close the window.**

Do not skip from Ready for maintenance straight to closing. Jobs are parked and modules are queued at that point, and only the Resuming sweep wakes them; the panel will refuse and tell you the same thing.

## Afterwards

The old bus can be decommissioned once the new one has carried a full cycle of work. If you are moving off Azure Service Bus, delete the namespace only after confirming the Transport monitor shows activity on the new transport — the queues on the old namespace should be empty and static.

If you are moving between Azure Service Bus namespaces and used `EndpointsPrefix`, remember the prefix travels with the deployment, not the namespace; the new namespace will get the same queue names unless you change it deliberately.
