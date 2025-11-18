#!/bin/bash

# Valkey Key Population Script
# Usage: ./populate_keys.sh <start_number> <end_number> [host] [port]

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

echo "Populating Valkey with keys from $START to $END"
echo "Connecting to $VALKEY_HOST:$VALKEY_PORT"
echo "---"

# Counter for successful operations
SUCCESS_COUNT=0
TOTAL=$((END - START + 1))

# Populate keys
for i in $(seq $START $END); do
    # Use valkey-cli to set the key
    valkey-cli -h "$VALKEY_HOST" -p "$VALKEY_PORT" SET "key:$i" "$i" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        ((SUCCESS_COUNT++))
        # Show progress every 100 keys
        if [ $((SUCCESS_COUNT % 100)) -eq 0 ]; then
            echo "Progress: $SUCCESS_COUNT/$TOTAL keys created..."
        fi
    else
        echo "Warning: Failed to set key:$i"
    fi
done

echo "---"
echo "Complete! Successfully created $SUCCESS_COUNT out of $TOTAL keys"
echo "Key pattern: key:<number>"
echo "Value: <number>"