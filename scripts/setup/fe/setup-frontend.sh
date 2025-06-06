#!/bin/bash
set -e

# Source the root directory check and config loader
source scripts/utils/check-root-dir.sh
source scripts/utils/config-loader.sh

check_root_dir || exit 1

# Parse arguments
SETUP_TYPE="default"
if [ "$1" == "--default" ]; then
    SETUP_TYPE="default"
fi

# Main script
echo "🛠️ [setup-frontend.sh] Setting up QLDSV-HTC frontend ($SETUP_TYPE setup)..."

# Load environment variables
load_env_file

# Change to frontend directory
cd frontend

# Check if .env file exists, if not create it from example
if [ ! -f ".env" ]; then
    echo "📄 Creating .env file from template..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo "✅ Created .env from .env.example"
    else
        # Create minimal .env file with proper quoting
        echo "VITE_API_URL=\"$BACKEND_API_URL\"" > .env
        echo "VITE_APP_NAME=\"QLDSV-HTC\"" >> .env
        echo "✅ Created minimal .env file"
    fi
fi

# Install dependencies
echo "📦 Installing frontend dependencies..."
npm install

# Build the frontend (optional for development)
if [ "$SETUP_TYPE" != "default" ]; then
    echo "🏗️ Building frontend..."
    npm run build
fi

echo "✅ [setup-frontend.sh] Frontend setup completed successfully!" 