#!/bin/bash
# Exit on error, print commands
set -ex

NETWORK_NAME="valkey-demo-net"
VALKEY_START_PORT=8000

# Check if network exists
if ! podman network ls | grep -q "$NETWORK_NAME"; then
    echo "Error: Docker network $NETWORK_NAME not found. Run script 01 first."
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
        --net "$NETWORK_NAME" \
        -p "$port:$port" \
        valkey/valkey:7.2 \
        valkey-server --cluster-enabled yes --cluster-node-timeout 5000 --port "$port" --appendonly no
    
    sleep 0.5
    HOST_IP=$(podman inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "valkey-c-$port")
    CLUSTER_HOSTS+="$HOST_IP:$port "
done

echo "Waiting for containers to start up..."
sleep 10

# Create the cluster
echo "Creating Valkey cluster..."
echo "yes" | valkey-cli --cluster create $CLUSTER_HOSTS --cluster-replicas 2

echo "Waiting for cluster to form..."
sleep 5

# Check cluster status
echo "Valkey Cluster Info:"
valkey-cli -p $VALKEY_START_PORT cluster info
valkey-cli -p $VALKEY_START_PORT cluster nodes | head -n 10
echo "Valkey cluster created successfully. It is currently empty."
valkey-cli -c -p $VALKEY_START_PORT DBSIZE
