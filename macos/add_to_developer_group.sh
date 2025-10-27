#!/bin/bash
set -euo pipefail

# Add yourself to the _developer user group to avoid the annoying pop-up when starting any IDE debugger session asking for "Developer Tools Access"

USERNAME=$(whoami)
sudo dscl . append /Groups/_developer GroupMembership "$USERNAME"
DevToolsSecurity -enable