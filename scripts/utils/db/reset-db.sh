#!/bin/bash
set -e

# Source the root directory check and config loader
source scripts/utils/check-root-dir.sh
source scripts/utils/config-loader.sh

check_root_dir || exit 1

# Main script
echo "♻️ [reset-db.sh] Resetting QLDSV-HTC database..."

# Load environment variables
load_env_file

# Confirm reset
echo "⚠️ WARNING: This will reset your database. All data will be lost!"
echo "❗ This action is irreversible and cannot be undone!"
read -p "Are you sure you want to continue? (yes/no): " confirmation
confirmation=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]')

if [[ "$confirmation" != "yes" ]]; then
    echo "❌ Operation cancelled."
    exit 0
fi

# Change to database directory
cd database

# Reset database (down and up)
echo "🗑️ Removing database container..."
docker-compose down -v

echo "🚀 Restarting database container..."
docker-compose up -d --build

echo "⏳ Waiting for database to be ready..."
sleep 10

echo "✅ [reset-db.sh] Database has been reset!" 