#!/bin/bash
set -e

# Check ODBC driver availability and simple connection test
source scripts/utils/check-root-dir.sh
source scripts/utils/config-loader.sh
check_root_dir || exit 1

# Load env (need DB_*, MSSQL_SA_PASSWORD)
load_env_file

echo "🔍 [check-odbc] Verifying Microsoft ODBC Driver & connectivity..."

if [ ! -f "backend/venv/bin/python" ]; then
  echo "⚠️  backend/venv not found – skipping ODBC test."
  exit 0
fi

PYTHON_CMD="backend/venv/bin/python"

ODBC_STATUS=$($PYTHON_CMD - << 'PY' 2>/dev/null || echo "SCRIPT_ERROR"
import os, sys
try:
    import pyodbc
except ImportError:
    print('PYODBC_MISSING'); sys.exit()

drivers = [d for d in pyodbc.drivers() if d.startswith('ODBC Driver')]
if not drivers:
    print('DRIVER_MISSING'); sys.exit()

try:
    conn = pyodbc.connect(f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={os.environ['DB_HOST']},{os.environ['DB_PORT']};UID=sa;PWD={os.environ['MSSQL_SA_PASSWORD']};TrustServerCertificate=yes;", timeout=5)
    conn.close()
    print('SUCCESS')
except Exception as e:
    print('CONNECTION_ERROR')
PY)

case $ODBC_STATUS in
  "PYODBC_MISSING")
    echo "⚠️ pyodbc not installed in backend env. Run: backend/venv/bin/pip install pyodbc";;
  "DRIVER_MISSING")
    echo "⚠️ Microsoft ODBC driver not detected. Run setup script: ./scripts/setup/db/install-odbc-driver.sh";;
  "CONNECTION_ERROR")
    echo "⚠️ Driver installed but cannot connect. Check DB container & credentials.";;
  "SUCCESS")
    echo "✅ ODBC driver installed & connection successful.";;
  *)
    echo "ℹ️ ODBC test skipped or unknown result ($ODBC_STATUS).";;
esac 