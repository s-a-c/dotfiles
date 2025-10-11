#!/usr/bin/env zsh
# 220-dev-node.zsh - Node.js + Bun (+ PNPM) Development Environment for ZSH REDESIGN v2
# Phase 3B: Node.js + Bun Environment
# Refactored from legacy 010-add-plugins.zsh (lines 75-82)
# PRE_PLUGIN_DEPS: 050-dev-node.zsh (NVM environment variables)
# POST_PLUGIN_DEPS: none
# RESTART_REQUIRED: yes-if-pre-missing
# D11 Override: PNPM supplemental flags block (opt-out) with validation marker `_ZF_PNPM_FLAGS`

# Check for pre-plugin dependencies
_check_node_pre_plugin_deps() {
  local missing_deps=()

  # Check if NVM environment setup exists in pre-plugins
  if [[ ! -f "${ZDOTDIR}/.zshrc.pre-plugins.d/050-dev-node.zsh" ]]; then
    missing_deps+=("050-dev-node.zsh (NVM environment variables)")
  fi

  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    echo ""
    echo "🔄 RESTART REQUIRED: Node.js plugins need pre-plugin setup"
    echo "📋 Missing pre-plugin dependencies:"
    for dep in "${missing_deps[@]}"; do
      echo "   - $dep"
    done
    echo "💡 Add NVM environment setup to .zshrc.pre-plugins.d/ and restart ZSH"
    echo ""
    return 1
  fi
  return 0
}

# Skip if OMZ plugins disabled or NVM plugins specifically disabled
if [[ "${ZSH_DISABLE_OMZ_PLUGINS:-0}" == "1" || "${ZSH_ENABLE_NVM_PLUGINS:-1}" != "1" ]]; then
  zf::debug "# [dev-node] Node.js plugins disabled (ZSH_DISABLE_OMZ_PLUGINS or ZSH_ENABLE_NVM_PLUGINS=0)"
  return 0
fi

# Run dependency check
if ! _check_node_pre_plugin_deps; then
  zf::debug "# [dev-node] Loading with missing pre-plugin deps (restart recommended)"
else
  zf::debug "# [dev-node] All dependencies satisfied"
fi

zf::debug "# [dev-node] Loading Node.js development environment..."

# CRITICAL: Handle NVM/NPM conflict
# NPM plugin sets NPM_CONFIG_PREFIX, but NVM requires it to be unset
# Solution: Load NPM first, then unset NPM_CONFIG_PREFIX, then load NVM

# Load NPM plugin first (guarded)
if typeset -f zgenom >/dev/null 2>&1; then
  zgenom oh-my-zsh plugins/npm || zf::debug "# [dev-node] npm plugin load failed"
else
  zf::debug "# [dev-node] zgenom absent; skipping npm plugin"
fi
zf::debug "# [dev-node] NPM plugin loaded"

# Handle NVM/NPM conflict: unset NPM_CONFIG_PREFIX for NVM compatibility
if [[ -n "${NPM_CONFIG_PREFIX:-}" ]]; then
  zf::debug "# [dev-node] Unsetting NPM_CONFIG_PREFIX for NVM compatibility (was: $NPM_CONFIG_PREFIX)"
  unset NPM_CONFIG_PREFIX
fi

# Now load NVM plugin (after NPM_CONFIG_PREFIX is cleared)
if typeset -f zgenom >/dev/null 2>&1; then
  zgenom oh-my-zsh plugins/nvm || zf::debug "# [dev-node] nvm plugin load failed"
else
  zf::debug "# [dev-node] zgenom absent; skipping nvm plugin"
fi
zf::debug "# [dev-node] NVM plugin loaded (NPM_CONFIG_PREFIX conflict resolved)"

# NVM configuration for lazy loading
export NVM_AUTO_USE=true
export NVM_LAZY_LOAD=true
export NVM_COMPLETION=true

# Herd NVM integration (if available)
if [[ -d "/Users/s-a-c/Library/Application Support/Herd/config/nvm" ]]; then
  export NVM_DIR="/Users/s-a-c/Library/Application Support/Herd/config/nvm"
  zf::debug "# [dev-node] Using Herd NVM at: $NVM_DIR"
fi

# Bun integration (additional runtime)
if [[ -d "$HOME/.bun" ]]; then
  export PATH="$HOME/.bun/bin:$PATH"
  zf::debug "# [dev-node] Bun runtime available"
fi

# PNPM integration (lightweight; does not require plugin manager)
# Detect via directory first (more reliable for fresh installs), otherwise command presence.
if [[ -z ${_ZF_PNPM_DONE:-} ]]; then
  if [[ -d "${XDG_DATA_HOME:-${HOME}/.local/share}/pnpm" ]]; then
    export PNPM_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/pnpm"
  elif [[ -d "${HOME}/.local/share/pnpm" ]]; then
    export PNPM_HOME="${HOME}/.local/share/pnpm"
  fi
  if [[ -n ${PNPM_HOME:-} && -d ${PNPM_HOME} ]]; then
    case ":$PATH:" in
    *":${PNPM_HOME}:"*) : ;;
    *) export PATH="${PNPM_HOME}:$PATH" ;;
    esac
    _ZF_PNPM=1
    zf::debug "# [dev-node] pnpm environment configured (PNPM_HOME=${PNPM_HOME})"
  elif command -v pnpm >/dev/null 2>&1; then
    _ZF_PNPM=1
    zf::debug "# [dev-node] pnpm command present (no PNPM_HOME directory detected)"
  else
    _ZF_PNPM=0
    zf::debug "# [dev-node] pnpm not detected"
  fi
  _ZF_PNPM_DONE=1
fi

# D11: PNPM supplemental flags (lean, opt-out)
# Goal: provide low-noise install experience without altering dependency resolution semantics.
# Opt-out: export ZF_PNPM_FLAGS_DISABLE=1 before this file loads.
# Markers:
#   _ZF_PNPM_FLAGS=1 when supplemental flags applied
#   _ZF_PNPM_FLAGS=0 when skipped (either pnpm absent or user disabled)
if [[ "${ZF_PNPM_FLAGS_DISABLE:-0}" != 1 && "${_ZF_PNPM:-0}" == 1 ]]; then
  # Use npm-compatible variable names respected by pnpm for behavior tuning.
  # These default to reducing non-essential output; they avoid changing dependency graph semantics.
  : "${npm_config_fund:=false}"     # Suppress funding prompt noise
  : "${npm_config_audit:=false}"    # Skip automatic audit (user can run manually)
  : "${npm_config_progress:=false}" # Reduce progress bar overhead in CI / fast shells
  export npm_config_fund npm_config_audit npm_config_progress
  _ZF_PNPM_FLAGS=1
  zf::debug "# [dev-node] pnpm supplemental flags applied (fund/audit/progress disabled)"
else
  _ZF_PNPM_FLAGS=0
  [[ "${ZF_PNPM_FLAGS_DISABLE:-0}" == 1 ]] && zf::debug "# [dev-node] pnpm supplemental flags explicitly disabled"
fi
export _ZF_PNPM _ZF_PNPM_FLAGS

zf::debug "# [dev-node] Node.js development environment loaded"

return 0
