#!/bin/bash
set -e

# Ensure dockutil is installed
if ! command -v dockutil >/dev/null 2>&1; then
  echo "Installing dockutil..."
  brew install dockutil
fi

# Clear existing Dock
echo "Clearing Dock..."
dockutil --remove all --no-restart
dockutil --remove "Launchpad"
dockutil --remove "Messages"
dockutil --remove "Mail"
dockutil --remove "Maps"
dockutil --remove "Photos"
dockutil --remove "FaceTime"
dockutil --remove "Calendar"
dockutil --remove "Contacts"
dockutil --remove "Reminders"
dockutil --remove "Notes"
dockutil --remove "Freeform"
dockutil --remove "TV"
dockutil --remove "Music"
dockutil --remove "Keynote"
dockutil --remove "Numbers"
dockutil --remove "Pages"
dockutil --remove "App Store"
dockutil --remove "System Settings"

# Add preferred apps
echo "Adding preferred apps..."
dockutil --add "/Applications/iTerm.app" --no-restart
dockutil --add "/Applications/Visual Studio Code.app" --no-restart
dockutil --add "/Applications/Obsidian.app" --no-restart

# Other Dock configurations
defaults write com.apple.dock autohide -bool true


# Restart Dock
killall Dock

