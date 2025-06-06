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
echo "🛠️ [setup-backend.sh] Setting up QLDSV-HTC backend ($SETUP_TYPE setup)..."

# Load environment variables
load_env_file

# Change to backend directory
cd backend

# Check if virtual environment exists, if not create it
if [ ! -d "venv" ]; then
    echo "🐍 Creating Python virtual environment..."
    python -m venv venv
    echo "✅ Virtual environment created"
fi

# Activate virtual environment
echo "🔄 Activating virtual environment..."
source venv/bin/activate

# Check if .env file exists, if not create it from example
if [ ! -f ".env" ]; then
    echo "📄 Creating .env file from template..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo "✅ Created .env from .env.example"
    else
        # Create minimal .env file with database connection
        echo "DB_HOST=$DB_HOST" > .env
        echo "DB_PORT=$DB_PORT" >> .env
        echo "DB_NAME=$DB_NAME" >> .env
        echo "DB_USER=$MSSQL_APP_USER" >> .env
        echo "DB_PASSWORD=$MSSQL_APP_PASSWORD" >> .env
        echo "DB_DRIVER=\"$DB_DRIVER\"" >> .env
        echo "✅ Created minimal .env file"
    fi
fi

# Install dependencies
echo "📦 Installing backend dependencies..."
pip install -r requirements.txt

# Create necessary directories if they don't exist
echo "📁 Creating necessary directories..."
mkdir -p logs
mkdir -p app/static

echo "✅ [setup-backend.sh] Backend setup completed successfully!" 