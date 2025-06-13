#!/bin/bash
set -e

# Source the root directory check and config loader
source scripts/utils/check-root-dir.sh
source scripts/utils/config-loader.sh

check_root_dir || exit 1

# Load environment variables
load_env_file

# Parse arguments
FULL_SETUP=0
RESET_DB=0

for arg in "$@"; do
    case $arg in
        --full-default-setup)
            FULL_SETUP=1
            shift
            ;;
        --reset-db)
            RESET_DB=1
            shift
            ;;
        *)
            # Unknown option
            ;;
    esac
done

# Reset database if requested
if [ $RESET_DB -eq 1 ]; then
    echo "🔄 Resetting database..."
    if [ -f "scripts/utils/db/delete-db.sh" ]; then
        ./scripts/utils/db/delete-db.sh --force
    else
        echo "⚠️ Database delete script not found. Cannot reset database."
        exit 1
    fi
fi

# Run full setup if requested
if [ $FULL_SETUP -eq 1 ]; then
    echo "🔄 Running full default setup before starting database..."
    if [ -f "scripts/setup/db/setup-database.sh" ]; then
        ./scripts/setup/db/setup-database.sh
    else
        echo "⚠️ Database setup script not found. Continuing with start..."
    fi
fi

# Install ODBC driver if full setup requested
if [ $FULL_SETUP -eq 1 ]; then
    if [ -f "scripts/setup/db/install-odbc-driver.sh" ]; then
        echo "🔌 Installing ODBC Driver for SQL Server..."
        ./scripts/setup/db/install-odbc-driver.sh --skip-test
    else
        echo "⚠️ ODBC Driver installation script not found. Skipping..."
    fi
fi

# Start the database
echo "🚀 Starting database..."
./scripts/utils/db/start-db.sh

# Check for ODBC driver after database is running  
if [ -f "scripts/setup/db/install-odbc-driver.sh" ]; then
    echo "🔍 Checking ODBC Driver configuration..."
    
    # Determine which Python environment to use
    PYTHON_CMD="python3"
    if [ -f "backend/venv/bin/python" ]; then
        PYTHON_CMD="backend/venv/bin/python"
        echo "🔍 Using backend virtual environment for ODBC test"
    elif [ -f "venv/bin/python" ]; then
        PYTHON_CMD="venv/bin/python"  
        echo "🔍 Using root virtual environment for ODBC test"
    fi
    
    # Try a simple connection test with Python
    ODBC_TEST=$($PYTHON_CMD -c "
import pyodbc
import os
try:
    # First check if driver is installed
    drivers = [x for x in pyodbc.drivers() if x.startswith('ODBC Driver')]
    if not drivers:
        print('DRIVER_MISSING')
        exit(0)
        
    # Then try connection
    conn_str = f\"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER=${DB_HOST},${DB_PORT};UID=sa;PWD=${MSSQL_SA_PASSWORD};TrustServerCertificate=yes;\"
    conn = pyodbc.connect(conn_str, timeout=5)
    conn.close()
    print('SUCCESS')
except ImportError:
    print('PYODBC_MISSING')
except Exception as e:
    if \"Can't open lib 'ODBC Driver 18 for SQL Server'\" in str(e):
        print('DRIVER_MISSING')
    else:
        print('CONNECTION_ERROR')
" 2>/dev/null) || echo "SCRIPT_ERROR"

    case $ODBC_TEST in
        "PYODBC_MISSING")
            echo "⚠️ pyodbc module not found. Consider installing it for direct database access."
            echo "   Run: pip install pyodbc"
            ;;
        "DRIVER_MISSING")
            echo "⚠️ ODBC Driver for SQL Server not detected."
            echo "   To install, run: ./scripts/setup/db/install-odbc-driver.sh"
            ;;
        "CONNECTION_ERROR")
            echo "⚠️ ODBC Driver installed but connection test failed."
            echo "   This may be due to network or authentication issues."
            ;;
        "SUCCESS")
            echo "✅ ODBC Driver properly installed and connection test successful!"
            ;;
        *)
            echo "⚠️ Unknown ODBC test result: $ODBC_TEST"
            ;;
    esac
fi

# Run health check
if [ -f "scripts/utils/db/db-health-check.sh" ]; then
    echo "🔍 Running database health check..."
    ./scripts/utils/db/db-health-check.sh
fi

echo "✅ Database started successfully!"
echo ""
echo "📊 Database Information:"
echo "   - Host: $DB_HOST"
echo "   - Port: $DB_PORT"
echo "   - Database: $DB_NAME"
echo ""
echo "🔍 To check database status, run: ./scripts/utils/db/db-health-check.sh"
echo "🔧 For full setup with ODBC, run: ./scripts/start-database.sh --full-default-setup"
echo "🔄 To reset database completely, run: ./scripts/start-database.sh --reset-db" 