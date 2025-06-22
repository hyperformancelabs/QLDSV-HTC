#!/bin/bash
set -e

# Source the root directory check and config loader
source scripts/utils/check-root-dir.sh
source scripts/utils/config-loader.sh

check_root_dir || exit 1

# Load environment variables
load_env_file

# Parse arguments
SETUP=0      # --setup  : run frontend setup before start
RESET_FE=0   # --reset  : clean & reinstall node_modules before start
DELETE_FE=0  # --delete : remove node_modules & logs then exit

for arg in "$@"; do
    case $arg in
        --setup)
            SETUP=1
            shift
            ;;
        --reset)
            RESET_FE=1
            shift
            ;;
        --delete)
            DELETE_FE=1
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

# Remove old log file if it exists
if [ -f "$LOG_FILE" ]; then
    echo "🗑️ Removing old frontend log file..."
    rm -f "$LOG_FILE"
fi

# Delete
if [ $DELETE_FE -eq 1 ]; then
    ./scripts/utils/fe/delete-frontend.sh | tee -a "$LOG_FILE"
    exit 0
fi

# Reset dependencies
if [ $RESET_FE -eq 1 ]; then
    ./scripts/utils/fe/reset-frontend.sh | tee -a "$LOG_FILE"
fi

# Run setup if requested
if [ $SETUP -eq 1 ]; then
    echo "🔄 Running frontend setup..." | tee -a "$LOG_FILE"
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