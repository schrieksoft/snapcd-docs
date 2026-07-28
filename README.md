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
source-only commit changes nothing in production.

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

## Generated artifacts from the snapcd repo

Two kinds of content on this site are **generated artifacts owned by the snapcd code
repo**, not authored here:

| Artifact | Rendered by | Lands at |
|---|---|---|
| Settings schemas (`{server,runner,agent}.schema.yaml`) | the `{{< settings component="…" >}}` shortcode | `data/schemas/<component>.yaml` |
| OpenAPI document (`openapi.yaml`) | the API reference page (Scalar) | `static/openapi/v1.yaml` |

Both are produced by generators in snapcd and guarded there by pre-commit hooks
(`scripts/check-settings-schemas.sh`, `scripts/check-openapi-document.sh`), so the
committed artifacts cannot drift from the C# source. Settings descriptions come from
`///` XML doc comments and defaults from property initialisers; the OpenAPI document
comes from the controllers and DTOs via `generators/SnapCd.OpenApi.Generator`.

### How they get here

**In CI (authoritative).** The release workflow runs
`scripts/fetch-snapcd-artifacts.sh`, which downloads all four files from the snapcd
GitHub release named in `versions.env`. Nothing is committed to this repo, and the
published site is always tied to a specific snapcd release. Renovate bumps
`SNAPCD_VERSION` in `versions.env` when a new release ships — hourly, and immediately
via a `repository_dispatch` from snapcd's release workflow.

**Locally.** Two make targets bring the same four files in, depending on whether you
want what has been released or what is on your disk:

```bash
make sync                                   # download from the release in versions.env
make sync VERSION=1.9.0                     # or a specific release

make sync-local                             # copy from a snapcd checkout instead
make sync-local SNAPCD_REPO=~/code/snapcd   # non-default checkout location

hugo server --port 1314                     # eyeball the Settings sections and /api-reference/
```

`make sync` wraps the same script CI runs, so it is the way to reproduce what the
published site will render. `make sync-local` is for previewing changes that have not
been released yet — it regenerates nothing, so run the generators on the snapcd side
first if the source has changed there:

```bash
cd /path/to/snapcd/applications/snapcd
scripts/check-settings-schemas.sh --write
scripts/check-openapi-document.sh --write
```

Note the `.schema` segment is dropped for the settings files on the way in: Hugo's
`Site.Data` indexes by basename, and the shortcode looks up
`Site.Data.schemas.<component>`.

### When they change

Settings schemas: a new public property on a settings POCO, a new `<summary>`, a new
default, a new section bound via `Configure<T>`, or a change to the hand-authored
carve-out fragments under `SnapCd.Utils/Settings/Carveouts/`.

OpenAPI document: any change to a controller, route, or DTO shape.

In both cases the snapcd-side hook regenerates the artifact, the release publishes it,
and Renovate pulls it in — no manual step.

The hand-written "At a glance" tables above the settings shortcode are **not**
auto-generated: they are a curated short index and can drift from the schema-side
descriptions. Reconcile them by hand when the underlying settings change.


