# Generated artifacts owned by the snapcd code repo, brought in for the docs site to
# render. Two ways to get them:
#
#   make sync        — download from a snapcd GitHub release (what CI does; the version
#                      comes from versions.env, or pass VERSION=1.9.0)
#   make sync-local  — copy from a local snapcd checkout, for previewing changes that
#                      have not been released yet
SNAPCD_REPO ?= ../../applications/snapcd

SCHEMA_SRC := $(SNAPCD_REPO)/schemas

.PHONY: sync
sync:
	@scripts/fetch-snapcd-artifacts.sh $(VERSION)
	@git --no-pager diff --stat -- data/schemas static/openapi || true

.PHONY: sync-local
sync-local:
	@test -d "$(SCHEMA_SRC)" || { \
	    echo "snapcd repo not found at $(SNAPCD_REPO)"; \
	    echo "pass SNAPCD_REPO=/path/to/snapcd, e.g. make sync-local SNAPCD_REPO=~/code/snapcd"; \
	    exit 1; \
	}
	@# Settings schemas: Hugo indexes Site.Data by basename, so the .schema segment goes.
	cp "$(SCHEMA_SRC)/server.schema.json" data/schemas/server.json
	cp "$(SCHEMA_SRC)/runner.schema.json" data/schemas/runner.json
	cp "$(SCHEMA_SRC)/agent.schema.json"  data/schemas/agent.json
	@# OpenAPI document: served as a static asset, fetched by Scalar at runtime.
	cp "$(SCHEMA_SRC)/openapi.json" static/openapi/v1.json
	@echo "synced settings schemas + OpenAPI document from $(SNAPCD_REPO)"
	@git --no-pager diff --stat -- data/schemas static/openapi || true
