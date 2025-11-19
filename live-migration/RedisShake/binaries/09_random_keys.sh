#!/bin/bash

source ./config.sh

echo "🔍 Finding 10 random keys from Redis OSS cluster and checking them on Valkey cluster..."

for i in {1..3}; do
    echo "=== 🎰 Random Key $i ==="
    
    # Get random key from source
    RANDOM_KEY=$(valkey-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -c -${RESP_VERSION} RANDOMKEY)
    echo "🔑 Source key: $RANDOM_KEY"
    
    # Get value from source
    SOURCE_VALUE=$(valkey-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -c -${RESP_VERSION} GET "$RANDOM_KEY")
    echo "🗃️ Source value: $SOURCE_VALUE"
    
    # Try to get same key from target
    TARGET_VALUE=$(valkey-cli -h ${VALKEY_HOST} -p ${VALKEY_PORT} -c -${RESP_VERSION} GET "$RANDOM_KEY")
    echo "🎯 Target value: $TARGET_VALUE"
    
    # Compare values
    if [ "$SOURCE_VALUE" = "$TARGET_VALUE" ]; then
        echo "✅ Match"
    else
        echo "❌ Mismatch"
    fi
    echo ""
done