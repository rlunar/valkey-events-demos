#!/bin/bash
# Exit on error, print commands
set -ex

BACKUP_DIR="./redis-backup"
REDIS_PRIMARY_PORTS=$(ls $BACKUP_DIR/dump-*.rdb | xargs -n 1 basename | cut -d '-' -f 2 | cut -d '.' -f 1)
VALKEY_START_PORT=18000

if [ -z "$REDIS_PRIMARY_PORTS" ]; then
    echo "Error: No backup files found in $BACKUP_DIR. Run script 02 first."
    exit 1
fi

echo "--- DEMO: COLD MIGRATION (BACKUP/RESTORE) ---"
echo "Found Redis primary backups for ports: $REDIS_PRIMARY_PORTS"

# Map Redis primary ports to Valkey primary ports
# 17000 -> 18000, 17001 -> 18001, 17002 -> 18002
# This assumes the first 3 nodes are primaries in both clusters.
echo "Stopping Valkey primary nodes..."
VALKEY_PRIMARY_PORTS=""
for r_port in $REDIS_PRIMARY_PORTS; do
    v_port=$((r_port + 1000)) # 17000 -> 18000, 17001 -> 18001, etc.
    VALKEY_PRIMARY_PORTS+=" $v_port"

    echo "Stopping valkey-c-$v_port"
    podman stop "valkey-c-$v_port"

    echo "Copying Redis RDB dump-$r_port.rdb to valkey-c-$v_port"
    podman cp "$BACKUP_DIR/dump-$r_port.rdb" "valkey-c-$v_port:/data/dump.rdb"
done

# Restart Valkey primaries
echo "Restarting Valkey primary nodes..."
for v_port in $VALKEY_PRIMARY_PORTS; do
    echo "Starting valkey-c-$v_port"
    podman start "valkey-c-$v_port"
done

echo "Waiting for cluster to re-stabilize..."
sleep 15

# Check for data using podman exec
echo "Checking for restored data in Valkey cluster..."
echo "Total keys in Valkey: $(podman exec valkey-c-$VALKEY_START_PORT valkey-cli -c -p $VALKEY_START_PORT DBSIZE)"

echo "Fetching sample keys:"
podman exec valkey-c-$VALKEY_START_PORT valkey-cli -c -p $VALKEY_START_PORT GET "key__rand_int__"

echo "Backup/Restore demo complete."
