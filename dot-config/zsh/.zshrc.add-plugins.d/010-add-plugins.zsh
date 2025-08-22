# Additional Plugin Configuration - Extends ZSH Quickstart Kit defaults
# Only includes plugins NOT already loaded by the default .zgen-setup
[[ "$ZSH_DEBUG" == "1" ]] && printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2

# =============================================================================
# PRODUCTIVITY ADDITIONS - Plugins not in default setup
# =============================================================================

# Abbreviations system (not in default setup)
zgenom load olets/zsh-abbr

# Auto-pair quotes, brackets, etc. (not in default setup)
zgenom load hlissner/zsh-autopair

# =============================================================================
# ADDITIONAL OH-MY-ZSH PLUGINS - Extending defaults
# =============================================================================
# NOTE: Default already includes: git, colored-man-pages, pip, sudo, aws,
# chruby, github, python, rsync, screen, vagrant, brew (if available), macos (if macOS)

# Development essentials not in defaults
# DISABLED: npm plugin conflicts with NVM by setting NPM_CONFIG_PREFIX
# zgenom oh-my-zsh plugins/npm
# TEMPORARILY DISABLED: NVM plugin for performance testing
# zgenom oh-my-zsh plugins/nvm
zgenom oh-my-zsh plugins/composer
zgenom oh-my-zsh plugins/laravel

# File management additions
zgenom oh-my-zsh plugins/aliases
zgenom oh-my-zsh plugins/eza

# System integration additions
zgenom oh-my-zsh plugins/gh
zgenom oh-my-zsh plugins/iterm2

# Smart directory navigation (zoxide integration)
zgenom oh-my-zsh plugins/zoxide

# =============================================================================
# PERFORMANCE PLUGINS - Not in defaults
# =============================================================================

# Command evaluation caching for faster repeated commands
zgenom load mroth/evalcache

# Async loading utilities
zgenom load mafredri/zsh-async

# Deferred loading utilities
zgenom load romkatv/zsh-defer

# =============================================================================
# FZF INTEGRATION - Handled separately to avoid conflicts
# =============================================================================

# FZF integration is handled by the default unixorn/fzf-zsh-plugin
# We'll add the oh-my-zsh fzf plugin for additional completions
zgenom oh-my-zsh plugins/fzf

# =============================================================================
# COMPLETION & FINALIZATION
# =============================================================================

# Note: Key bindings for history substring search are handled by default setup
# No need to duplicate them here

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [add-plugins] Additional plugins loaded (no duplicates with defaults)" >&2
