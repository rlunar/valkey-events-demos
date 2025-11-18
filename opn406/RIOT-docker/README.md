# Redis OSS to Valkey Live migration

```bash
export OPN406_DIR=$(pwd)
export RESP_VERSION=3
export RESP_PROTOCOL="RESP3"
```

```bash
podman pull valkey/valkey:7-alpine
```

```bash
podman run valkey/valkey:7-alpine valkey-cli --help
```

```bash
export RESP_VERSION=3
export REDIS_HOST=host.docker.internal
export REDIS_PORT=30001
export RIOT_SOURCE="redis://default:@${REDIS_HOST}:${REDIS_PORT}"
```

## Docker

```bash
podman run --network host valkey/valkey:7-alpine valkey-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -c -${RESP_VERSION} PING
```

```bash
podman run --network host valkey/valkey:7-alpine valkey-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -c -${RESP_VERSION} CLUSTER INFO
```

```bash
podman run --network host valkey/valkey:7-alpine valkey-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -c -${RESP_VERSION} CLUSTER NODES
```

```bash
podman run --network host -it --rm valkey/valkey:7-alpine valkey-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -c -${RESP_VERSION}
```

```bash
podman pull riotx/riot:v4.0.4
```

```bash
podman run --network host -it --rm \
    riotx/riot:v4.0.4 generate \
    --cluster --count=1000000 \
    --string-value=512 --types=STRING \
    --uri ${RIOT_SOURCE}
```

```bash
podman run --network host -it --rm \
    valkey/valkey:7-alpine valkey-cli \
    -h ${REDIS_HOST} \
    -p ${REDIS_PORT} \
    -${RESP_VERSION} -c
```

------------------------------------------------------------------------------------------------------------

## Local

------------------------------------------------------------------------------------------------------------

### Install Redis OSS 7.2.4

```bash
echo $OPN406_DIR
```

```bash
cd $OPN406_DIR
wget https://github.com/redis/redis/archive/refs/tags/7.2.4.tar.gz
tar xvzf 7.2.4.tar.gz
cd $OPN406_DIR/redis-7.2.4
make distclean
make BUILD_TLS=yes
```

### Create a Redis OSS Cluster

```bash
cd $OPN406_DIR/redis-7.2.4/utils/create-cluster
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
cd $OPN406_DIR
wget https://github.com/redis/riot/releases/download/v4.0.4/riot-standalone-4.0.4-osx-aarch64.zip
unzip riot-standalone-4.0.4-osx-aarch64.zip
cd $OPN406_DIR/riot-standalone-4.0.4-osx-aarch64/
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
cd $OPN406_DIR
wget https://github.com/valkey-io/valkey/archive/refs/tags/9.0.0.tar.gz
tar xvzf 9.0.0.tar.gz
cd $OPN406_DIR/valkey-9.0.0/
make distclean
make BUILD_TLS=yes
```

### Create a Redis OSS Cluster

```bash
cd $OPN406_DIR/valkey-9.0.0/utils/create-cluster
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

```bash
cd $OPN406_DIR/riot-standalone-4.0.4-osx-aarch64/
```

### Enable Keyspace Notifications on the Source

```bash
valkey-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -c -${RESP_VERSION} CONFIG SET notify-keyspace-events KEA
```

### Generate 1 million keys

```bash
bin/riot replicate \
    --compare="NONE" \
    --idle-timeout=10 \
    --key-pattern="*" \
    --key-type="STRING" \
    --key-slots="0:16383" \
    --log-keys \
    --mem-limit="-1" \
    --mode="LIVE" \
    --read-from="ANY" \
    --source-resp=${RESP_PROTOCOL} \
    --target-cluster \
    --target-resp=${RESP_PROTOCOL} \
    --quiet \
    ${RIOT_SOURCE} ${RIOT_TARGET}
```