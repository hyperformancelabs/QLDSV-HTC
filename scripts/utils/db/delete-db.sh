#!/bin/bash
set -e

# Source the root directory check and config loader
source scripts/utils/check-root-dir.sh
source scripts/utils/config-loader.sh

check_root_dir || exit 1

# Main script
echo "🗑️ [delete-db.sh] Deleting QLDSV-HTC database container and volumes..."

# Load environment variables
load_env_file

# Confirm deletion
echo "⚠️ WARNING: This will delete the database container and ALL DATA will be lost!"
echo "❗ This action is irreversible and cannot be undone!"
read -p "Are you sure you want to continue? (yes/no): " confirmation
confirmation=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]')

if [[ "$confirmation" != "yes" ]]; then
    echo "❌ Operation cancelled."
    exit 0
fi

# Change to database directory
cd database

# Delete database container and volumes
echo "🗑️ Deleting database container and volumes..."
docker-compose down -v

# Remove any orphaned volumes
echo "🧹 Cleaning up orphaned volumes..."
docker volume ls -q | grep -E "db_data|sqlserver|qldsv" | xargs -r docker volume rm

echo "✅ [delete-db.sh] Database container and volumes deleted!" 