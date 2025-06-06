#!/bin/bash
set -e

# Source the root directory check and config loader
source scripts/utils/check-root-dir.sh
source scripts/utils/config-loader.sh

check_root_dir || exit 1

# Main script
echo "🔄 [restart-db.sh] Restarting QLDSV-HTC database container..."

# Load environment variables
load_env_file

# Change to database directory
cd database

# Restart database container
echo "🛑 Stopping database container..."
docker-compose down

echo "🚀 Starting database container..."
docker-compose up -d --build

echo "✅ [restart-db.sh] Database container restarted! You can check logs with: docker logs $DB_CONTAINER_NAME" 