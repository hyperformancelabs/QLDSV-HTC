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

# Create logs directory if it doesn't exist
mkdir -p frontend/logs

# Set log file path
LOG_FILE="frontend/logs/server.log"

# Run full setup if requested
if [ $FULL_SETUP -eq 1 ]; then
    echo "🔄 Running full default setup before starting frontend..." | tee -a "$LOG_FILE"
    ./scripts/setup/fe/setup-frontend.sh --default 2>&1 | tee -a "$LOG_FILE"
fi

# Start the frontend
echo "🚀 Starting frontend..." | tee -a "$LOG_FILE"
./scripts/utils/fe/start-frontend.sh 2>&1 | tee -a "$LOG_FILE"

echo "✅ Frontend started successfully!" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "📊 Frontend Information:" | tee -a "$LOG_FILE"
echo "   - Host: $FRONTEND_HOST" | tee -a "$LOG_FILE"
echo "   - Port: $FRONTEND_PORT" | tee -a "$LOG_FILE"
echo "   - URL: $FRONTEND_URL" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "📝 Server logs: $LOG_FILE" | tee -a "$LOG_FILE" 