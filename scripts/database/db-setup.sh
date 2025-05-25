#!/bin/bash
set -e

echo "🛠️ [db-setup.sh] Setting up QLDSV-HTC database..."

# Load configuration
source scripts/utils/config-loader.sh
load_global_config

# Ensure we're in the correct directory
cd database

# Start database container
echo "🚀 Starting SQL Server container..."
docker-compose up -d --build

echo "⏳ Waiting for SQL Server to be ready..."
sleep 30

# Wait for health check to pass
echo "🏥 Waiting for health check to pass..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if docker exec $DB_CONTAINER_NAME /var/health/healthcheck.sh; then
        echo "✅ SQL Server is ready!"
        break
    else
        echo "⏳ Attempt $attempt/$max_attempts - SQL Server not ready yet..."
        sleep 10
        ((attempt++))
    fi
done

if [ $attempt -gt $max_attempts ]; then
    echo "❌ SQL Server failed to start properly"
    exit 1
fi

# Use the new database manager for setup
echo "📜 Using new database manager for full setup..."
./scripts/database/db-manager.sh full-setup

echo "🔍 Verifying setup..."
cd ..
./scripts/database/db-health.sh

echo "✅ [db-setup.sh] QLDSV-HTC database setup completed successfully!"
echo ""
echo "🔗 Connection Information:"
echo "   Server: localhost,$DB_PORT"
echo "   Database: $DB_NAME"
echo "   SA Password: [configured in .env]"
echo ""
echo "👥 Available Users:"
echo "   - pgv_user (Phòng Giáo Vụ - Full access)"
echo "   - khoa_user (Khoa - Limited access)"
echo "   - sv (Sinh Viên - Registration only)"
echo "   - qldsv_app (Application backend)"
echo ""
echo "🛠️ Database Management:"
echo "   ./database/management/db-manager.sh help    # Show all commands"
echo "   ./database/management/db-manager.sh dev-reset    # Quick development reset"
echo "   ./database/management/db-manager.sh reseed       # Refresh test data"