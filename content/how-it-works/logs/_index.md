---
title: Log Storage
weight: 3
sidebar:
  open: false
---

Snap CD captures and stores logs from [Job]({{< relref "how-it-works/orchestration" >}}) execution, providing visibility into Terraform/OpenTofu operations.

## How Logs Work

1. [Runners]({{< relref "components/runner" >}}) execute Jobs and generate logs via Serilog
2. Logs are batched and sent to the [Server]({{< relref "components/server" >}}) via SignalR in real-time
3. The Server stores logs as JSON in the database, attached to the **ModuleJob** record
4. Logs are available in the Dashboard and via the API

## Log Entry Structure

Each log entry contains:

| Field | Description |
|-------|-------------|
| `Timestamp` | When the log entry was created |
| `Level` | Severity: Verbose, Debug, Information, Warning, Error, Fatal |
| `Message` | The log message content |
| `TaskName` | The Job step (e.g., Init, Plan, Apply, Output) |
| `ModuleId` | The [Module]({{< relref "resources/stack-namespace-module#module" >}}) that generated the log |
| `StackName` / `NamespaceName` / `ModuleName` | Context for the log entry |

## Real-time Streaming

Logs are streamed to the Dashboard in real-time as Jobs execute. The Runner batches logs (default: every 5 seconds or 50 entries) and sends them via a persistent SignalR connection.

If the connection is temporarily lost, logs are buffered locally (up to 10,000 entries) and flushed when the connection is restored.

## Runner Configuration

Configure log batching on the Runner in `appsettings.json`:

```json
{
  "Logging": {
    "SystemDefaultLogLevel": "Error",
    "SnapCdDefaultLogLevel": "Information",
    "BatchSizeLimit": 50,
    "PeriodSeconds": 5
  }
}
```

| Setting | Default | Description |
|---------|---------|-------------|
| `SystemDefaultLogLevel` | Error | Log level for system/framework logs |
| `SnapCdDefaultLogLevel` | Information | Log level for Snap CD application logs |
| `BatchSizeLimit` | 50 | Maximum entries per batch |
| `PeriodSeconds` | 5 | How often to send batches |

## API Access

Logs can be retrieved via the API:

- `GET /api/{organizationId}/logs/{jobId}` - Returns structured log entries
- `GET /api/{organizationId}/logs/string/{jobId}` - Returns concatenated log text

## Storage

Logs are stored in the database as part of the **ModuleJob** entity. They persist for the lifetime of the Job record.
