#!/bin/bash
set -e

echo "Updating all dependencies..."

go get -u ./...

echo "Restoring pinned dependencies..."

go get "github.com/caddyserver/caddy/v2@v2.11.4"

echo "Cleaning graph..."
go mod tidy

echo "Verifying modules..."
go mod verify
