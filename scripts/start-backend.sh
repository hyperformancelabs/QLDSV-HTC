#!/bin/bash
set -e

# Source the root directory check and config loader
source scripts/utils/check-root-dir.sh
source scripts/utils/config-loader.sh

check_root_dir || exit 1

# Load environment variables
load_env_file

# Parse arguments
RESET_DB=0
FULL_SETUP=0

for arg in "$@"; do
    case $arg in
        --reset-db)
            RESET_DB=1
            shift
            ;;
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
    echo "🔄 Running full default setup before starting backend..."
    ./scripts/setup/be/setup-backend.sh --default
fi

# Start the backend with or without reset-db flag
echo "🚀 Starting backend..."
if [ $RESET_DB -eq 1 ]; then
    ./scripts/utils/be/start-backend.sh --reset-db
else
./scripts/utils/be/start-backend.sh
fi

echo "✅ Backend started successfully!"
echo ""
echo "📊 Backend Information:"
echo "   - Host: $BACKEND_HOST"
echo "   - Port: $BACKEND_PORT"
echo "   - API URL: $BACKEND_API_URL"
echo ""
echo "🔍 API Documentation: $BACKEND_API_URL/docs" 