#!/bin/bash

# set -x

source ./config.sh

echo "=== Redis OSS Cluster ==="
echo "DBSIZE:"
valkey-cli --cluster call "${REDIS_HOST}:${REDIS_PORT}" DBSIZE

echo "INFO keyspace:"
valkey-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -c -${RESP_VERSION} INFO keyspace

echo ""
echo "=== Valkey Cluster ==="
echo "DBSIZE:"
valkey-cli --cluster call "${VALKEY_HOST}:${VALKEY_PORT}" DBSIZE

echo "INFO keyspace:"
valkey-cli -h ${VALKEY_HOST} -p ${VALKEY_PORT} -c -${RESP_VERSION} INFO keyspace