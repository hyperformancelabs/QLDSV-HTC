#!/bin/bash
set -e

# Source the root directory check and config loader
source scripts/utils/check-root-dir.sh
source scripts/utils/config-loader.sh

check_root_dir || exit 1

# Main script
echo "🏥 [db-health-check.sh] Checking QLDSV-HTC database health..."

# Load environment variables
load_env_file

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
test_user_connection "$MSSQL_APP_USER" "$MSSQL_APP_PASSWORD"

# Optional users - only test if passwords are defined
if [ ! -z "$MSSQL_PGV_PASSWORD" ]; then
    test_user_connection "pgv_user" "$MSSQL_PGV_PASSWORD"
fi
if [ ! -z "$MSSQL_KHOA_PASSWORD" ]; then
    test_user_connection "khoa_user" "$MSSQL_KHOA_PASSWORD"
fi
if [ ! -z "$MSSQL_SV_PASSWORD" ]; then
    test_user_connection "sv" "$MSSQL_SV_PASSWORD"
fi

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
echo "👤 SQL Server Logins:"

# List all logins with creation date and status
docker exec $DB_CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
    -S localhost \
    -U sa \
    -P "$MSSQL_SA_PASSWORD" \
    -C \
    -Q "
    SELECT 
        name as LoginName,
        CONVERT(VARCHAR(20), create_date, 120) as CreatedDate,
        CASE WHEN is_disabled = 1 THEN 'Disabled' ELSE 'Enabled' END as Status,
        type_desc as LoginType
    FROM sys.server_principals
    WHERE type IN ('S', 'U')
    AND name NOT LIKE '##%'
    AND name NOT IN ('sa', 'distributor_admin')
    ORDER BY name
    " \
    -h -1 -W

echo ""
echo "🔑 Database Users and Roles:"

# List database users and their roles
docker exec $DB_CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
    -S localhost \
    -U sa \
    -P "$MSSQL_SA_PASSWORD" \
    -C \
    -d "$DB_NAME" \
    -Q "
    SELECT 
        u.name as DatabaseUser,
        CASE WHEN u.type = 'S' THEN 'SQL User'
             WHEN u.type = 'U' THEN 'Windows User'
             WHEN u.type = 'R' THEN 'Role'
             ELSE u.type_desc END as UserType,
        ISNULL(l.name, 'No login') as ServerLogin,
        r.name as RoleName
    FROM sys.database_principals u
    LEFT JOIN sys.server_principals l ON u.sid = l.sid
    LEFT JOIN sys.database_role_members m ON u.principal_id = m.member_principal_id
    LEFT JOIN sys.database_principals r ON m.role_principal_id = r.principal_id
    WHERE u.type IN ('S', 'U', 'G')
    AND u.name NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys')
    ORDER BY u.name, r.name
    " \
    -h -1 -W

echo ""
echo "🔒 Database Permissions:"

# List database permissions
docker exec $DB_CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
    -S localhost \
    -U sa \
    -P "$MSSQL_SA_PASSWORD" \
    -C \
    -d "$DB_NAME" \
    -Q "
    SELECT 
        u.name as Principal,
        CASE u.type 
            WHEN 'S' THEN 'SQL User'
            WHEN 'U' THEN 'Windows User'
            WHEN 'R' THEN 'Role'
            ELSE u.type_desc 
        END as PrincipalType,
        p.permission_name as Permission,
        CASE p.state
            WHEN 'W' THEN 'Grant with Grant'
            WHEN 'G' THEN 'Grant'
            WHEN 'D' THEN 'Deny'
            ELSE p.state_desc
        END as State,
        CASE 
            WHEN p.class = 0 THEN 'Database'
            WHEN p.class = 1 THEN OBJECT_NAME(p.major_id)
            WHEN p.class = 3 THEN SCHEMA_NAME(p.major_id)
            ELSE CAST(p.class as VARCHAR) + ':' + CAST(p.major_id as VARCHAR)
        END as ObjectName
    FROM sys.database_permissions p
    JOIN sys.database_principals u ON p.grantee_principal_id = u.principal_id
    WHERE u.name NOT IN ('public')
    ORDER BY u.name, p.permission_name
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
        SCHEMA_NAME(t.schema_id) + '.' + t.name as TableName,
        SUM(p.rows) as [RowCount]
    FROM sys.tables t
    INNER JOIN sys.partitions p ON t.object_id = p.object_id
    WHERE p.index_id IN (0,1)
    GROUP BY t.schema_id, t.name
    ORDER BY TableName
    " \
    -h -1 -W

echo ""
echo "📊 Database Objects Summary:"

# List database objects by type
docker exec $DB_CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
    -S localhost \
    -U sa \
    -P "$MSSQL_SA_PASSWORD" \
    -C \
    -d "$DB_NAME" \
    -Q "
    SELECT 
        CASE type
            WHEN 'P' THEN 'Stored Procedure'
            WHEN 'V' THEN 'View'
            WHEN 'FN' THEN 'Function'
            WHEN 'TR' THEN 'Trigger'
            WHEN 'U' THEN 'Table'
            ELSE type_desc
        END as ObjectType,
        COUNT(*) as [Count]
    FROM sys.objects
    WHERE is_ms_shipped = 0
    GROUP BY type, type_desc
    ORDER BY ObjectType
    " \
    -h -1 -W

echo "✅ [db-health-check.sh] Health check completed!" 