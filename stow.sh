#!/bin/bash
set -euo pipefail

# Define packages to stow
PACKAGES=(
    "zsh"
)

# Suffix to add to conflicting files
BACKUP_SUFFIX=".local"


DOTFILES_DIR=$(cd "$(dirname "$0")" && pwd)
TARGET=$HOME
LOG_FILE="$DOTFILES_DIR/stow.log"

log() {
    # Write to terminal
    gum log -t "timeonly" $*

    # Write to log file
    gum log -t "datetime" -o "$LOG_FILE" $*
}

# Checks for conflicts with existing local files before stowing.
# If a conflicting file exists, give it a suffix to avoid collision.
safe_stow() {
    PACKAGE=$1
    log -l info "📦 Stowing package: '$PACKAGE'"

    conflicts=$(stow --target="$TARGET" --no --verbose "$PACKAGE" 2>&1 | grep "cannot stow" || true)

    if [[ -n "$conflicts" ]]; then
        log -l warn "⚠️ Conflicts detected:"
        echo "$conflicts" | tee -a "$LOG_FILE"
        
        while read -r line; do
            
            conflicting_file=$(echo "$line" | rg -or '$1' "existing target (.*) since")
            
            # If $conflicting_file is an empty string
            [[ -z "$conflicting_file" ]] && continue

            src="$TARGET/$conflicting_file"
            # If $src is a file (-f) and not a symbolic link (-L)
            if [[  -f "$src" && ! -L "$src" ]]; then
                mv "$src" "$src$BACKUP_SUFFIX"
                log -l warn "   ✏️ Moved '$src' ➡︎ '$src$BACKUP_SUFFIX'"
            fi
        done <<< "$conflicts"

    else
        log -l info "✅ No conflicts detected"
    fi
    
    stow --target="$TARGET" "$PACKAGE"
    log -l info "🔗 Package '$PACKAGE' stowed successfully"
}

# Initialize log file with timestamp
{
    echo "==========================================="
    echo "Stow execution started: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "==========================================="
} >> "$LOG_FILE"


# Stow packages
log -l info "🏃 Running stow.sh to stow packages"

# Ensure all submodules are fetched
log -l info "🌐 Updating all git submodules"
git submodule update --init --recursive
log -l info "✅ Git submodules updated successfully"

for package in "${PACKAGES[@]}"; do
    safe_stow "$package"
done