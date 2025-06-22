#!/bin/bash
set -e

source scripts/utils/check-root-dir.sh
check_root_dir || exit 1

echo "♻️ [reset-frontend] Resetting frontend dependencies..."
rm -rf frontend/node_modules frontend/logs || true

# Reinstall dependencies
(cd frontend && npm install)

echo "✅ Frontend environment reset complete." 