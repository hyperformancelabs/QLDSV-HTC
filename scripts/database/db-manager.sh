#!/bin/bash
set -e

# =============================================
# QLDSV-HTC Database Management Script
# File: scripts/database/db-manager.sh
# Purpose: Comprehensive database management for development
# =============================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Load configuration
source scripts/utils/config-loader.sh
load_global_config

# Check if we're in the right directory
if [ ! -f "DESCRIPTION.md" ]; then
    echo -e "${RED}❌ Please run this script from the QLDSV-HTC project root directory${NC}"
    exit 1
fi

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE} QLDSV-HTC Database Manager${NC}"
    echo -e "${BLUE}================================================${NC}"
}

print_usage() {
    echo "Usage: $0 {command} [options]"
    echo ""
    echo -e "${CYAN}Foundation Commands:${NC}"
    echo "  init-db              - Initialize database (DROP + CREATE)"
    echo "  create-logins        - Create SQL Server logins"
    echo ""
    echo -e "${CYAN}Schema Commands:${NC}"
    echo "  drop-tables          - Drop all tables"
    echo "  create-tables        - Create all tables"
    echo "  create-indexes       - Create performance indexes"
    echo "  rebuild-schema       - Full schema rebuild (drop + create + indexes)"
    echo ""
    echo -e "${CYAN}Security Commands:${NC}"
    echo "  drop-security        - Drop users and roles"
    echo "  create-roles         - Create custom roles"
    echo "  create-users         - Create database users"
    echo "  set-permissions      - Configure permissions"
    echo "  rebuild-security     - Full security rebuild"
    echo ""
    echo -e "${CYAN}Backup Commands:${NC}"
    echo "  drop-backup-devices  - Drop backup devices"
    echo "  create-backup-devices- Create backup devices"
    echo "  backup-full          - Create full backup"
    echo "  backup-diff          - Create differential backup"
    echo "  backup-log           - Create log backup"
    echo ""
    echo -e "${CYAN}Data Commands:${NC}"
    echo "  clear-data           - Clear all data"
    echo "  seed-basic           - Insert basic test data"
    echo "  reseed               - Clear + seed basic data"
    echo ""
    echo -e "${CYAN}Full Operations:${NC}"
    echo "  full-setup           - Complete setup (foundation + schema + security + backup + data)"
    echo "  full-reset           - Complete reset and setup"
    echo "  dev-reset            - Quick development reset (schema + data only)"
    echo ""
    echo -e "${CYAN}Utility Commands:${NC}"
    echo "  status               - Show database status"
    echo "  test-connections     - Test all user connections"
    echo "  show-tables          - Show table information"
    echo "  show-permissions     - Show user permissions"
}

execute_sql_file() {
    local file_path=$1
    local description=$2
    
    # SQL files are now in database/ directory
    local full_path="database/$file_path"
    
    if [ ! -f "$full_path" ]; then
        echo -e "${RED}❌ File not found: $full_path${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}📜 Executing: $description${NC}"
    
    docker exec $DB_CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
        -S localhost \
        -U sa \
        -P "$MSSQL_SA_PASSWORD" \
        -C \
        -i "/var/scripts/$file_path" \
        -v QLDSV_DB_NAME="$DB_NAME" \
        -v QLDSV_APP_USER="$MSSQL_APP_USER" \
        -v QLDSV_APP_PASSWORD="$MSSQL_APP_PASSWORD"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $description completed${NC}"
    else
        echo -e "${RED}❌ $description failed${NC}"
        return 1
    fi
}

# Foundation Commands
init_database() {
    execute_sql_file "01-foundation/01-init-database.sql" "Database initialization"
}

create_logins() {
    execute_sql_file "01-foundation/02-create-logins.sql" "SQL Server logins creation"
}

# Schema Commands
drop_tables() {
    execute_sql_file "02-schema/01-drop-tables.sql" "Drop tables"
}

create_tables() {
    execute_sql_file "02-schema/02-create-tables.sql" "Create tables"
}

create_indexes() {
    execute_sql_file "02-schema/03-create-indexes.sql" "Create indexes"
}

rebuild_schema() {
    echo -e "${PURPLE}🏗️ Rebuilding complete schema...${NC}"
    drop_tables
    create_tables
    create_indexes
    echo -e "${GREEN}✅ Schema rebuild completed${NC}"
}

# Security Commands
drop_security() {
    execute_sql_file "03-security/01-drop-users-roles.sql" "Drop users and roles"
}

create_roles() {
    execute_sql_file "03-security/02-create-roles.sql" "Create roles"
}

create_users() {
    execute_sql_file "03-security/03-create-users.sql" "Create users"
}

set_permissions() {
    execute_sql_file "03-security/04-set-permissions.sql" "Set permissions"
}

rebuild_security() {
    echo -e "${PURPLE}🛡️ Rebuilding complete security...${NC}"
    drop_security
    create_roles
    create_users
    set_permissions
    echo -e "${GREEN}✅ Security rebuild completed${NC}"
}

# Backup Commands
drop_backup_devices() {
    execute_sql_file "04-backup/01-drop-backup-devices.sql" "Drop backup devices"
}

