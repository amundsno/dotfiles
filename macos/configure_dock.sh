#!/bin/bash
set -euo pipefail

# Ensure dockutil is installed
if ! command -v dockutil >/dev/null 2>&1; then
  echo "Installing dockutil..."
  brew install dockutil
fi

# Wipe ALL (default) app icons from the Dock
# defaults write com.apple.dock persistent-apps -array


# Clear existing Dock
echo "Clearing Dock..."
dockutil --remove "Launchpad" --no-restart
dockutil --remove "Messages" --no-restart
dockutil --remove "Mail" --no-restart
dockutil --remove "Maps" --no-restart
dockutil --remove "Photos" --no-restart
dockutil --remove "FaceTime" --no-restart
dockutil --remove "Calendar" --no-restart
dockutil --remove "Contacts" --no-restart
dockutil --remove "Reminders" --no-restart
dockutil --remove "Notes" --no-restart
dockutil --remove "Freeform" --no-restart
dockutil --remove "TV" --no-restart
dockutil --remove "Music" --no-restart
dockutil --remove "Keynote" --no-restart
dockutil --remove "Numbers" --no-restart
dockutil --remove "Pages" --no-restart
dockutil --remove "App Store" --no-restart
dockutil --remove "System Settings" --no-restart

# Add preferred apps
echo "Adding preferred apps..."
dockutil --add "/Applications/iTerm.app" --no-restart
dockutil --add "/Applications/Visual Studio Code.app" --no-restart
dockutil --add "/Applications/Obsidian.app" --no-restart

# Restart Dock
killall Dock

