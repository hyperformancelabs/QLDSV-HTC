#!/bin/bash
set -e

# Source utilities
source scripts/utils/check-root-dir.sh
source scripts/utils/config-loader.sh

check_root_dir || exit 1

# Load environment variables
load_env_file

echo "🔍 Running database health check..."
echo "========================================"

# Check if Docker is running
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed or not in PATH"
    exit 1
fi

# Check if the container is running
if ! docker ps | grep -q $DB_CONTAINER_NAME; then
    echo "❌ SQL Server container '$DB_CONTAINER_NAME' is not running"
    echo "   Run ./scripts/start-database.sh to start the database"
    exit 1
fi

echo "✅ SQL Server container is running"

# Function to test connection
test_connection() {
    local user=$1
    local password=$2
    local database=${3:-master}
    
    echo "🔍 Testing connection as user '$user' to database '$database'..."
    
    if docker exec $DB_CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
        -S localhost \
        -U $user \
        -P "$password" \
        -C \
        -d $database \
        -Q "SELECT @@VERSION" &> /dev/null; then
        echo "✅ Successfully connected as $user to $database"
        return 0
    else
        echo "❌ Failed to connect as $user to $database"
        return 1
    fi
}

# Test SA connection (lowercase 'sa')
echo ""
echo "TESTING SA CONNECTION:"
echo "----------------------"
test_connection "sa" "$MSSQL_SA_PASSWORD"

# Test app_user connection if the database exists
echo ""
echo "TESTING APP USER CONNECTION:"
echo "---------------------------"
if docker exec $DB_CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
    -S localhost \
    -U sa \
    -P "$MSSQL_SA_PASSWORD" \
    -C \
    -Q "SELECT name FROM master.dbo.sysdatabases WHERE name = '$DB_NAME'" | grep -q "$DB_NAME"; then
    
    test_connection "$MSSQL_APP_USER" "$MSSQL_APP_PASSWORD" "$DB_NAME"
else
    echo "⚠️ Database $DB_NAME doesn't exist yet - skipping app_user test"
fi

# Get SQL Server version
echo ""
echo "SQL SERVER INFORMATION:"
echo "----------------------"
docker exec $DB_CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
    -S localhost \
    -U sa \
    -P "$MSSQL_SA_PASSWORD" \
    -C \
    -Q "SELECT @@VERSION" | grep -v "^$" | head -3

# Function to execute SQL and format output
execute_sql() {
    local sql_query="$1"
    local header="$2"
    
    if [ -n "$header" ]; then
echo ""
        echo "$header"
        echo "$(printf '%*s' ${#header} '' | tr ' ' '-')"
    fi

docker exec $DB_CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
    -S localhost \
    -U sa \
    -P "$MSSQL_SA_PASSWORD" \
    -C \
    -d "$DB_NAME" \
        -Q "$sql_query" \
        -h-1 \
        -s"," \
        -W \
        -w 999 | grep -v "^$" | head -20 2>/dev/null || echo "   No data found"
}

