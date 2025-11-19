#!/bin/bash

set -x

export VALKEY_LIVE_MIGRATION=$(pwd)

# Compile Redis OSS 7.2.4
if [ ! -f "redis-7.2.4/src/redis-server" ]; then
    echo "Compiling Redis OSS 7.2.4..."
    cd $VALKEY_LIVE_MIGRATION/redis-7.2.4
    make distclean
    make BUILD_TLS=yes
    cd $VALKEY_LIVE_MIGRATION
else
    echo "Redis OSS 7.2.4 already compiled."
fi

# Compile Valkey 9.0.0
if [ ! -f "valkey-9.0.0/src/valkey-server" ]; then
    echo "Compiling Valkey 9.0.0..."
    cd $VALKEY_LIVE_MIGRATION/valkey-9.0.0
    make distclean
    make BUILD_TLS=yes
    cd $VALKEY_LIVE_MIGRATION
else
    echo "Valkey 9.0.0 already compiled."
fi

# Make RedisShake executable
if [ -f "redis-shake-v4.4.1-darwin-arm64/redis-shake" ]; then
    chmod +x redis-shake-v4.4.1-darwin-arm64/redis-shake
    echo "RedisShake binary is ready."
else
    echo "RedisShake binary not found!"
    exit 1
fi

echo "All binaries compiled and ready."