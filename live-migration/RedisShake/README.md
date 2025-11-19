# RedisShake Migration Demos

RedisShake is a production-grade tool for migrating data between Redis/Valkey clusters. This directory contains two different deployment approaches for demonstrating migration from Redis OSS to Valkey.

## Available Approaches

### 📦 Native Binaries (`./binaries/`)

**Deployment**: Native macOS ARM64 binaries - no containers required

**Architecture**:
- Source: Redis OSS 7.2.4 cluster (6 nodes on ports 31001-31006)
- Target: Valkey 9.0.0 cluster (6 nodes on ports 32001-32006)
- Tool: RedisShake v4.4.1
- Data Generator: RIOT 4.0.4 (100K test keys)

**Migration Method**: Cluster-to-cluster sync using scan-based replication

**Best For**:
- Production-like demonstrations
- Technical audiences interested in binary deployment
- Scenarios where containers aren't available
- Performance testing with native execution

**Quick Start**:
```bash
cd binaries
./01_download.sh        # Download all components
./02_compile.sh         # Compile Redis and Valkey
./03_create_clusters.sh # Create both clusters
./06_populate_source.sh # Generate 100K test keys
./07_live_migration.sh  # Start migration
./09_check_dbsize.sh    # Verify migration
```

**Key Features**:
- Full automation from download to migration
- Comprehensive validation scripts
- Real-time monitoring capabilities
- Data consistency verification
- Clean separation of source and target

See `binaries/README.md` for detailed documentation.

---

### 🐳 Podman/Docker (`./podman/`)

**Deployment**: Container-based with Docker/Podman

**Architecture**:
- Source: Redis OSS 7.2 cluster (9 nodes - 3 primary + 6 replica)
- Target: Valkey cluster (9 nodes - 3 primary + 6 replica)
- Tool: RedisShake
- Data: 1K sample keys

**Migration Methods**: Demonstrates BOTH cold and hot migration

**Best For**:
- Complete migration story (cold + hot paths)
- Cross-platform demonstrations
- Interactive demos with live key insertion
- Comparing different migration strategies

**Quick Start**:
```bash
cd podman
./01-create-redis-cluster.sh   # Create source cluster
./02-load-and-backup-redis.sh  # Load data and backup
./03-create-valkey-cluster.sh  # Create target cluster

# Choose your migration path:
./04-restore-from-backup.sh        # Path A: Cold migration
# OR
./05-live-migration-redishake.sh   # Path B: Hot migration
```

**Key Features**:
- Demonstrates both cold (backup/restore) and hot (live sync) migration
- Interactive live key insertion during migration
- Larger cluster topology (9 nodes)
- Container isolation for clean demos
- Cross-platform compatibility

See `podman/README.md` for detailed documentation.

---

## Comparison

| Aspect | Native Binaries | Podman/Docker |
|--------|----------------|---------------|
| **Platform** | macOS ARM64 | Cross-platform |
| **Deployment** | Native processes | Containers |
| **Cluster Size** | 6 nodes (3+3) | 9 nodes (3+6) |
| **Test Data** | 100K keys | 1K keys |
| **Migration Types** | Hot only | Cold + Hot |
| **Setup Time** | ~5 minutes | ~3 minutes |
| **Resource Usage** | Lower | Higher |
| **Portability** | macOS only | Any platform |
| **Realism** | High (native) | High (isolated) |

## Migration Approaches Explained

### Hot Migration (Live Sync)
Both demos support hot migration using RedisShake:

1. **Keyspace Notifications**: Enables tracking of changes on source
2. **Full Scan**: RedisShake scans all existing keys
3. **Continuous Sync**: Monitors and replicates new changes
4. **Zero Downtime**: Source remains operational throughout

**Use Cases**:
- Production migrations
- Large datasets
- Cannot afford downtime
- Need to validate before cutover

### Cold Migration (Backup/Restore)
Only the Podman demo includes cold migration:

1. **Backup**: Create RDB snapshots from Redis primaries
2. **Transfer**: Copy RDB files to target
3. **Restore**: Valkey loads RDB files on startup
4. **Verify**: Check data integrity

**Use Cases**:
- Smaller datasets
- Maintenance windows available
- Simpler migration path
- One-time migrations

## Prerequisites

