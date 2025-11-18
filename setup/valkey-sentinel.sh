#!/bin/bash

VALKEY_PATH="/Users/rberoj/Code/GitHub/valkey-io/valkey"
SETUP_DIR="/Users/rberoj/Code/GitHub/valkey-io/valkey-booth-demo/setup"
MASTER_PORT=6379
REPLICA_PORT=6380
SENTINEL_PORT=26379

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

# Stop existing instances
echo "Stopping existing instances..."
./src/valkey-cli -p $MASTER_PORT shutdown nosave 2>/dev/null || true
./src/valkey-cli -p $REPLICA_PORT shutdown nosave 2>/dev/null || true
./src/valkey-cli -p $SENTINEL_PORT shutdown nosave 2>/dev/null || true

# Start master
echo "Starting Valkey master on port $MASTER_PORT..."
./src/valkey-server "$SETUP_DIR/valkey-sentinel-master.conf" --port $MASTER_PORT --daemonize yes --logfile "$SETUP_DIR/valkey-master.log" --dir "$SETUP_DIR"

# Start replica
echo "Starting Valkey replica on port $REPLICA_PORT..."
./src/valkey-server "$SETUP_DIR/valkey-sentinel-replica.conf" --port $REPLICA_PORT --replicaof 127.0.0.1 $MASTER_PORT --daemonize yes --logfile "$SETUP_DIR/valkey-replica.log" --dir "$SETUP_DIR"

# Create sentinel config
cat > "$SETUP_DIR/sentinel.conf" << EOF
port $SENTINEL_PORT
sentinel monitor mymaster 127.0.0.1 $MASTER_PORT 1
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 10000
sentinel parallel-syncs mymaster 1
daemonize yes
logfile $SETUP_DIR/valkey-sentinel.log
dir $SETUP_DIR
EOF

# Start sentinel
echo "Starting Valkey Sentinel on port $SENTINEL_PORT..."
./src/valkey-sentinel "$SETUP_DIR/sentinel.conf"

echo "Valkey Sentinel setup complete:"
echo "Master: port $MASTER_PORT"
echo "Replica: port $REPLICA_PORT"
echo "Sentinel: port $SENTINEL_PORT"
echo "Connect to master: ./src/valkey-cli -p $MASTER_PORT"
echo "Connect to sentinel: ./src/valkey-cli -p $SENTINEL_PORT"