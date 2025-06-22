#!/bin/bash
set -e

# Source utilities
source scripts/utils/check-root-dir.sh
source scripts/utils/config-loader.sh

check_root_dir || exit 1

# Load environment variables
load_env_file

echo "🚀 Setting up database environment..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed or not in PATH"
    echo "   Please install Docker Desktop: https://www.docker.com/products/docker-desktop/"
    exit 1
fi

# Create Docker network if it doesn't exist
if ! docker network inspect $DOCKER_NETWORK &> /dev/null; then
    echo "🔄 Creating Docker network: $DOCKER_NETWORK"
    docker network create $DOCKER_NETWORK
fi

# Check for SQL Server image
if ! docker images | grep -q "mcr.microsoft.com/mssql/server"; then
    echo "🔄 Pulling SQL Server image..."
    docker pull mcr.microsoft.com/mssql/server:2022-latest
fi

# Check platform for Apple Silicon Macs
if [[ "$(uname)" == "Darwin" && "$(uname -m)" == "arm64" ]]; then
    echo "🍎 Detected Apple Silicon Mac."
    echo "   Verifying Docker settings for SQL Server compatibility..."
    
    # Check Docker version (needs 4.16+ for better ARM support)
    DOCKER_VERSION=$(docker version --format '{{.Server.Version}}' | cut -d. -f1,2)
    if (( $(echo "$DOCKER_VERSION < 4.16" | bc -l) )); then
        echo "⚠️  Your Docker version is $DOCKER_VERSION."
        echo "   For best performance on Apple Silicon, consider upgrading to Docker Desktop 4.16+"
    fi
    
    echo "✅ Platform setup complete for Apple Silicon Mac."
fi

# Create database directories
mkdir -p database/backups
mkdir -p database/health

# Check and update permissions
echo "🔄 Setting up database directory permissions..."
chmod +x scripts/utils/db/*.sh 2>/dev/null || true
chmod +x scripts/setup/db/install-odbc-driver.sh 2>/dev/null || true

echo "✅ Database setup complete!"
echo ""
echo "🚀 To start the database, run: ./scripts/start-database.sh" 