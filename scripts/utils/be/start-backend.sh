#!/bin/bash
set -e

# Source the root directory check and config loader
source scripts/utils/check-root-dir.sh
source scripts/utils/config-loader.sh

check_root_dir || exit 1

# Main script
echo "🚀 [start-backend.sh] Starting QLDSV-HTC backend..."

# Load environment variables
load_env_file

# Change to backend directory
cd backend

# Activate virtual environment
echo "🔄 Activating virtual environment..."
source venv/bin/activate

# Start the backend server
echo "🚀 Starting backend server with uvicorn..."
uvicorn app.main:app --host $BACKEND_HOST --port $BACKEND_PORT --reload

echo "✅ [start-backend.sh] Backend started!" 