<<<<<<< HEAD
#!/usr/bin/env zsh
=======
#!/opt/homebrew/bin/zsh
>>>>>>> origin/develop
# Context-Aware Configuration: Dotfiles Management
# Automatically loaded when entering dotfiles directories

# Set dotfiles environment
export PROJECT_TYPE="dotfiles"
export DOTFILES_DIR="$PWD"

# Dotfiles management aliases
alias dots="cd $DOTFILES_DIR"
alias dotfiles="cd $DOTFILES_DIR"
alias reload="source ~/.zshrc"
alias edit-zsh="$EDITOR $ZDOTDIR/.zshrc"
alias edit-aliases="$EDITOR $ZDOTDIR/.zsh_aliases"

# Configuration editing shortcuts
alias zshrc="$EDITOR $ZDOTDIR/.zshrc"
alias zshenv="$EDITOR $ZDOTDIR/.zshenv"
alias aliases="$EDITOR $ZDOTDIR/.zsh_aliases"

# Dotfiles 040-testing and validation
if [[ -f "$PWD/dot-config/zsh/tests/test-config-validation.zsh" ]]; then
    alias test-config="$PWD/dot-config/zsh/tests/test-config-validation.zsh"
fi

if [[ -f "$PWD/dot-config/zsh/tests/test-startup-time.zsh" ]]; then
    alias test-performance="$PWD/dot-config/zsh/tests/test-startup-time.zsh"
fi

if [[ -f "$PWD/dot-config/zsh/tests/test-security-audit.zsh" ]]; then
    alias test-security="$PWD/dot-config/zsh/tests/test-security-audit.zsh"
fi

if [[ -f "$PWD/dot-config/zsh/run-integration-tests" ]]; then
    alias test-integration="$PWD/dot-config/zsh/run-integration-tests"
fi

# Security and maintenance shortcuts
if [[ -f "$PWD/dot-config/zsh/weekly-security-maintenance" ]]; then
    alias security-maintenance="$PWD/dot-config/zsh/weekly-security-maintenance"
fi

if [[ -f "$PWD/dot-config/zsh/setup-weekly-cron" ]]; then
    alias setup-cron="$PWD/dot-config/zsh/setup-weekly-cron"
fi

# Performance profiling
if [[ -f "$PWD/dot-config/zsh/zsh-profile-startup" ]]; then
    alias profile="$PWD/dot-config/zsh/zsh-profile-startup"
    alias profile-fast="$PWD/dot-config/zsh/zsh-profile-startup -i 3 -w 1"
fi

# Git operations for dotfiles
alias dots-status="git status"
alias dots-add="git add ."
alias dots-commit="git commit -m"
alias dots-push="git push"
alias dots-pull="git pull"
alias dots-sync="git add . && git commit -m 'Update dotfiles' && git push"

# Backup and restore
<<<<<<< HEAD
alias backup-zsh="cp -r $ZDOTDIR $ZDOTDIR.backup-\$(command -v date >/dev/null && date +%Y%m%d-%H%M%S || zf::debug 'backup')"
alias list-backups="ls -la $ZDOTDIR.backup-* 2>/dev/null || zf::debug 'No backups found'"

# Installation and setup helpers
alias install-deps="echo 'Installing dotfiles dependencies...' && brew bundle --file=$PWD/Brewfile 2>/dev/null || zf::debug 'No Brewfile found'"
alias setup-symlinks="echo 'Setting up symlinks...' && $PWD/install.sh 2>/dev/null || zf::debug 'No install script found'"
=======
alias backup-zsh="cp -r $ZDOTDIR $ZDOTDIR.backup-\$(command -v date >/dev/null && date +%Y%m%d-%H%M%S || zsh_debug_echo 'backup')"
alias list-backups="ls -la $ZDOTDIR.backup-* 2>/dev/null || zsh_debug_echo 'No backups found'"

# Installation and setup helpers
alias install-deps="echo 'Installing dotfiles dependencies...' && brew bundle --file=$PWD/Brewfile 2>/dev/null || zsh_debug_echo 'No Brewfile found'"
alias setup-symlinks="echo 'Setting up symlinks...' && $PWD/install.sh 2>/dev/null || zsh_debug_echo 'No install script found'"
>>>>>>> origin/develop

# Documentation
alias docs="$EDITOR $PWD/README.md"
alias changelog="$EDITOR $PWD/CHANGELOG.md"

# Quick navigation to common dotfiles locations
alias zsh-config="cd $ZDOTDIR"
alias zsh-core="cd $ZDOTDIR/.zshrc.d/00-core"
alias zsh-plugins="cd $ZDOTDIR/.zshrc.d/20-plugins"
alias zsh-ui="cd $ZDOTDIR/.zshrc.d/30-ui"
alias zsh-tests="cd $ZDOTDIR/tests"
alias zsh-logs="cd $ZDOTDIR/logs"

if command -v basename >/dev/null 2>&1; then
<<<<<<< HEAD
    zf::debug "⚙️  Dotfiles context loaded (dir: $(basename "$PWD"))"
else
    zf::debug "⚙️  Dotfiles context loaded (dir: ${PWD##*/})"
=======
        zsh_debug_echo "⚙️  Dotfiles context loaded (dir: $(basename "$PWD"))"
else
        zsh_debug_echo "⚙️  Dotfiles context loaded (dir: ${PWD##*/})"
>>>>>>> origin/develop
fi
