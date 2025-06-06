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
    echo "🔄 Running full default setup before starting frontend..."
    ./scripts/setup/fe/setup-frontend.sh --default
fi

# Start the frontend
echo "🚀 Starting frontend..."
./scripts/utils/fe/start-frontend.sh

echo "✅ Frontend started successfully!"
echo ""
echo "📊 Frontend Information:"
echo "   - Host: $FRONTEND_HOST"
echo "   - Port: $FRONTEND_PORT"
echo "   - URL: $FRONTEND_URL" 