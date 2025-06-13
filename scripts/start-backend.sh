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

# Create logs directory if it doesn't exist
mkdir -p backend/logs

# Set log file path
LOG_FILE="backend/logs/server.log"

# Run full setup if requested
if [ $FULL_SETUP -eq 1 ]; then
    echo "🔄 Running full default setup before starting backend..." | tee -a "$LOG_FILE"
    ./scripts/setup/be/setup-backend.sh --default 2>&1 | tee -a "$LOG_FILE"
fi

# Start the backend with or without reset-db flag
echo "🚀 Starting backend..." | tee -a "$LOG_FILE"
if [ $RESET_DB -eq 1 ]; then
    ./scripts/utils/be/start-backend.sh --reset-db 2>&1 | tee -a "$LOG_FILE"
else
    ./scripts/utils/be/start-backend.sh 2>&1 | tee -a "$LOG_FILE"
fi

echo "✅ Backend started successfully!" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "📊 Backend Information:" | tee -a "$LOG_FILE"
echo "   - Host: $BACKEND_HOST" | tee -a "$LOG_FILE"
echo "   - Port: $BACKEND_PORT" | tee -a "$LOG_FILE"
echo "   - API URL: $BACKEND_API_URL" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "🔍 API Documentation: $BACKEND_API_URL/docs" | tee -a "$LOG_FILE"
echo "📝 Server logs: $LOG_FILE" | tee -a "$LOG_FILE" 