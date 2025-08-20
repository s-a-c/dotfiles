# Safe Completion System Configuration
[[ "$ZSH_DEBUG" == "1" ]] && printf "# Loading safe completion system\n" >&2

# Use simple completion without complex cache manipulation
if autoload -Uz compinit 2>/dev/null; then
    # Simple compinit call
    compinit -i 2>/dev/null
    
    # Safe bashcompinit
    if autoload -Uz bashcompinit 2>/dev/null; then
        bashcompinit 2>/dev/null
    fi
fi

# Basic completion styles only
zstyle ':completion:*' menu select 2>/dev/null
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 2>/dev/null
zstyle ':completion:*' use-cache on 2>/dev/null

[[ "$ZSH_DEBUG" == "1" ]] && echo "# Safe completion system loaded" >&2
