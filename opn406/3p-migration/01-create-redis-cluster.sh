#!/bin/bash
# Exit on error, print commands
set -ex

NETWORK_NAME="valkey-demo-net"
REDIS_START_PORT=17000

# Start 9 Redis nodes
echo "Starting 9 Redis containers..."
CLUSTER_HOSTS=""
for i in $(seq 0 8); do
    port=$((REDIS_START_PORT + i))
    echo "Starting redis-c-$port on port $port"
    podman run -d \
        --name "redis-c-$port" \
        --network "$NETWORK_NAME" \
        -p "$port:$port" \
        redis:7.2-alpine \
        redis-server --cluster-enabled yes --cluster-node-timeout 5000 --port "$port" --appendonly no
    
    # Use container names for cluster creation (they resolve on the network)
    CLUSTER_HOSTS+="redis-c-$port:$port "
done

echo "Waiting for containers to start up..."
sleep 10

podman ps

# Create the cluster using podman exec
echo "Creating Redis cluster..."
echo "yes" | podman exec -i redis-c-$REDIS_START_PORT redis-cli --cluster create $CLUSTER_HOSTS --cluster-replicas 2

echo "Waiting for cluster to form..."
sleep 5

# Check cluster status using podman exec
echo "Redis Cluster Info:"
podman exec redis-c-$REDIS_START_PORT redis-cli -p $REDIS_START_PORT cluster info
podman exec redis-c-$REDIS_START_PORT redis-cli -p $REDIS_START_PORT cluster nodes | head -n 10

echo "Redis cluster created successfully."