# Check if the database exists
echo ""
echo "DATABASE STATUS:"
echo "---------------"
if docker exec $DB_CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
    -S localhost \
    -U sa \
    -P "$MSSQL_SA_PASSWORD" \
    -C \
    -Q "SELECT name FROM master.dbo.sysdatabases WHERE name = '$DB_NAME'" | grep -q "$DB_NAME"; then
    
    echo "✅ Database $DB_NAME exists"

    # Get database size
    execute_sql "SELECT DB_NAME(database_id) AS DatabaseName, 
        CAST((SUM(size) * 8.0 / 1024) AS DECIMAL(10,2)) AS SizeMB
        FROM sys.master_files
        WHERE DB_NAME(database_id) = '$DB_NAME'
        GROUP BY database_id" "📊 DATABASE SIZE:"

    # Show SQL Server logins
    execute_sql "SELECT 
        name AS LoginName,
        type_desc AS LoginType,
        create_date AS Created,
        modify_date AS LastModified,
        is_disabled AS IsDisabled
        FROM sys.server_principals 
        WHERE type IN ('S', 'U', 'G') 
        AND name NOT LIKE '##%'
        ORDER BY name" "🔐 SQL SERVER LOGINS:"

    # Show database users and their roles
    execute_sql "SELECT 
        dp.name AS PrincipalName,
        dp.type_desc AS PrincipalType,
        r.name AS RoleName
        FROM sys.database_principals dp
        LEFT JOIN sys.database_role_members rm ON dp.principal_id = rm.member_principal_id
        LEFT JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
        WHERE dp.type IN ('S', 'U', 'G') 
        AND dp.name NOT LIKE '##%'
        ORDER BY dp.name, r.name" "👥 DATABASE USERS & ROLES:"

    # Show detailed permissions
    execute_sql "SELECT 
        dp.class_desc AS ObjectClass,
        dp.permission_name AS Permission,
        dp.state_desc AS PermissionState,
        pr.name AS Principal,
        ISNULL(o.name, 'DATABASE') AS ObjectName
        FROM sys.database_permissions dp
        LEFT JOIN sys.objects o ON dp.major_id = o.object_id
        LEFT JOIN sys.database_principals pr ON dp.grantee_principal_id = pr.principal_id
        WHERE pr.name IS NOT NULL
        ORDER BY pr.name, dp.permission_name" "🛡️ PERMISSIONS MATRIX:"

    # Show tables with row counts
    execute_sql "SELECT 
        t.name AS TableName,
        p.rows AS RowCnt,
        au.total_pages AS TotalPages,
        CAST((au.total_pages * 8.0 / 1024) AS DECIMAL(10,2)) AS SizeMB
        FROM sys.tables t
        INNER JOIN sys.indexes i ON t.object_id = i.object_id
        INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
        INNER JOIN sys.allocation_units au ON p.partition_id = au.container_id
        WHERE i.index_id <= 1
        ORDER BY p.rows DESC" "📋 TABLES & ROW COUNTS:"

    # Show stored procedures
    execute_sql "SELECT 
        name AS ProcedureName,
        create_date AS Created,
        modify_date AS LastModified
        FROM sys.procedures
        ORDER BY name" "⚙️ STORED PROCEDURES:"

    # Show user-defined functions
    execute_sql "SELECT 
        name AS FunctionName,
        type_desc AS FunctionType,
        create_date AS Created,
        modify_date AS LastModified
        FROM sys.objects
        WHERE type IN ('FN', 'IF', 'TF', 'FS', 'FT')
        ORDER BY name" "🔧 USER-DEFINED FUNCTIONS:"

    # Show views
    execute_sql "SELECT 
        name AS ViewName,
        create_date AS Created,
        modify_date AS LastModified
        FROM sys.views
        ORDER BY name" "👁️ VIEWS:"

    # Show triggers
    execute_sql "SELECT 
        tr.name AS TriggerName,
        OBJECT_NAME(tr.parent_id) AS TableName,
        tr.type_desc AS TriggerType,
        tr.create_date AS Created,
        tr.modify_date AS LastModified,
        tr.is_disabled AS IsDisabled
        FROM sys.triggers tr
        WHERE tr.parent_class = 1
        ORDER BY OBJECT_NAME(tr.parent_id), tr.name" "🎯 TRIGGERS:"

    # Show indexes
    execute_sql "SELECT 
        OBJECT_NAME(i.object_id) AS TableName,
        i.name AS IndexName,
        i.type_desc AS IndexType,
        i.is_unique AS IsUnique,
        i.is_primary_key AS IsPrimaryKey
        FROM sys.indexes i
        WHERE i.type > 0
        AND OBJECT_NAME(i.object_id) NOT LIKE 'sys%'
        ORDER BY OBJECT_NAME(i.object_id), i.name" "📇 INDEXES:"

    # Show database objects summary
    execute_sql "SELECT 
        type_desc AS ObjectType,
        COUNT(*) AS Count
        FROM sys.objects
        WHERE type IN ('U', 'P', 'V', 'FN', 'IF', 'TF', 'TR')
        GROUP BY type_desc
        ORDER BY type_desc" "📊 DATABASE OBJECTS SUMMARY:"

    # Show backup information
    execute_sql "SELECT 
        database_name AS DatabaseName,
        type AS BackupType,
        backup_start_date AS BackupDate,
        backup_size/1024/1024 AS BackupSizeMB,
        compressed_backup_size/1024/1024 AS CompressedSizeMB
        FROM msdb.dbo.backupset
        WHERE database_name = '$DB_NAME'
        ORDER BY backup_start_date DESC" "💾 RECENT BACKUPS:"

else
    echo "⚠️ Database $DB_NAME doesn't exist yet"
    echo "   Run ./scripts/start-backend.sh --reset-db to create the database"
    
    # Still show server-level information
echo ""
    echo "🔐 SQL SERVER LOGINS (Server Level):"
    echo "-----------------------------------"
docker exec $DB_CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
    -S localhost \
    -U sa \
    -P "$MSSQL_SA_PASSWORD" \
    -C \
        -Q "SELECT 
            name AS LoginName,
            type_desc AS LoginType,
            create_date AS Created,
            is_disabled AS IsDisabled
            FROM sys.server_principals 
            WHERE type IN ('S', 'U', 'G') 
            AND name NOT LIKE '##%'
            ORDER BY name" \
        -h-1 -s"," -W -w 999 | grep -v "^$" | head -10 2>/dev/null || echo "   No custom logins found"
fi

echo ""
echo "✅ Comprehensive database health check completed"
echo "🔄 For detailed logs, check: docker logs $DB_CONTAINER_NAME" 