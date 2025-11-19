# RedisShake Live Migration Demo (Binaries)

This demo shows live migration from Redis to Valkey using RedisShake binary (no Docker/Podman required).

## Prerequisites

- macOS with ARM64 architecture
- wget and tar utilities
- Make and GCC for compiling Redis/Valkey

## Quick Start

1. **Download and compile binaries:**
   ```bash
   ./01_download.sh
   ./02_compile.sh
   ```

2. **Create clusters:**
   ```bash
   ./03_create_clusters.sh
   ./04_validate_clusters.sh
   ```

3. **Populate source data:**
   ```bash
   ./06_populate_source.sh
   ```

4. **Run live migration:**
   ```bash
   ./07_live_migration.sh
   ```

5. **Verify migration:**
   ```bash
   ./08_check_dbsize.sh
   ./09_random_keys.sh
   ```

6. **Cleanup:**
   ```bash
   ./05_cleanup.sh
   ```

## Configuration

- Redis cluster: ports 31001-31006
- Valkey cluster: ports 32001-32006
- RedisShake binary: downloaded from GitHub releases

## Files

- `config.sh` - Environment configuration
- `redis-shake.toml` - RedisShake configuration (generated)
- All scripts are executable and follow the RIOT pattern