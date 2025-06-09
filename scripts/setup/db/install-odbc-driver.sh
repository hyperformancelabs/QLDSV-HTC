#!/bin/bash
set -e

# Source utilities
source scripts/utils/check-root-dir.sh
source scripts/utils/config-loader.sh

check_root_dir || exit 1

# Parse arguments
SKIP_TEST=0

for arg in "$@"; do
    case $arg in
        --skip-test)
            SKIP_TEST=1
            shift
            ;;
        *)
            ;;
    esac
done

echo "🚀 ODBC Driver 18 for SQL Server Installation Script"
echo "============================================="

# Load environment variables
echo "🔍 Loading environment variables from .env"
load_env_file

# Detect platform
echo "🔍 Detecting platform..."
PLATFORM=$(uname)
ARCH=$(uname -m)

if [[ "$PLATFORM" == "Darwin" ]]; then
    if [[ "$ARCH" == "arm64" ]]; then
        echo "✅ Detected Apple Silicon Mac (arm64)"
        DETECTED_PLATFORM="macos_arm64"
    else
        echo "✅ Detected Intel Mac (x86_64)"
        DETECTED_PLATFORM="macos_x86_64"
    fi
elif [[ "$PLATFORM" == "Linux" ]]; then
    echo "✅ Detected Linux ($ARCH)"
    DETECTED_PLATFORM="linux"
else
    echo "✅ Detected Windows or other platform"
    DETECTED_PLATFORM="other"
fi

# Check if ODBC Driver is already installed
echo "🔍 Checking if ODBC Driver is already installed..."

case $DETECTED_PLATFORM in
    "macos_arm64"|"macos_x86_64")
        # Check if installed via Homebrew
        if command -v brew &> /dev/null; then
            if brew list --formula | grep -q msodbcsql18; then
                echo "✅ ODBC Driver 18 is already installed via Homebrew"
                DRIVER_INSTALLED=true
            else
                echo "⚠️ ODBC Driver 18 not found via Homebrew"
                DRIVER_INSTALLED=false
            fi
        else
            echo "⚠️ Homebrew not found. Please install Homebrew first: https://brew.sh"
            DRIVER_INSTALLED=false
        fi
        ;;
    "linux")
        # Check if ODBC driver exists in common locations
        if [ -f "/opt/microsoft/msodbcsql18/lib64/libmsodbcsql-18.*.so.*" ] || \
           [ -f "/usr/lib/x86_64-linux-gnu/odbc/libmsodbcsql-18.*.so" ]; then
            echo "✅ ODBC Driver 18 is already installed"
            DRIVER_INSTALLED=true
        else
            echo "⚠️ ODBC Driver 18 not found"
            DRIVER_INSTALLED=false
        fi
        ;;
    *)
        echo "⚠️ Automatic ODBC driver installation not supported on this platform"
        echo "   Please install manually: https://docs.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server"
        exit 1
        ;;
esac

# Install ODBC driver if not already installed
if [ "$DRIVER_INSTALLED" = false ]; then
    case $DETECTED_PLATFORM in
        "macos_arm64"|"macos_x86_64")
            echo "🔄 Installing ODBC Driver 18 via Homebrew..."
            if ! command -v brew &> /dev/null; then
                echo "❌ Homebrew is required but not installed."
                echo "   Please install Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                exit 1
            fi
            
            # Add Microsoft tap if not already added
            echo "🔄 Adding Microsoft Homebrew tap..."
            brew tap microsoft/mssql-release https://github.com/Microsoft/homebrew-mssql-release || true
            
            # Install ODBC driver
            echo "🔄 Installing msodbcsql18..."
            HOMEBREW_NO_ENV_FILTERING=1 ACCEPT_EULA=Y brew install msodbcsql18 || {
                echo "❌ Failed to install ODBC driver via Homebrew"
                exit 1
            }
            
            # Install unixODBC if not present
            echo "🔄 Installing unixODBC..."
            brew install unixodbc || true
            
            echo "✅ ODBC Driver 18 installed successfully via Homebrew"
            ;;
        "linux")
            echo "🔄 Installing ODBC Driver 18 on Linux..."
            # This is a simplified version - full Linux support would need distribution detection
            echo "⚠️ Please install ODBC Driver 18 manually on Linux:"
            echo "   https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server"
            exit 1
            ;;
    esac
