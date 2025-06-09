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

for arg in "$@"; do
    case $arg in
        --full-default-setup)
            FULL_SETUP=1
            shift
            ;;
        *)
            # Unknown option
            ;;
    esac
done

# Run full setup if requested
if [ $FULL_SETUP -eq 1 ]; then
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