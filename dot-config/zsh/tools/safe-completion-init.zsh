#!/opt/homebrew/bin/zsh
# Safe Minimal Completion Initialization
# Replaces problematic completion systems
# UPDATED: Consistent with .zshenv configuration

# Source .zshenv to ensure consistent environment variables
[[ -f "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv" ]] && source "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv"

# Only initialize if compinit is available
if autoload -Uz compinit 2>/dev/null; then
    # Use ZSH_COMPDUMP from .zshenv for consistency
    local compdump_file="${ZSH_COMPDUMP:-${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zcompdump}"

    # Use simple compinit with .zshenv dump path
    compinit -i -d "$compdump_file" 2>/dev/null

    # Basic completion settings only
    zstyle ':completion:*' menu select
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
    zstyle ':completion:*' use-cache on

    # Use ZSH_CACHE_DIR from .zshenv for completion cache
    if [[ -n "$ZSH_CACHE_DIR" ]]; then
        zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR"
    fi

    # Safe bashcompinit if available
    if autoload -Uz bashcompinit 2>/dev/null; then
        bashcompinit 2>/dev/null
    fi

    # Use zsh_debug_echo from .zshenv if available
    if declare -f zsh_debug_echo >/dev/null 2>&1; then
        zsh_debug_echo "# [safe-completion-init] Initialized with $compdump_file"
    fi
fi
