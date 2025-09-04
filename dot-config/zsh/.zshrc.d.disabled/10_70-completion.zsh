#!/usr/bin/env zsh
# Completion System Integration with Centralized Management
zsh_debug_echo "# Loading completion system integration"

# Check if centralized completion management is available
if [[ -n "${ZSH_COMPLETION_MANAGEMENT_LOADED:-}" ]]; then
    zsh_debug_echo "# Using centralized completion management system"

    # Centralized system handles compinit, just add basic styles
    zstyle ':completion:*' menu select 2>/dev/null
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 2>/dev/null

    # Safe bashcompinit (if needed)
    if autoload -Uz bashcompinit 2>/dev/null; then
        bashcompinit 2>/dev/null
    fi
else
    zsh_debug_echo "# Fallback: Using simple completion system"

    # Fallback to simple completion system
    if autoload -Uz compinit 2>/dev/null; then
        # Simple compinit call
        compinit -i 2>/dev/null

        # Safe bashcompinit
        if autoload -Uz bashcompinit 2>/dev/null; then
            bashcompinit 2>/dev/null
        fi
    fi

    # Basic completion styles
    zstyle ':completion:*' menu select 2>/dev/null
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 2>/dev/null
    zstyle ':completion:*' use-cache on 2>/dev/null
fi

zsh_debug_echo "# Completion system integration loaded"
