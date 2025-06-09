#!/bin/bash
set -e

# Source utilities
source scripts/utils/check-root-dir.sh
source scripts/utils/config-loader.sh

check_root_dir || exit 1

# Load environment variables
load_env_file

echo "🚀 Starting SQL Server database container..."

# Check if Docker is running
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed or not in PATH"
    exit 1
fi

# Create Docker network if it doesn't exist
if ! docker network inspect $DOCKER_NETWORK &> /dev/null; then
    echo "🔄 Creating Docker network: $DOCKER_NETWORK"
    docker network create $DOCKER_NETWORK
fi

# Check if container already exists
if docker ps -a | grep -q $DB_CONTAINER_NAME; then
    # Check if container is running
    if docker ps | grep -q $DB_CONTAINER_NAME; then
        echo "✅ SQL Server container is already running."
        exit 0
    else
        echo "🔄 Starting existing container: $DB_CONTAINER_NAME"
        docker start $DB_CONTAINER_NAME
    fi
else
    echo "🔄 Creating and starting SQL Server container..."
    
    # Check platform for Apple Silicon Macs
    if [[ "$(uname)" == "Darwin" && "$(uname -m)" == "arm64" ]]; then
        echo "🍎 Detected Apple Silicon Mac. Using platform: $PLATFORM"
        PLATFORM_FLAG="--platform $PLATFORM"
    else
        PLATFORM_FLAG=""
    fi
    
    # Run SQL Server container
    docker run -d \
        $PLATFORM_FLAG \
        --name $DB_CONTAINER_NAME \
        --network $DOCKER_NETWORK \
        -p $DB_PORT:1433 \
        -e "ACCEPT_EULA=Y" \
        -e "MSSQL_SA_PASSWORD=$MSSQL_SA_PASSWORD" \
        -e "MSSQL_PID=$MSSQL_PID" \
        -e "MSSQL_LCID=$MSSQL_LCID" \
        -e "MSSQL_COLLATION=$MSSQL_COLLATION" \
        mcr.microsoft.com/mssql/server:2022-latest
fi

echo "⏳ Waiting for SQL Server to start..."
sleep 5

# Check if SQL Server is up and running
for i in {1..10}; do
    if docker exec $DB_CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
        -S localhost \
        -U sa \
        -P "$MSSQL_SA_PASSWORD" \
        -C \
        -Q "SELECT @@VERSION" &> /dev/null; then
        
        echo "✅ SQL Server is now running."
        echo "   - Host: $DB_HOST"
        echo "   - Port: $DB_PORT"
        echo "   - SA Password: <hidden>"
        
        # You can run the health check script for more details
        echo ""
        echo "🔍 To check database status, run: ./scripts/utils/db/db-health-check.sh"
        exit 0
    fi
    
    echo "⏳ Waiting for SQL Server to be ready... ($i/10)"
    sleep 2
done

echo "❌ SQL Server failed to start properly."
exit 1 