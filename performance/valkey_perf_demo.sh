#!/bin/bash

# Valkey Performance Demo Script
# Creates a cluster and runs performance tests to achieve 1M+ RPS
# Based on: https://valkey.io/blog/testing-the-limits/

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALKEY_PASSWORD=$(head -16 /dev/urandom | openssl sha1 | cut -d' ' -f2)
VALKEY_SERVER_IP="${VALKEY_SERVER_IP:-localhost}"
IO_THREADS="${IO_THREADS:-2}"
BENCHMARK_CYCLES="${BENCHMARK_CYCLES:-1}"
REQUESTS_PER_CYCLE=10000000  # 10M requests per cycle
WAIT_BETWEEN_CYCLES=10       # 10 seconds

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check dependencies
check_dependencies() {
    log "Checking dependencies..."
    
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    if ! command -v valkey-benchmark &> /dev/null; then
        warning "valkey-benchmark not found. Installing valkey-tools..."
        if command -v apt &> /dev/null; then
            sudo apt update -qq && sudo apt install -y valkey-tools
        elif command -v yum &> /dev/null; then
            sudo yum install -y valkey
        else
            error "Unable to install valkey-tools automatically. Please install it manually."
            exit 1
        fi
    fi
    
    success "All dependencies are available"
}

# Create configuration files
create_config_files() {
    log "Creating configuration files..."
    
    # Create .env file
    cat > "$SCRIPT_DIR/.env" << EOF
VALKEY_PASSWORD=$VALKEY_PASSWORD
VALKEY_SERVER_IP=$VALKEY_SERVER_IP
IO_THREADS=$IO_THREADS
EOF

    # Create single instance docker-compose file
    cat > "$SCRIPT_DIR/valkey.yaml" << 'EOF'
services:
  valkey-1:
    image: valkey/valkey:latest
    hostname: valkey1
    command: valkey-server --port 6379 --requirepass ${VALKEY_PASSWORD} --io-threads ${IO_THREADS} --save ""
    volumes:
      - ./data:/data
    network_mode: host
    restart: unless-stopped

volumes:
  data:
    driver: local
EOF

    # Create cluster docker-compose file
    cat > "$SCRIPT_DIR/valkey-cluster.yaml" << 'EOF'
services:
  valkey-node-1:
    hostname: valkey1
    image: valkey/valkey:latest
    command: valkey-server --port 6379 --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout 5000 --requirepass ${VALKEY_PASSWORD} --save ""
    volumes:
      - ./data1:/data
    network_mode: host
    restart: unless-stopped

  valkey-node-2:
    hostname: valkey2
    image: valkey/valkey:latest
    command: valkey-server --port 6380 --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout 5000 --requirepass ${VALKEY_PASSWORD} --save ""
    volumes:
      - ./data2:/data
    network_mode: host
    restart: unless-stopped

  valkey-node-3:
    hostname: valkey3
    image: valkey/valkey:latest
    command: valkey-server --port 6381 --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout 5000 --requirepass ${VALKEY_PASSWORD} --save ""
    volumes:
      - ./data3:/data
    network_mode: host
    restart: unless-stopped

volumes:
  data1:
    driver: local
  data2:
    driver: local
  data3:
    driver: local
EOF

    success "Configuration files created"
}

# Clean up existing containers
cleanup() {
    log "Cleaning up existing containers..."
    
    docker-compose -f "$SCRIPT_DIR/valkey.yaml" down 2>/dev/null || true
    docker-compose -f "$SCRIPT_DIR/valkey-cluster.yaml" down 2>/dev/null || true
    
    # Remove data directories
    rm -rf "$SCRIPT_DIR/data" "$SCRIPT_DIR/data1" "$SCRIPT_DIR/data2" "$SCRIPT_DIR/data3" 2>/dev/null || true
    
    success "Cleanup completed"
}

# Start single Valkey instance
start_single_instance() {
    log "Starting single Valkey instance..."
    
    cd "$SCRIPT_DIR"
    docker-compose -f valkey.yaml up -d
    
    # Wait for service to be ready
    log "Waiting for Valkey to be ready..."
    for i in {1..30}; do
        if valkey-cli -h "$VALKEY_SERVER_IP" -p 6379 -a "$VALKEY_PASSWORD" ping 2>/dev/null | grep -q PONG; then
            success "Single Valkey instance is ready"
            return 0
        fi
        sleep 1
    done
    
    error "Single Valkey instance failed to start"
    exit 1
}

# Start Valkey cluster
start_cluster() {
    log "Starting Valkey cluster..."
    
    cd "$SCRIPT_DIR"
    docker-compose -f valkey-cluster.yaml up -d
    
    # Wait for all nodes to be ready
    log "Waiting for cluster nodes to be ready..."
    sleep 5
    
    # Get container name for cluster creation
    CONTAINER_NAME=$(docker ps --format '{{.Names}}' | grep valkey-node-1 | head -n1)
    
    if [ -z "$CONTAINER_NAME" ]; then
        error "Could not find valkey-node-1 container"
        exit 1
    fi
    
    # Create the cluster
    log "Creating Valkey cluster..."
    docker exec -it "$CONTAINER_NAME" valkey-cli --cluster create \
        "$VALKEY_SERVER_IP:6379" \
        "$VALKEY_SERVER_IP:6380" \
        "$VALKEY_SERVER_IP:6381" \
        -a "$VALKEY_PASSWORD" \
        --cluster-yes
    
    success "Valkey cluster is ready"
}

