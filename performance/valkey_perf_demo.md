# Valkey performance demo

## Key Features

**🚀 Performance Target**: Designed to achieve 1M+ RPS using the same techniques from the blog
- Single instance mode with optimized IO threading
- 3-node cluster mode for maximum performance
- Cycles through 10M requests with 10-second waits as requested

**📊 Benchmarking Modes**:
- `single`: Single Valkey instance with IO threading
- `cluster`: 3-node cluster (achieves 1M+ RPS like in the blog)
- `both`: Runs both tests sequentially

**⚙️ Configuration Options**:
- Customizable IO threads (defaults to 2, optimal for most systems)
- Configurable server IP and cycles
- Automatic password generation for security
- Based on exact docker-compose configs from the blog

## Usage Examples

```bash
# Basic cluster test (achieves 1M+ RPS)
./valkey_perf_demo.sh cluster

# Run 5 cycles with custom settings
./valkey_perf_demo.sh -c 5 -i 4 -s 192.168.1.100 cluster

# Test both single and cluster modes
./valkey_perf_demo.sh -c 3 both
```

## Script Highlights

1. **Automated Setup**: Creates all necessary docker-compose files and configurations
2. **Dependency Checking**: Automatically installs valkey-benchmark if needed  
3. **Cluster Creation**: Properly initializes the 3-node Valkey cluster
4. **Performance Monitoring**: Shows detailed benchmark results for each cycle
5. **Error Handling**: Robust error handling and cleanup procedures

The script follows the exact methodology from the blog post, including:
- Using the same docker-compose configurations with cluster-enabled nodes
- Implementing the cluster creation process with valkey-cli --cluster create  
- Using the same valkey-benchmark parameters that achieved "1,155,000 requests per second" in the blog
