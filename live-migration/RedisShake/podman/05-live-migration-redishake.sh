#!/bin/bash
# Exit on error, print commands
set -ex

NETWORK_NAME="valkey-demo-net"
REDIS_START_PORT=17000
VALKEY_START_PORT=18000
CONFIG_FILE="redis-shake.toml"

echo "--- DEMO: LIVE MIGRATION (REDIS-SHAKE) ---"

# Clean the Valkey cluster from the previous demo
echo "Flushing Valkey cluster to prepare for live migration..."
podman exec valkey-c-$VALKEY_START_PORT valkey-cli -p $VALKEY_START_PORT cluster nodes | grep 'master' | awk '{print $2}' | cut -d ':' -f 2 | cut -d '@' -f 1 | while read -r port; do
    echo "Flushing node $port"
    podman exec valkey-c-$port valkey-cli -p "$port" FLUSHALL
done
echo "Valkey cluster flushed. Total keys: $(podman exec valkey-c-$VALKEY_START_PORT valkey-cli -c -p $VALKEY_START_PORT DBSIZE)"

# Create redis-shake TOML config for cluster-to-cluster migration
echo "Creating $CONFIG_FILE for cluster migration..."
cat > "$CONFIG_FILE" << EOL
[sync_reader]
cluster = true
address = "redis-c-$REDIS_START_PORT:$REDIS_START_PORT"

[redis_writer]
cluster = true
address = "valkey-c-$VALKEY_START_PORT:$VALKEY_START_PORT"
EOL

echo "Config file created:"
cat "$CONFIG_FILE"

echo ""
echo "Starting redis-shake in scan mode for cluster migration..."
echo "This will scan all keys from Redis cluster and write to Valkey cluster."
echo ""
echo "******************************************************************"
echo "After migration completes, verify the data:"
echo "podman exec valkey-c-$VALKEY_START_PORT valkey-cli -c -p $VALKEY_START_PORT DBSIZE"
echo "******************************************************************"
echo ""

# Run redis-shake in a container on the same network with SCAN mode
podman run --rm \
    --network "$NETWORK_NAME" \
    -e SCAN=true \
    -v "$(pwd)/$CONFIG_FILE:/shake.toml:ro" \
    ghcr.io/tair-opensource/redisshake:latest \
    redis-shake /shake.toml

echo ""
echo "Migration complete!"

