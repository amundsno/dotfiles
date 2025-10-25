#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

echo "Installing packages..."
brew bundle --file="$SCRIPT_DIR/.Brewfile"