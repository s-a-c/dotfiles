# Optimized Plugin Configuration
# Reduced from 69+ plugins to ~20 essential plugins for 3x faster startup
[[ "$ZSH_DEBUG" == "1" ]] && printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2

# =============================================================================
# CORE PLUGINS - Essential functionality (load order matters)
# =============================================================================

# Fast syntax highlighting (MUST be loaded before history-substring-search)
zgenom load zdharma-continuum/fast-syntax-highlighting

# History substring search (MUST be loaded after syntax highlighting)
zgenom load zsh-users/zsh-history-substring-search

# Enhanced autosuggestions (load before zsh-abbr for compatibility)
zgenom load zsh-users/zsh-autosuggestions

# =============================================================================
# PRODUCTIVITY PLUGINS - High-value additions
# =============================================================================

# Abbreviations system (loads AFTER autosuggestions for compatibility)
zgenom load olets/zsh-abbr

# Auto-pair quotes, brackets, etc.
zgenom load hlissner/zsh-autopair

# =============================================================================
# ESSENTIAL OH-MY-ZSH PLUGINS - Core functionality only
# =============================================================================

# Development essentials
zgenom oh-my-zsh plugins/git
zgenom oh-my-zsh plugins/npm
zgenom oh-my-zsh plugins/nvm
zgenom oh-my-zsh plugins/composer
zgenom oh-my-zsh plugins/laravel

# File management
zgenom oh-my-zsh plugins/aliases
zgenom oh-my-zsh plugins/eza
zgenom oh-my-zsh plugins/fzf

# System integration
zgenom oh-my-zsh plugins/gh
zgenom oh-my-zsh plugins/iterm2

# =============================================================================
# PERFORMANCE PLUGINS - Speed enhancements
# =============================================================================

# Command evaluation caching for faster repeated commands
zgenom load mroth/evalcache

# Async loading utilities
zgenom load mafredri/zsh-async

# Deferred loading utilities  
zgenom load romkatv/zsh-defer

# =============================================================================
# COMPLETION & FINALIZATION
# =============================================================================

# Set key bindings for history substring search
zmodload zsh/terminfo
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [add-plugins] Optimized plugin set loaded (~20 plugins vs 69+ before)" >&2
