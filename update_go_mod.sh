#!/bin/bash
set -e

echo "Updating all dependencies..."

go get -u ./...

echo "Restoring pinned dependencies..."

# go get "github.com/quic-go/quic-go@v0.64.1"

echo "Cleaning graph..."
go mod tidy

echo "Verifying modules..."
go mod verify
