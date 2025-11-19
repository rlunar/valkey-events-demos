#!/bin/bash

set -x

source config.sh

echo "--- DEMO: LIVE MIGRATION (REDIS-SHAKE) ---"

echo "Enabling keyspace notifications 📢 on Redis OSS cluster..."
valkey-cli --cluster call "${REDIS_HOST}:${REDIS_PORT}" CONFIG SET notify-keyspace-events KEA

echo "Verifying keyspace notifications 📢 configuration..."
valkey-cli --cluster call "${REDIS_HOST}:${REDIS_PORT}" CONFIG GET notify-keyspace-events

# Create redis-shake TOML config for cluster-to-cluster migration
CONFIG_FILE="redis-shake.toml"
echo "Creating $CONFIG_FILE for cluster migration..."
cat > "$CONFIG_FILE" << EOL
[sync_reader]
cluster = true
address = "$REDIS_HOST:$REDIS_PORT"

[redis_writer]
cluster = true
address = "$VALKEY_HOST:$VALKEY_PORT"
EOL

echo "Config file created:"
cat "$CONFIG_FILE"

echo ""
echo "Starting redis-shake in scan mode for cluster migration..."
echo "This will scan all keys from Redis cluster and write to Valkey cluster."
echo ""
echo "******************************************************************"
echo "After migration completes, verify the data:"
echo "valkey-cli --cluster call "${VALKEY_HOST}:${VALKEY_PORT}" DBSIZE"
echo "******************************************************************"
echo ""

# Run redis-shake with SCAN mode
SCAN=true $REDIS_SHAKE_BINARY $CONFIG_FILE

echo ""
echo "Migration complete!"
echo "Verifying migration..."
echo "Redis cluster keys: $($VALKEY_LIVE_MIGRATION/redis-7.2.4/src/redis-cli -c -p $REDIS_PORT DBSIZE)"
echo "Valkey cluster keys: $($VALKEY_LIVE_MIGRATION/valkey-9.0.0/src/valkey-cli -c -p $VALKEY_PORT DBSIZE)"