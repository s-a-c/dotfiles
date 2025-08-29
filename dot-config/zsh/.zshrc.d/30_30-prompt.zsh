#!/usr/bin/env zsh
# Prompt and UI Configuration - POST-PLUGIN PHASE
# Comprehensive prompt and UI setup from refactored zsh configuration
# This file consolidates theme and UI-related configurations

[[ "$ZSH_DEBUG" == "1" ]] && {
        zsh_debug_echo "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
    zsh_debug_echo "# [prompt-ui] Setting up prompt and UI configurations"
}

## [ui.bullet-train] - Bullet Train theme configuration
{
    zsh_debug_echo "# [ui.bullet-train]"

    export BULLETTRAIN_PROMPT_CHAR="$"
    export BULLETTRAIN_PROMPT_ORDER=(
        time
        status
        custom
        context
        dir
        screen
        perl
        ruby
        virtualenv
        nvm
        aws
        go
        rust
        elixir
        git
        hg
        cmd_exec_time
    )
}

## [ui.powerlevel10k] - Powerlevel10k theme configuration
{
    zsh_debug_echo "# [ui.powerlevel10k]"

    export POWERLEVEL9K_MODE='nerdfont-complete'
    export POWERLEVEL9K_DISABLE_HOT_RELOAD=false
}

## [ui.starship] - Starship prompt configuration
{
    zsh_debug_echo "# [ui.starship]"

    export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-${HOME}/.config}/starship.toml"
    export STARSHIP_CACHE="${XDG_CACHE_HOME:-${HOME}/.cache}/starship"
    export ZSH_THEME="jonathan"
}

## [ui.colorize] - Syntax highlighting for various tools
{
    zsh_debug_echo "# [ui.colorize]"

    export ZSH_COLORIZE_CHROMA_FORMATTER="terminal256"
    export ZSH_COLORIZE_STYLE="perldoc"
    export ZSH_COLORIZE_TOOL="chroma"
}

## [ui.vi-mode] - Vi mode cursor configuration
{
    zsh_debug_echo "# [ui.vi-mode]"

    export VI_MODE_SET_CURSOR=true
    export VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
    export VI_MODE_CURSOR_NORMAL=6  # Steady bar
    export VI_MODE_CURSOR_VISUAL=2  # Block
    export VI_MODE_CURSOR_INSERT=6  # Steady bar
    export VI_MODE_CURSOR_OPPEND=0  # Blinking block
}

## [ui.carapace] - Carapace completion styling
{
    zsh_debug_echo "# [ui.carapace]"

    export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
    zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
}

## [ui.thefuck] - The Fuck command correction
{
    zsh_debug_echo "# [ui.thefuck]"

    export THEFUCK_REQUIRE_CONFIRMATION=false
    export THEFUCK_WAIT_COMMAND=10
    export THEFUCK_NO_COLORS=false
}


## [ui.completion-styles] - Enhanced completion styling
{
    zsh_debug_echo "# [ui.completion-styles]"

    # Docker completion styling
    zstyle ':completion:*:*:docker:*' option-stacking yes
    zstyle ':completion:*:*:docker-*:*' option-stacking yes

    # General completion styling
    zstyle ':completion:*' menu select
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
    zstyle ':completion:*' group-name ''
    zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
    zstyle ':completion:*:messages' format '%F{purple}-- %d --%f'
    zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'
    zstyle ':completion:*:corrections' format '%F{green}-- %d (errors: %e) --%f'
}

## [ui.nvm-omz] - OMZ NVM plugin styling
{
    zsh_debug_echo "# [ui.nvm-omz]"

    zstyle ':omz:plugins:nvm' lazy yes
    zstyle ':omz:plugins:nvm' lazy-cmd eslint prettier typescript
    zstyle ':omz:plugins:nvm' autoload yes
}

# Check if Starship is available and preferred
if command_exists starship; then
    # Use Starship for modern, fast prompt
    eval "$(starship init zsh)"
    zsh_debug_echo "# [prompt] Starship prompt initialized"
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
        zsh_debug_echo " (${ref#refs/heads/})"
    }

    # Fast directory shortening
    prompt_dir() {
        zsh_debug_echo "${PWD/#$HOME/~}"
    }

    # Simple, fast prompt
    PROMPT='%F{blue}%n@%m%f:%F{yellow}$(prompt_dir)%f%F{green}$(git_prompt_info)%f$ '

    # Right prompt with time (optional)
    RPROMPT='%F{gray}%*%f'

    zsh_debug_echo "# [prompt] Built-in prompt configured"
}

# Check for P10k (Powerlevel10k) if available
if command_exists starship; then
    # Starship already handled above
    :
elif [[ -f "$ZDOTDIR/.p10k.zsh" ]]; then
    # Source P10k configuration if it exists
    source "$ZDOTDIR/.p10k.zsh"

    # Load P10k if available
    if zgenom_available; then
        zgenom load romkatv/powerlevel10k powerlevel10k
        zsh_debug_echo "# [prompt] Powerlevel10k prompt loaded"
    fi
else
    # Use built-in prompt
    setup_builtin_prompt
fi

zsh_debug_echo "# [prompt-ui] ✅ Prompt and UI configurations applied"
