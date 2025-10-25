#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR"

echo "🏃 Running export-plists.sh to export all tracked plist preferences..."

for script in */export.sh; do
    # echo "$script"
    bash "$script"
done
