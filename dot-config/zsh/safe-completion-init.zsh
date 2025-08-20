# Safe Minimal Completion Initialization
# Replaces problematic completion systems

# Only initialize if compinit is available
if autoload -Uz compinit 2>/dev/null; then
    # Use simple compinit without cache manipulation
    compinit -i 2>/dev/null
    
    # Basic completion settings only
    zstyle ':completion:*' menu select
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
    zstyle ':completion:*' use-cache on
    
    # Safe bashcompinit if available
    if autoload -Uz bashcompinit 2>/dev/null; then
        bashcompinit 2>/dev/null
    fi
fi
