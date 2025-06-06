#!/bin/bash
set -e

# Source the root directory check and config loader
source scripts/utils/check-root-dir.sh
source scripts/utils/config-loader.sh

check_root_dir || exit 1

# Main script
echo "🛑 [stop-db.sh] Stopping QLDSV-HTC database container..."

# Load environment variables
load_env_file

# Change to database directory
cd database

# Stop database container
echo "🛑 Stopping database container..."
docker-compose down

echo "✅ [stop-db.sh] Database container stopped!" 