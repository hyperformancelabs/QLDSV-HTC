#!/bin/bash
set -e

echo "🔍 [verify-setup.sh] Verifying QLDSV-HTC setup..."

# Load configuration
source scripts/utils/config-loader.sh
load_global_config

echo "📋 Verification Checklist:"
echo ""

# 1. Check Docker
echo "1️⃣ Checking Docker..."
if command -v docker &> /dev/null; then
    if docker info &> /dev/null; then
        echo "   ✅ Docker is running"
    else
        echo "   ❌ Docker is not running"
        exit 1
    fi
else
    echo "   ❌ Docker is not installed"
    exit 1
fi

# 2. Check configuration files
echo "2️⃣ Checking configuration files..."
required_files=(".env" "docker-compose.yml" "database/Dockerfile" "database/docker-compose.yml")
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ $file exists"
    else
        echo "   ❌ $file missing"
        exit 1
    fi
done

# 3. Check Docker network
echo "3️⃣ Checking Docker network..."
if docker network ls | grep -q "$DOCKER_NETWORK"; then
    echo "   ✅ Docker network '$DOCKER_NETWORK' exists"
else
    echo "   ❌ Docker network '$DOCKER_NETWORK' not found"
    exit 1
fi

# 4. Check database container
echo "4️⃣ Checking database container..."
if docker ps | grep -q "$DB_CONTAINER_NAME"; then
    echo "   ✅ Database container is running"
    
    # Check database connectivity
    echo "5️⃣ Checking database connectivity..."
    if docker exec $DB_CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C \
        -Q "SELECT 1" -h -1 > /dev/null 2>&1; then
        echo "   ✅ Database connection successful"
    else
        echo "   ❌ Database connection failed"
        exit 1
    fi
    
    # Check database and tables
    echo "6️⃣ Checking database schema..."
    table_count=$(docker exec $DB_CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C \
        -d "$DB_NAME" \
        -Q "SELECT COUNT(*) FROM sys.tables WHERE name IN ('KHOA', 'LOP', 'SINHVIEN', 'MONHOC', 'GIANGVIEN', 'LOPTINCHI', 'DANGKY')" \
        -h -1 -W | grep -E '^[0-9]+$' | head -1)
    
    if [ "$table_count" = "7" ]; then
        echo "   ✅ All required tables exist ($table_count/7)"
    else
        echo "   ❌ Missing tables (found: $table_count/7)"
        exit 1
    fi
    
    # Check users
    echo "7️⃣ Checking database users..."
    users=("qldsv_app" "pgv_user" "khoa_user" "sv_user")
    for user in "${users[@]}"; do
        if docker exec $DB_CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
            -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C \
            -d "$DB_NAME" \
            -Q "SELECT name FROM sys.database_principals WHERE name = '$user'" \
            -h -1 -W | grep -q "$user"; then
            echo "   ✅ User '$user' exists"
        else
            echo "   ❌ User '$user' missing"
            exit 1
        fi
    done
    
    # Check backup devices
    echo "8️⃣ Checking backup devices..."
    backup_count=$(docker exec $DB_CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C \
        -Q "SELECT COUNT(*) FROM sys.backup_devices WHERE name LIKE 'DEVICE_QLDSV_HTC%'" \
        -h -1 -W | grep -E '^[0-9]+$' | head -1)
    
    if [ "$backup_count" -ge "2" ]; then
        echo "   ✅ Backup devices configured ($backup_count devices)"
    else
        echo "   ❌ Backup devices missing (found: $backup_count)"
        exit 1
    fi
    
else
    echo "   ❌ Database container is not running"
    exit 1
fi

echo ""
echo "🎉 [verify-setup.sh] All verification checks passed!"
echo ""
echo "🚀 Your QLDSV-HTC environment is ready!"
echo ""
echo "📋 Next Steps:"
echo "   1. Connect to database using Azure Data Studio:"
echo "      Server: localhost,$DB_PORT"
echo "      Authentication: SQL Server Authentication"
echo "      Username: pgv_user (or sa)"
echo "      Password: [from .env file]"
echo ""
echo "   2. Start development:"
echo "      ./scripts/service-mgmt.sh start all"
echo ""
echo "   3. Check service status:"
echo "      ./scripts/service-mgmt.sh status"
echo ""
echo "   4. Database management:"
echo "      ./scripts/database/db-manager.sh help" 