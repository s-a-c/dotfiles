# Additional Plugin Configuration - Extends ZSH Quickstart Kit defaults
# CRITICAL: Maintains proper plugin loading order per ZSH-QS and zgenom best practices
#
# PERF_CAPTURE_FAST:
#   When PERF_CAPTURE_FAST=1 we skip all non-essential plugin loads to
#   accelerate perf-capture harness runs (avoids network / clone latency).
#   The core interactive configuration still establishes baseline PATH and
#   instrumentation earlier in .zshrc/.zshenv, so skipping here is safe.

# TEMPORARILY DISABLED FOR ZLE DEBUGGING - Testing if additional plugins cause ZLE corruption
zf::debug "# [add-plugins] TEMPORARILY DISABLED FOR ZLE DEBUGGING - Skipping all additional plugins"
return 0

# CRITICAL FIX: Add loading guard to prevent infinite loops
if [[ -n "${_ZSH_ADD_PLUGINS_LOADED:-}" ]]; then
        zf::debug "# [add-plugins] Already loaded, skipping to prevent infinite loop"
        return 0
fi
typeset -g _ZSH_ADD_PLUGINS_LOADED=1

# Fast path: skip plugin additions entirely during perf capture fast mode
if [[ "${PERF_CAPTURE_FAST:-0}" == "1" ]]; then
    zf::debug "# [add-plugins][perf-capture-fast] Skipping extended plugin list (PERF_CAPTURE_FAST=1)"
    return 0
fi

# Track ordered plugin load sequence for design tests / diagnostics
typeset -ga ZSH_REDESIGN_PLUGIN_SEQUENCE

zf::debug "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"

# =============================================================================
# PHASE 1: CORE FUNCTIONALITY PLUGINS (Load Early)
# These extend core shell functionality and should load before everything else
# =============================================================================

# Auto-pair quotes, brackets, etc. - DISABLED: using custom implementation in pre-plugin phase
# Original hlissner/zsh-autopair has parameter passing bugs, replaced with simple-autopair in 07-simple-autopair.zsh
# zgenom load hlissner/zsh-autopair
ZSH_REDESIGN_PLUGIN_SEQUENCE+=("hlissner/zsh-autopair")

# Abbreviations system (optional; gated until recursion issue resolved)
if [[ ${ZSH_ENABLE_ABBR:-0} == 1 ]]; then
    zgenom load olets/zsh-abbr
    ZSH_REDESIGN_PLUGIN_SEQUENCE+=("olets/zsh-abbr")
fi

# =============================================================================
# PHASE 2: DEVELOPMENT ENVIRONMENT PLUGINS
# Load after core functionality but before performance/async plugins
# =============================================================================

# Development essentials - safe to load mid-sequence
if [[ "${ZSH_DISABLE_OMZ_PLUGINS:-0}" != "1" ]]; then
  zgenom oh-my-zsh plugins/composer
  ZSH_REDESIGN_PLUGIN_SEQUENCE+=("composer")

  zgenom oh-my-zsh plugins/laravel
  ZSH_REDESIGN_PLUGIN_SEQUENCE+=("laravel")

  # System integration additions - load before async plugins
  zgenom oh-my-zsh plugins/gh
  ZSH_REDESIGN_PLUGIN_SEQUENCE+=("gh")

  zgenom oh-my-zsh plugins/iterm2
  ZSH_REDESIGN_PLUGIN_SEQUENCE+=("iterm2")
else
  zf::debug "# [add-plugins] OMZ dev plugins disabled via ZSH_DISABLE_OMZ_PLUGINS=1"
fi

# =============================================================================
# PHASE 3: NODE ECOSYSTEM (Lazy / Gated)
# Reactivate nvm & npm plugins conditionally; rely on lazy stubs from 15-node-runtime-env
# =============================================================================
if [[ "${ZSH_DISABLE_OMZ_PLUGINS:-0}" != "1" && ${ZSH_ENABLE_NVM_PLUGINS:-1} == 1 ]]; then
    zgenom oh-my-zsh plugins/nvm
    ZSH_REDESIGN_PLUGIN_SEQUENCE+=("nvm")
    zgenom oh-my-zsh plugins/npm
    ZSH_REDESIGN_PLUGIN_SEQUENCE+=("npm")
