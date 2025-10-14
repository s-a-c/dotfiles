#!/usr/bin/env zsh
# Safe completion rebuild function
# UPDATED: Consistent with .zshenv configuration

# Source .zshenv to ensure consistent environment variables
[[ -f "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv" ]] && source "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv"

rebuild_completions() {
<<<<<<< HEAD
        zf::debug "🔄 Rebuilding completions safely..."
=======
        zsh_debug_echo "🔄 Rebuilding completions safely..."
>>>>>>> origin/develop

    # Use ZSH_COMPDUMP from .zshenv for consistency
    local compdump_file="${ZSH_COMPDUMP:-${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zcompdump}"

    # Remove old cache using the correct path
    rm -f "${compdump_file}"* 2>/dev/null
    if [[ -n "$ZSH_CACHE_DIR" ]]; then
        rm -f "${ZSH_CACHE_DIR}"/.zcompdump* 2>/dev/null
    fi

    # Remove any legacy completion dumps
    rm -f ~/.zcompdump* 2>/dev/null

    # Rebuild with proper error handling using .zshenv path
    if command -v compinit >/dev/null 2>&1; then
        autoload -Uz compinit
        compinit -d "$compdump_file"
<<<<<<< HEAD
            zf::debug "✅ Completions rebuilt successfully at $compdump_file"
    else
            zf::debug "⚠️  compinit not available"
=======
            zsh_debug_echo "✅ Completions rebuilt successfully at $compdump_file"
    else
            zsh_debug_echo "⚠️  compinit not available"
>>>>>>> origin/develop
        return 1
    fi
}

# Auto-run if script is executed directly
<<<<<<< HEAD
if [[ "${(%):-%N}" == "${0}" ]] || [[ "${(%):-%N}" == "${0:t}" ]]; then
=======
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${(%):-%N}" == "${0:t}" ]]; then
>>>>>>> origin/develop
    rebuild_completions
fi
