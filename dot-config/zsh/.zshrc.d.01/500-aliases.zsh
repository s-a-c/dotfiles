#!/usr/bin/env zsh
# Filename: 500-aliases.zsh
# Purpose:  Provides a comprehensive and safe set of aliases for common commands, with a focus on Git and Node.js project management. This script uses a safety-first approach for package manager commands to prevent accidental execution outside of a project context. Features: - Extensive Git aliases for common workflows (`gs`, `ga`, `gc`, `gpl`, etc.). - Filesystem and system utility aliases (`..`, `ll`, `psa`, `top`). - Safe package manager aliases (`install`, `build`, `dev`, `test`) that automatically detect the correct package manager (npm, yarn, pnpm, bun) and validate that a `package.json` exists before running. - Helper functions (`pm-info`, `pm-npm`, etc.) to manage and inspect the package manager environment. - A comprehensive help command (`aliases-help`) to list all available aliases. --- Git Aliases ---
# Phase:    Post-plugin (.zshrc.d/)

# --- Git Aliases ---
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
alias gl="git log --oneline -10"
alias gd="git diff"
alias gdc="git diff --cached"
alias gst="git stash"
alias gstp="git stash pop"
alias root="cd \$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
alias main="git checkout \$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo 'main')"

# --- Filesystem & System Aliases ---
alias ..="cd .."
alias ...="cd ../.."
if command -v eza >/dev/null 2>&1 && [[ ${ZF_DISABLE_EZA_ALIAS:-0} != 1 ]]; then
  alias ls='\eza'
  alias ll='\eza -lh'
  alias la='eza -alh'
  alias tree='\eza --tree'
fi
alias mkdir='\mkdir -p'
alias md='\mkdir -p'
alias df='\df -h'
alias du='\du -h'
alias psa='\ps aux'
alias psg='\ps aux | grep -v grep | grep'
alias myip='\curl -s ifconfig.me'
if command -v htop >/dev/null 2>&1; then alias top='\htop'; fi
if command -v btop >/dev/null 2>&1; then alias top='\btop'; fi
if command -v bat >/dev/null 2>&1; then alias cat='\bat'; fi
if command -v nvim >/dev/null 2>&1; then
  alias vim='\nvim'
  alias vi='\nvim'
fi

# --- Safe Package Manager Functions (defined in .zshenv) ---
# zf::detect_pkg_manager, zf::safe_pm_command, etc. are globally available.

# --- Safe Package Manager Aliases ---
install() { zf::safe_pm_command "install" "$@"; }
build() { zf::safe_pm_command "run" "build" "$@"; }
dev() { zf::safe_pm_command "run" "dev" "$@"; }
start() { zf::safe_pm_command "start" "$@"; }
nt() { zf::safe_pm_command "test" "$@"; }
run() { [[ $# -eq 0 ]] && echo "Usage: run <script>" >&2 || zf::safe_pm_command "run" "$@"; }
serve() { zf::safe_pm_command "run" "serve" "$@"; }
clean() { zf::safe_pm_command "run" "clean" "$@"; }
format() { zf::safe_pm_command "run" "format" "$@"; }
lint() { zf::safe_pm_command "run" "lint" "$@"; }
lint-fix() { zf::safe_pm_command "run" "lint:fix" "$@"; }
add() { zf::safe_pm_command "install" "$@"; }
remove() { zf::safe_pm_command "uninstall" "$@"; }
update() { zf::safe_pm_command "update" "$@"; }
outdated() { zf::safe_pm_command "outdated" "$@"; }
publish() { zf::safe_pm_command "publish" "$@"; }
audit() { zf::safe_pm_command "audit" "$@"; }
audit-fix() { zf::safe_pm_command "audit" "fix"; }

# Short aliases
alias ni='install'
alias nid='zf::safe_pm_command "install" --save-dev'
alias nr='run'
alias ns='start'
alias nb='build'

# --- Help Function ---
aliases-help() {
  echo "--- Safe Package Manager Aliases ---"
  echo "install, add, remove, update, outdated, publish, audit, audit-fix"
  echo "run, dev, build, test, start, serve, clean, format, lint, lint-fix"
  echo "Shortcuts: ni (install), nid (install --save-dev), nr (run), ns (start), nt (test), nb (build)"
  echo ""
  echo "--- Package Manager Switchers ---"
  echo "pm-info, pm-npm, pm-yarn, pm-pnpm, pm-bun, pm-auto"
  echo ""
  echo "--- Git Aliases ---"
  echo "gs, ga, gaa, gc, gcm, gca, gp, gpl, gf, gb, gco, gcb, gl, gd, gdc, gst, gstp, root, main"
  echo ""
  echo "--- System Aliases ---"
  echo ".., ..., ls, ll, la, tree, mkdir, df, du, psa, psg, myip, top, cat, vim, vi"
}

# --- Welcome Message ---
if [[ -z "${_ZF_ALIASES_NOTIFIED:-}" ]]; then
  echo "🎯 Safe aliases active. Type 'aliases-help' for a full list."
  export _ZF_ALIASES_NOTIFIED=1
fi

typeset -f zf::debug >/dev/null 2>&1 && zf::debug "# [aliases] Safe aliases and package manager functions loaded"
return 0
