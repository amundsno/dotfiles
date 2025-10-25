#!/bin/bash
set -euo pipefail

APP_ID="com.googlecode.iterm2"
SRC_DIR="$(dirname "$0")/Library/Preferences"

echo "📥 Importing $APP_ID preferences..."
plutil -convert binary1 "$SRC_DIR/$APP_ID.plist.xml" -o "$SRC_DIR/$APP_ID.plist"
defaults import "$APP_ID" "$SRC_DIR/$APP_ID.plist"
rm "$SRC_DIR/$APP_ID.plist"