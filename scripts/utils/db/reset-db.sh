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

# Force kill any active connections first
echo "🔌 Force disconnecting any active database connections..."
if docker ps -q --filter "name=${DB_CONTAINER_NAME}" | grep -q .; then
    echo "   Killing active connections to database..."
    docker exec ${DB_CONTAINER_NAME} /opt/mssql-tools18/bin/sqlcmd \
        -S localhost \
        -U sa \
        -P "${MSSQL_SA_PASSWORD}" \
        -C \
        -Q "ALTER DATABASE [${DB_NAME}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE IF EXISTS [${DB_NAME}];" \
        2>/dev/null || true
fi

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

# Reset database (down and up) with force options
echo "🗑️ Force removing database resources..."
docker-compose down -v --remove-orphans || true

# Force remove any remaining volumes
echo "🧹 Force cleaning up database volumes..."
docker volume rm ${DB_CONTAINER_NAME}_data 2>/dev/null || true
docker volume rm database_db_data 2>/dev/null || true

echo "🚀 Restarting database container with fresh setup..."
docker-compose up -d --build

echo "⏳ Waiting for database to be ready..."
# Wait longer for fresh setup
sleep 15

# Verify the container is actually running
if ! docker ps | grep -q ${DB_CONTAINER_NAME}; then
    echo "❌ Database container failed to start!"
    echo "🔍 Check container logs: docker logs ${DB_CONTAINER_NAME}"
    exit 1
fi

echo "✅ [reset-db.sh] Database has been completely reset with fresh data!"
echo "🔄 Database is ready for new setup." 