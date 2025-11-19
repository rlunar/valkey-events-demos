#!/bin/bash

set -x

source ./config.sh

echo "=== Validating Redis OSS Cluster ==="
echo "PING:"
valkey-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -c -${RESP_VERSION} PING

echo "INFO server:"
valkey-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -c -${RESP_VERSION} INFO server

echo "CLUSTER INFO:"
valkey-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -c -${RESP_VERSION} CLUSTER INFO

echo "CLUSTER NODES:"
valkey-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -c -${RESP_VERSION} CLUSTER NODES

echo "SET key value:"
valkey-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -c -${RESP_VERSION} SET key value

echo "GET key:"
valkey-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -c -${RESP_VERSION} GET key

echo "DBSIZE:"
valkey-cli --cluster call "${REDIS_HOST}:${REDIS_PORT}" DBSIZE

echo "INFO keyspace:"
valkey-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -c -${RESP_VERSION} INFO keyspace

echo ""
echo "=== Validating Valkey Cluster ==="
echo "PING:"
valkey-cli -h ${VALKEY_HOST} -p ${VALKEY_PORT} -c -${RESP_VERSION} PING

echo "INFO server:"
valkey-cli -h ${VALKEY_HOST} -p ${VALKEY_PORT} -c -${RESP_VERSION} INFO server

echo "CLUSTER INFO:"
valkey-cli -h ${VALKEY_HOST} -p ${VALKEY_PORT} -c -${RESP_VERSION} CLUSTER INFO

echo "CLUSTER NODES:"
valkey-cli -h ${VALKEY_HOST} -p ${VALKEY_PORT} -c -${RESP_VERSION} CLUSTER NODES

echo "SET key value:"
valkey-cli -h ${VALKEY_HOST} -p ${VALKEY_PORT} -c -${RESP_VERSION} SET key value

echo "GET key:"
valkey-cli -h ${VALKEY_HOST} -p ${VALKEY_PORT} -c -${RESP_VERSION} GET key

echo "DBSIZE:"
valkey-cli --cluster call "${VALKEY_HOST}:${VALKEY_PORT}" DBSIZE

echo "INFO keyspace:"
valkey-cli -h ${VALKEY_HOST} -p ${VALKEY_PORT} -c -${RESP_VERSION} INFO keyspace

echo "Clusters validated successfully."