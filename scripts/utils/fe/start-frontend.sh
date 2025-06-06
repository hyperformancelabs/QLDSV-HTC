#!/bin/bash
set -e

# Source the root directory check and config loader
source scripts/utils/check-root-dir.sh
source scripts/utils/config-loader.sh

check_root_dir || exit 1

# Main script
echo "🚀 [start-frontend.sh] Starting QLDSV-HTC frontend..."

# Load environment variables
load_env_file

# Change to frontend directory
cd frontend

# Start the frontend development server
echo "🚀 Starting frontend development server..."
npm run dev

echo "✅ [start-frontend.sh] Frontend started!" 