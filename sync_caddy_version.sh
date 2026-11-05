#!/usr/bin/env bash
set -euo pipefail

CADDY_MODULE="github.com/caddyserver/caddy/v2"
DOCKERFILE="Dockerfile"

echo "Reading selected Caddy version from go.mod..."

CADDY_VERSION="$(go list -m -f '{{.Version}}' "$CADDY_MODULE")"

if [[ -z "$CADDY_VERSION" || "$CADDY_VERSION" == "(devel)" ]]; then
    echo "::error::Could not determine the selected Caddy module version"
    exit 1
fi

if [[ "$CADDY_VERSION" != v* ]]; then
    echo "::error::Unexpected Caddy module version: $CADDY_VERSION"
    exit 1
fi

echo "Selected Caddy version: $CADDY_VERSION"

ARG_COUNT="$(grep -Ec '^ARG CADDY_VERSION=' "$DOCKERFILE" || true)"

if [[ "$ARG_COUNT" -ne 1 ]]; then
    echo "::error::Expected exactly one ARG CADDY_VERSION declaration in Dockerfile"
    exit 1
fi

CURRENT_VERSION="$(
    sed -nE 's/^ARG CADDY_VERSION=([^[:space:]]+).*$/\1/p' "$DOCKERFILE"
)"

if [[ "$CURRENT_VERSION" == "$CADDY_VERSION" ]]; then
    echo "Dockerfile already references Caddy $CADDY_VERSION"
    exit 0
fi

echo "Updating Dockerfile Caddy version:"
echo "  Previous: $CURRENT_VERSION"
echo "  Updated:  $CADDY_VERSION"

sed -i -E \
    "s|^ARG CADDY_VERSION=.*$|ARG CADDY_VERSION=${CADDY_VERSION}|" \
    "$DOCKERFILE"

echo "Dockerfile Caddy version successfully synchronized"