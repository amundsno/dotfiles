#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR"

source "./helpers.sh"

LOG_FILE="$0.log"
log() {
  echo "$@" | tee -a "$LOG_FILE"
}
{
    echo "==========================================="
    echo "MacOS bootstrap started: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "==========================================="
} >> "$LOG_FILE"

log "🚀 Starting macOS bootstrap process..."

# Check macOS version
if [[ "$(uname)" != "Darwin" ]]; then
    log "❌ This bootstrap script is designed for macOS only"
    exit 1
fi

# Check if this looks like a fresh system
if [[ ! -f "$LOG_FILE" ]]; then
    log "📋 Applying system settings..."
    ./macos/apply_system_settings.sh
else
    log "⏭️ Skipping system settings (already applied)"
fi

log "🍺 Setting up Homebrew and packages..."
./macos/install_homebrew.sh
./macos/install_packages.sh

log "🎯 Configuring Dock..."
./macos/configure_dock.sh

log "🔗 Stowing dotfiles..."
./stow.sh

log "⚙️  Importing application preferences..."
./import-plists.sh

log "🔐 Setting up GPG and SSH for Git..."
./git/setup_gpg.sh
./git/setup_ssh.sh

# Mark bootstrap as completed
log "✅ Bootstrap completed successfully!"

{
    echo "==========================================="
    echo "MacOS bootstrap finished: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "==========================================="
} >> "$LOG_FILE"
