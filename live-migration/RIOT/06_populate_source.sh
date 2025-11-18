#!/bin/bash

set -x

source ./config.sh

echo "Populating Redis OSS cluster with 100K keys of 128 bytes..."
# valkey-benchmark --cluster -h ${REDIS_HOST} -p ${REDIS_PORT} -t set -n 10000 -d 128 -r 10000 --sequential --precision 2

cd $VALKEY_LIVE_MIGRATION/riot-standalone-4.0.4-osx-aarch64/
bin/riot generate \
    --batch=100 \
    --sleep=100 \
    --cluster \
    --count=100000 \
    --resp=${RESP_PROTOCOL} \
    --string-value=128 \
    --types=STRING \
    --uri ${RIOT_SOURCE} \
    --quiet

    # --expiration=3600 \
    # --keys=1:* \
    # --keyspace="gen" \