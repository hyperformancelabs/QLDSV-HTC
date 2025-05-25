#!/bin/bash
set -e

echo "🚀 [initial-setup.sh] QLDSV-HTC Initial Setup..."

# Check if we're in the right directory
if [ ! -f "DESCRIPTION.md" ]; then
    echo "❌ Please run this script from the QLDSV-HTC project root directory"
    exit 1
fi

# Load utilities
source scripts/utils/config-loader.sh

echo "📋 Step 1: Environment Configuration"
if [ ! -f ".env" ]; then
    echo "📄 Creating .env from template..."
    cp .env.example .env
    echo "✏️  Please edit .env file with your specific configurations"
    echo "⚠️  Default passwords should be changed for production!"
else
    echo "✅ .env file already exists"
fi

echo "📋 Step 2: Docker Network Setup"
source scripts/utils/network-setup.sh

echo "📋 Step 3: Database Setup"
chmod +x scripts/database/*.sh
./scripts/database/db-setup.sh

echo "📋 Step 4: Verification"
./scripts/setup/verify-setup.sh

echo "🎉 [initial-setup.sh] Setup completed successfully!"
echo ""
echo "🚀 Quick start commands:"
echo "   ./scripts/service-mgmt.sh start all    # Start full stack"
echo "   ./scripts/service-mgmt.sh start db     # Start database only"
echo "   ./scripts/service-mgmt.sh status       # Check services status"
echo "   ./scripts/database/db-mgmt.sh          # Database management console"