create_backup_devices() {
    execute_sql_file "04-backup/02-create-backup-devices.sql" "Create backup devices"
}

# Data Commands
clear_data() {
    execute_sql_file "05-data/01-clear-data.sql" "Clear data"
}

seed_basic() {
    execute_sql_file "05-data/02-seed-basic-data.sql" "Seed basic data"
}

reseed_data() {
    echo -e "${PURPLE}🌱 Reseeding data...${NC}"
    clear_data
    seed_basic
    echo -e "${GREEN}✅ Data reseeding completed${NC}"
}

# Full Operations
full_setup() {
    print_header
    echo -e "${PURPLE}🚀 Starting full database setup...${NC}"
    
    init_database
    create_logins
    create_tables
    create_indexes
    create_roles
    create_users
    set_permissions
    create_backup_devices
    seed_basic
    
    echo -e "${GREEN}🎉 Full setup completed successfully!${NC}"
}

full_reset() {
    print_header
    echo -e "${PURPLE}🔄 Starting full database reset...${NC}"
    
    # Confirm destructive operation
    read -p "⚠️  This will completely reset the database. Continue? (yes/no): " confirm
    if [[ $confirm != "yes" ]]; then
        echo "Operation cancelled"
        exit 0
    fi
    
    full_setup
    echo -e "${GREEN}🎉 Full reset completed successfully!${NC}"
}

dev_reset() {
    print_header
    echo -e "${PURPLE}⚡ Quick development reset...${NC}"
    
    rebuild_schema
    reseed_data
    
    echo -e "${GREEN}⚡ Development reset completed!${NC}"
}

# Utility Commands
show_status() {
    print_header
    echo -e "${CYAN}📊 Database Status${NC}"
    
    docker exec $DB_CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
        -S localhost \
        -U sa \
        -P "$MSSQL_SA_PASSWORD" \
        -C \
        -d "$DB_NAME" \
        -Q "
        SELECT 'Database' as Component, '$DB_NAME' as Name, 'Active' as Status
        UNION ALL
        SELECT 'Tables', CAST(COUNT(*) AS VARCHAR), 'Created'
        FROM sys.tables
        WHERE name IN ('KHOA', 'LOP', 'SINHVIEN', 'MONHOC', 'GIANGVIEN', 'LOPTINCHI', 'DANGKY')
        UNION ALL
        SELECT 'Users', CAST(COUNT(*) AS VARCHAR), 'Created'
        FROM sys.database_principals
        WHERE name IN ('qldsv_app', 'pgv_user', 'khoa_user', 'sv_user')
        UNION ALL
        SELECT 'Backup Devices', CAST(COUNT(*) AS VARCHAR), 'Created'
        FROM sys.backup_devices
        WHERE name LIKE 'DEVICE_QLDSV_HTC%'
        " \
        -h -1 -W
}

test_connections() {
    print_header
    echo -e "${CYAN}🔐 Testing database connections...${NC}"
    
    # Test each user individually
    test_user_connection "sa" "$MSSQL_SA_PASSWORD"
    test_user_connection "qldsv_app" "$MSSQL_APP_PASSWORD"
    test_user_connection "pgv_user" "$MSSQL_PGV_PASSWORD"
    test_user_connection "khoa_user" "$MSSQL_KHOA_PASSWORD"
    test_user_connection "sv" "$MSSQL_SV_PASSWORD"
}

test_user_connection() {
    local username="$1"
    local password="$2"
    
    echo -e "${YELLOW}Testing $username...${NC}"
    
    if docker exec $DB_CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
        -S localhost \
        -U "$username" \
        -P "$password" \
        -C \
        -d "$DB_NAME" \
        -Q "SELECT 'Connection successful for $username' as Status" \
        -h -1 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $username connection OK${NC}"
    else
        echo -e "${RED}❌ $username connection FAILED${NC}"
    fi
}

# Main script logic
case "${1:-help}" in
    # Foundation
    "init-db") init_database ;;
    "create-logins") create_logins ;;
    
    # Schema
    "drop-tables") drop_tables ;;
    "create-tables") create_tables ;;
    "create-indexes") create_indexes ;;
    "rebuild-schema") rebuild_schema ;;
    
    # Security
    "drop-security") drop_security ;;
    "create-roles") create_roles ;;
    "create-users") create_users ;;
    "set-permissions") set_permissions ;;
    "rebuild-security") rebuild_security ;;
    
    # Backup
    "drop-backup-devices") drop_backup_devices ;;
    "create-backup-devices") create_backup_devices ;;
    
    # Data
    "clear-data") clear_data ;;
    "seed-basic") seed_basic ;;
    "reseed") reseed_data ;;
    
    # Full Operations
    "full-setup") full_setup ;;
    "full-reset") full_reset ;;
    "dev-reset") dev_reset ;;
    
    # Utilities
    "status") show_status ;;
    "test-connections") test_connections ;;
    
    "help"|"--help"|"-h")
        print_usage
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        print_usage
        exit 1
        ;;
esac 