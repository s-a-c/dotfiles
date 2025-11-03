#!/usr/bin/env zsh
# 900-catalogued-aliases.zsh - Comprehensive consolidated aliases with safety-first approach
# Purpose: Authoritative source for all aliases, organizing active and catalogued commands
# Load Order: 900 (last, after all other functionality, takes priority)

if [[ "${ZF_DISABLE_CATALOGUED_ALIASES:-0}" == 1 ]]; then
  return 0
fi

# =============================================================================
# ACTIVE ALIASES (From 400-aliases.zsh - TAKE PRIORITY)
# =============================================================================
# These are the currently active, safe aliases that should always be available

# Git aliases (from 400-aliases.zsh - ACTIVE)
alias gs="git status"
alias ga="git add"
alias gaa="git add ."
alias gc="git commit"
alias gcm="git commit -m"
alias gca="git commit --amend"
alias gp="git push"
alias gpl="git pull"
alias gf="git fetch"
alias gb="git branch"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gm="git merge"
alias gr="git rebase"
alias gl="git log --oneline -10"
alias gd="git diff"
alias gdc="git diff --cached"
alias gst="git stash"
alias gstp="git stash pop"

# Repository-specific shortcuts (from 400-aliases.zsh - ACTIVE)
alias root="cd $(git rev-parse --show-toplevel 2>/dev/null || echo .)"
alias main="git checkout $(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo 'main')"

# Branch management (from 400-aliases.zsh - ACTIVE)
alias branches="git branch -a"
alias clean-branches="git branch --merged | grep -v '\*\|main\|master\|develop' | xargs -n 1 git branch -d"

# Commit helpers (from 400-aliases.zsh - ACTIVE)
alias amend="git commit --amend --no-edit"
alias fixup="git commit --fixup"
alias wip="git add . && git commit -m 'WIP: work in progress'"
alias unwip="git reset HEAD~1"

# Log and history (from 400-aliases.zsh - ACTIVE)
alias history="git log --oneline --graph --decorate --all -20"
alias contributors="git shortlog -sn"
alias changes="git log --oneline --since='1 week ago'"

# Diff and show (from 400-aliases.zsh - ACTIVE)
alias show="git show"
alias blame="git blame"
alias conflicts="git diff --name-only --diff-filter=U"

# Remote operations (from 400-aliases.zsh - ACTIVE)
alias sync="git fetch --all && git pull"

# File system aliases (from 400-aliases.zsh - ACTIVE)
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# Directory listing with safety (from 400-aliases.zsh - ACTIVE)
if command -v eza >/dev/null 2>&1; then
  if [[ ${ZF_DISABLE_EZA_ALIAS:-0} != 1 ]]; then
    alias ls='eza'
    alias ll='eza -lh'
    alias la='eza -alh'
    alias tree='eza --tree'
    export ALIAS_LS_EZA=1
  else
    export ALIAS_LS_EZA=0
  fi
fi

# File operations (from 400-aliases.zsh - ACTIVE)
alias mkdir='mkdir -p'
alias df='df -h'
alias du='du -h'
alias dus='du -sh * | sort -h'

# System aliases (from 400-aliases.zsh - ACTIVE)
alias psa='ps aux'
alias psg='ps aux | grep -v grep | grep'
alias kill9='kill -9'

# Network utilities (from 400-aliases.zsh - ACTIVE)
alias myip='curl -s ifconfig.me'
alias ports='netstat -tuln'

# Quick access to common tools (from 400-aliases.zsh - ACTIVE)
if command -v htop >/dev/null 2>&1; then
  alias top='htop'
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat'
fi

# Neovim aliases (from 400-aliases.zsh - ACTIVE)
if command -v nvim >/dev/null 2>&1; then
  alias vim='nvim'
  alias vi='nvim'
fi

