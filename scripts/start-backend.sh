#!/bin/bash
set -e

# Source the root directory check and config loader
source scripts/utils/check-root-dir.sh
source scripts/utils/config-loader.sh

check_root_dir || exit 1

# Load environment variables
load_env_file

# Parse arguments
if [ "$1" == "--full-default-setup" ]; then
    echo "🔄 Running full default setup before starting backend..."
    ./scripts/setup/be/setup-backend.sh --default
fi

# Start the backend
echo "🚀 Starting backend..."
./scripts/utils/be/start-backend.sh

echo "✅ Backend started successfully!"
echo ""
echo "📊 Backend Information:"
echo "   - Host: $BACKEND_HOST"
echo "   - Port: $BACKEND_PORT"
echo "   - API URL: $BACKEND_API_URL"
echo ""
echo "🔍 API Documentation: $BACKEND_API_URL/docs" 