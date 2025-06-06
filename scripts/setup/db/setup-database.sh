#!/bin/bash
set -e

# Source the root directory check and config loader
source scripts/utils/check-root-dir.sh
source scripts/utils/config-loader.sh

check_root_dir || exit 1

# Main script
echo "🛠️ [setup-database.sh] Setting up QLDSV-HTC database..."

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

# Platform-specific checks
if [[ "$(uname)" == "Darwin" && "$(uname -m)" == "arm64" ]]; then
    echo "🍎 Detected Apple Silicon Mac..."
    
    # Check Docker version for Apple Silicon compatibility
    DOCKER_VERSION=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "0.0.0")
    MIN_VERSION="4.16.0"
    
    if [[ "$(printf '%s\n' "$MIN_VERSION" "$DOCKER_VERSION" | sort -V | head -n1)" != "$MIN_VERSION" ]]; then
        echo "⚠️ Warning: Your Docker version ($DOCKER_VERSION) may be too old."
        echo "   For SQL Server on Apple Silicon, Docker 4.16.0 or later is recommended."
        echo "   Please consider updating Docker Desktop."
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Check if Rosetta 2 is installed
    if ! pgrep -q oahd; then
        echo "⚙️ Installing Rosetta 2 (required for SQL Server on Apple Silicon)..."
        softwareupdate --install-rosetta --agree-to-license
        
        if [ $? -ne 0 ]; then
            echo "❌ Failed to install Rosetta 2. Please install it manually with:"
            echo "   softwareupdate --install-rosetta --agree-to-license"
            exit 1
        fi
        
        echo "✅ Rosetta 2 installed successfully."
    else
        echo "✅ Rosetta 2 is already installed."
    fi
    
    echo "ℹ️ Make sure you have enabled the following in Docker Desktop:"
    echo "   1. Settings > General > 'Use Virtualization Framework'"
    echo "   2. Settings > Features in development > 'Use Rosetta for x86/amd64 emulation on Apple Silicon'"
    echo "   After changing these settings, restart Docker Desktop."
    
    read -p "Have you enabled these settings? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Please enable the settings and run this script again."
        exit 1
    fi
fi

# Create network if it doesn't exist
if ! docker network inspect qldsv-network &>/dev/null; then
    echo "🌐 Creating Docker network: qldsv-network"
    docker network create --subnet=172.25.0.0/16 qldsv-network
fi

# Start database container if not running
if [ ! "$(docker ps -q -f name=$DB_CONTAINER_NAME)" ]; then
    echo "🚀 Starting database container..."
    cd database
    docker-compose up -d --build
    
    echo "⏳ Waiting for database to be ready..."
    for i in {1..60}; do
        if [ "$(docker inspect --format='{{.State.Health.Status}}' $DB_CONTAINER_NAME 2>/dev/null)" == "healthy" ]; then
            echo "✅ SQL Server is now healthy and ready."
            break
        fi
        
        echo -n "."
        sleep 2
        
        if [ $i -eq 60 ]; then
            echo "❌ Timed out waiting for SQL Server to become healthy."
            echo "   Please check logs with: docker logs $DB_CONTAINER_NAME"
            exit 1
        fi
    done
    cd ..
else
    echo "✅ Database container is already running"
fi

# Execute SQL files in order
echo "📜 Executing SQL scripts..."

# Function to execute SQL files in a directory
execute_sql_files() {
    local dir=$1
    local description=$2
    
    echo "📂 Processing $description files from $dir..."
    
    # Find all SQL files starting with digits
    for file in $(find "database/$dir" -name "[0-9][0-9]-*.sql" | sort); do
        local filename=$(basename "$file")
        echo "📜 Executing: $filename"
        
        docker exec $DB_CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
            -S localhost \
            -U sa \
            -P "$MSSQL_SA_PASSWORD" \
            -C \
            -i "/var/scripts/$dir/$filename" \
            -v QLDSV_DB_NAME="$DB_NAME" \
            -v QLDSV_APP_USER="$MSSQL_APP_USER" \
            -v QLDSV_APP_PASSWORD="$MSSQL_APP_PASSWORD"
        
        if [ $? -eq 0 ]; then
            echo "✅ $filename completed"
        else
            echo "❌ $filename failed"
            return 1
        fi
    done
}

# Process foundation directory only (database creation and SA user setup)
execute_sql_files "01-foundation" "Foundation"

# Check database health
echo "🏥 Checking database health..."
./scripts/utils/db/db-health-check.sh

echo "✅ [setup-database.sh] Database setup completed successfully!"
echo "💡 Note: Only foundation scripts were executed. The database is ready for further configuration."
echo "💡 The SQL Server SA password is: $MSSQL_SA_PASSWORD"
echo "💡 Connect using:"
echo "   - Host: localhost"
echo "   - Port: $DB_PORT"
echo "   - Username: sa"
echo "   - Password: $MSSQL_SA_PASSWORD" 