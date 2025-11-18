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

# Create redis-shake TOML config for cluster-to-cluster sync
echo "Creating $CONFIG_FILE for cluster sync..."
cat > "$CONFIG_FILE" << EOL
[sync_reader]
cluster = true
address = "127.0.0.1:$REDIS_START_PORT"

[redis_writer]
cluster = true
address = "127.0.0.1:$VALKEY_START_PORT"
EOL

echo "Config file created:"
cat "$CONFIG_FILE"

echo ""
echo "Starting redis-shake in sync mode..."
echo "It will perform a full sync, then stay connected for live updates."
echo ""
echo "******************************************************************"
echo "IN A NEW TERMINAL, test the live sync:"
echo "1. Add a key to Redis: podman exec redis-c-$REDIS_START_PORT redis-cli -c -p $REDIS_START_PORT SET live_key 'it works!'"
echo "2. Read the key from Valkey: podman exec valkey-c-$VALKEY_START_PORT valkey-cli -c -p $VALKEY_START_PORT GET live_key"
echo "******************************************************************"
echo ""
echo "Press [Ctrl+C] to stop redis-shake when you are finished."

# Run redis-shake binary. This command will block.
/Users/rberoj/Code/GitHub/OSS/RedisShake/bin/redis-shake "$CONFIG_FILE"

