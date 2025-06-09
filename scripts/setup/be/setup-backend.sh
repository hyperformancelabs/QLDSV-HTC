#!/bin/bash
set -e

# Source utilities
source scripts/utils/check-root-dir.sh
source scripts/utils/config-loader.sh

check_root_dir || exit 1

# Parse arguments
DEFAULT_MODE=0

for arg in "$@"; do
    case $arg in
        --default)
            DEFAULT_MODE=1
            shift
            ;;
        *)
            # Unknown option
            ;;
    esac
done

echo "🚀 Setting up backend environment..."

# Load environment variables
load_env_file

# Create backend directories if they don't exist
mkdir -p backend/logs
mkdir -p backend/app

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.8 or higher."
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "backend/venv" ]; then
    echo "🔄 Creating Python virtual environment..."
    
    # Use the appropriate command based on the OS
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        # Windows
        python -m venv backend/venv
    else
        # Linux/MacOS
        python3 -m venv backend/venv
    fi
fi

# Activate virtual environment
echo "🔄 Activating virtual environment..."

if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    # Windows
    source backend/venv/Scripts/activate
    else
    # Linux/MacOS
    source backend/venv/bin/activate
fi

# Install required packages
echo "🔄 Installing required Python packages..."
pip install --upgrade pip

# Check if requirements.txt exists in backend directory
if [ -f "backend/requirements.txt" ]; then
    pip install -r backend/requirements.txt
elif [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
else
    echo "⚠️ requirements.txt not found, installing basic packages..."
    pip install fastapi uvicorn pyodbc python-dotenv sqlalchemy
fi

# Install SQL Server ODBC driver if not already installed
echo "🔄 Checking for SQL Server ODBC driver..."

# Detect OS for driver installation
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    echo "⚠️ On macOS, you need to install the ODBC Driver manually."
    echo "Please visit: https://learn.microsoft.com/en-us/sql/connect/odbc/mac"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    echo "⚠️ On Linux, you need to install the ODBC Driver manually."
    echo "Please visit: https://learn.microsoft.com/en-us/sql/connect/odbc/linux"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    # Windows
    echo "⚠️ On Windows, you need to install the ODBC Driver manually."
    echo "Please visit: https://learn.microsoft.com/en-us/sql/connect/odbc/windows"
fi

# Create .env file if it doesn't exist
if [ ! -f "backend/.env" ]; then
    echo "🔄 Creating backend .env file..."
    cat > backend/.env << EOF
# Database connection
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-1434}
DB_NAME=${DB_NAME:-QLDSV_HTC}
MSSQL_APP_USER=${MSSQL_APP_USER:-app_user}
MSSQL_APP_PASSWORD=${MSSQL_APP_PASSWORD:-AppPassword123!}
MSSQL_SA_PASSWORD=${MSSQL_SA_PASSWORD:-YourStrongPassword123!}

# Backend configuration
BACKEND_HOST=${BACKEND_HOST:-0.0.0.0}
BACKEND_PORT=${BACKEND_PORT:-8000}
BACKEND_API_URL=${BACKEND_API_URL:-http://localhost:8000}

# Debug settings
FASTAPI_DEBUG=${FASTAPI_DEBUG:-true}
FASTAPI_RELOAD=${FASTAPI_RELOAD:-true}
LOG_LEVEL=${LOG_LEVEL:-DEBUG}
EOF
fi

# Deactivate virtual environment
deactivate

echo "✅ Backend environment setup completed!" 