fi

# Configure ODBC
echo "🔧 Configuring ODBC..."

case $DETECTED_PLATFORM in
    "macos_arm64"|"macos_x86_64")
        # Find driver path
        if [ -f "/opt/homebrew/opt/msodbcsql18/lib/libmsodbcsql.18.dylib" ]; then
            DRIVER_PATH="/opt/homebrew/opt/msodbcsql18/lib/libmsodbcsql.18.dylib"
        elif [ -f "/usr/local/opt/msodbcsql18/lib/libmsodbcsql.18.dylib" ]; then
            DRIVER_PATH="/usr/local/opt/msodbcsql18/lib/libmsodbcsql.18.dylib"
        else
            echo "❌ Could not find ODBC driver library"
            exit 1
        fi
        
        echo "🔍 Driver path: $DRIVER_PATH"
        
        # Create ODBC configuration files
        echo "📝 Creating odbcinst.ini..."
        cat > ~/.odbcinst.ini << EOF
[ODBC Driver 18 for SQL Server]
Description=Microsoft ODBC Driver 18 for SQL Server
Driver=$DRIVER_PATH
Threading=1
UsageCount=1
EOF

        echo "📝 Creating odbc.ini..."
        cat > ~/.odbc.ini << EOF
[ODBC Data Sources]
QLDSV_HTC = ODBC Driver 18 for SQL Server

[QLDSV_HTC]
Driver = ODBC Driver 18 for SQL Server
Description = QLDSV-HTC Database
Server = $DB_HOST,$DB_PORT
Database = $DB_NAME
TrustServerCertificate = yes
EOF

        echo "✅ ODBC configuration completed!"
        ;;
esac

# Skip connection test if requested
if [ $SKIP_TEST -eq 1 ]; then
    echo "⏭️ Skipping connection test as requested"
    echo "✅ ODBC Driver installation completed!"
    exit 0
fi

# Test ODBC connection
echo "🔍 Testing ODBC connection..."

# Install pyodbc Python package
echo "📦 Installing pyodbc Python package..."

# Determine which Python environment to use
if [ -f "backend/venv/bin/python" ]; then
    echo "🔍 Installing pyodbc in backend virtual environment"
    backend/venv/bin/pip install pyodbc
    PYTHON_CMD="backend/venv/bin/python"
elif [ -f "venv/bin/python" ]; then
    echo "🔍 Installing pyodbc in root virtual environment"
    venv/bin/pip install pyodbc
    PYTHON_CMD="venv/bin/python"
else
    echo "🔍 Installing pyodbc in system Python"
    pip3 install pyodbc
    PYTHON_CMD="python3"
fi

# Test connection
echo "🧪 Running connection test with Python..."

CONNECTION_TEST=$($PYTHON_CMD -c "
import pyodbc
import sys

try:
    # List available drivers
    drivers = pyodbc.drivers()
    print('Available ODBC drivers:')
    for driver in drivers:
        if 'SQL Server' in driver:
            print(f'  - {driver}')
    
    # Check if our driver is available
    target_driver = 'ODBC Driver 18 for SQL Server'
    if target_driver in drivers:
        print(f'✅ Found target driver: {target_driver}')
    else:
        print(f'❌ Target driver not found: {target_driver}')
        sys.exit(1)
    
    print('✅ ODBC Driver test completed successfully!')
    
except ImportError as e:
    print(f'❌ Failed to import pyodbc: {e}')
    sys.exit(1)
except Exception as e:
    print(f'❌ ODBC test failed: {e}')
    sys.exit(1)
" 2>&1) || {
    echo "❌ Connection test failed"
    echo "$CONNECTION_TEST"
    exit 1
}

echo "$CONNECTION_TEST"
echo ""
echo "🎉 ODBC Driver 18 for SQL Server is properly installed and configured!"
echo ""
echo "📋 Next steps:"
echo "   1. Start the database: ./scripts/start-database.sh"
echo "   2. Test backend connection: ./scripts/start-backend.sh"
echo ""
echo "🔍 To test the full connection manually:"
echo "   python3 -c \"import pyodbc; print([d for d in pyodbc.drivers() if 'SQL Server' in d])\"" 