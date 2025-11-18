#!/bin/bash

set -x

source ./config.sh

# Update Redis OSS cluster config to use port 31000
cd $VALKEY_LIVE_MIGRATION/redis-7.2.4/utils/create-cluster
sed -i '' 's/PORT=30000/PORT=31000/' create-cluster
./create-cluster stop
./create-cluster clean
echo "Creating Redis OSS cluster on port 31000..."
./create-cluster start
./create-cluster create -f

# Update Valkey cluster config to use port 32000
cd $VALKEY_LIVE_MIGRATION/valkey-9.0.0/utils/create-cluster
sed -i '' 's/PORT=30000/PORT=32000/' create-cluster
./create-cluster stop
./create-cluster clean
echo "Creating Valkey cluster on port 32000..."
./create-cluster start
./create-cluster create -f

echo "Both clusters created successfully."