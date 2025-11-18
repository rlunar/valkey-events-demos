#!/bin/bash
# Exit on error, print commands
set -ex

REDIS_START_PORT=7000
VALKEY_START_PORT=8000
CONFIG_FILE="redis-shake.conf"

echo "--- DEMO: LIVE MIGRATION (REDIS-SHAKE) ---"

# Clean the Valkey cluster from the previous demo
echo "Flushing Valkey cluster to prepare for live migration..."
valkey-cli -p $VALKEY_START_PORT cluster nodes | grep 'primary' | awk '{print $2}' | cut -d ':' -f 2 | cut -d '@' -f 1 | while read -r port; do
    echo "Flushing node $port"
    valkey-cli -p "$port" FLUSHALL
done
echo "Valkey cluster flushed. Total keys: $(valkey-cli -c -p $VALKEY_START_PORT DBSIZE)"

# Create redis-shake config
echo "Creating $CONFIG_FILE"
cat > "$CONFIG_FILE" << EOL
[common]
# log file
log.file = redis-shake.log

[source]
type = cluster
address = 127.0.0.1:$REDIS_START_PORT

[target]
type = cluster
address = 127.0.0.1:$VALKEY_START_PORT
EOL

echo "Config file created:"
cat "$CONFIG_FILE"

echo ""
echo "Starting redis-shake in sync mode..."
echo "It will perform a full sync, then stay connected for live updates."
echo ""
echo "******************************************************************"
echo "IN A NEW TERMINAL, test the live sync:"
echo "1. Add a key to Redis: redis-cli -c -p $REDIS_START_PORT SET live_key 'it works!'"
echo "2. Read the key from Valkey: valkey-cli -c -p $VALKEY_START_PORT GET live_key"
echo "******************************************************************"
echo ""
echo "Press [Ctrl+C] to stop redis-shake when you are finished."

# Run redis-shake. This command will block.
# Ensure 'redis-shake' binary is in your PATH
redis-shake -conf="$CONFIG_FILE" -type=sync
