#!/bin/bash

set -x

source ./config.sh

echo "Enabling keyspace notifications on Redis OSS cluster..."
valkey-cli --cluster call "${REDIS_HOST}:${REDIS_PORT}" CONFIG SET notify-keyspace-events KEA

echo "Verifying keyspace notifications configuration..."
valkey-cli --cluster call "${REDIS_HOST}:${REDIS_PORT}" CONFIG GET notify-keyspace-events

echo "Starting RIOT live migration..."
cd $VALKEY_LIVE_MIGRATION/riot-standalone-4.0.4-osx-aarch64/

bin/riot replicate \
    --compare="NONE" \
    --event-queue=10000 \
    --flush-interval=100 \
    --idle-timeout=20 \
    --key-pattern="*" \
    --key-type="STRING" \
    --key-slots="0:16383" \
    --log-keys \
    --mem-limit="-1" \
    --mode="LIVE" \
    --read-batch=100 \
    --read-from="ANY" \
    --source-cluster \
    --source-resp=${RESP_PROTOCOL} \
    --target-cluster \
    --target-resp=${RESP_PROTOCOL} \
    --quiet \
    ${RIOT_SOURCE} ${RIOT_TARGET}

    # --read-pool=8 \
    # --read-queue=100000 \
    # --read-threads=2 \
    # --scan-count=1000 \

    # --write-pool=8 \
    # --batch=100 \
    # --retry=LIMIT \
    # --retry-limit=10 \
    # --skip=NEVER \
    # --skip-limit=0 \
    # --sleep=100 \
    # --threads=8 \