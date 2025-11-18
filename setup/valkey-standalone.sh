#!/bin/bash

VALKEY_PATH="/Users/rberoj/Code/GitHub/valkey-io/valkey"
SETUP_DIR="/Users/rberoj/Code/GitHub/valkey-io/valkey-booth-demo/setup"
MASTER_PORT=6379
REPLICA_PORT=6380
CONFIG_FILE="$SETUP_DIR/valkey-standalone.conf"

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

# Stop any existing instances
echo "Stopping existing instances..."
./src/valkey-cli -p $MASTER_PORT shutdown nosave 2>/dev/null || true
./src/valkey-cli -p $REPLICA_PORT shutdown nosave 2>/dev/null || true

# Start master instance
echo "Starting Valkey master on port $MASTER_PORT..."
./src/valkey-server "$CONFIG_FILE" --port $MASTER_PORT --daemonize yes --logfile "$SETUP_DIR/valkey-master.log" --dir "$SETUP_DIR"

# Start replica instance
echo "Starting Valkey replica on port $REPLICA_PORT..."
./src/valkey-server "$CONFIG_FILE" --port $REPLICA_PORT --replicaof 127.0.0.1 $MASTER_PORT --daemonize yes --logfile "$SETUP_DIR/valkey-replica.log" --dbfilename dump-replica.rdb --dir "$SETUP_DIR"

echo "Valkey standalone with replica setup complete:"
echo "Master: port $MASTER_PORT"
echo "Replica: port $REPLICA_PORT"
echo "Connect with: ./src/valkey-cli -p $MASTER_PORT"