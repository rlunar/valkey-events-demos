# Valkey Migration Demo Script

This demo showcases migrating from a Redis OSS cluster to a Valkey cluster using two different methods:
- Cold Migration: Backup from Redis OSS and Restore to Valkey.
- Hot/Live Migration: Using redis-shake for a zero-downtime migration.

## Prerequisites
You'll need the following tools installed on your machine:
- Docker: To run the databases. (https://www.docker.com/get-started)
- redis-cli: To interact with the Redis cluster. (sudo apt install redis-tools or brew install redis)
- valkey-cli: To interact with the Valkey cluster. (Build from source or check for packages: https://github.com/valkey-io/valkey)
- redis-shake: For the live migration. (Download binaries from: https://github.com/alibaba/RedisShake/releases)

## Demo Flow

Run these scripts in order. Each script is set to print its commands (set -x) so the audience can follow along.

### Step 1: Create the Source Redis Cluster

Run the first script to create a 9-node (3 primary, 6 replica) Redis cluster.

```bash
01-create-redis-cluster.sh
```

What it does:
- Creates a dedicated Docker network.
- Starts 9 Redis 7.2 containers.
- Uses `redis-cli --cluster create` to form the cluster.
- Checks the cluster status.

### Step 2: Load Data and Back It Up

Run the second script to load sample data and create RDB backups.

```bash
02-load-and-backup-redis.sh
```

What it does:
- Uses `redis-cli -c` to add 1,000 sample keys to the cluster.
- Finds the three primary nodes.
- Triggers `BGSAVE` on each primary.
- Copies the `dump.rdb` files from the containers to a local ./redis-backup directory.

### Step 3: Create the Target Valkey Cluster (Topic 1)

This script creates our 9-node Valkey cluster, demonstrating the ease of creation.

```bash
03-create-valkey-cluster.sh
```

What it does:
- Starts 9 Valkey containers on the same Docker network.
- Uses `valkey-cli --cluster create` to form the cluster.
- Checks the cluster status. At this point, it's empty.

### Demo Path A: Cold Migration (Backup/Restore - Topic 2)

This path shows how to migrate by restoring from the Redis OSS backup.

```bash
04-restore-from-backup.sh
```

What it does:
- Stops the three Valkey primary nodes.
- Copies the corresponding `dump.rdb` files from `./redis-backup` into the stopped Valkey containers.
- Starts the Valkey primaries back up.
- Valkey reads the RDB file on boot.Checks the cluster and queries for a sample key to prove the data is there.

### Demo Path B: Live Migration (redis-shake - Topic 3)

This path shows a zero-downtime migration.

First, run the main script. It will clean the Valkey cluster (from the previous demo path) and start `redis-shake` in sync mode.

```bash
05-live-migration-redishake.sh
```

What it does:
- CRITICAL: Flushes all data from the Valkey cluster to provide a clean slate.
- Creates a `redis-shake.conf` file.
- Starts `redis-shake`. It will first do a full data sync and then stay connected, listening for new writes.
- The script will pause, waiting for you...

While redis-shake is running, open a NEW terminal window.

In the new terminal, run this command to add a new key to the source Redis cluster:

```bash
redis-cli -c -p 7000 SET live_key "This was migrated live!"
```

Now, in that same new terminal, check the target Valkey cluster:

```bash
valkey-cli -c -p 8000 GET live_key
```

You should see the key! This proves the live sync is working.Go back to the first terminal and press Ctrl+C to stop `redis-shake`.

### Step 4: Cleanup

Once you're all done, run the cleanup script to remove all containers and the Docker network.

```bash
06-cleanup.sh
```
