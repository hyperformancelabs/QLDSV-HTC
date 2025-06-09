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

echo "🚀 Setting up frontend environment..."

# Load environment variables
load_env_file

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 16 or higher."
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm."
    exit 1
fi

# Change to frontend directory
cd frontend

# Install dependencies
echo "🔄 Installing frontend dependencies..."
npm install

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "🔄 Creating frontend .env file..."
    cat > .env << EOF
# API connection
VITE_API_URL=${VITE_API_URL:-http://localhost:8000}
VITE_API_BASE_URL=${VITE_API_BASE_URL:-http://localhost:8000/api/v1}

# Frontend configuration
VITE_APP_NAME=${VITE_APP_NAME:-QLDSV-HTC}
VITE_APP_VERSION=${VITE_APP_VERSION:-1.0.0}
VITE_HMR_PORT=${FRONTEND_PORT:-5173}
EOF
fi

# Create directories if they don't exist
mkdir -p src/assets
mkdir -p src/components/common
mkdir -p src/components/specific
mkdir -p src/hooks
mkdir -p src/layouts
mkdir -p src/pages
mkdir -p src/services
mkdir -p src/store
mkdir -p src/styles
mkdir -p src/types
mkdir -p src/utils

echo "✅ Frontend environment setup completed!" 