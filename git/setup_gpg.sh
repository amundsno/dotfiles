#!/bin/bash
set -euo pipefail

# Check for required dependencies
command -v gpg >/dev/null 2>&1 || { echo "❌ Error: gpg is required but not installed." >&2; exit 1; }
command -v gum >/dev/null 2>&1 || { echo "❌ Error: gum is required but not installed." >&2; exit 1; }
command -v rg >/dev/null 2>&1 || { echo "❌ Error: ripgrep (rg) is required but not installed." >&2; exit 1; }

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
LOG_FILE="$SCRIPT_DIR/setup_gpg.log"

# Initialize log file with timestamp
{
    echo "==========================================="
    echo "GPG key generation started: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "==========================================="
} >> "$LOG_FILE"

log() {
    # Write to terminal
    gum log -t "timeonly" "$@"

    # Write to log file
    gum log -t "datetime" -o "$LOG_FILE" "$@"
}

# If no secret key exist, generate a new one
log -l info "🔍 Looking for existing secret GPG keys..."
if ! gpg --list-secret-keys -q | rg "sec" -q; then
    log -l info "🤷 No existing secret keys found"
    log -l info "⚙️ Generating GPG key (use defaults)"
    log -l warn "🫵 Have a passphrase ready before continuing to avoid the generation process timing out"
    echo ""
    read -p "Press Enter to continue..."

    gpg --full-generate-key
    log -l info "✅ Key generated"
else
    log -l info "🎯 Existing secret keys detected"
fi

log -l info "🔑 Your secret keys:"
gpg --list-secret-keys --keyid-format=long
KEYIDS=$(gpg --list-secret-keys --keyid-format=long | rg -or '$1' "sec.*\/(.*?)\s")

if [[ -z "$KEYIDS" ]]; then
    log -l error "❌ No GPG keys found after generation attempt"
    exit 1
fi

SELECTED_KEY=$(echo "$KEYIDS" | gum choose --header "Choose GPG key:")
{
    echo ""
    echo "[user]"
    echo "    signingkey = $SELECTED_KEY"
} >> ~/.gitconfig.local

log -l info "✅ Added '$SELECTED_KEY' as GPG signing key (~/.gitconfig.local)"

log -l info "🫵 Go to GitHub > Profile > Settings > SSH and GPG keys > New GPG key"
echo ""
read -p "Press Enter to copy public key to clipboard..."

if gpg --armor --export "$SELECTED_KEY" | pbcopy; then
    log -l info "📋 Public key copied to clipboard. Paste in GitHub and save."
else
    log -l error "❌ Failed to copy public key to clipboard"
    log -l info "🔑 Here's your public key (copy manually):"
    echo ""
    gpg --armor --export "$SELECTED_KEY"
fi

{
    echo "==========================================="
    echo "GPG setup completed: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Selected key: $SELECTED_KEY"
    echo "==========================================="
} >> "$LOG_FILE"

log -l info "✅ GPG setup completed successfully!"
log -l info "📝 Log saved to: $LOG_FILE"