#!/usr/bin/env zsh
# 450-node-environment.zsh
#
# Purpose:
#   Manages the Node.js environment, with a focus on NVM (Node Version Manager)
#   and compatibility with Laravel Herd. This script ensures that the correct
#   NVM instance is configured and provides validation for npm settings.
#
# Features:
#   - Prioritizes Laravel Herd's NVM installation.
#   - Falls back to Homebrew or standard `~/.nvm` installations.
#   - Configures the `oh-my-zsh` nvm plugin for lazy loading.
#   - Includes an enhanced lazy loader for `nvm` as a fallback.
#   - Validates and fixes potentially corrupted npm configuration settings.
#
# Toggles:
#   - `ZF_DISABLE_NPM_VALIDATION=1`: Skips the npm configuration validation.

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# --- NVM Post-Plugin Augmentation ---
unset NPM_CONFIG_HOME 2>/dev/null || true

# Detect NVM directory, prioritizing Herd
if [[ -z "${NVM_DIR:-}" ]]; then
  if [[ -d "${HOME}/Library/Application Support/Herd/config/nvm" ]]; then
    export NVM_DIR="${HOME}/Library/Application Support/Herd/config/nvm"
    export _ZF_HERD_NVM=1
    zf::debug "# [node] Using Herd NVM_DIR: ${NVM_DIR}"
  elif [[ -d "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/nvm" ]]; then
    export NVM_DIR="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/nvm"
    zf::debug "# [node] Using Homebrew NVM_DIR: ${NVM_DIR}"
  elif [[ -d "${HOME}/.nvm" ]]; then
    export NVM_DIR="${HOME}/.nvm"
    zf::debug "# [node] Using standard NVM_DIR: ${NVM_DIR}"
  fi
fi

# Configure OMZ nvm plugin for lazy loading
zstyle ':omz:plugins:nvm' lazy yes
zstyle ':omz:plugins:nvm' autoload yes
zstyle ':omz:plugins:nvm' silent-autoload yes

# Enhanced lazy loader for nvm as a fallback
if ! typeset -f nvm >/dev/null 2>&1 && [[ -n ${NVM_DIR:-} && -s "${NVM_DIR}/nvm.sh" ]]; then
  zf::debug "# [node] Injecting enhanced fallback lazy nvm stub"
  nvm() {
    unset -f nvm 2>/dev/null || true
    unset NPM_CONFIG_PREFIX
    source "$NVM_DIR/nvm.sh" || return 1
    [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion" 2>/dev/null
    command nvm "$@"
  }
fi

# --- NPM Config Validator ---
if [[ "${ZF_DISABLE_NPM_VALIDATION:-0}" != 1 ]] && command -v npm >/dev/null 2>&1; then
  # If in a Herd environment, set the global npmrc path
  if [[ -n "${_ZF_HERD_NVM:-}" ]]; then
    export NPM_CONFIG_GLOBALCONFIG="${NVM_DIR}/etc/npmrc"
    if [[ ! -f "$NPM_CONFIG_GLOBALCONFIG" ]]; then
      mkdir -p "$(dirname "$NPM_CONFIG_GLOBALCONFIG")"
      touch "$NPM_CONFIG_GLOBALCONFIG" 2>/dev/null
    fi
  fi

  # Fix known corrupted npm config values
  if [[ "$(npm config get before 2>/dev/null)" != "null" ]]; then
    npm config set before null >/dev/null 2>&1 && zf::debug "# [node] Fixed corrupted npm 'before' config"
  fi
fi

export _ZF_NODE_ENV_COMPLETE=1
zf::debug "# [node] Node.js environment setup complete"

# Define the function to safely load .nvmrc
herd-load-nvmrc() {
  # If the main nvm function for finding .nvmrc doesn't exist,
  # the nvm environment is not fully loaded. Source it now.
  if ! typeset -f nvm_find_nvmrc >/dev/null 2>&1; then
    if [[ -s "${NVM_DIR:-}/nvm.sh" ]]; then
      source "${NVM_DIR}/nvm.sh"
    fi
  fi

  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc 2>/dev/null)"
  if [[ -n "$nvmrc_path" ]]; then
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")
    if [[ "$nvmrc_node_version" != "N/A" ]]; then
      nvm use --silent
    fi
  fi
}

# Add nvmrc loader to chpwd_functions to auto-load .nvmrc on directory change
if typeset -f herd-load-nvmrc >/dev/null 2>&1; then
  chpwd_functions+=("herd-load-nvmrc")
fi
# Manually trigger for the initial directory on shell startup
herd-load-nvmrc

# Health check: if in a node project, run a quick version check.
if [[ -f "package.json" ]]; then
  zf::safe_pm_verify
fi

return 0
