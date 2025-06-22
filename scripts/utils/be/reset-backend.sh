#!/bin/bash
set -e

source scripts/utils/check-root-dir.sh
check_root_dir || exit 1

echo "♻️ [reset-backend] Resetting backend environment..."
rm -rf backend/venv backend/logs || true

# Recreate environment via setup script
./scripts/setup/be/setup-backend.sh --default

echo "✅ Backend environment reset & ready." 