### Native Binaries
- macOS with ARM64 (Apple Silicon)
- Xcode Command Line Tools: `xcode-select --install`
- wget: `brew install wget`
- Build tools (make, gcc)
- ~500MB disk space

### Podman/Docker
- Docker or Podman installed
- redis-cli: `brew install redis` or `apt install redis-tools`
- valkey-cli: Build from source or use package
- redis-shake: Download from releases
- ~1GB disk space

## Common Operations

### Check Cluster Health
```bash
# Native binaries
valkey-cli -p 31001 CLUSTER INFO
valkey-cli -p 32001 CLUSTER INFO

# Podman
redis-cli -c -p 7000 CLUSTER INFO
valkey-cli -c -p 8000 CLUSTER INFO
```

### Monitor Migration Progress
```bash
# Native binaries
./09_check_dbsize.sh

# Podman
redis-cli -c -p 7000 DBSIZE
valkey-cli -c -p 8000 DBSIZE
```

### Validate Data
```bash
# Native binaries
./10_random_keys.sh

# Podman
redis-cli -c -p 7000 RANDOMKEY
valkey-cli -c -p 8000 GET <key>
```

## Choosing the Right Approach

**Use Native Binaries When**:
- Running on macOS ARM64
- Want production-like performance
- Need larger test datasets (100K keys)
- Prefer native execution
- Demonstrating to technical audiences

**Use Podman/Docker When**:
- Need cross-platform compatibility
- Want to show both cold and hot migration
- Prefer container isolation
- Need quick setup/teardown
- Demonstrating migration strategy comparison

## Troubleshooting

### Native Binaries

**Compilation fails**:
```bash
xcode-select --install
brew install wget
```

**Port conflicts**:
```bash
lsof -i :31001
# Kill conflicting processes or change ports in config.sh
```

**Migration not syncing**:
```bash
valkey-cli -p 31001 CONFIG GET notify-keyspace-events
# Should return: "KEA" or similar
```

### Podman/Docker

**Containers won't start**:
```bash
docker ps -a
docker logs <container_name>
```

**Network issues**:
```bash
docker network ls
docker network inspect <network_name>
```

**redis-shake not connecting**:
- Check redis-shake.toml configuration
- Verify cluster endpoints are accessible
- Ensure keyspace notifications are enabled

## Cleanup

### Native Binaries
```bash
cd binaries
./11_cleanup.sh
```
Stops all processes and removes cluster data directories.

### Podman/Docker
```bash
cd podman
./06-cleanup.sh
```
Removes all containers, networks, and backup files.

## Architecture Details

### Native Binaries Architecture
```
Redis OSS Cluster (31001-31006)
    ├── Primary: 31001, 31002, 31003
    └── Replica: 31004, 31005, 31006
                    ↓
              RedisShake v4.4.1
              (scan + sync)
                    ↓
Valkey Cluster (32001-32006)
    ├── Primary: 32001, 32002, 32003
    └── Replica: 32004, 32005, 32006
```

### Podman Architecture
```
Redis OSS Cluster (7000-7008)
    ├── Primary: 7000, 7001, 7002
    └── Replica: 7003-7008
                    ↓
              RedisShake
              (sync mode)
                    ↓
Valkey Cluster (8000-8008)
    ├── Primary: 8000, 8001, 8002
    └── Replica: 8003-8008
```

## Performance Considerations

### Native Binaries
- Direct system access = better performance
- No container overhead
- Suitable for performance benchmarking
- Can handle larger datasets efficiently

### Podman/Docker
- Container isolation = slight overhead
- Network bridge adds latency
- Better for functional testing
- Easier to reset and reproduce

## Additional Resources

- [RedisShake GitHub](https://github.com/tair-opensource/RedisShake)
- [RedisShake Documentation](https://tair-opensource.github.io/RedisShake/)
- [Valkey Documentation](https://valkey.io/)
- [Redis Cluster Specification](https://redis.io/docs/reference/cluster-spec/)
- [RIOT Documentation](https://github.com/redis/riot)

## Next Steps

After completing a migration demo:

1. **Validate Data**: Use random key sampling to verify consistency
2. **Performance Test**: Run benchmarks on both clusters
3. **Cutover Planning**: Discuss application switchover strategies
4. **Monitoring**: Show how to monitor migration progress
5. **Rollback**: Explain rollback procedures if needed
