#!/bin/bash
set -e

# Source utilities
source scripts/utils/check-root-dir.sh
source scripts/utils/config-loader.sh

check_root_dir || exit 1

# Load environment variables
load_env_file

# Check if Python virtual environment exists
if [ ! -d "backend/venv" ]; then
    echo "❌ Python virtual environment not found. Please run setup-backend.sh first."
    exit 1
fi

# Activate virtual environment
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    # Windows
    source backend/venv/Scripts/activate
else
    # Linux/MacOS
    source backend/venv/bin/activate
fi

# Check if dependencies are installed
if ! backend/venv/bin/pip show fastapi > /dev/null 2>&1; then
    echo "❌ Dependencies not installed. Please run setup-backend.sh first."
    exit 1
fi

# Parse arguments
RESET_DB=0
for arg in "$@"; do
    case $arg in
        --reset-db)
            RESET_DB=1
            shift
            ;;
        *)
            # Unknown option
            ;;
    esac
done

# Create logs directory if it doesn't exist
mkdir -p backend/logs

# Store the full path to the Python interpreter before changing directory
PYTHON_PATH=$(pwd)/backend/venv/bin/python

# Change to backend directory
cd backend

# Start the backend
echo "🔄 Starting FastAPI backend..."

if [ $RESET_DB -eq 1 ]; then
    echo "🔄 Resetting database before starting..."
    $PYTHON_PATH main.py --reset-db
    echo "✅ Database reset completed"
fi

# Start the uvicorn server
BACKEND_HOST=${BACKEND_HOST:-0.0.0.0}
BACKEND_PORT=${BACKEND_PORT:-8000}
FASTAPI_DEBUG=${FASTAPI_DEBUG:-true}
FASTAPI_RELOAD=${FASTAPI_RELOAD:-true}

if [ "$FASTAPI_DEBUG" = "true" ]; then
    DEBUG_FLAG="--log-level debug"
else
    DEBUG_FLAG="--log-level info"
fi

if [ "$FASTAPI_RELOAD" = "true" ]; then
    RELOAD_FLAG="--reload"
else
    RELOAD_FLAG=""
fi

# Start uvicorn using explicit Python interpreter
$PYTHON_PATH -m uvicorn main:app --host $BACKEND_HOST --port $BACKEND_PORT $DEBUG_FLAG $RELOAD_FLAG

# Deactivate virtual environment
# no deactivate needed when not sourcing, but we keep consistency

echo "✅ [start-backend.sh] Backend started!" 