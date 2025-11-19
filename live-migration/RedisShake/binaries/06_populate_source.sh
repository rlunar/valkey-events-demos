#!/bin/bash

set -x

source ./config.sh

echo "Populating Redis OSS cluster with 100K keys of 128 bytes..."

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

echo "Redis OSS cluster populated:"

valkey-cli --cluster call "${REDIS_HOST}:${REDIS_PORT}" DBSIZE