# Installation and setup helpers (from 400-aliases.zsh - ACTIVE)
alias install-deps="echo 'Installing dotfiles dependencies...' && brew bundle --file=$PWD/Brewfile 2>/dev/null || echo 'No Brewfile found'"
alias setup-symlinks="echo 'Setting up symlinks...' && $PWD/install.sh 2>/dev/null || echo 'No install script found'"

# =============================================================================
# PACKAGE MANAGER DETECTION AND SAFETY FUNCTIONS (From 400-aliases.zsh - ACTIVE)
# =============================================================================

# Preferred package manager - set to override auto-detection
export ZF_PREFERRED_PKG_MANAGER="${ZF_PREFERRED_PKG_MANAGER:-auto}"

# Package manager executables
export ZF_NPM_CMD="${ZF_NPM_CMD:-npm}"
export ZF_NPX_CMD="${ZF_NPX_CMD:-npx}"
export ZF_YARN_CMD="${ZF_YARN_CMD:-yarn}"
export ZF_PNPM_CMD="${ZF_PNPM_CMD:-pnpm}"
export ZF_BUN_CMD="${ZF_BUN_CMD:-bun}"

# Function to detect preferred package manager
zf::detect_pkg_manager() {
  local preferred="${ZF_PREFERRED_PKG_MANAGER:-auto}"

  # If explicitly set, use that
  if [[ "$preferred" != "auto" ]]; then
    echo "$preferred"
    return 0
  fi

  # Auto-detect based on lock files
  if [[ -f "$PWD/bun.lockb" ]]; then
    echo "bun"
  elif [[ -f "$PWD/pnpm-lock.yaml" ]]; then
    echo "pnpm"
  elif [[ -f "$PWD/yarn.lock" ]]; then
    echo "yarn"
  else
    echo "npm"
  fi
}

# Function to get package manager executable
_zf_get_pm_exec() {
  local pm="$1"
  case "$pm" in
  "npm") echo "${ZF_NPM_CMD:-npm}" ;;
  "npx") echo "${ZF_NPX_CMD:-npx}" ;;
  "yarn") echo "${ZF_YARN_CMD:-yarn}" ;;
  "pnpm") echo "${ZF_PNPM_CMD:-pnpm}" ;;
  "bun") echo "${ZF_BUN_CMD:-bun}" ;;
  *) echo "$pm" ;;
  esac
}

# Function to get package manager executable for running scripts
_zf_get_pm_run_exec() {
  local pm="$1"
  case "$pm" in
  "bun") echo "${ZF_BUN_CMD:-bun}" ;;
  *) echo "$(_zf_get_pm_exec "$pm")" ;;
  esac
}

# Core safety check function
zf::safe_pm_command() {
  local cmd="$1"
  shift
  local args=("$@")
  local pm="$(zf::detect_pkg_manager)"
  local pm_exec="$(_zf_get_pm_run_exec "$pm")"

  # Check if we're in a Node.js project for commands that need package.json
  local needs_package_json=("install" "run" "start" "test" "build" "dev" "serve" "clean" "format" "lint" "lint-fix")
  local command_needs_json=false

  for need_cmd in "${needs_package_json[@]}"; do
    if [[ "$cmd" == "$need_cmd" ]]; then
      command_needs_json=true
      break
    fi
  done

  # Special handling for run commands with script names
  if [[ "$cmd" == "run" && -n "${args[1]:-}" ]]; then
    command_needs_json=true
  fi

  # Validate project context
  if [[ "$command_needs_json" == true && ! -f "package.json" && "$PWD" != "$HOME" ]]; then
    echo "⚠️  Command '$pm $cmd${args:+ ${args[*]}}' requires a package.json file" >&2
    echo "💡 Run this command in a Node.js project directory" >&2
    echo "🎯 Current directory: $PWD" >&2

    # Suggest common solutions
    if [[ -d "node_modules" ]]; then
      echo "💡 Found node_modules/ but no package.json - project may be corrupted" >&2
    fi

    # Show detected lock file if any
    local lock_file=""
    [[ -f "package-lock.json" ]] && lock_file="package-lock.json"
    [[ -f "yarn.lock" ]] && lock_file="yarn.lock"
    [[ -f "pnpm-lock.yaml" ]] && lock_file="pnpm-lock.yaml"
    [[ -f "bun.lockb" ]] && lock_file="bun.lockb"

    if [[ -n "$lock_file" ]]; then
      echo "💡 Found lock file: $lock_file" >&2
    fi

    # Show environment context
    if [[ -n "${_ZF_HERD_NVM:-}" ]]; then
      echo "🐘 Running in Laravel Herd environment" >&2
    fi

    return 1
  fi

  # Execute command safely
  if ! command "$pm_exec" "$cmd" "${args[@]}"; then
    echo "⚠️  Failed to execute '$pm $cmd${args:+ ${args[*]}}'" >&2
    return 1
  fi
}

