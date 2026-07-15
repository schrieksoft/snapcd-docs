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

## Changing content vs. changing styling

These are two different workflows, and confusing them is how the site once spent
weeks serving a **blue** accent while the source said orange. Read this before you
touch any CSS.

### Editing content (`.md` files) — nothing special

Hugo renders markdown on every save and the dev server hot-reloads. Just edit and
look. This covers prose, front matter, `data/`, new pages — the overwhelming
majority of work on this repo.

The stylesheet is not involved and does not need rebuilding.

### Editing styling (CSS, Tailwind classes) — you must rebuild

Hugo serves a **pre-compiled** stylesheet,
`themes/snapcd/assets/css/compiled/main.css`, which is committed to the repo. It
does **not** compile the CSS for you. So editing `styles.css` and reloading shows
you nothing: the compiled file is what the browser gets, and nothing has changed
it.

After any CSS change:

```bash
# 1. refresh hugo_stats.json (the list of classes actually used — see below)
hugo --gc --buildDrafts --buildFuture

# 2. recompile the stylesheet
cd themes/snapcd
npm install          # first time only
npm run build:css    # -> assets/css/compiled/main.css

# 3. sanity-check, then commit BOTH the source and the compiled file
grep -o 'hx-' assets/css/compiled/main.css | wc -l   # expect ~500. A handful means it purged.
```

(Use `grep -o … | wc -l` to count *occurrences*. `grep -c` counts matching *lines*,
which is meaningless once the CSS is minified onto a single line.)

Commit the regenerated `compiled/main.css` **together with** your source edit. A
source-only commit changes nothing in production — that is exactly the bug that
shipped the blue accent: the brand commit (`3c6126d`) changed `styles.css` from
blue to orange but never rebuilt the artifact.

You also need this if you add a **new Tailwind class** to a layout or shortcode
(e.g. `hx-mt-24`), even though that is not a CSS file: the class does not exist in
the compiled stylesheet until it is rebuilt.

**Where to edit what:**

| Want to change… | Edit |
| --- | --- |
| The brand accent | the three `--primary-*` numbers in `themes/snapcd/assets/css/styles.css` |
| Fonts, colour scale, breakpoints | `themes/snapcd/tailwind.config.js` |
| A component (navbar, sidebar, cards…) | `themes/snapcd/assets/css/components/` |
| Prose / markdown body styles | `themes/snapcd/assets/css/typography.css` |
| Syntax highlighting | `themes/snapcd/assets/css/highlight.css` |

`styles.css` imports all the others, so it is the single entry point Tailwind
compiles.

### Why it works this way (and how it breaks)

Tailwind **purges every utility class it cannot prove is used**, to keep the
stylesheet small. It proves usage from two sources, configured in
`tailwind.config.js`:

- **`hugo_stats.json`** — a manifest Hugo writes listing every class it actually
  emitted. Rebuild it (step 1 above) before compiling, or you purge against a
  stale snapshot.
- **`layouts/**/*.html`** — the templates themselves. This matters: the manifest
  only records classes on pages that were *rendered*, so a shortcode nobody has
  used yet (`callout`, `icon`, `hero-headline`) contributes nothing. Without
  scanning the templates, the first person to write `{{< callout >}}` in a doc
  would get an unstyled box.

The failure mode is silent — Tailwind cheerfully emits a stylesheet with every
`hx-` class stripped, and the site renders naked. If that happens, the class-count
check in step 3 is how you spot it.

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


