#!/bin/bash
set -euo pipefail

APP_ID="com.googlecode.iterm2"
DEST_DIR="$(dirname "$0")/Library/Preferences"

echo "💾 Exporting $APP_ID preferences"
defaults export "$APP_ID" "$DEST_DIR/$APP_ID.plist.xml"
plutil -convert xml1 "$DEST_DIR/$APP_ID.plist.xml"