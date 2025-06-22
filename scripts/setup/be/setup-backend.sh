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
backend/venv/bin/pip install --upgrade pip

# Check if requirements.txt exists in backend directory
if [ -f "backend/requirements.txt" ]; then
    backend/venv/bin/pip install -r backend/requirements.txt
elif [ -f "requirements.txt" ]; then
    backend/venv/bin/pip install -r requirements.txt
else
    echo "⚠️ requirements.txt not found, installing basic packages..."
    backend/venv/bin/pip install fastapi uvicorn pyodbc python-dotenv sqlalchemy
fi

# Install SQL Server ODBC driver if not already installed
echo "🔄 Checking for SQL Server ODBC driver..."

# Use backend virtual env to detect driver via pyodbc
driver_check=1
if backend/venv/bin/python - << 'PY'
import sys, pyodbc
sys.exit(0 if any('ODBC Driver 18' in d or 'ODBC Driver 17' in d for d in pyodbc.drivers()) else 1)
PY
then
    echo "✅ Detected ODBC Driver for SQL Server (17/18) already installed."
    driver_check=0
else
    echo "⚠️ ODBC Driver for SQL Server not detected on this system."
fi

# Provide platform-specific guidance only when driver missing
if [ $driver_check -ne 0 ]; then
if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "💡 On macOS, install via Homebrew:"
        echo "   brew tap microsoft/mssql-release && ACCEPT_EULA=Y brew install msodbcsql18 unixodbc"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "💡 On Linux, follow Microsoft docs: https://learn.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        echo "💡 On Windows, download the installer: https://learn.microsoft.com/en-us/sql/connect/odbc/windows/microsoft-odbc-driver-for-sql-server"
    fi
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

# After installing python packages

# ---- ODBC Driver check/install ----
if backend/venv/bin/python - << 'PYCODE' 2>/dev/null | grep -q YES
import pyodbc, sys
print('YES' if any('ODBC Driver 17' in d or 'ODBC Driver 18' in d for d in pyodbc.drivers()) else 'NO')
PYCODE
then
    echo "✅ ODBC driver detected"
else
    echo "🔄 ODBC driver not detected – running installer..."
    scripts/setup/db/install-odbc-driver.sh --skip-test || true
fi

# Deactivate virtual environment
deactivate

echo "✅ Backend environment setup completed!" 