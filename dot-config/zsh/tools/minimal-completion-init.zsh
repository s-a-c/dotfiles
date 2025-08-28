#!/usr/bin/env zsh
# Minimal completion initialization
# UPDATED: Consistent with .zshenv configuration

# Source .zshenv to ensure consistent environment variables
[[ -f "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv" ]] && source "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv"

if command -v compinit >/dev/null 2>&1; then
    autoload -Uz compinit
    # Use ZSH_COMPDUMP from .zshenv for consistency
    local compdump_file="${ZSH_COMPDUMP:-${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zcompdump}"
    compinit -d "$compdump_file" 2>/dev/null || true

    # Use zsh_debug_echo from .zshenv if available
    if declare -f zsh_debug_echo >/dev/null 2>&1; then
        zsh_debug_echo "# [minimal-completion-init] Initialized with $compdump_file"
    fi
fi
