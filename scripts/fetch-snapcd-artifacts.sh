#!/usr/bin/env bash
set -euo pipefail

# Downloads the generated artifacts the docs site renders — the three settings schemas
# and the OpenAPI document — from a snapcd release, and drops them where Hugo expects
# them. This is what CI uses; `make sync` is the local-development shortcut that copies
# from a checkout instead.
#
# The version comes from versions.env, which Renovate bumps when a new snapcd release
# appears.
#
# Usage:
#   scripts/fetch-snapcd-artifacts.sh              # version from versions.env
#   scripts/fetch-snapcd-artifacts.sh 1.9.0        # explicit version

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
    VERSION="$(grep -oP '^SNAPCD_VERSION=\K.*' versions.env)"
fi

BASE="https://github.com/schrieksoft/snapcd/releases/download/${VERSION}"

echo "Fetching snapcd ${VERSION} docs artifacts"

# Download to a staging dir first: a partial failure must not leave the tree with a
# mix of old and new artifacts, and the site must not publish with stale ones.
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT

fetch() {
    if ! curl -fsSL "${BASE}/$1" -o "${STAGING}/$1"; then
        echo "  failed to download $1 from ${VERSION}" >&2
        echo "  (releases before the artifact-publishing change do not carry it)" >&2
        exit 1
    fi
}

for component in server runner agent; do
    fetch "${component}.schema.yaml"
done
fetch "openapi.yaml"

# Hugo indexes Site.Data by basename, so the .schema segment is dropped on the way in.
for component in server runner agent; do
    mv "${STAGING}/${component}.schema.yaml" "data/schemas/${component}.yaml"
    echo "  data/schemas/${component}.yaml"
done

# The OpenAPI document is a static asset: Scalar fetches it over HTTP at runtime.
mv "${STAGING}/openapi.yaml" "static/openapi/v1.yaml"
echo "  static/openapi/v1.yaml"
