#!/bin/bash
set -e

# Delete backend environment (venv + logs)
source scripts/utils/check-root-dir.sh
check_root_dir || exit 1

echo "🗑️ [delete-backend] Removing backend environment (venv & logs)..."
rm -rf backend/venv backend/logs || true

echo "✅ Backend environment deleted." 