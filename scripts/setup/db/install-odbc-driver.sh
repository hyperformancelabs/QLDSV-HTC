#!/bin/bash
set -e

# =============================================
#  Install / Verify Microsoft ODBC Driver 17/18
#  for SQL Server (macOS & Linux)
#  Using the project unified virtual-env
# =============================================

# Source utilities
source scripts/utils/check-root-dir.sh
source scripts/utils/config-loader.sh
check_root_dir || exit 1

#-------------- CLI flags ---------------------
SKIP_TEST=0
for arg in "$@"; do
    case $arg in
        --skip-test)
      SKIP_TEST=1; shift ;;
    esac
done

#-------------- Environment -------------------
load_env_file

# Ensure unified virtual-env exists
if [ ! -f "backend/venv/bin/python" ]; then
  echo "❌ backend/venv not found. Run ./scripts/setup/be/setup-backend.sh first."; exit 1
fi
PYTHON=backend/venv/bin/python
PIP=backend/venv/bin/pip

# Ensure pyodbc available (needed for driver detection)
$PIP install --quiet --upgrade pip
$PIP install --quiet pyodbc

#-------------- Helper: has_driver ------------
has_driver() {
  $PYTHON - << 'PY' 2>/dev/null || true
import sys
try:
    import pyodbc
    found = any('ODBC Driver 17' in d or 'ODBC Driver 18' in d for d in pyodbc.drivers())
    print('YES' if found else 'NO')
except Exception:
    print('NO')
PY
}

DRIVER_PRESENT=$(has_driver)

if [ "$DRIVER_PRESENT" == "YES" ]; then
  echo "✅ Microsoft ODBC Driver 17/18 already installed."
  [ $SKIP_TEST -eq 0 ] && $PYTHON - << 'PY'
import pyodbc, pprint; pprint.pp(pyodbc.drivers())
PY
  exit 0
fi

#-------------- Install when missing ----------
OS=$(uname)
ARCH=$(uname -m)

echo "🔄 ODBC Driver not found – proceeding with installation..."

case $OS in
  Darwin)
    # macOS (Intel & Apple Silicon)
    if ! command -v brew >/dev/null 2>&1; then
      echo "❌ Homebrew required but not found. Install from https://brew.sh"; exit 1
    fi
    echo "🔧 Installing via Homebrew (msodbcsql18 + unixodbc)"
    brew tap microsoft/mssql-release >/dev/null 2>&1 || true
    printf "YES\n" | HOMEBREW_NO_ENV_FILTERING=1 ACCEPT_EULA=Y brew install msodbcsql18 unixodbc
    ;;
  Linux)
    echo "⚠️  Automatic install on Linux is distro-specific. Follow Microsoft docs:"
    echo "    https://learn.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server"
    exit 1
    ;;
  *)
    echo "⚠️  Unsupported platform for automatic install. Please install driver manually."
        exit 1
        ;;
esac

#-------------- Post-install check ------------
if [ "$(has_driver)" != "YES" ]; then
  echo "❌ Driver installation attempted but still not detected. Check logs above."; exit 1
fi

echo "🎉 ODBC Driver successfully installed & detected!"
if [ $SKIP_TEST -eq 0 ]; then
  echo "🔎 Available drivers:"; $PYTHON - << 'PY'
import pyodbc, pprint; pprint.pp(pyodbc.drivers())
PY
fi

echo "✅ Done. You can now connect using pyodbc or SQLAlchemy." 