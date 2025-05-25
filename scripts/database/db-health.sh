#!/bin/bash
set -e

echo "🏥 [db-health.sh] Checking QLDSV-HTC database health..."

# Load configuration
source scripts/utils/config-loader.sh
load_global_config

# Check if container is running
if [ ! "$(docker ps -q -f name=$DB_CONTAINER_NAME)" ]; then
    echo "❌ Container '$DB_CONTAINER_NAME' is not running!"
    exit 1
fi

echo "🔍 Testing database connections..."

# Test connections for all users
test_user_connection() {
    local username="$1"
    local password="$2"
    
    echo "🔐 Testing connection for user: $username"
    
    if docker exec $DB_CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
        -S localhost \
        -U "$username" \
        -P "$password" \
        -C \
        -d "$DB_NAME" \
        -Q "SELECT 'Connection successful for $username' as Status" \
        -h -1 > /dev/null 2>&1; then
        echo "✅ $username connection OK"
    else
        echo "❌ $username connection FAILED"
    fi
}

# Test each user
test_user_connection "sa" "$MSSQL_SA_PASSWORD"
test_user_connection "qldsv_app" "$MSSQL_APP_PASSWORD"
test_user_connection "pgv_user" "$MSSQL_PGV_PASSWORD"
test_user_connection "khoa_user" "$MSSQL_KHOA_PASSWORD"
test_user_connection "sv" "$MSSQL_SV_PASSWORD"

echo ""
echo "📊 Database Information:"

# Get database info
docker exec $DB_CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
    -S localhost \
    -U sa \
    -P "$MSSQL_SA_PASSWORD" \
    -C \
    -Q "
    SELECT 'SQL Server Version' as Info, @@VERSION as Value
    UNION ALL
    SELECT 'Database Name', DB_NAME()
    UNION ALL
    SELECT 'Database Size (MB)', CAST(SUM(size * 8.0 / 1024) AS VARCHAR(20))
    FROM sys.master_files 
    WHERE database_id = DB_ID('$DB_NAME')
    " \
    -h -1 -W

echo ""
echo "🏗️ Tables Status:"

# Check tables
docker exec $DB_CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
    -S localhost \
    -U sa \
    -P "$MSSQL_SA_PASSWORD" \
    -C \
    -d "$DB_NAME" \
    -Q "
    SELECT 
        t.name as TableName,
        SUM(p.rows) as RowCount
    FROM sys.tables t
    INNER JOIN sys.partitions p ON t.object_id = p.object_id
    WHERE p.index_id IN (0,1)
    GROUP BY t.name
    ORDER BY t.name
    " \
    -h -1 -W

echo ""
echo "💾 Backup Devices:"

# Check backup devices
docker exec $DB_CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
    -S localhost \
    -U sa \
    -P "$MSSQL_SA_PASSWORD" \
    -C \
    -Q "
    SELECT 
        name as DeviceName,
        physical_name as PhysicalPath,
        type_desc as DeviceType
    FROM sys.backup_devices
    WHERE name LIKE 'DEVICE_QLDSV_HTC%'
    ORDER BY name
    " \
    -h -1 -W

echo "✅ [db-health.sh] Health check completed!"
echo ""
echo "🛠️ Database Management Commands:"
echo "   ./scripts/database/db-manager.sh status           # Show detailed status"
echo "   ./scripts/database/db-manager.sh test-connections # Test all connections"
echo "   ./scripts/database/db-manager.sh dev-reset        # Quick development reset"
echo "   ./scripts/database/db-manager.sh help             # Show all commands" 