# Enhanced package manager information
pm-info() {
  local current_pm pm_exec
  current_pm=$(zf::detect_pkg_manager)
  pm_exec=$(command -v "$current_pm" 2>/dev/null || echo "not found")

  # Enhanced environment information
  echo "Current package manager: $current_pm ($pm_exec)"

  # Show additional context
  if [[ -n "${_ZF_HERD_NVM:-}" ]]; then
    echo "Environment: Laravel Herd (NVM: $NVM_DIR)"
  elif [[ -n "${NVM_DIR:-}" ]]; then
    echo "Environment: NVM (${NVM_DIR})"
  else
    echo "Environment: System Node.js"
  fi

  # Project validation
  if [[ -f "package.json" ]]; then
    echo "✅ Project detected (package.json found)"
  elif [[ "$PWD" != "$HOME" ]]; then
    echo "⚠️  Not in a Node.js project (no package.json found)"
    echo "💡 Some package manager commands may not work as expected"
    return 1
  fi
}

# Enhanced package manager switching with environment awareness
pm-npm() {
  export ZF_PREFERRED_PKG_MANAGER="npm"
  echo "✅ Switched to npm"
  [[ -n "${_ZF_HERD_NVM:-}" ]] && echo "🐘 Running in Laravel Herd environment"
}

pm-yarn() {
  export ZF_PREFERRED_PKG_MANAGER="yarn"
  echo "✅ Switched to yarn"
  [[ -n "${_ZF_HERD_NVM:-}" ]] && echo "🐘 Running in Laravel Herd environment"
}

pm-pnpm() {
  export ZF_PREFERRED_PKG_MANAGER="pnpm"
  echo "✅ Switched to pnpm"
  [[ -n "${_ZF_HERD_NVM:-}" ]] && echo "🐘 Running in Laravel Herd environment"
}

pm-bun() {
  export ZF_PREFERRED_PKG_MANAGER="bun"
  echo "✅ Switched to bun"
  [[ -n "${_ZF_HERD_NVM:-}" ]] && echo "🐘 Running in Laravel Herd environment"
}

pm-auto() {
  export ZF_PREFERRED_PKG_MANAGER="auto"
  echo "🔍 Auto-detection enabled"
  [[ -n "${_ZF_HERD_NVM:-}" ]] && echo "🐘 Running in Laravel Herd environment"
}

pm-switch() {
  export ZF_PREFERRED_PKG_MANAGER=""
  echo "🔄 Package manager preference cleared (auto-detection active)"
}

# =============================================================================
# SAFE LEGACY ALIASES (From 400-aliases.zsh - ACTIVE)
# =============================================================================

