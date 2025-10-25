#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR"

echo "🏃 Running import-plists.sh to import all tracked plist preferences..."

for script in */import.sh; do
    # echo "$script"
    bash "$script"
done
