#!/bin/bash
set -e

# Source the root directory check and config loader
source scripts/utils/check-root-dir.sh
source scripts/utils/config-loader.sh

check_root_dir || exit 1

# Load environment variables
load_env_file

# Parse arguments
if [ "$1" == "--full-default-setup" ]; then
    echo "🔄 Running full default setup before starting database..."
    ./scripts/setup/db/setup-database.sh --default
fi

# Start the database
echo "🚀 Starting database..."
./scripts/utils/db/start-db.sh

echo "✅ Database started successfully!"
echo ""
echo "📊 Database Information:"
echo "   - Host: $DB_HOST"
echo "   - Port: $DB_PORT"
echo "   - Name: $DB_NAME"
echo ""
echo "🔍 To check database health: ./scripts/utils/db/db-health-check.sh" 