---
title: Settings
weight: 1
sidebar:
  open: false
---

## Overview

The Snap CD **Server**, **Runner** and **Agent** all read their runtime settings from the same .NET configuration pipeline. This page explains the layering and the External Settings provider mechanism. For the sections each individual component reads, see the [component pages]({{< relref "components" >}}).

## Layers

Settings are resolved in ascending priority. Later layers override earlier ones:

1. `appsettings.json` — nested JSON, ships in the image as the baseline
2. `appsettings.<Environment>.json` — nested JSON; per-environment overrides (`Development`, `Staging`, `Production`); the active file is selected by `ASPNETCORE_ENVIRONMENT` / `DOTNET_ENVIRONMENT`
3. Environment variables — use `__` to separate nested sections, since environment-variable names can't contain colons (e.g. `Runner__Credentials__ClientSecret=…`)
4. Command-line arguments — `--Runner:Credentials:ClientSecret=…`
5. **External Settings provider** — loads values from external secret stores into a `Data` map at startup; see below

All five layers describe the same nested-section tree. When this page or the [component pages]({{< relref "components" >}}) refers to a setting in prose, the form used is the nested-JSON path (e.g. `Runner.Credentials.ClientSecret` means the `ClientSecret` value inside the `Credentials` object inside the `Runner` object). Translate to the form your layer needs: nested JSON in `appsettings.json`, `__`-separated for env vars, `:`-separated for command-line arguments and External Settings provider `Data` keys.

## External Settings provider

The External Settings provider is Snap CD's mechanism for sourcing runtime values from external secret stores without baking them into image files or environment variables on disk. The typical use is keeping dev-friendly placeholders in `appsettings.json` while resolving the real production secrets from a vault at component startup.

The provider is configured via a separate `appsettings.External.json` file. The file contains a list of `Providers`, each declaring a `Loader` type, per-loader connection settings, and the mapping of Snap CD setting paths to external source keys:

```json
{
  "Providers": [
    {
      "Loader": "AzureKeyVault",
      "Configuration": { "VaultUrl": "https://my-vault.vault.azure.net" },
      "Data": {
        "ConnectionString": "snapcd-db-conn",
        "EmailSender:SendGrid:ApiKey": "sendgrid-key/d023e916822d4dc18c03e924cdc7c285"
      }
    }
  ]
}
```

Per-provider fields:

| Field | Purpose |
|-------|---------|
| `Loader` | Name of the loader type. Supported values: `AzureKeyVault`, `AmazonSecretsManager`, `Literal` |
| `Configuration` | Per-loader connection settings (e.g. vault URL, AWS region) |
| `Data` | Mapping of Snap CD setting paths to source-key references. Each entry's **key** is the dotted path the value lands at in the configuration pipeline; the **value** is the name of the secret in the external source |

The provider sits at the top of the configuration priority list, so any value it resolves overrides whatever was present in `appsettings.json`, environment variables, or command-line arguments.

### Supported loaders

#### `AzureKeyVault`

Resolves keys from an Azure Key Vault using `DefaultAzureCredential` (managed identity, environment, CLI, etc.).

```json
{
  "Loader": "AzureKeyVault",
  "Configuration": { "VaultUrl": "https://my-vault.vault.azure.net" },
  "Data": {
    "ConnectionString": "snapcd-db-conn",
    "Runner:Credentials:ClientSecret": "runner-sp-secret"
  }
}
```

Source-key references take the form `secret-name` or `secret-name/version`. Omitting the version resolves the current value.

| Configuration field | Purpose |
|---------------------|---------|
| `VaultUrl` | The vault's URL, e.g. `https://my-vault.vault.azure.net` |

#### `AmazonSecretsManager`

Resolves keys from AWS Secrets Manager. Authentication follows the standard AWS SDK credential chain (instance role, environment, profile).

```json
{
  "Loader": "AmazonSecretsManager",
  "Configuration": { "Region": "eu-west-1" },
  "Data": {
    "ConnectionString": "prod/snapcd/db-conn",
    "Runner:Credentials:ClientSecret": "prod/snapcd/runner-sp"
  }
}
```

| Configuration field | Purpose |
|---------------------|---------|
| `Region` | AWS region containing the secrets, e.g. `eu-west-1` |

#### `Literal`

Reads each `Data` value verbatim — no external lookup. Useful for composing multiple providers in a single file (a few literals alongside a vault block) and for layering secrets in via a sidecar that writes `appsettings.External.json` at startup.

```json
{
  "Loader": "Literal",
  "Configuration": {},
  "Data": {
    "Agent:Credentials:ClientSecret": "actual-secret-value-here"
  }
}
```

### Combining providers

The `Providers` list is processed top to bottom, with later entries overriding earlier ones. A common pattern is one `AzureKeyVault` or `AmazonSecretsManager` block for production secrets, with a small `Literal` block above it for values that don't merit a vault entry:

```json
{
  "Providers": [
    {
      "Loader": "Literal",
      "Configuration": {},
      "Data": {
        "Server:Host": "https://snapcd.example.com"
      }
    },
    {
      "Loader": "AzureKeyVault",
      "Configuration": { "VaultUrl": "https://my-vault.vault.azure.net" },
      "Data": {
        "ConnectionString": "snapcd-db-conn"
      }
    }
  ]
}
```

## Per-component settings

For the sections each component process actually reads, see:

- [Server settings]({{< relref "components/server#settings" >}})
- [Runner settings]({{< relref "components/runner#settings" >}})
- [Agent settings]({{< relref "components/agent#settings" >}})
