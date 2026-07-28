# Vendored Scalar API Reference bundle

`standalone.min.js` — `@scalar/api-reference` **1.63.0** (browser standalone build),
self-hosted so the docs site never loads from a CDN.

Keep this in lockstep with the copy the app ships
(`applications/snapcd/SnapCd.Server.Core/wwwroot/scalar/standalone.min.js` in the
snapcd repo) so the in-app and public renderings stay identical:

```bash
curl -sL -o standalone.min.js \
  "https://cdn.jsdelivr.net/npm/@scalar/api-reference@<VERSION>/dist/browser/standalone.min.js"
```

The OpenAPI document it renders lives at `static/openapi/v1.json` — see the
"API reference" section of the repo README for how that file is refreshed.
