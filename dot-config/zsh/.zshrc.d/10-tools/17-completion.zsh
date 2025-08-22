# Completion System Integration with Centralized Management
[[ "$ZSH_DEBUG" == "1" ]] && printf "# Loading completion system integration\n" >&2

# Check if centralized completion management is available
if [[ -n "${ZSH_COMPLETION_MANAGEMENT_LOADED:-}" ]]; then
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# Using centralized completion management system" >&2

    # Centralized system handles compinit, just add basic styles
    zstyle ':completion:*' menu select 2>/dev/null
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 2>/dev/null

    # Safe bashcompinit (if needed)
    if autoload -Uz bashcompinit 2>/dev/null; then
        bashcompinit 2>/dev/null
    fi
else
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# Fallback: Using simple completion system" >&2

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

[[ "$ZSH_DEBUG" == "1" ]] && echo "# Completion system integration loaded" >&2
