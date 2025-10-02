#!/usr/bin/env zsh
# Emergency Plugin Disable
# Temporarily disable problematic plugins causing ZLE widget errors

# Add to the top of post-plugin modules to prevent widget conflicts
export ZSH_AUTOSUGGEST_DISABLE=1
export DISABLE_AUTO_SUGGESTIONS=1

# Prevent zsh-autosuggestions from loading until ZLE is properly initialized
unset ZSH_AUTOSUGGEST_STRATEGY
unset ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE

# Disable gitstatus temporarily to prevent the cascade of errors
export GITSTATUS_DISABLE=1

# Create safe no-op functions for missing widget functions
_zsh_autosuggest_bind_widget() { return 0; }
_zsh_autosuggest_enable() { return 0; }
_zsh_autosuggest_disable() { return 0; }

echo "# [emergency] Problematic plugins temporarily disabled for ZLE repair"