#!/bin/bash
# Exit on error, print commands
set -ex

NETWORK_NAME="valkey-demo-net"

echo "Cleaning up demo environment..."

# Stop and remove all Redis containers
echo "Stopping and removing Redis containers..."
podman stop $(podman ps -a -q -f "name=redis-c-") || true
podman rm $(podman ps -a -q -f "name=redis-c-") || true

# Stop and remove all Valkey containers
echo "Stopping and removing Valkey containers..."
podman stop $(podman ps -a -q -f "name=valkey-c-") || true
podman rm $(podman ps -a -q -f "name=valkey-c-") || true

# Remove the Docker network
echo "Removing Docker network $NETWORK_NAME..."
podman network rm "$NETWORK_NAME" || true

# Remove local backup files
echo "Removing local backup directory..."
rm -rf ./redis-backup

# Remove redis-shake config and log
echo "Removing redis-shake files..."
rm -f redis-shake.conf redis-shake.log

echo "Cleanup complete."
