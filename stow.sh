#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR"

source "./helpers.sh"

# Check for required dependencies
require_commands stow gum rg git

# Define packages to stow
PACKAGES=(
    "stow-config"
    "macos"
    "zsh"
    "git"
    "iterm2"
    "vim"
)

# Suffix to add to conflicting files
BACKUP_SUFFIX=".local"


DOTFILES_DIR="$SCRIPT_DIR"
TARGET=$HOME
LOG_FILE="$DOTFILES_DIR/stow.sh.log"

log() {
    # Write to terminal
    gum log -t "timeonly" "$@"

    # Write to log file
    gum log -t "datetime" -o "$LOG_FILE" "$@"
}

# Checks for conflicts with existing local files before stowing.
# If a conflicting file exists, give it a suffix to avoid collision.
safe_stow() {
    local PACKAGE=$1
    
    # Validate that the package directory exists
    if [[ ! -d "$DOTFILES_DIR/$PACKAGE" ]]; then
        log -l error "❌ Package directory '$PACKAGE' does not exist"
        return 1
    fi
    
    log -l info "📦 Stowing package: '$PACKAGE'"

    conflicts=$(stow --target="$TARGET" --no --verbose "$PACKAGE" 2>&1 | grep "cannot stow" || true)

    if [[ -n "$conflicts" ]]; then
        log -l warn "⚠️ Conflicts detected:"
        echo "$conflicts" | tee -a "$LOG_FILE"
        
        while read -r line; do
            conflicting_file=$(echo "$line" | rg -or '$1' "existing target (.*) since" || true)
            
            # If $conflicting_file is an empty string, skip this line
            [[ -z "$conflicting_file" ]] && continue

            local src="$TARGET/$conflicting_file"
            
            # If $src is a file (-f) and not a symbolic link (-L)
            if [[ -f "$src" && ! -L "$src" ]]; then
                
                # Check if the backup already exists
                if [[ -f "$src$BACKUP_SUFFIX" ]]; then
                    log -l warn "   ⚠️ Backup '$src$BACKUP_SUFFIX' already exists, skipping"
                    continue
                fi
                
                if mv "$src" "$src$BACKUP_SUFFIX" 2>/dev/null; then
                    log -l warn "   ✏️ Moved '$src' ➡︎ '$src$BACKUP_SUFFIX'"
                else
                    log -l error "   ❌ Failed to move '$src'"
                    return 1
                fi
            elif [[ -d "$src" && ! -L "$src" ]]; then
                log -l warn "   📁 Directory conflict: '$src' (manual resolution required)"
            fi
        done <<< "$conflicts"

    else
        log -l info "😌 No conflicts detected"
    fi
    
    if stow --target="$TARGET" "$PACKAGE" 2>/dev/null; then
        log -l info "🔗 Package '$PACKAGE' stowed successfully"
    else
        log -l error "❌ Failed to stow package '$PACKAGE'"
        return 1
    fi
}

# Initialize log file with timestamp
{
    echo "==========================================="
    echo "Stow execution started: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "==========================================="
} >> "$LOG_FILE"


# Change to dotfiles directory to ensure relative paths work correctly
cd "$DOTFILES_DIR" || {
    log -l error "❌ Failed to change to dotfiles directory: $DOTFILES_DIR"
    exit 1
}

# Stow packages
log -l info "🏃 Running stow.sh to stow packages"

# Ensure all submodules are fetched (only if we're in a git repository)
if [[ -d .git ]]; then
    log -l info "🌐 Updating all git submodules"
    if git submodule update --init --recursive; then
        log -l info "✅ Git submodules updated successfully"
    else
        log -l warn "⚠️ Git submodule update failed, continuing anyway"
    fi
else
    log -l info "📁 Not a git repository, skipping submodule update"
fi

# Track success/failure of package installations
failed_packages=()
successful_packages=()

for package in "${PACKAGES[@]}"; do
    if safe_stow "$package"; then
        successful_packages+=("$package")
    else
        failed_packages+=("$package")
        log -l error "❌ Failed to stow package: $package"
    fi
done

# Final summary
{
    echo "==========================================="
    echo "Stow execution completed: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Successful packages: ${successful_packages[*]:-none}"
    echo "Failed packages: ${failed_packages[*]:-none}"
    echo "==========================================="
} >> "$LOG_FILE"

if [[ ${#failed_packages[@]} -eq 0 ]]; then
    log -l info "✅ All packages stowed successfully!"
else
    log -l error "❌ ${#failed_packages[@]} package(s) failed to stow: ${failed_packages[*]}"
    exit 1
fi

log -l info "📝 Log saved to: $LOG_FILE"