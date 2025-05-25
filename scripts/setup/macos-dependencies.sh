#!/bin/bash
set -e

echo "🍎 [macos-dependencies.sh] Setting up macOS dependencies for QLDSV-HTC..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "📦 Installing Docker Desktop..."
if ! command -v docker &> /dev/null; then
    brew install --cask docker
    echo "⚠️  Please start Docker Desktop manually and return to continue..."
    read -p "Press Enter when Docker Desktop is running..."
fi

echo "📦 Installing Azure Data Studio..."
if ! command -v azuredatastudio &> /dev/null; then
    brew install --cask azure-data-studio
fi

echo "📦 Installing Microsoft ODBC Driver..."
if ! odbcinst -q -d | grep -q "ODBC Driver 18 for SQL Server"; then
    brew tap microsoft/mssql-release https://github.com/Microsoft/homebrew-mssql-release
    brew update
    brew install msodbcsql18 mssql-tools18
fi

echo "📦 Installing Additional Tools..."
brew install curl jq wget

echo "✅ [macos-dependencies.sh] All dependencies installed successfully!"
echo "🔗 Next steps:"
echo "   1. Start Docker Desktop if not already running"
echo "   2. Run ./scripts/setup/initial-setup.sh" 