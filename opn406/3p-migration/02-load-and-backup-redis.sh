#!/bin/bash
# Exit on error, print commands
set -ex

REDIS_START_PORT=17000
BACKUP_DIR="./redis-backup"

# Load 1000 sample keys
echo "Loading 1000 sample keys into Redis cluster..."
for i in $(seq 1 1000); do
    podman exec redis-c-$REDIS_START_PORT redis-cli -c -p $REDIS_START_PORT SET "key:$i" "value:$i-$RANDOM"
done

echo "Data loaded. Verifying key distribution..."
podman exec redis-c-$REDIS_START_PORT redis-cli -p $REDIS_START_PORT cluster nodes
echo "Total keys: $(podman exec redis-c-$REDIS_START_PORT redis-cli -c -p $REDIS_START_PORT DBSIZE)"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Find primary nodes and back them up
echo "Finding primary nodes and initiating BGSAVE..."
PRIMARY_PORTS=$(podman exec redis-c-$REDIS_START_PORT redis-cli -p $REDIS_START_PORT cluster nodes | grep 'master' | awk '{print $2}' | cut -d ':' -f 2 | cut -d '@' -f 1)

if [ -z "$PRIMARY_PORTS" ]; then
    echo "Error: Could not find primary nodes!"
    exit 1
fi

echo "Found primary nodes at ports: $PRIMARY_PORTS"

for port in $PRIMARY_PORTS; do
    echo "Triggering BGSAVE on port $port"
    podman exec redis-c-$port redis-cli -p "$port" BGSAVE

    # In a real script, you'd loop and check `INFO persistence`
    # For a demo, a simple sleep is fine.
    echo "Waiting for RDB file to be written on $port..."
    sleep 5

    echo "Copying dump.rdb from redis-c-$port"
    podman cp "redis-c-$port:/data/dump.rdb" "$BACKUP_DIR/dump-$port.rdb"
done

echo "Backup complete. RDB files are in $BACKUP_DIR:"
ls -l "$BACKUP_DIR"
