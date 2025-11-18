#!/bin/bash
# Exit on error, print commands
set -ex

NETWORK_NAME="valkey-demo-net"
VALKEY_START_PORT=18000

# Check if network exists
if ! podman network ls | grep -q "$NETWORK_NAME"; then
    echo "Error: Network $NETWORK_NAME not found. Run script 00 first."
    exit 1
fi

# Start 9 Valkey nodes
echo "Starting 9 Valkey containers..."
CLUSTER_HOSTS=""
for i in $(seq 0 8); do
    port=$((VALKEY_START_PORT + i))
    echo "Starting valkey-c-$port on port $port"
    podman run -d \
        --name "valkey-c-$port" \
        --network "$NETWORK_NAME" \
        -p "$port:$port" \
        valkey/valkey:7.2-alpine \
        valkey-server --cluster-enabled yes --cluster-node-timeout 5000 --port "$port" --appendonly no
    
    # Use container names for cluster creation (they resolve on the network)
    CLUSTER_HOSTS+="valkey-c-$port:$port "
done

echo "Waiting for containers to start up..."
sleep 10

podman ps

# Create the cluster using podman exec
echo "Creating Valkey cluster..."
echo "yes" | podman exec -i valkey-c-$VALKEY_START_PORT valkey-cli --cluster create $CLUSTER_HOSTS --cluster-replicas 2

echo "Waiting for cluster to form..."
sleep 5

# Check cluster status using podman exec
echo "Valkey Cluster Info:"
podman exec valkey-c-$VALKEY_START_PORT valkey-cli -p $VALKEY_START_PORT cluster info
podman exec valkey-c-$VALKEY_START_PORT valkey-cli -p $VALKEY_START_PORT cluster nodes | head -n 10
echo "Valkey cluster created successfully. It is currently empty."
podman exec valkey-c-$VALKEY_START_PORT valkey-cli -c -p $VALKEY_START_PORT DBSIZE
