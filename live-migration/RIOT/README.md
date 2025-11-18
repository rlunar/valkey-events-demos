# Redis OSS to Valkey Live migration

```bash
export VALKEY_LIVE_MIGRATION=$(pwd)
export RESP_VERSION=3
export RESP_PROTOCOL="RESP3"
```

### Install Redis OSS 7.2.4

```bash
echo $VALKEY_LIVE_MIGRATION
```

```bash
cd $VALKEY_LIVE_MIGRATION
wget https://github.com/redis/redis/archive/refs/tags/7.2.4.tar.gz
tar xvzf 7.2.4.tar.gz
cd $VALKEY_LIVE_MIGRATION/redis-7.2.4
make distclean
make BUILD_TLS=yes
```

### Create a Redis OSS Cluster

```bash
cd $VALKEY_LIVE_MIGRATION/redis-7.2.4/utils/create-cluster
./create-cluster start
./create-cluster create -f
```

```bash
export REDIS_HOST=localhost
export REDIS_PORT=31001
export RIOT_SOURCE="redis://default:@${REDIS_HOST}:${REDIS_PORT}"
```

```bash
valkey-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -c -${RESP_VERSION} PING
```

```bash
valkey-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -c -${RESP_VERSION} INFO server
```

```bash
valkey-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -c -${RESP_VERSION} CLUSTER INFO
```

```bash
valkey-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -c -${RESP_VERSION} CLUSTER NODES
```

```bash
valkey-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -c -${RESP_VERSION} SET key value
```

```bash
valkey-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -c -${RESP_VERSION} GET key
```

### Install RIOT

```bash
cd $VALKEY_LIVE_MIGRATION
wget https://github.com/redis/riot/releases/download/v4.0.4/riot-standalone-4.0.4-osx-aarch64.zip
unzip riot-standalone-4.0.4-osx-aarch64.zip
cd $VALKEY_LIVE_MIGRATION/riot-standalone-4.0.4-osx-aarch64/
```

### Generate 1 million keys

```bash
bin/riot generate \
    --cluster --count=1000000 \
    --string-value=512 --types=STRING \
    --uri ${RIOT_SOURCE}
```

```bash
valkey-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -c -${RESP_VERSION} GET gen:123456
```

```bash
valkey-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -c -${RESP_VERSION}
```

```bash
SCAN 0 MATCH * COUNT 10 TYPE string
```

### Install Valkey 9.0.0

```bash
cd $VALKEY_LIVE_MIGRATION
wget https://github.com/valkey-io/valkey/archive/refs/tags/9.0.0.tar.gz
tar xvzf 9.0.0.tar.gz
cd $VALKEY_LIVE_MIGRATION/valkey-9.0.0/
make distclean
make BUILD_TLS=yes
```

### Create a Valkey Cluster

```bash
cd $VALKEY_LIVE_MIGRATION/valkey-9.0.0/utils/create-cluster
./create-cluster start
./create-cluster create -f
```

```bash
export VALKEY_HOST=localhost
export VALKEY_PORT=32001
export RIOT_TARGET="redis://default:@${VALKEY_HOST}:${VALKEY_PORT}"
```

```bash
valkey-cli -h ${VALKEY_HOST} -p ${VALKEY_PORT} -c -${RESP_VERSION} PING
```

```bash
valkey-cli -h ${VALKEY_HOST} -p ${VALKEY_PORT} -c -${RESP_VERSION} INFO server
```

```bash
valkey-cli -h ${VALKEY_HOST} -p ${VALKEY_PORT} -c -${RESP_VERSION} CLUSTER INFO
```

```bash
valkey-cli -h ${VALKEY_HOST} -p ${VALKEY_PORT} -c -${RESP_VERSION} CLUSTER NODES
```

```bash
valkey-cli -h ${VALKEY_HOST} -p ${VALKEY_PORT} -c -${RESP_VERSION} SET key value
```

```bash
valkey-cli -h ${VALKEY_HOST} -p ${VALKEY_PORT} -c -${RESP_VERSION} GET key
```

## Live Migration

### Enable Keyspace Notifications on the Source

```bash
valkey-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -c -${RESP_VERSION} CONFIG SET notify-keyspace-events KEA
```

```bash
valkey-cli --cluster call "${REDIS_HOST}:${REDIS_PORT}" CONFIG SET notify-keyspace-events KEA
```

```bash
valkey-cli --cluster call "${REDIS_HOST}:${REDIS_PORT}" CONFIG GET notify-keyspace-events
```

Clean up Source Cluster

```bash
valkey-cli --cluster call "${REDIS_HOST}:${REDIS_PORT}" FLUSHALL --cluster-only-primaries
```

