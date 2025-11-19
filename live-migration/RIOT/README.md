# Redis OSS to Valkey Live Migration Demo

This demo shows how to perform a live migration from Redis OSS 7.2.4 to Valkey 9.0.0 using RIOT.

## Prerequisites

- macOS with ARM64 architecture
- wget and unzip utilities
- Make and build tools

## Quick Start

Run the following scripts in order:

### 1. Download Required Packages

```bash
./01_download.sh
```

Downloads Redis OSS 7.2.4, Valkey 9.0.0, and RIOT 4.0.4 if they don't already exist.

### 2. Compile Binaries

```bash
./02_compile.sh
```

Compiles Redis OSS and Valkey binaries with TLS support.

### 3. Create Clusters

```bash
./03_create_clusters.sh
```

Creates Redis OSS cluster on port 31000 and Valkey cluster on port 32000.

### 4. Validate Clusters

```bash
./04_validate_clusters.sh
```

Tests both clusters with PING, INFO, CLUSTER commands, and basic key operations.

### 5. Clean Up Clusters (Optional)

```bash
./05_cleanup.sh
```

Flushes all data from both clusters and verifies with DBSIZE.

### 6. Populate Source Cluster

```bash
./06_populate_source.sh
```

Generates 100K keys with 128-byte values in the Redis OSS cluster.

### 7. Start Live Migration

```bash
./07_live_migration.sh
```

Enables keyspace notifications and starts RIOT live replication. This runs continuously - use Ctrl+C to stop.

### 8. Check Migration Progress

In another terminal:

```bash
./08_check_dbsize.sh
```

Checks DBSIZE and keyspace info on both clusters.

## Demo Window Setup

For best demonstration experience, use 3 terminal windows:

**Window 1 (Main):** Run setup scripts (steps 1-6) and 
**Window 2 (Monitoring):** Run `./07_live_migration.sh.sh` to start live migration
**Window 3 (Monitoring):** Run `./08_check_dbsize.sh` periodically to monitor migration progress
**Window 4 (Validation):** Run `./09_random_keys.sh` to validate data consistency during migration

Optional 4th window for manual CLI exploration of both clusters.

### 9. Validate Random Keys

```bash
./09_random_keys.sh
```

Finds 10 random keys from source and verifies they exist on target.

## Configuration

All scripts use `config.sh` which sets:
- Redis OSS cluster: localhost:31001
- Valkey cluster: localhost:32001
- RESP3 protocol

## Manual Commands

Connect to Redis OSS cluster:
```bash
valkey-cli -h localhost -p 31001 -c -3
```

Connect to Valkey cluster:
```bash
valkey-cli -h localhost -p 32001 -c -3
```