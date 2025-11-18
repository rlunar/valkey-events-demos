#!/bin/bash

export VALKEY_LIVE_MIGRATION=$(pwd)

# Download Redis OSS 7.2.4 if not exists
if [ ! -f "7.2.4.tar.gz" ]; then
    echo "Downloading Redis OSS 7.2.4..."
    wget https://github.com/redis/redis/archive/refs/tags/7.2.4.tar.gz
fi

if [ ! -d "redis-7.2.4" ]; then
    echo "Extracting Redis OSS 7.2.4..."
    tar xvzf 7.2.4.tar.gz
fi

# Download Valkey 9.0.0 if not exists
if [ ! -f "9.0.0.tar.gz" ]; then
    echo "Downloading Valkey 9.0.0..."
    wget https://github.com/valkey-io/valkey/archive/refs/tags/9.0.0.tar.gz
fi

if [ ! -d "valkey-9.0.0" ]; then
    echo "Extracting Valkey 9.0.0..."
    tar xvzf 9.0.0.tar.gz
fi

# Download RIOT if not exists
if [ ! -f "riot-standalone-4.0.4-osx-aarch64.zip" ]; then
    echo "Downloading RIOT 4.0.4..."
    wget https://github.com/redis/riot/releases/download/v4.0.4/riot-standalone-4.0.4-osx-aarch64.zip
fi

if [ ! -d "riot-standalone-4.0.4-osx-aarch64" ]; then
    echo "Extracting RIOT 4.0.4..."
    unzip riot-standalone-4.0.4-osx-aarch64.zip
fi

echo "All packages downloaded and extracted."