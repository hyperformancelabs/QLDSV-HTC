#!/bin/bash
set -e

# Source the root directory check and config loader
source scripts/utils/check-root-dir.sh
source scripts/utils/config-loader.sh

check_root_dir || exit 1

# Main script
echo "🚀 [start-db.sh] Starting QLDSV-HTC database container..."

# Load environment variables
load_env_file

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed or not in PATH"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "❌ Docker is not running"
    exit 1
fi

# Create network if it doesn't exist
if ! docker network inspect qldsv-network &>/dev/null; then
    echo "🌐 Creating Docker network: qldsv-network"
    docker network create --subnet=172.25.0.0/16 qldsv-network
fi

# Change to database directory
cd database

# Start database container
echo "🚀 Starting database container..."
docker-compose up -d --build

echo "✅ [start-db.sh] Database container started! You can check logs with: docker logs $DB_CONTAINER_NAME" 