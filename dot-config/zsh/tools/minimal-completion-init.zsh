#!/usr/bin/env zsh
# Minimal completion initialization
# UPDATED: Consistent with .zshenv configuration

# Single-run guard to ensure compinit executes only once per session
[[ -n ${_COMPINIT_DONE:-} ]] && return

# Source .zshenv to ensure consistent environment variables
[[ -f "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv" ]] && source "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv"

if command -v compinit >/dev/null 2>&1; then
    autoload -Uz compinit
    # Use consistent compdump path (fallback if not exported yet)
    local compdump_file="${ZGEN_CUSTOM_COMPDUMP:-${ZSH_COMPDUMP:-${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zcompdump}}"
    compinit -d "$compdump_file" 2>/dev/null || true
    _COMPINIT_DONE=1
    export _COMPINIT_DONE
    # Use zf::debug from .zshenv if available
    if declare -f zf::debug >/dev/null 2>&1; then
        zf::debug "# [minimal-completion-init] Initialized with $compdump_file (single-run)"
    fi
fi
