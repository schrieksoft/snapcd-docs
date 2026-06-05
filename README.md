# Snap CD Documentation

This repository contains the technical documentation for Snap CD, built using [Hugo](https://gohugo.io/).

## Overview

The documentation is organized into several key sections:



## Prerequisites

- [Hugo](https://gohugo.io/) (Extended version)
- Git

## Local Development

- Either start the Hugo development server locally:

```bash
hugo server --port 1314
```

- Or run the pre-build docs base image. 
- 
```bash
# run docker container
docker run --rm --name scapcd-docs -v $(pwd):/site -p 1314:1314 ghcr.io/schrieksoft/docs-base-image:0.1.0 hugo server --port 1314 --bind 0.0.0.0 --buildDrafts --buildFuture --watch
```

Open your browser and navigate to `http://localhost:1314`

## Refreshing the Settings reference

The `## Settings` section on each `content/components/{server,runner,agent}/_index.md` page is rendered by the `{{< settings component="…" >}}` shortcode (defined under `layouts/`), which walks a JSON Schema data file at `data/schemas/<component>.json`.

The JSON Schemas are **generated artifacts** owned by the snapcd code repo. The source of truth is `applications/snapcd/schemas/{server,runner,agent}.schema.json`, produced by per-component generators under `applications/snapcd/generators/SnapCd.Settings.Generator.*`. Settings POCO descriptions come from `///` XML doc comments on the C# settings types; defaults come from the property initialisers. See the [Snap CD repository README](https://github.com/schrieksoft/snapcd) for how the generators work end-to-end.

To pull the latest schemas into this docs repo:

```bash
# from the snapcd code repo
cd applications/snapcd
scripts/check-settings-schemas.sh --write    # regenerates schemas/*.schema.json

# from this docs repo
cp /path/to/snapcd/applications/snapcd/schemas/server.schema.json   data/schemas/server.json
cp /path/to/snapcd/applications/snapcd/schemas/runner.schema.json   data/schemas/runner.json
cp /path/to/snapcd/applications/snapcd/schemas/agent.schema.json    data/schemas/agent.json
```

Drop the `.schema` segment when copying — Hugo's `Site.Data` indexes by the basename, and the shortcode looks up `Site.Data.schemas.<component>`.

After copying:

```bash
hugo server --port 1314    # rebuild; eyeball each component page's Settings section
```

The hand-written "At a glance" tables above the shortcode are **not** auto-generated — they're a curated short index. They can drift from the schema-side descriptions; reconcile by hand when the underlying settings change. (See [open question on auto-generating the tables](#) below.)

### When to refresh

Refresh whenever any of the following lands on snapcd `main`:

- A new public property on a settings POCO (e.g. `RunnerSettings`, `OpenIdConnectSettings`, …)
- A new `<summary>` doc on an existing property
- A new default value in a property initialiser
- A new section bound via `Configure<T>` in a host project
- A change to one of the hand-authored carve-out fragments under `SnapCd.Utils/Settings/Carveouts/` (e.g. `logging.schema.json`, `azurekeyvault-credentialoptions.schema.json`)
- A change to the post-process callback in `SnapCd.Settings.Generator.Server` that builds the MassTransit or AzureKeyVault.CredentialOptions fragments

The pre-commit hook in the snapcd repo (`scripts/check-settings-schemas.sh`) guards against drift between the C# source and the committed `schemas/*.schema.json` artifacts there. There is **no automated guard** between the snapcd-side artifacts and the copies in this docs repo's `data/schemas/`; the copy step is currently manual.

### Future: automate the cross-repo sync

The schemas live in two places: `applications/snapcd/schemas/*.schema.json` (canonical) and `docs/snapcd-docs/data/schemas/*.json` (consumed). A future GitHub Action on the snapcd repo could open a cross-repo PR against this docs repo whenever the canonical schemas change. Until that lands, the copy is manual and worth running after any merge to snapcd `main` that touches a settings type, its XML doc, or the generators.


