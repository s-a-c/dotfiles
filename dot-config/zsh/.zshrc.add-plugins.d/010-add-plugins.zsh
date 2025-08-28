# Additional Plugin Configuration - Extends ZSH Quickstart Kit defaults
# CRITICAL: Maintains proper plugin loading order per ZSH-QS and zgenom best practices

# CRITICAL FIX: Add loading guard to prevent infinite loops
if [[ -n "${_ZSH_ADD_PLUGINS_LOADED:-}" ]]; then
    [[ "$ZSH_DEBUG" == "1" ]] &&     zsh_debug_echo "# [add-plugins] Already loaded, skipping to prevent infinite loop"
    return 0
fi
typeset -g _ZSH_ADD_PLUGINS_LOADED=1

[[ "$ZSH_DEBUG" == "1" ]] &&     zsh_debug_echo "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"

# =============================================================================
# PHASE 1: CORE FUNCTIONALITY PLUGINS (Load Early)
# These extend core shell functionality and should load before everything else
# =============================================================================

# Auto-pair quotes, brackets, etc. - loads early to avoid conflicts
zgenom load hlissner/zsh-autopair

# Abbreviations system - COMMENTED OUT DUE TO RECURSION ISSUES
# This plugin is causing infinite loops and job table overflow
# zgenom load olets/zsh-abbr

# =============================================================================
# PHASE 2: DEVELOPMENT ENVIRONMENT PLUGINS
# Load after core functionality but before performance/async plugins
# =============================================================================

# Node.js development environment - COMMENTED OUT to prevent conflicts
# DISABLED: npm plugin conflicts with NVM by setting NPM_CONFIG_PREFIX
# zgenom oh-my-zsh plugins/npm ; UNSET NPM_CONFIG_PREFIX
# DISABLED: NVM plugin can be slow to load and may conflict with lazy loading
# UNSET NPM_CONFIG_PREFIX ; zgenom oh-my-zsh plugins/nvm

# Development essentials - safe to load mid-sequence
zgenom oh-my-zsh plugins/composer
zgenom oh-my-zsh plugins/laravel

# System integration additions - load before async plugins
zgenom oh-my-zsh plugins/gh
zgenom oh-my-zsh plugins/iterm2

# =============================================================================
# PHASE 3: FILE MANAGEMENT AND NAVIGATION
# Load after development tools but before performance plugins
# =============================================================================

# File management additions - order matters for alias conflicts
zgenom oh-my-zsh plugins/aliases
zgenom oh-my-zsh plugins/eza

# Smart directory navigation - load after file management
zgenom oh-my-zsh plugins/zoxide

# =============================================================================
# PHASE 4: COMPLETION ENHANCEMENTS
# Load before async/performance plugins to ensure proper completion setup
# =============================================================================

# FZF integration - load before async plugins that might use it
zgenom oh-my-zsh plugins/fzf

# =============================================================================
# PHASE 5: PERFORMANCE AND ASYNC PLUGINS (Load Last)
# These plugins modify shell behavior and should load after everything else
# CRITICAL: Load order within this section matters for performance
# =============================================================================

# Command evaluation caching - load first among performance plugins
zgenom load mroth/evalcache

# Async loading utilities - load after evalcache but before defer
zgenom load mafredri/zsh-async

# Deferred loading utilities - MUST be last among performance plugins
# This allows other plugins to register deferred functions
zgenom load romkatv/zsh-defer

# =============================================================================
# COMPLETION & FINALIZATION
# =============================================================================

# Note: Key bindings for history substring search are handled by default setup
# The default .zgen-setup already loads syntax highlighting in correct order:
# 1. zdharma-continuum/fast-syntax-highlighting
# 2. zsh-users/zsh-history-substring-search
# We must NOT interfere with this critical ordering

[[ "$ZSH_DEBUG" == "1" ]] &&     zsh_debug_echo "# [add-plugins] Optimal plugin loading sequence complete"
