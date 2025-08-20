# Prompt Configuration - Optimized for performance
# This file configures the shell prompt with minimal overhead
# Load time target: <50ms

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
}

# Check if Starship is available and preferred
if command_exists starship; then
    # Use Starship for modern, fast prompt
    eval "$(starship init zsh)"
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [prompt] Starship prompt initialized" >&2
    return 0
fi

# Fallback to optimized built-in prompt
setup_builtin_prompt() {
    # Enable prompt substitution
    setopt PROMPT_SUBST

    # Fast Git status function (only when in Git repo)
    git_prompt_info() {
        local ref
        ref=$(command git symbolic-ref HEAD 2>/dev/null) || \
        ref=$(command git rev-parse --short HEAD 2>/dev/null) || return 0
        echo " (${ref#refs/heads/})"
    }

    # Fast directory shortening
    prompt_dir() {
        echo "${PWD/#$HOME/~}"
    }

    # Simple, fast prompt
    PROMPT='%F{blue}%n@%m%f:%F{yellow}$(prompt_dir)%f%F{green}$(git_prompt_info)%f$ '

    # Right prompt with time (optional)
    RPROMPT='%F{gray}%*%f'

    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [prompt] Built-in prompt configured" >&2
}

# Check for P10k (Powerlevel10k) if available
if [[ -f "$ZDOTDIR/.p10k.zsh" ]]; then
    # Source P10k configuration if it exists
    source "$ZDOTDIR/.p10k.zsh"

    # Load P10k if available
    if zgenom_available; then
        zgenom load romkatv/powerlevel10k powerlevel10k
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [prompt] Powerlevel10k prompt loaded" >&2
    fi
elif command_exists starship; then
    # Starship already handled above
    :
else
    # Use built-in prompt
    setup_builtin_prompt
fi

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [30-ui] Prompt configuration complete" >&2