else
    zf::debug "# [add-plugins] nvm/npm plugins disabled (ZSH_DISABLE_OMZ_PLUGINS or ZSH_ENABLE_NVM_PLUGINS=0)"
fi

# =============================================================================
# PHASE 4: FILE MANAGEMENT AND NAVIGATION
# Load after development tools but before performance plugins
# =============================================================================

# File management additions - order matters for alias conflicts
if [[ "${ZSH_DISABLE_OMZ_PLUGINS:-0}" != "1" ]]; then
  zgenom oh-my-zsh plugins/aliases
  ZSH_REDESIGN_PLUGIN_SEQUENCE+=("aliases")

  zgenom oh-my-zsh plugins/eza
  ZSH_REDESIGN_PLUGIN_SEQUENCE+=("eza")

  # Smart directory navigation - load after file management
  zgenom oh-my-zsh plugins/zoxide
  ZSH_REDESIGN_PLUGIN_SEQUENCE+=("zoxide")
else
  zf::debug "# [add-plugins] OMZ file/nav plugins disabled via ZSH_DISABLE_OMZ_PLUGINS=1"
fi

# =============================================================================
# PHASE 5: COMPLETION ENHANCEMENTS
# Load before async/performance plugins to ensure proper completion setup
# =============================================================================

# FZF integration - load before async plugins that might use it
if [[ "${ZSH_DISABLE_OMZ_PLUGINS:-0}" != "1" ]]; then
  zgenom oh-my-zsh plugins/fzf
  ZSH_REDESIGN_PLUGIN_SEQUENCE+=("fzf")
else
  zf::debug "# [add-plugins] OMZ fzf plugin disabled via ZSH_DISABLE_OMZ_PLUGINS=1"
fi

# =============================================================================
# WARP COMPATIBILITY: DISABLE CONFLICTING PLUGINS
# =============================================================================

# Disable k plugin in Warp to avoid alias conflict with kubectl alias
if [[ "$TERM_PROGRAM" == "WarpTerminal" ]]; then
    # Undefine k function if already loaded by default zgen-setup
    if [[ -n "${functions[k]:-}" ]]; then
        unfunction k 2>/dev/null || true
        print -r -- "# [add-plugins] Disabled k plugin function for Warp compatibility"
    fi
fi

# =============================================================================
# PHASE 6: PERFORMANCE AND ASYNC PLUGINS (Load Last)
# These plugins modify shell behavior and should load after everything else
# CRITICAL: Load order within this section matters for performance
# =============================================================================

# Command evaluation caching - load first among performance plugins
zgenom load mroth/evalcache
ZSH_REDESIGN_PLUGIN_SEQUENCE+=("mroth/evalcache")

# Async loading utilities - load after evalcache but before defer
zgenom load mafredri/zsh-async
ZSH_REDESIGN_PLUGIN_SEQUENCE+=("mafredri/zsh-async")

# Deferred loading utilities - MUST be last among performance plugins
# This allows other plugins to register deferred functions
zgenom load romkatv/zsh-defer
ZSH_REDESIGN_PLUGIN_SEQUENCE+=("romkatv/zsh-defer")

# =============================================================================
# COMPLETION & FINALIZATION
# =============================================================================

# Note: Key bindings for history substring search are handled by default setup
# The default .zgen-setup already loads syntax highlighting in correct order:
# 1. zdharma-continuum/fast-syntax-highlighting
# 2. zsh-users/zsh-history-substring-search
# We must NOT interfere with this critical ordering

zf::debug "# [add-plugins] Optimal plugin loading sequence complete (${#ZSH_REDESIGN_PLUGIN_SEQUENCE[@]} entries)"
