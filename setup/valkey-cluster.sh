#!/bin/bash

VALKEY_PATH="/Users/rberoj/Code/GitHub/valkey-io/valkey"
SETUP_DIR="/Users/rberoj/Code/GitHub/valkey-io/valkey-booth-demo/setup"
CLUSTER_DIR="$SETUP_DIR/cluster"

cd "$VALKEY_PATH"

# Update and compile Valkey if there are changes
echo "Checking for Valkey repository updates..."
git fetch
if [ $(git rev-list HEAD...origin/unstable --count) -gt 0 ]; then
    echo "Updates found, pulling and compiling..."
    git pull
    make clean
    make
else
    echo "No updates found, skipping compilation"
fi

# Create cluster directory in setup folder
mkdir -p "$CLUSTER_DIR"
cd "$CLUSTER_DIR"

# Stop existing cluster
echo "Stopping existing cluster..."
for port in {30001..30009}; do
    "$VALKEY_PATH/src/valkey-cli" -p $port shutdown nosave 2>/dev/null || true
done

# Clean previous cluster data
echo "Cleaning previous cluster data..."
rm -f *.log *.rdb nodes-*.conf appendonlydir-*

# Start 9 cluster nodes
echo "Starting 9 cluster nodes..."
for port in {30001..30009}; do
    "$VALKEY_PATH/src/valkey-server" --port $port --cluster-enabled yes --cluster-config-file "nodes-${port}.conf" --cluster-node-timeout 2000 --appendonly yes --appendfilename "appendonly-${port}.aof" --appenddirname "appendonlydir-${port}" --dbfilename "dump-${port}.rdb" --logfile "${port}.log" --daemonize yes --dir "$CLUSTER_DIR" --save 900 1
done

# Wait for nodes to start
sleep 3

# Create cluster with 3 shards and 2 replicas each
echo "Creating cluster with 3 shards and 2 replicas each..."
"$VALKEY_PATH/src/valkey-cli" --cluster create 127.0.0.1:30001 127.0.0.1:30002 127.0.0.1:30003 127.0.0.1:30004 127.0.0.1:30005 127.0.0.1:30006 127.0.0.1:30007 127.0.0.1:30008 127.0.0.1:30009 --cluster-replicas 2 --cluster-yes

echo "Valkey Cluster setup complete:"
echo "9 nodes running on ports 30001-30009"
echo "3 shards with 2 replicas each"
echo "Cluster data in: $CLUSTER_DIR"
echo "Connect with: $VALKEY_PATH/src/valkey-cli -c -p 30001"
echo "View cluster nodes: $VALKEY_PATH/src/valkey-cli -p 30001 cluster nodes"