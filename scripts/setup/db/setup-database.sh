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

# Check if the ODBC driver installation script exists
if [ -f "scripts/setup/db/install-odbc-driver.sh" ]; then
    # Check if pyodbc can connect without errors
    echo "🔍 Checking if ODBC driver is properly installed..."
    
    # Check if pyodbc can be imported in the project's virtual environment
    PYODBC_CHECK="failed"
    
    # Try to import pyodbc from different locations
    if [ -f "backend/venv/bin/python" ]; then
        echo "🔍 Checking pyodbc in backend virtual environment..."
        if backend/venv/bin/python -c "import pyodbc; print('SUCCESS')" 2>/dev/null; then
            PYODBC_CHECK="backend_venv"
        fi
    elif [ -f "venv/bin/python" ]; then
        echo "🔍 Checking pyodbc in root virtual environment..."
        if venv/bin/python -c "import pyodbc; print('SUCCESS')" 2>/dev/null; then
            PYODBC_CHECK="root_venv"
        fi
    elif python3 -c "import pyodbc" 2>/dev/null; then
        echo "🔍 Checking pyodbc in system Python..."
        PYODBC_CHECK="system"
    fi
    
    if [ "$PYODBC_CHECK" != "failed" ]; then
        echo "✅ pyodbc found in $PYODBC_CHECK environment"
        # Skip connection test for now since database may not be running
        echo "📝 ODBC driver check will be performed after database startup"

            else
        echo "⚠️ pyodbc module not found in any Python environment."
        echo "   Installing pyodbc in backend virtual environment..."
        
        # Create backend venv if it doesn't exist
        if [ ! -f "backend/venv/bin/python" ]; then
            echo "🔄 Creating backend virtual environment..."
            cd backend
            python3 -m venv venv
            cd ..
        fi
        
        # Install pyodbc in backend venv
        backend/venv/bin/pip install pyodbc
        echo "✅ pyodbc installed in backend virtual environment"
    fi
    
    # Install ODBC driver if the script exists
    if [ -f "scripts/setup/db/install-odbc-driver.sh" ]; then
        echo "🔄 Installing/updating ODBC Driver..."
        ./scripts/setup/db/install-odbc-driver.sh --skip-test
    fi
else
    echo "⚠️ ODBC driver installation script not found."
    echo "   Manual driver installation may be required for direct database connections."
fi

echo "✅ Database setup complete!"
echo ""
echo "🚀 To start the database, run: ./scripts/start-database.sh" 