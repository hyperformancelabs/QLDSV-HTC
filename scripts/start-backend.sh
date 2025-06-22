#!/bin/bash
set -e

# Source the root directory check and config loader
source scripts/utils/check-root-dir.sh
source scripts/utils/config-loader.sh

check_root_dir || exit 1

# Load environment variables
load_env_file

# Parse arguments
RESET_DB=0      # --reset-db : reset database via python
RESET_ENV=0     # --reset    : delete & recreate backend env (venv + logs)
SETUP=0         # --setup    : run backend setup before start
DELETE_BACKEND=0 # --delete   : delete env only, no start

for arg in "$@"; do
    case $arg in
        --reset-db)
            RESET_DB=1
            shift
            ;;
        --setup)
            SETUP=1
            shift
            ;;
        --reset)
            RESET_ENV=1
            shift
            ;;
        --delete)
            DELETE_BACKEND=1
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

# Remove old log file if it exists
if [ -f "$LOG_FILE" ]; then
    echo "🗑️ Removing old backend log file..."
    rm -f "$LOG_FILE"
fi

# Delete backend env via dedicated util
if [ $DELETE_BACKEND -eq 1 ]; then
    ./scripts/utils/be/delete-backend.sh
    exit 0
fi

# Reset environment (includes setup)
if [ $RESET_ENV -eq 1 ]; then
    ./scripts/utils/be/reset-backend.sh 2>&1 | tee -a "$LOG_FILE"
else
    # Run setup if requested
    if [ $SETUP -eq 1 ]; then
        ./scripts/setup/be/setup-backend.sh --default 2>&1 | tee -a "$LOG_FILE"
    fi
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
echo ""
echo -e "✅ Usage:\n  --setup       : setup backend env then start\n  --reset       : reset env (delete & recreate) then start\n  --reset-db    : pass through to FastAPI for DB reset\n  --delete      : delete env, do NOT start" 