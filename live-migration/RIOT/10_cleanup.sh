#!/bin/bash

set -x

source ./config.sh

# Stop and clean Redis OSS cluster
cd $VALKEY_LIVE_MIGRATION/redis-7.2.4/utils/create-cluster
./create-cluster stop
./create-cluster clean

# Stop and clean Valkey cluster
cd $VALKEY_LIVE_MIGRATION/valkey-9.0.0/utils/create-cluster
./create-cluster stop
./create-cluster clean

ps aux | grep redis-server
ps aux | grep valkey-server

echo "Cleanup completed."