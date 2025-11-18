#!/bin/bash

source ./config.sh

echo "Cleaning up Redis OSS cluster..."
valkey-cli --cluster call "${REDIS_HOST}:${REDIS_PORT}" FLUSHALL --cluster-only-primaries

echo "Cleaning up Valkey cluster..."
valkey-cli --cluster call "${VALKEY_HOST}:${VALKEY_PORT}" FLUSHALL --cluster-only-primaries

echo "Checking Redis OSS cluster DBSIZE:"
valkey-cli --cluster call "${REDIS_HOST}:${REDIS_PORT}" DBSIZE

echo "Checking Valkey cluster DBSIZE:"
valkey-cli --cluster call "${VALKEY_HOST}:${VALKEY_PORT}" DBSIZE

echo "Both clusters cleaned up."