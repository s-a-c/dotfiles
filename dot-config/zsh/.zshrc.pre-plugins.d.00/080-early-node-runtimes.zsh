#!/usr/bin/env zsh
# 080-early-node-runtimes.zsh - Early Node/JS Runtime Path Shaping with Herd-aware NVM
# Purpose: Expose alternative JS toolchain bins and NVM environment BEFORE plugin layer
# Ensures:
#   * oh-my-zsh nvm plugin lazy-cmd detection sees all available tools
#   * User scripts/early modules can call these runtimes without waiting
#   * Laravel Herd NVM is prioritized when available
#   * Baseline tooling order: (Herd) -> early alt runtimes -> post-plugin NVM lazy

if [[ -n "${ZF_DISABLE_EARLY_JS:-}" ]]; then
  zf::debug "# [early-node-runtimes] disabled via ZF_DISABLE_EARLY_JS"
  return 0
fi

zf::debug "# [early-node-runtimes] begin"

# =============================================================================
# Laravel Herd NVM Environment Setup (NEW - Pre-plugin NVM support)
# =============================================================================

# Herd NVM integration - Primary detection for Laravel developers
if [[ -d "/Users/s-a-c/Library/Application Support/Herd/config/nvm" ]]; then
  export NVM_DIR="/Users/s-a-c/Library/Application Support/Herd/config/nvm"
  export _ZF_HERD_NVM=1
  zf::debug "# [early-node-runtimes] Using Herd NVM at: $NVM_DIR"
else
  # Fallback NVM detection for non-Herd environments
  if [[ -d "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/nvm" ]]; then
    export NVM_DIR="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/nvm"
    export _ZF_HERD_NVM=0
    zf::debug "# [early-node-runtimes] Using Homebrew NVM at: $NVM_DIR"
  elif [[ -d "${XDG_DATA_HOME:-${HOME}/.local/share}/nvm" ]]; then
    export NVM_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/nvm"
    export _ZF_HERD_NVM=0
    zf::debug "# [early-node-runtimes] Using XDG NVM at: $NVM_DIR"
  elif [[ -d "${HOME}/.nvm" ]]; then
    export NVM_DIR="${HOME}/.nvm"
    export _ZF_HERD_NVM=0
    zf::debug "# [early-node-runtimes] Using standard NVM at: $NVM_DIR"
  fi
fi

# Export markers for plugin compatibility
export _ZF_NVM_PRESETUP=1
[[ -n "${NVM_DIR:-}" ]] && export _ZF_NVM_DETECTED=1

# =============================================================================
# Alternative JavaScript Runtime Paths (EXISTING - Enhanced)
# =============================================================================

# Bun
if [[ -z "${BUN_INSTALL:-}" ]]; then
  export BUN_INSTALL="${XDG_DATA_HOME:-${HOME}/.local/share}/bun"
fi
if [[ -d "${BUN_INSTALL}/bin" ]]; then
  zf::path_prepend "${BUN_INSTALL}/bin"
  zf::debug "# [early-node-runtimes] bun path added"
fi

# Deno
if [[ -z "${DENO_INSTALL:-}" ]]; then
  export DENO_INSTALL="${XDG_DATA_HOME:-${HOME}/.local/share}/deno"
fi
if [[ -d "${DENO_INSTALL}/bin" ]]; then
  zf::path_prepend "${DENO_INSTALL}/bin"
  zf::debug "# [early-node-runtimes] deno path added"
fi

# PNPM
if [[ -z "${PNPM_HOME:-}" ]]; then
  export PNPM_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/pnpm"
fi
if [[ -d "${PNPM_HOME}" ]]; then
  zf::path_prepend "${PNPM_HOME}"
  zf::debug "# [early-node-runtimes] pnpm path added"
fi

# Herd-specific Node.js path (if available)
if [[ -n "${_ZF_HERD_NVM:-}" && -d "${NVM_DIR}/versions/node" ]]; then
  local herd_node_dir="$(ls -1d "${NVM_DIR}"/versions/node/v* 2>/dev/null | tail -1)"
  if [[ -d "$herd_node_dir/bin" ]]; then
    export PATH="$herd_node_dir/bin:$PATH"
    zf::debug "# [early-node-runtimes] Herd Node.js path added: $herd_node_dir/bin"
  fi
fi

# =============================================================================
# Pre-plugin Environment Markers
# =============================================================================

# Export environment markers for plugin detection and compatibility
export _ZF_EARLY_NODE_COMPLETE=1
[[ -n "${_ZF_HERD_NVM:-}" ]] && export _ZF_HERD_DETECTED=1

zf::debug "# [early-node-runtimes] complete - NVM: ${NVM_DIR:-not detected}, Herd: ${_ZF_HERD_NVM:-0}"
