#!/bin/bash

# Helper functions for dotfiles scripts

# Check for required command dependencies
# Usage: require_commands cmd1 cmd2 cmd3 ...
# Returns: 0 if all commands exist, 1 if any are missing
require_commands() {
    local missing_deps=()
    
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "❌ Error: The following required commands are not installed:" >&2
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep" >&2
        done
        return 1
    fi
    
    return 0
}