# Core development aliases - most commonly used
install() {
  if [[ $# -eq 0 ]]; then
    zf::safe_pm_command "install"
  else
    zf::safe_pm_command "install" "$@"
  fi
}

build() {
  if [[ $# -eq 0 ]]; then
    zf::safe_pm_command "run" "build"
  else
    zf::safe_pm_command "run" "build" -- "$@"
  fi
}

dev() {
  if [[ $# -eq 0 ]]; then
    zf::safe_pm_command "run" "dev"
  else
    zf::safe_pm_command "run" "dev" -- "$@"
  fi
}

start() {
  if [[ $# -eq 0 ]]; then
    zf::safe_pm_command "start"
  else
    zf::safe_pm_command "start" "$@"
  fi
}

test() {
  if [[ $# -eq 0 ]]; then
    zf::safe_pm_command "test"
  else
    zf::safe_pm_command "test" "$@"
  fi
}

# Additional commonly used aliases
run() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: run <script-name> [args...]" >&2
    echo "💡 Example: run build, run dev, run test" >&2
    return 1
  else
    zf::safe_pm_command "run" "$@"
  fi
}

serve() {
  if [[ $# -eq 0 ]]; then
    zf::safe_pm_command "run" "serve"
  else
    zf::safe_pm_command "run" "serve" -- "$@"
  fi
}

clean() {
  if [[ $# -eq 0 ]]; then
    zf::safe_pm_command "run" "clean"
  else
    zf::safe_pm_command "run" "clean" -- "$@"
  fi
}

format() {
  if [[ $# -eq 0 ]]; then
    zf::safe_pm_command "run" "format"
  else
    zf::safe_pm_command "run" "format" -- "$@"
  fi
}

lint() {
  if [[ $# -eq 0 ]]; then
    zf::safe_pm_command "run" "lint"
  else
    zf::safe_pm_command "run" "lint" -- "$@"
  fi
}

lint-fix() {
  if [[ $# -eq 0 ]]; then
    zf::safe_pm_command "run" "lint:fix"
  else
    zf::safe_pm_command "run" "lint:fix" -- "$@"
  fi
}

# Package management aliases
add() {
  zf::safe_pm_command "install" "$@"
}

remove() {
  zf::safe_pm_command "uninstall" "$@"
}

update() {
  if [[ $# -eq 0 ]]; then
    zf::safe_pm_command "update"
  else
    zf::safe_pm_command "update" "$@"
  fi
}

outdated() {
  zf::safe_pm_command "outdated" "$@"
}

publish() {
  zf::safe_pm_command "publish" "$@"
}

audit() {
  zf::safe_pm_command "audit" "$@"
}

audit-fix() {
  zf::safe_pm_command "audit" "fix"
}

# =============================================================================
# COMPATIBILITY SHORT ALIASES (From 400-aliases.zsh - ACTIVE)
# =============================================================================

# Short-form aliases for power users
ni() { install "$@"; }
nid() { zf::safe_pm_command "install" --save-dev "$@"; }
nr() { run "$@"; }
ns() { start "$@"; }
nt() { test "$@"; }
nb() { build "$@"; }
nw() {
  if [[ $# -eq 0 ]]; then
    zf::safe_pm_command "run" "watch"
  else
    zf::safe_pm_command "run" "watch" -- "$@"
  fi
}

# =============================================================================
# CATALOGUED ALIASES (ORGANIZED FOR REFERENCE)
# =============================================================================

# -----------------------------------------------------------------------------
# TERMINAL AND ENVIRONMENT SPECIFIC ALIASES
# -----------------------------------------------------------------------------

# Kitty terminal enhancements (commented - requires kitty)
# alias icat="kitten icat"                    # Image preview
# alias s="kitten ssh"                         # Enhanced SSH
# alias d="kitten diff"                         # Enhanced diff

# Aerospace window manager (commented - requires aerospace)
# alias as="aerospace"                         # Window manager control

# -----------------------------------------------------------------------------
# ENHANCED SYSTEM ALIASES
# -----------------------------------------------------------------------------

# Enhanced navigation (commented - alternatives to active ones)
# alias cd..="cd .."                        # Alternative to ".."
# alias cd...="cd ../.."                      # Alternative to "..."

# Enhanced file operations (commented - safety alternatives)
# alias ln='ln -i'                           # Interactive link creation
# alias cp='cp -iv'                          # Verbose interactive copy
# alias mv='mv -iv'                           # Verbose interactive move
# alias rm='rm -iv'                           # Verbose interactive remove

# System information aliases (commented - alternatives to active ones)
# alias fpath='echo $fpath | tr " " "\n" | sort'  # Show function path
# alias free='free -h'                        # Human-readable memory
# alias ports='netstat -tuln'                 # Show open ports

# Process management enhancements (commented - alternatives to active ones)
# alias ps='ps aux'                          # Alternative to psa
# alias pgrep='pgrep -f'                      # Full process grep
# alias topc='top -o cpu'                    # CPU-sorted top
# alias topm='top -o %mem'                  # Memory-sorted top

# Network utilities (commented - alternatives to active ones)
# alias wget='wget -c'                       # Continue downloads
# alias now='date +"%T"'                    # Current time
# alias nowdate='date +"%d-%m-%Y"'           # Current date

# History management (commented - advanced features)
# alias disablehistory='function zshaddhistory() { return 1 }'  # Disable history
# alias enablehistory='unset -f zshaddhistory'                  # Re-enable history

# Performance monitoring (commented - benchmarking)
# alias zshbench='for i in $(seq 1 10); do time $SHELL -i -c exit; done'  # Benchmark shell

# -----------------------------------------------------------------------------
# ENHANCED GIT ALIASES (Additional to active ones)
# -----------------------------------------------------------------------------

# Extended git operations (commented - alternatives to active ones)
# alias gba='git branch --all'                 # Alternative to branches
# alias gds='git diff --staged'               # Alternative to gdc
# alias gf='git fetch'                         # Alternative to gf
# alias gbd='git branch -d'                    # Delete branch
# alias gbD='git branch -D'                    # Force delete branch
# alias gcam='git commit -am'                  # Alternative to gca
# alias gdc='git diff --cached'                 # Alternative to gdc
# alias gll='git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit'  # Fancy log
# alias gpu='git push -u origin'               # Upstream push
# alias gr='git remote'                        # Show remotes
# alias grv='git remote -v'                    # Verbose remotes
# alias gss='git status -s'                   # Short status
# alias gstl='git stash list'                  # List stashes

# -----------------------------------------------------------------------------
# DEVELOPMENT LANGUAGE SPECIFIC ALIASES
# -----------------------------------------------------------------------------

# Python aliases (commented - language specific)
# alias py='python3'                          # Python shortcut
# alias pip='pip3'                             # Python pip shortcut

# Node.js alternatives (commented - handled by safe functions above)
# alias node='node'                            # Node.js command

# -----------------------------------------------------------------------------
# SHELL CONFIGURATION ALIASES
# -----------------------------------------------------------------------------

# Configuration editing (commented - alternatives to active ones)
# alias zshconfig='$EDITOR "$ZDOTDIR/.zshrc"'      # Edit zsh config
# alias zshenv='$EDITOR "$ZDOTDIR/.zshenv"'         # Edit zsh environment
# alias aliases='$EDITOR "$ZDOTDIR/.zsh_aliases"'    # Edit aliases
# alias zshrc='$EDITOR "$ZDOTDIR/.zshrc"'          # Alternative to edit-zsh
# alias zshenv='$EDITOR "$ZDOTDIR/.zshenv"'         # Alternative to edit-env

# Quick reload (commented - alternative to reload)
# alias reload='source ~/.zshrc'               # Reload zsh

# -----------------------------------------------------------------------------
# TESTING AND VALIDATION ALIASES
# -----------------------------------------------------------------------------

# Configuration testing (commented - requires test files)
# alias test-config='$PWD/dot-config/zsh/tests/test-config-validation.zsh'  # Config validation
# alias test-performance='$PWD/dot-config/zsh/tests/test-startup-time.zsh'      # Performance test
# alias test-security='$PWD/dot-config/zsh/tests/test-security-audit.zsh'      # Security test
# alias test-integration='$PWD/dot-config/zsh/run-integration-tests'         # Integration tests

# Security and maintenance (commented - requires scripts)
# alias security-maintenance='$PWD/dot-config/zsh/weekly-security-maintenance'   # Weekly security
# alias setup-cron='$PWD/dot-config/zsh/setup-weekly-cron'                   # Cron setup

# Performance profiling (commented - requires profiling script)
# alias profile='$PWD/dot-config/zsh/zsh-profile-startup'                  # Startup profile
# alias profile-fast='$PWD/dot-config/zsh/zsh-profile-startup -i 3 -w 1'   # Fast profile

# -----------------------------------------------------------------------------
# DOTFILES MANAGEMENT ALIASES (Alternatives to active ones)
# -----------------------------------------------------------------------------

# Git operations for dotfiles (commented - alternatives to active ones)
# alias dots-status='git status'               # Alternative to gs in dotfiles
# alias dots-add='git add .'                 # Alternative to gaa in dotfiles
# alias dots-commit='git commit -m'            # Alternative to gc in dotfiles
# alias dots-push='git push'                 # Alternative to gp in dotfiles
# alias dots-pull='git pull'                 # Alternative to gpl in dotfiles
# alias dots-sync='git add . && git commit -m "Update dotfiles" && git push'  # Alternative to sync

# Navigation to dotfiles (commented - alternatives to active ones)
# alias dots='cd $DOTFILES_DIR'              # Alternative to root in dotfiles
# alias dotfiles='cd $DOTFILES_DIR'           # Alternative to dots

# Backup and restore (commented - backup functions)
# alias backup-zsh='cp -r $ZDOTDIR $ZDOTDIR.backup-$(date +%Y%m%d-%H%M%S)'  # Backup zsh config
# alias list-backups='ls -la $ZDOTDIR.backup-* 2>/dev/null || echo "No backups found"'  # List backups

# -----------------------------------------------------------------------------
# ENHANCED HELP AND DOCUMENTATION
# =============================================================================

safe-npm-help() {
  echo "🎯 Safe Package Manager Aliases - Consolidated from Active Config"
  echo "=================================================================="
  echo
  echo "Essential Commands (with automatic package manager detection):"
  echo "  install [package...]    Install dependencies"
  echo "  add <package>          Add a package"
  echo "  remove <package>       Remove a package"
  echo "  run <script>           Run npm script"
  echo "  dev                    Run development server"
  echo "  build                  Build the project"
  echo "  test                   Run tests"
  echo "  start                  Start production server"
  echo "  serve                  Run serve script"
  echo "  clean                  Run clean script"
  echo "  format                 Format code"
  echo "  lint                   Run linter"
  echo "  lint-fix               Fix linting issues"
  echo "  update                 Update dependencies"
  echo "  outdated               Check for outdated packages"
  echo "  publish                Publish package"
  echo "  audit                  Run security audit"
  echo "  audit-fix              Fix audit issues"
  echo
  echo "Short Aliases:"
  echo "  ni     install"
  echo "  nid    install --save-dev"
  echo "  nr     run"
  echo "  ns     start"
  echo "  nt     test"
  echo "  nb     build"
  echo "  nw     watch"
  echo
  echo "Enhanced Package Manager Commands:"
  echo "  pm-info               Show current package manager and environment"
  echo "  pm-npm / pm-yarn / pm-pnpm / pm-bun   Switch package manager"
  echo "  pm-auto               Enable auto-detection"
  echo "  pm-switch             Clear preference (auto-detect)"
  echo
  echo "Git Aliases (selected active):"
  echo "  gs     git status"
  echo "  ga     git add"
  echo "  gc     git commit"
  echo "  gp     git push"
  echo "  gpl    git pull"
  echo "  gco    git checkout"
  echo "  gl     git log --oneline -10"
  echo
  echo "System Aliases (active):"
  echo "  ..     cd .."
  echo "  ...    cd ../.."
  echo "  ll     eza -lh"
  echo "  la     eza -alh"
  echo "  psa    ps aux"
  echo "  top     htop (if available)"
  echo
  echo "Catalogued Aliases (commented - uncomment to activate):"
  echo "  🐘 Kitty: icat, s=ssh, d=diff (requires kitty terminal)"
  echo "  🪟 Aerospace: as=window manager (requires aerospace)"
  echo "  🔧 Enhanced git: gba, gds, gbd, gll, gpu, grv (advanced)"
  echo "  🐍 Python: py=python3, pip=pip3 (language-specific)"
  echo "  📁 File ops: ln=interactive, cp=verbose, rm=interactive (safety)"
  echo "  🧪 Testing: test-config, test-performance, test-security (dev)"
  echo "  💾 Dotfiles: dots-status, dots-sync, backup-zsh (management)"
  echo "  📊 System: fpath, free, ports, now, zshbench (monitoring)"
  echo
  echo "Safety Features:"
  echo "  ✅ Automatic project validation (package.json check)"
  echo "  ✅ Package manager auto-detection (npm/yarn/pnpm/bun)"
  echo "  ✅ Clear error messages and helpful suggestions"
  echo "  ✅ Laravel Herd environment awareness"
  echo "  ✅ Lock file detection and display"
  echo
  echo "Usage Examples:"
  echo "  install                    # Install all dependencies"
  echo "  add lodash                 # Add lodash as dependency"
  echo "  ni                         # Short for install"
  echo "  dev                        # Run development server"
  echo "  build                      # Build project"
  echo "  test                       # Run tests"
  echo "  run custom-script          # Run custom npm script"
  echo "  pm-info                    # Show package manager info"
  echo "  pm-bun                     # Switch to bun"
  echo
  echo "🚀 This consolidated system provides safe aliases and comprehensive catalog!"
}

# Create help aliases
alias safe-npm-help='safe-npm-help'
alias npm-help='safe-npm-help'
alias catalog-help='safe-npm-help'
alias aliases-help='safe-npm-help'

# =============================================================================
# ENVIRONMENT CLEANUP AND STATUS
# =============================================================================

# Clear any problematic environment variables that might cause npm warnings
unset npm_config_before 2>/dev/null || true

# Export status markers
export _ZF_SAFE_ALIASES_COMPLETE=1
export _ZF_PACKAGE_MANAGER_INTEGRATION_COMPLETE=1
export _ZF_CATALOGUED_ALIASES_LOADED=1

# Show welcome message (only once per session)
if [[ -z "${_ZF_CONSOLIDATED_ALIASES_NOTIFIED:-}" ]]; then
  echo "🎯 Consolidated package manager aliases active: install, build, dev, test, run"
  echo "💡 Type 'safe-npm-help' for complete usage guide"
  echo "📁 Catalogued aliases available - see 'catalog-help'"
  echo "🐘 Laravel Herd integration: $(if [[ -n "${_ZF_HERD_NVM:-}" ]]; then echo 'Active'; else echo 'Not detected'; fi)"
  export _ZF_CONSOLIDATED_ALIASES_NOTIFIED=1
fi

# =============================================================================
# ORGANIZATION NOTES
# =============================================================================
#
# This file serves as the authoritative source for all aliases:
# - ACTIVE: From 400-aliases.zsh (take priority)
# - CATALOGUED: Organized by category for reference
# - CONSISTENT: All package manager aliases use same safety functions
# - MAINTAINABLE: Single file, clear structure
# - DOCUMENTED: Comprehensive help system
#
# To activate catalogued aliases:
# 1. Uncomment the desired alias
# 2. Restart shell or source this file
#
# Active aliases will override any catalogued aliases with same names
#
# =============================================================================
