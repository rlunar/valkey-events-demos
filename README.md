# Valkey Booth Demo

A collection of demonstration scripts and tools for showcasing Valkey capabilities, including live migration, performance benchmarking, and various deployment configurations.

## Repository Structure

### 📦 `/live-migration`

Tools and scripts for demonstrating live migration scenarios.

#### `/live-migration/RIOT`
Complete demo for migrating from Redis OSS 7.2.4 to Valkey 9.0.0 using RIOT (Redis Input/Output Tool). Includes automated scripts for:
- Downloading and compiling Redis OSS and Valkey binaries
- Creating source and target clusters
- Populating test data (100K keys)
- Performing live replication with keyspace notifications
- Validating migration progress and data consistency

See `live-migration/RIOT/README.md` for detailed usage instructions.

#### `/live-migration/RedisShake`
Alternative migration approach using RedisShake tool (work in progress).

### 🚀 `/performance`

Performance benchmarking demonstrations for Valkey.

- `valkey_perf_demo.sh` - Automated performance testing script supporting:
  - Single instance mode with IO threading optimization
  - 3-node cluster mode (achieves 1M+ RPS)
  - Configurable benchmark cycles and parameters
  - Docker-based deployment with automatic setup

See `performance/valkey_perf_demo.md` for configuration options and usage examples.

### 🎲 `/raffle`

Utility scripts for interactive demonstrations:
- `populate_keys.sh` - Populate Valkey with sample keys for demos
- `delete_random_key.sh` - Randomly delete keys (useful for raffle-style demos)

### ⚙️ `/setup`

Configuration files and setup scripts for various Valkey deployment modes:

- `valkey-standalone.sh` - Launch standalone Valkey with master-replica setup
- `valkey-sentinel.sh` - Configure Valkey with Sentinel for high availability
- `valkey-cluster.sh` - Set up multi-node Valkey cluster
- Configuration files for each deployment mode
- Sample RDB dump files for testing

#### `/setup/cluster`
Additional cluster-specific configuration and setup files.

## Getting Started

1. Choose your demonstration scenario from the directories above
2. Navigate to the relevant directory
3. Follow the README or script comments for setup instructions
4. Most scripts are designed to run on macOS with ARM64 architecture

## Prerequisites

- macOS (most scripts optimized for ARM64)
- Docker and Docker Compose (for performance demos)
- Build tools (make, gcc) for compiling from source
- valkey-cli and valkey-benchmark utilities

## Common Use Cases

- **Live Migration Demo**: Use `/live-migration/RIOT` to show zero-downtime migration
- **Performance Benchmarking**: Use `/performance` to demonstrate Valkey's speed
- **Cluster Setup**: Use `/setup` scripts to quickly spin up different topologies
- **Interactive Demos**: Use `/raffle` scripts for audience participation
