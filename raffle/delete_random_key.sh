#!/bin/bash

# Valkey Random Key Delete Script
# Usage: ./delete_random_key.sh <start_number> <end_number> [host] [port]

# Default values
VALKEY_HOST="${3:-localhost}"
VALKEY_PORT="${4:-6379}"

# Check if start and end numbers are provided
if [ $# -lt 2 ]; then
    echo "Usage: $0 <start_number> <end_number> [host] [port]"
    echo "Example: $0 1 100"
    echo "Example: $0 1 100 localhost 6379"
    exit 1
fi

START=$1
END=$2

# Validate inputs are numbers
if ! [[ "$START" =~ ^[0-9]+$ ]] || ! [[ "$END" =~ ^[0-9]+$ ]]; then
    echo "Error: Start and end must be positive integers"
    exit 1
fi

if [ "$START" -gt "$END" ]; then
    echo "Error: Start number must be less than or equal to end number"
    exit 1
fi

echo "Selecting random key from range $START to $END"
echo "Connecting to $VALKEY_HOST:$VALKEY_PORT"
echo "---"

# Try to find an existing key (max 10 attempts)
MAX_ATTEMPTS=10
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    # Generate random number in range
    RANDOM_NUM=$((START + RANDOM % (END - START + 1)))
    KEY="key:$RANDOM_NUM"
    
    # Check if key exists
    EXISTS=$(valkey-cli -h "$VALKEY_HOST" -p "$VALKEY_PORT" EXISTS "$KEY" 2>/dev/null)
    
    if [ "$EXISTS" = "1" ]; then
        # Get the value before deleting
        VALUE=$(valkey-cli -h "$VALKEY_HOST" -p "$VALKEY_PORT" GET "$KEY" 2>/dev/null)
        
        # Delete the key
        RESULT=$(valkey-cli -h "$VALKEY_HOST" -p "$VALKEY_PORT" DEL "$KEY" 2>/dev/null)
        
        if [ "$RESULT" = "1" ]; then
            echo "✓ Successfully deleted key: $KEY"
            echo "  Value was: $VALUE"
            exit 0
        else
            echo "✗ Failed to delete key: $KEY"
            exit 1
        fi
    fi
    
    ((ATTEMPT++))
done

echo "✗ Could not find an existing key after $MAX_ATTEMPTS attempts"
echo "  The key range may be empty or sparsely populated"
exit 1
