#!/bin/bash
set -e

# =============================================
# QLDSV-HTC Database Management Wrapper
# File: scripts/database/db-mgmt.sh
# Purpose: Wrapper script to call database manager from scripts directory
# =============================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE} QLDSV-HTC Database Management Console${NC}"
    echo -e "${BLUE}================================================${NC}"
}

# Load configuration
source scripts/utils/config-loader.sh
load_global_config

# Check if we're in the right directory
if [ ! -f "DESCRIPTION.md" ]; then
    echo -e "${RED}❌ Please run this script from the QLDSV-HTC project root directory${NC}"
    exit 1
fi

# Check if database manager exists
if [ ! -f "scripts/database/db-manager.sh" ]; then
    echo -e "${RED}❌ Database manager not found at scripts/database/db-manager.sh${NC}"
    exit 1
fi

print_header

# If no arguments provided, show help
if [ $# -eq 0 ]; then
    echo -e "${CYAN}🛠️ Database Management Console${NC}"
    echo ""
    echo "This is a wrapper script that calls the main database manager."
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $0 {command} [options]"
    echo ""
    echo -e "${YELLOW}Quick Commands:${NC}"
    echo "  $0 status           # Show database status"
    echo "  $0 dev-reset        # Quick development reset"
    echo "  $0 reseed           # Refresh test data"
    echo "  $0 test-connections # Test all user connections"
    echo ""
    echo -e "${YELLOW}Full Command List:${NC}"
    ./scripts/database/db-manager.sh help
    exit 0
fi

# Pass all arguments to the database manager
echo -e "${CYAN}🔧 Executing database command: $*${NC}"
./scripts/database/db-manager.sh "$@" 