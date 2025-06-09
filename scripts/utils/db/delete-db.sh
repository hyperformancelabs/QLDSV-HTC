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

# Force stop container if running
echo "🛑 Force stopping database container..."
if docker ps -q --filter "name=${DB_CONTAINER_NAME}" | grep -q .; then
    echo "   Stopping container ${DB_CONTAINER_NAME}..."
    docker stop ${DB_CONTAINER_NAME} || true
fi

# Force remove container
echo "🗑️ Force removing database container..."
if docker ps -aq --filter "name=${DB_CONTAINER_NAME}" | grep -q .; then
    echo "   Removing container ${DB_CONTAINER_NAME}..."
    docker rm -f ${DB_CONTAINER_NAME} || true
fi

# Delete database container and volumes with force
echo "🗑️ Deleting database resources via docker-compose..."
docker-compose down -v --remove-orphans || true

# Force remove any remaining volumes
echo "🧹 Force cleaning up database volumes..."
# Remove specific volumes
docker volume rm ${DB_CONTAINER_NAME}_data 2>/dev/null || true
docker volume rm database_db_data 2>/dev/null || true

# Remove any orphaned volumes that match patterns
echo "🧹 Cleaning up orphaned volumes..."
docker volume ls -q | grep -E "(db_data|sqlserver|qldsv|${PROJECT_NAME})" | xargs -r docker volume rm 2>/dev/null || true

# Clean up any remaining database networks
echo "🌐 Cleaning up database networks..."
docker network rm ${DOCKER_NETWORK} 2>/dev/null || true

# Prune unused resources
echo "🧹 Pruning unused Docker resources..."
docker system prune -f --volumes || true

echo "✅ [delete-db.sh] Database container and ALL data forcefully deleted!"
echo "🔄 Run './scripts/start-database.sh' to create a fresh database." 