Clean up Target Cluster

```bash
valkey-cli --cluster call "${VALKEY_HOST}:${VALKEY_PORT}" FLUSHALL --cluster-only-primaries
```

Continously generate 1 million keys of 512 Bytes on the source

```bash
valkey-benchmark --cluster -h ${REDIS_HOST} -p ${REDIS_PORT} -t set -n 1000000 -d 512 -r 1000000 --sequential --precision 2 -l
```

Read the data and before the migration there will not be any data

```bash
valkey-benchmark --cluster -h ${VALKEY_HOST} -p ${VALKEY_PORT} -t get -n 1000000 -r 1000000 --sequential --precision 2 -l
```

### Extract ports and slots from the Redis OSS Source cluster

```bash
eval "$(redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} cluster nodes | grep master | sort -k9 | awk '{
  shard = NR
  port = $2
  gsub(/@.*/, "", port)
  gsub(/.*:/, "", port)
  slots = $9
  gsub(/-/, ":", slots)
  print "export SHARD" shard "_PORT=" port
  print "export SHARD" shard "_SLOTS=" slots
}')"
```

### Replicate data

```bash
cd $VALKEY_LIVE_MIGRATION/riot-standalone-4.0.4-osx-aarch64/
```

```bash
bin/riot replicate \
    --compare="NONE" \
    --idle-timeout=100 \
    --key-pattern="*" \
    --key-type="STRING" \
    --key-slots="0:16383" \
    --log-keys \
    --mem-limit="-1" \
    --mode="LIVE" \
    --read-from="ANY" \
    --source-cluster \
    --source-resp=${RESP_PROTOCOL} \
    --target-cluster \
    --target-resp=${RESP_PROTOCOL} \
    --quiet \
    ${RIOT_SOURCE} ${RIOT_TARGET}
```

#### Shard 1

```bash
export RIOT_SOURCE="redis://default:@${REDIS_HOST}:${SHARD1_PORT}"
```

```bash
bin/riot replicate \
    --compare="NONE" --idle-timeout=100 \
    --key-pattern="*" --key-type="STRING" \
    --key-slots="${SHARD1_SLOTS}" \
    --log-keys --mem-limit="-1" \
    --mode="LIVE" --read-from="ANY" \
    --source-cluster --source-resp=${RESP_PROTOCOL} \
    --target-cluster --target-resp=${RESP_PROTOCOL} \
    --quiet ${RIOT_SOURCE} ${RIOT_TARGET}
```

#### Shard 2

```bash
export RIOT_SOURCE="redis://default:@${REDIS_HOST}:${SHARD2_PORT}"
```

```bash
bin/riot replicate \
    --compare="NONE" --idle-timeout=100 \
    --key-pattern="*" --key-type="STRING" \
    --key-slots="${SHARD2_SLOTS}" \
    --log-keys --mem-limit="-1" \
    --mode="LIVE" --read-from="ANY" \
    --source-cluster --source-resp=${RESP_PROTOCOL} \
    --target-cluster --target-resp=${RESP_PROTOCOL} \
    --quiet ${RIOT_SOURCE} ${RIOT_TARGET}
```

#### Shard 3

```bash
export RIOT_SOURCE="redis://default:@${REDIS_HOST}:${SHARD3_PORT}"
```

```bash
bin/riot replicate \
    --compare="NONE" --idle-timeout=100 \
    --key-pattern="*" --key-type="STRING" \
    --key-slots="${SHARD3_SLOTS}" \
    --log-keys --mem-limit="-1" \
    --mode="LIVE" --read-from="ANY" \
    --source-cluster --source-resp=${RESP_PROTOCOL} \
    --target-cluster --target-resp=${RESP_PROTOCOL} \
    --quiet ${RIOT_SOURCE} ${RIOT_TARGET}
```

## Validate Migration

Check Source Cluster

```bash
valkey-cli --cluster call "${REDIS_HOST}:${REDIS_PORT}" DBSIZE
```

Check Target Cluster

```bash
valkey-cli --cluster call "${VALKEY_HOST}:${VALKEY_PORT}" DBSIZE
```

If I want to find all keys with specific pattern

On Redis OSS source

```bash
valkey-cli -c -3 -h ${REDIS_HOST} -p ${REDIS_PORT} --scan --pattern '*:12345*' --count 100
```

On Valkey target

```bash
valkey-cli -c -3 -h ${VALKEY_HOST} -p ${VALKEY_PORT} --scan --pattern '*:000000063475*' --count 10
```


```bash
valkey-cli -h ${VALKEY_HOST} -p ${VALKEY_PORT} -c -${RESP_VERSION} GET gen:123456
```
