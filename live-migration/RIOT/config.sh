#!/bin/bash

export VALKEY_LIVE_MIGRATION=$(pwd)
export RESP_VERSION=3
export RESP_PROTOCOL="RESP3"

export REDIS_HOST=localhost
export REDIS_PORT=31001
export RIOT_SOURCE="redis://default:@${REDIS_HOST}:${REDIS_PORT}"

export VALKEY_HOST=localhost
export VALKEY_PORT=32001
export RIOT_TARGET="redis://default:@${VALKEY_HOST}:${VALKEY_PORT}"