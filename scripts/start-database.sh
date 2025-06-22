#!/bin/bash
set -e

# Source the root directory check and config loader
source scripts/utils/check-root-dir.sh
source scripts/utils/config-loader.sh

check_root_dir || exit 1

# Load environment variables
load_env_file

# Parse arguments
# Flags
SETUP=0       # --setup : run initial setup before start
RESET_DB=0    # --reset : reset (drop) database then start fresh
DELETE_DB=0   # --delete: delete database container & exit

for arg in "$@"; do
    case $arg in
        --setup)
            SETUP=1
            shift
            ;;
        --reset)
            RESET_DB=1
            shift
            ;;
        --delete)
            DELETE_DB=1
            shift
            ;;
        *)
            # Unknown option
            ;;
    esac
done

# Reset database if requested
if [ $RESET_DB -eq 1 ]; then
    echo "🔄 Resetting database..."
    if [ -f "scripts/utils/db/delete-db.sh" ]; then
        ./scripts/utils/db/delete-db.sh --force
    else
        echo "⚠️ Database delete script not found. Cannot reset database."
        exit 1
    fi
fi

# NEW: Delete database (no restart) if requested
if [ $DELETE_DB -eq 1 ]; then
    echo "🗑️ Deleting database (container & volumes)..."
    if [ -f "scripts/utils/db/delete-db.sh" ]; then
        ./scripts/utils/db/delete-db.sh --force
        echo "✅ Database deleted successfully. Exiting..."
        exit 0
    else
        echo "⚠️ Database delete script not found. Cannot delete database."
        exit 1
    fi
fi

# Run full setup if requested
if [ $SETUP -eq 1 ]; then
    echo "🔄 Running setup before starting database..."
    if [ -f "scripts/setup/db/setup-database.sh" ]; then
        ./scripts/setup/db/setup-database.sh
    else
        echo "⚠️ Database setup script not found. Continuing with start..."
    fi
fi

# Start the database
echo "🚀 Starting database..."
./scripts/utils/db/start-db.sh

# Optional: ODBC driver check
if [ -f "scripts/utils/db/check-odbc.sh" ]; then
    scripts/utils/db/check-odbc.sh || true
fi

# Run health check
if [ -f "scripts/utils/db/db-health-check.sh" ]; then
    echo "🔍 Running database health check..."
    ./scripts/utils/db/db-health-check.sh
fi

echo "✅ Database started successfully!"
echo ""
echo "📊 Database Information:"
echo "   - Host: $DB_HOST"
echo "   - Port: $DB_PORT"
echo "   - Database: $DB_NAME"
echo ""
echo "🔍 To check database status, run: ./scripts/utils/db/db-health-check.sh"
echo "🔧 For initial setup, run: ./scripts/start-database.sh --setup"
echo "♻️  To reset database, run:    ./scripts/start-database.sh --reset"
echo "🗑️  To delete database, run:   ./scripts/start-database.sh --delete" 