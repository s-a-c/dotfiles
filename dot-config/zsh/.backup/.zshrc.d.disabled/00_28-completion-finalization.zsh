#!/usr/bin/env zsh
# Safe completion initialization - prevents multiple compinit calls

# Prevent multiple initializations
if [[ -n "${_COMPINIT_INITIALIZED:-}" ]]; then
    return 0
fi

# Use shared compdump file
local compdump="$ZSH_CACHE_DIR/.zcompdump"
mkdir -p "$(dirname "$compdump")"

# Initialize completion system once
autoload -Uz compinit
if [[ -f "$compdump" && "$compdump" -nt ~/.zshrc ]]; then
    compinit -C -d "$compdump" >/dev/null 2>&1
else
    compinit -d "$compdump" >/dev/null 2>&1
fi

# Mark as initialized
export _COMPINIT_INITIALIZED=1
