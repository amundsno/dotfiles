#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR"

source "../helpers.sh"

# Check for required dependencies
require_commands ssh-keygen gum rg

LOG_FILE="./setup_ssh.sh.log"
SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"

# Initialize log file with timestamp
{
    echo "==========================================="
    echo "SSH key generation started: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "==========================================="
} >> "$LOG_FILE"

log() {
    # Write to terminal
    gum log -t "timeonly" "$@"

    # Write to log file
    gum log -t "datetime" -o "$LOG_FILE" "$@"
}

# Ensure .ssh directory exists with correct permissions
if [[ ! -d "$SSH_DIR" ]]; then
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    log -l info "📁 Created ~/.ssh directory"
fi

# Check for existing GitHub SSH keys
log -l info "🔍 Looking for existing GitHub SSH keys..."
GITHUB_KEYS=()
if [[ -d "$SSH_DIR" ]]; then
    while IFS= read -r -d '' file; do
        if [[ "$file" == *"github"* ]] && [[ "$file" != *".pub" ]]; then
            GITHUB_KEYS+=("$(basename "$file")")
        fi
    done < <(find "$SSH_DIR" -name "id_*" -type f -print0 2>/dev/null || true)
fi

# If no GitHub keys exist, generate a new one
if [[ ${#GITHUB_KEYS[@]} -eq 0 ]]; then
    log -l info "🤷 No existing GitHub SSH keys found"
    
    # Get email for the key
    EMAIL=$(gum input --placeholder "Enter your GitHub email address")
    if [[ -z "$EMAIL" ]]; then
        log -l error "❌ Email is required for SSH key generation"
        exit 1
    fi
    
    # Choose key type
    KEY_TYPE=$(gum choose --header "Choose SSH key type:" "ed25519" "rsa")
    
    # Generate key name
    KEY_NAME="id_${KEY_TYPE}_github"
    KEY_PATH="$SSH_DIR/$KEY_NAME"
    
    log -l info "⚙️ Generating SSH key..."
    log -l warn "🫵 You may be prompted for a passphrase (recommended for security)"
    echo ""
    
    if [[ "$KEY_TYPE" == "ed25519" ]]; then
        ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY_PATH"
    else
        ssh-keygen -t rsa -b 4096 -C "$EMAIL" -f "$KEY_PATH"
    fi
    
    # Set correct permissions
    chmod 600 "$KEY_PATH"
    chmod 644 "$KEY_PATH.pub"
    
    log -l info "✅ SSH key generated: $KEY_NAME"
    SELECTED_KEY="$KEY_NAME"
else
    log -l info "🎯 Existing GitHub SSH keys detected"
    log -l info "📋 Available keys:"
    for key in "${GITHUB_KEYS[@]}"; do
        echo "  - $key"
    done
    
    if [[ ${#GITHUB_KEYS[@]} -eq 1 ]]; then
        SELECTED_KEY="${GITHUB_KEYS[0]}"
        log -l info "🔄 Using existing key: $SELECTED_KEY"
    else
        SELECTED_KEY=$(printf '%s\n' "${GITHUB_KEYS[@]}" | gum choose --header "Choose SSH key:")
    fi
fi

SELECTED_KEY_PATH="$SSH_DIR/$SELECTED_KEY"

# Add to SSH agent
log -l info "🔗 Adding key to SSH agent..."
eval "$(ssh-agent -s)" > /dev/null
ssh-add "$SELECTED_KEY_PATH"
log -l info "✅ Key added to SSH agent"

# Update SSH config for GitHub
log -l info "⚙️ Updating SSH config..."
GITHUB_CONFIG="
# GitHub configuration
Host github.com
    HostName github.com
    User git
    IdentityFile $SELECTED_KEY_PATH
    IdentitiesOnly yes
"

if [[ -f "$SSH_CONFIG" ]]; then
    if ! rg -q "Host github.com" "$SSH_CONFIG"; then
        echo "$GITHUB_CONFIG" >> "$SSH_CONFIG"
        log -l info "✅ Added GitHub config to ~/.ssh/config"
    else
        log -l info "🔄 GitHub config already exists in ~/.ssh/config"
    fi
else
    echo "$GITHUB_CONFIG" > "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
    log -l info "✅ Created ~/.ssh/config with GitHub configuration"
fi

log -l info "🫵 Go to GitHub > Profile > Settings > SSH and GPG keys > New SSH key"
echo ""
read -p "Press Enter to copy public key to clipboard..."

if cat "$SELECTED_KEY_PATH.pub" | pbcopy; then
    log -l info "📋 Public key copied to clipboard. Paste in GitHub and save."
else
    log -l error "❌ Failed to copy public key to clipboard"
    log -l info "🔑 Here's your public key (copy manually):"
    echo ""
    cat "$SELECTED_KEY_PATH.pub"
fi

# Test GitHub connection
echo ""
log -l info "🧪 Testing GitHub SSH connection..."
echo ""
read -p "Press Enter to test connection..."

# Capture both stdout and stderr, and check the exit code
SSH_OUTPUT=$(ssh -T git@github.com 2>&1 || true)
if echo "$SSH_OUTPUT" | rg -q "successfully authenticated"; then
    log -l info "✅ GitHub SSH connection successful!"
else
    log -l warn "⚠️ GitHub SSH connection test inconclusive"
    log -l info "💡 SSH output: $SSH_OUTPUT"
    log -l info "💡 After adding the key to GitHub, test with: ssh -T git@github.com"
fi

{
    echo "==========================================="
    echo "SSH setup completed: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Selected key: $SELECTED_KEY"
    echo "Key path: $SELECTED_KEY_PATH"
    echo "==========================================="
} >> "$LOG_FILE"

log -l info "✅ SSH setup completed successfully!"
log -l info "📝 Log saved to: $LOG_FILE"
log -l info "💡 To clone repos with SSH: git clone git@github.com:username/repo.git"