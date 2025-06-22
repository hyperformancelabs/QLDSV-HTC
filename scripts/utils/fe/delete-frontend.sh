#!/bin/bash
set -e

source scripts/utils/check-root-dir.sh
check_root_dir || exit 1

echo "🗑️ [delete-frontend] Removing frontend node_modules & logs..."
rm -rf frontend/node_modules frontend/logs || true

echo "✅ Frontend environment deleted." 