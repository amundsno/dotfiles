# Dotfiles

Automated setup for a new macOS development environment using Stow.

## Quick Start
```sh
# Clone and run
git clone --recursive https://github.com/amundsno/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap-macos.sh
```

## What gets configured
- System settings
- Package management
- App configuration

## Manual steps after bootstrap
1. Open (and sign in to) apps
2. Configure Github GPG and SSH

## Managing plugins for Oh-My-Zsh
```sh
# Add a new plugin
git submodule add $GITHUB_REPO zsh/.oh-my-zsh-custom/plugins/$REPO_NAME
git commit -m "Add $REPO_NAME plugin for oh-my-zsh"

# Remove a plugin
git submodule deinit -f zsh/.oh-my-zsh-custom/plugins/$REPO_NAME
git rm -f zsh/.oh-my-zsh-custom/plugins/$REPO_NAME
git commit -m "Remove $REPO_NAME plugin for oh-my-zsh"
```

# TODO
## Installing Git Hooks
Write a script (with gum) for installing and clearing custom hooks to a git repository.
Use stow for linking, so that changes to the hooks are reflected in all repos.
If there are existing hooks, rename it to *.local and include it at the start/end of the relevant hook