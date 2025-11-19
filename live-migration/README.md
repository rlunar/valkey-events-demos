# Live Migration Demos

This directory contains demonstrations of migrating data from Redis OSS to Valkey using different tools and approaches. All demos showcase zero-downtime migration strategies suitable for production scenarios.

## Available Demos

### 🔧 RIOT - Redis Input/Output Tool

**Location**: `./RIOT/`

**Best For**: Simple, straightforward live migration with minimal setup

**Approach**: Uses RIOT's built-in replication capabilities with keyspace notifications to perform continuous sync from Redis OSS 7.2.4 to Valkey 9.0.0.

**Key Features**:
- Native binary execution (no containers)
- Automated cluster setup and validation
- 100K test keys for demonstration
- Real-time migration monitoring
- Data consistency validation

**Quick Start**:
```bash
cd RIOT
./01_download.sh    # Download and setup
./02_compile.sh     # Compile binaries
./03_create_clusters.sh
./06_populate_source.sh
./07_live_migration.sh
```

See `RIOT/README.md` for detailed instructions.

---

### 🔄 RedisShake - Advanced Migration Tool

**Location**: `./RedisShake/`

**Best For**: Production-grade migrations with more control and flexibility

RedisShake offers two deployment approaches:

#### Option 1: Native Binaries (`./RedisShake/binaries/`)

**Approach**: Runs entirely with native macOS ARM64 binaries - no Docker required

**Key Features**:
- Full cluster-to-cluster sync
- Scan-based replication
- 6-node clusters (3 primary + 3 replica)
- 100K test dataset via RIOT
- Comprehensive validation scripts

**Quick Start**:
```bash
cd RedisShake/binaries
./01_download.sh
./02_compile.sh
./03_create_clusters.sh
./06_populate_source.sh
./07_live_migration.sh
```

#### Option 2: Podman/Docker (`./RedisShake/podman/`)

**Approach**: Container-based deployment with 9-node clusters

**Key Features**:
- Demonstrates both cold and hot migration paths
- Cold migration: Backup/restore using RDB files
- Hot migration: Zero-downtime with redis-shake sync
- 9-node clusters (3 primary + 6 replica)
- Interactive demo with live key insertion

**Quick Start**:
```bash
cd RedisShake/podman
./01-create-redis-cluster.sh
./02-load-and-backup-redis.sh
./03-create-valkey-cluster.sh

# Choose your path:
./04-restore-from-backup.sh        # Cold migration
# OR
./05-live-migration-redishake.sh   # Hot migration
```

See `RedisShake/binaries/README.md` or `RedisShake/podman/README.md` for detailed instructions.

---

## Comparison Matrix

| Feature | RIOT | RedisShake (Binaries) | RedisShake (Podman) |
|---------|------|----------------------|---------------------|
| **Deployment** | Native binaries | Native binaries | Docker containers |
| **Cluster Size** | 6 nodes | 6 nodes | 9 nodes |
| **Test Data** | 100K keys | 100K keys | 1K keys |
| **Migration Type** | Live only | Live only | Cold + Live |
| **Setup Complexity** | Low | Medium | Medium |
| **Platform** | macOS ARM64 | macOS ARM64 | Cross-platform |
| **Best Use Case** | Quick demos | Production-like | Full demo flow |

## Prerequisites

### All Demos
- macOS (ARM64 recommended for binary demos)
- Command-line tools: `wget`, `tar`, `unzip`
- Build tools: `make`, `gcc` (Xcode Command Line Tools)

### Podman Demo Only
- Docker or Podman
- redis-cli and valkey-cli

## Migration Strategies Explained

### Live Migration (Hot)
- Source cluster remains operational during migration
- Uses keyspace notifications or replication streams
- Zero downtime for applications
- Suitable for production environments
- Demonstrated by: RIOT, RedisShake (both variants)

### Cold Migration (Backup/Restore)
- Source cluster is backed up using RDB files
- Target cluster is restored from backup
- Requires brief downtime
- Simpler but less flexible
- Demonstrated by: RedisShake (Podman only)

## Choosing the Right Demo

**For Quick Booth Demos**: Use RIOT
- Fastest setup
- Clear, simple workflow
- Easy to explain

**For Technical Deep Dives**: Use RedisShake (Binaries)
- Shows production-grade tooling
- More realistic cluster sizes
- Better for technical audiences

**For Complete Migration Story**: Use RedisShake (Podman)
- Shows both cold and hot paths
- Interactive live key insertion
- Good for comparing approaches

## Common Operations

### Check Cluster Status
```bash
# Redis OSS
valkey-cli -h localhost -p 31001 -c CLUSTER INFO

# Valkey
valkey-cli -h localhost -p 32001 -c CLUSTER INFO
```

### Monitor Migration Progress
```bash
# Check database sizes
valkey-cli -p 31001 DBSIZE  # Source
valkey-cli -p 32001 DBSIZE  # Target
```

### Validate Data Consistency
```bash
# Get random keys from source and verify on target
valkey-cli -p 31001 RANDOMKEY
valkey-cli -p 32001 GET <key>
```

## Troubleshooting

**Port conflicts**: Check if ports 31001-32006 are available
```bash
lsof -i :31001
```

**Compilation issues**: Install Xcode Command Line Tools
```bash
xcode-select --install
```

**Migration not syncing**: Verify keyspace notifications
```bash
valkey-cli -p 31001 CONFIG GET notify-keyspace-events
```

## Cleanup

Each demo includes cleanup scripts to stop clusters and remove temporary data:
- RIOT: `./10_cleanup.sh`
- RedisShake (Binaries): `./11_cleanup.sh`
- RedisShake (Podman): `./06-cleanup.sh`

## Additional Resources

- [RIOT Documentation](https://github.com/redis/riot)
- [RedisShake Documentation](https://github.com/tair-opensource/RedisShake)
- [Valkey Documentation](https://valkey.io/)
- [Redis Cluster Tutorial](https://redis.io/docs/management/scaling/)