# Run single instance benchmark
benchmark_single() {
    log "Running benchmark on single instance..."
    
    echo "=========================================="
    echo "SINGLE INSTANCE BENCHMARK"
    echo "=========================================="
    
    valkey-benchmark \
        -n $REQUESTS_PER_CYCLE \
        -t set,get \
        -P 16 \
        -q \
        -a "$VALKEY_PASSWORD" \
        --threads 5 \
        -h "$VALKEY_SERVER_IP" \
        -p 6379
    
    echo "=========================================="
}

# Run cluster benchmark
benchmark_cluster() {
    log "Running benchmark on cluster..."
    
    echo "=========================================="
    echo "CLUSTER BENCHMARK"
    echo "=========================================="
    
    valkey-benchmark \
        -n $REQUESTS_PER_CYCLE \
        -t set,get \
        -P 16 \
        -q \
        --cluster \
        -a "$VALKEY_PASSWORD" \
        --threads 5 \
        -h "$VALKEY_SERVER_IP" \
        -p 6379
    
    echo "=========================================="
}

# Main performance demo function
run_performance_demo() {
    local mode=$1
    local cycles=$2
    
    log "Starting performance demo in $mode mode for $cycles cycles"
    log "Each cycle will run $REQUESTS_PER_CYCLE requests"
    log "Waiting $WAIT_BETWEEN_CYCLES seconds between cycles"
    
    for ((i=1; i<=cycles; i++)); do
        echo ""
        log "========== CYCLE $i/$cycles =========="
        
        if [ "$mode" = "single" ]; then
            benchmark_single
        elif [ "$mode" = "cluster" ]; then
            benchmark_cluster
        fi
        
        if [ $i -lt $cycles ]; then
            log "Waiting $WAIT_BETWEEN_CYCLES seconds before next cycle..."
            sleep $WAIT_BETWEEN_CYCLES
        fi
    done
    
    success "Performance demo completed!"
}

# Display system information
show_system_info() {
    log "System Information:"
    echo "  CPU cores: $(nproc)"
    echo "  Memory: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "  Valkey Password: $VALKEY_PASSWORD"
    echo "  Server IP: $VALKEY_SERVER_IP"
    echo "  IO Threads: $IO_THREADS"
    echo ""
}

# Usage information
usage() {
    echo "Usage: $0 [OPTIONS] MODE"
    echo ""
    echo "Modes:"
    echo "  single    - Run with single Valkey instance"
    echo "  cluster   - Run with 3-node Valkey cluster"
    echo "  both      - Run both single and cluster tests"
    echo ""
    echo "Options:"
    echo "  -c, --cycles NUM      Number of benchmark cycles (default: 1)"
    echo "  -i, --io-threads NUM  Number of IO threads (default: 2)"
    echo "  -s, --server IP       Valkey server IP (default: localhost)"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  VALKEY_SERVER_IP     Override server IP"
    echo "  IO_THREADS           Override IO threads"
    echo "  BENCHMARK_CYCLES     Override number of cycles"
    echo ""
    echo "Examples:"
    echo "  $0 cluster                    # Run cluster test once"
    echo "  $0 -c 5 single               # Run single instance test 5 times"
    echo "  $0 -c 3 -i 4 -s 192.168.1.100 both"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--cycles)
                BENCHMARK_CYCLES="$2"
                shift 2
                ;;
            -i|--io-threads)
                IO_THREADS="$2"
                shift 2
                ;;
            -s|--server)
                VALKEY_SERVER_IP="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            single|cluster|both)
                MODE="$1"
                shift
                ;;
            *)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    if [ -z "$MODE" ]; then
        error "Mode is required"
        usage
        exit 1
    fi
}

# Main function
main() {
    parse_args "$@"
    
    log "Starting Valkey Performance Demo"
    show_system_info
    
    check_dependencies
    create_config_files
    cleanup
    
    case $MODE in
        single)
            start_single_instance
            run_performance_demo "single" "$BENCHMARK_CYCLES"
            ;;
        cluster)
            start_cluster
            run_performance_demo "cluster" "$BENCHMARK_CYCLES"
            ;;
        both)
            log "Running single instance test first..."
            start_single_instance
            run_performance_demo "single" "$BENCHMARK_CYCLES"
            
            cleanup
            
            log "Now running cluster test..."
            start_cluster
            run_performance_demo "cluster" "$BENCHMARK_CYCLES"
            ;;
    esac
    
    log "Performance demo completed successfully!"
    log "To clean up, run: docker-compose -f valkey-cluster.yaml down && docker-compose -f valkey.yaml down"
}

# Trap for cleanup on exit
trap cleanup EXIT

# Run main function with all arguments
main "$@"