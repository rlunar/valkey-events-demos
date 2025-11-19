#!/bin/bash
# Exit on error, print commands
set -ex

NETWORK_NAME="valkey-demo-net"

# Create a dedicated network for our clusters
if ! podman network ls | grep -q "$NETWORK_NAME"; then
    echo "Creating network: $NETWORK_NAME"
    podman network create "$NETWORK_NAME"
else
    echo "Network $NETWORK_NAME already exists."
fi

podman pull ghcr.io/tair-opensource/redisshake:latest
podman pull docker.io/redis:7.2-alpine
podman pull docker.io/valkey/valkey:7.2-alpine
podman pull docker.io/valkey/valkey:8.0-alpine
podman pull docker.io/valkey/valkey:8.1-alpine
podman pull docker.io/valkey/valkey:9.0-alpine
