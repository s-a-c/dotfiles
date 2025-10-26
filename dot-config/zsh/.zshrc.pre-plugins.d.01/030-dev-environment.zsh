#!/usr/bin/env zsh
# 030-dev-environment.zsh
#
# Purpose:
#   Configures the environment for various development tools and runtimes. This
#   script runs early to ensure that paths and settings for tools like Node.js,
#   ripgrep, and CodeQL are available before plugins are loaded.
#
# Features:
#   - XDG-aware configuration for tools like ripgrep.
#   - Prioritized detection of Laravel Herd NVM, with fallbacks to Homebrew,
#     XDG, and standard ~/.nvm locations.
#   - Path setup for alternative JavaScript runtimes: Bun, Deno, and PNPM.
#   - Early PATH configuration for the CodeQL CLI.
#   - Nounset-safe and idempotent.

# Idempotency Guard
[[ -n ${_ZF_DEV_ENVIRONMENT_DONE:-} ]] && return 0
_ZF_DEV_ENVIRONMENT_DONE=1

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }
typeset -f zf::path_prepend >/dev/null 2>&1 || zf::path_prepend() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}

zf::debug "# [dev-environment] configuring development tools"

# --- XDG-based Tool Configuration ---
: "${XDG_CONFIG_HOME:=${HOME}/.config}"

# Auto-detect ripgrep configuration
if [[ -z ${RIPGREP_CONFIG_PATH:-} ]]; then
  local _rg_candidate1="${XDG_CONFIG_HOME}/ripgrep/ripgreprc"
  local _rg_candidate2="${XDG_CONFIG_HOME}/ripgrep/config"

  if [[ -f "${_rg_candidate1}" ]]; then
    export RIPGREP_CONFIG_PATH="${_rg_candidate1}"
  elif [[ -f "${_rg_candidate2}" ]]; then
    export RIPGREP_CONFIG_PATH="${_rg_candidate2}"
  fi

  [[ -n ${RIPGREP_CONFIG_PATH:-} ]] && zf::debug "# [dev-environment] RIPGREP_CONFIG_PATH=${RIPGREP_CONFIG_PATH}"
  unset _rg_candidate1 _rg_candidate2
fi


# --- Node.js and JavaScript Runtimes ---
if [[ -z "${ZF_DISABLE_EARLY_JS:-}" ]]; then
  # Laravel Herd NVM integration
  if [[ -d "/Users/s-a-c/Library/Application Support/Herd/config/nvm" ]]; then
    export NVM_DIR="/Users/s-a-c/Library/Application Support/Herd/config/nvm"
    export _ZF_HERD_NVM=1
    zf::debug "# [dev-environment] Using Herd NVM at: $NVM_DIR"
  # Fallback NVM detection
  elif [[ -d "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/nvm" ]]; then
    export NVM_DIR="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/nvm"
  elif [[ -d "${XDG_DATA_HOME:-${HOME}/.local/share}/nvm" ]]; then
    export NVM_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/nvm"
  elif [[ -d "${HOME}/.nvm" ]]; then
    export NVM_DIR="${HOME}/.nvm"
  fi
  [[ -n "${NVM_DIR:-}" ]] && zf::debug "# [dev-environment] NVM_DIR set to '${NVM_DIR}'"

  # Alternative JS Runtimes
  : "${XDG_DATA_HOME:=${HOME}/.local/share}"
  export BUN_INSTALL="${BUN_INSTALL:-${XDG_DATA_HOME}/bun}"
  export DENO_INSTALL="${DENO_INSTALL:-${XDG_DATA_HOME}/deno}"
  export PNPM_HOME="${PNPM_HOME:-${XDG_DATA_HOME}/pnpm}"

  [[ -d "${BUN_INSTALL}/bin" ]] && zf::path_prepend "${BUN_INSTALL}/bin"
  [[ -d "${DENO_INSTALL}/bin" ]] && zf::path_prepend "${DENO_INSTALL}/bin"
  [[ -d "${PNPM_HOME}" ]] && zf::path_prepend "${PNPM_HOME}"

  # Herd-specific Node.js path
  if [[ -n "${_ZF_HERD_NVM:-}" && -d "${NVM_DIR}/versions/node" ]]; then
    local herd_node_dir="$(ls -1d "${NVM_DIR}"/versions/node/v* 2>/dev/null | tail -1)"
    if [[ -d "$herd_node_dir/bin" ]]; then
      zf::path_prepend "$herd_node_dir/bin"
      zf::debug "# [dev-environment] Prepended Herd Node.js path: $herd_node_dir/bin"
    fi
  fi
else
  zf::debug "# [dev-environment] Early JS runtime setup disabled via ZF_DISABLE_EARLY_JS"
fi


# --- CodeQL CLI ---
: "${XDG_DATA_HOME:=${HOME}/.local/share}"
local _zf_codeql_dir="${XDG_DATA_HOME}/codeql"
if [[ -d "${_zf_codeql_dir}" ]]; then
  zf::path_prepend "${_zf_codeql_dir}"
  zf::debug "# [dev-environment] CodeQL path configured"
fi
unset _zf_codeql_dir

zf::debug "# [dev-environment] configuration complete"
return 0
