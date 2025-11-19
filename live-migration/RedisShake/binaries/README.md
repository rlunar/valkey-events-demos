# RedisShake Live Migration Demo

This project demonstrates live data migration from Redis OSS 7.2.4 to Valkey 9.0.0 using RedisShake v4.4.1. The demo runs entirely with native binaries on macOS ARM64 - no Docker or containers required.

## What This Demo Does

The demo sets up two separate clusters and migrates data between them:

- **Source**: Redis OSS 7.2.4 cluster (6 nodes on ports 31001-31006)
- **Target**: Valkey 9.0.0 cluster (6 nodes on ports 32001-32006)
- **Migration Tool**: RedisShake v4.4.1 (cluster-to-cluster sync)
- **Data Generator**: RIOT 4.0.4 (generates 100K test keys)

RedisShake performs a full scan of the Redis cluster and replicates all keys to the Valkey cluster, enabling zero-downtime migration.

## Prerequisites

- macOS with ARM64 (Apple Silicon) architecture
- Command-line tools: `wget`, `tar`, `unzip`
- Build tools: `make`, `gcc` (Xcode Command Line Tools)
- Disk space: ~500MB for source code and binaries

## Quick Start

Run the scripts in order:

```bash
# 1. Download all required binaries and source code
./01_download.sh

# 2. Compile Redis and Valkey from source
./02_compile.sh

# 3. Create both Redis and Valkey clusters
./03_create_clusters.sh

# 4. Validate cluster health (optional)
./04_validate_clusters.sh

# 5. Flush databases to start fresh (optional)
./05_flushdbs.sh

# 6. Populate Redis cluster with 100K test keys
./06_populate_source.sh

# 7. Run live migration from Redis to Valkey
./07_live_migration.sh

# 8. Update source with additional data (optional - tests live sync)
./08_update_soure.sh

# 9. Check database sizes on both clusters
./09_check_dbsize.sh

# 10. Sample random keys from both clusters
./10_random_keys.sh

# 11. Stop clusters and cleanup
./11_cleanup.sh
```

## How Live Migration Works

1. **Keyspace Notifications**: Enables `notify-keyspace-events KEA` on Redis to track changes
2. **Configuration**: Generates `redis-shake.toml` with cluster endpoints
3. **Scan Mode**: RedisShake scans all keys from Redis cluster using `SCAN` command
4. **Replication**: Writes all keys to Valkey cluster maintaining data integrity
5. **Verification**: Compares `DBSIZE` between source and target clusters

The migration is non-destructive - source data remains intact.

## Project Structure

```
.
├── config.sh                    # Environment variables and cluster configuration
├── 01_download.sh              # Downloads Redis, Valkey, RedisShake, RIOT
├── 02_compile.sh               # Compiles Redis and Valkey with TLS support
├── 03_create_clusters.sh       # Creates 6-node clusters for both systems
├── 04_validate_clusters.sh     # Validates cluster health
├── 05_flushdbs.sh              # Flushes all databases
├── 06_populate_source.sh       # Generates 100K keys using RIOT
├── 07_live_migration.sh        # Runs RedisShake migration
├── 08_update_soure.sh          # Adds more data to test live sync
├── 09_check_dbsize.sh          # Compares database sizes
├── 10_random_keys.sh           # Samples random keys from both clusters
├── 11_cleanup.sh               # Stops clusters and cleans up
└── redis-shake.toml            # Generated RedisShake configuration
```

## Configuration Details

All configuration is centralized in `config.sh`:

- **Redis Cluster**: `localhost:31001-31006`
- **Valkey Cluster**: `localhost:32001-32006`
- **RESP Protocol**: RESP3
- **Test Data**: 100K STRING keys, 128 bytes each

## Troubleshooting

**Clusters won't start**: Check if ports 31001-31006 or 32001-32006 are already in use
```bash
lsof -i :31001
```

**Compilation fails**: Ensure Xcode Command Line Tools are installed
```bash
xcode-select --install
```

**Migration incomplete**: Verify keyspace notifications are enabled
```bash
valkey-cli -p 31001 CONFIG GET notify-keyspace-events
```

**Permission denied**: Make scripts executable
```bash
chmod +x *.sh
```

## Cleanup

To stop all clusters and remove temporary data:

```bash
./11_cleanup.sh
```

This stops all Redis and Valkey processes and removes cluster data directories.

## References

- [RedisShake Documentation](https://github.com/tair-opensource/RedisShake)
- [Valkey Documentation](https://valkey.io/)
- [Redis Cluster Tutorial](https://redis.io/docs/management/scaling/)
- [RIOT - Redis Input/Output Tools](https://github.com/redis/riot)