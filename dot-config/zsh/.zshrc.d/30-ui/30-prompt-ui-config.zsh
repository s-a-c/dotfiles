# Prompt and UI Configuration - POST-PLUGIN PHASE
# Comprehensive prompt and UI setup from refactored zsh configuration
# This file consolidates theme and UI-related configurations

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
    echo "# [prompt-ui] Setting up prompt and UI configurations" >&2
}

## [ui.bullet-train] - Bullet Train theme configuration
{
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [ui.bullet-train]" >&2

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
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [ui.powerlevel10k]" >&2

    export POWERLEVEL9K_MODE='nerdfont-complete'
    export POWERLEVEL9K_DISABLE_HOT_RELOAD=false
}

## [ui.starship] - Starship prompt configuration
{
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [ui.starship]" >&2

    export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-${HOME}/.config}/starship.toml"
    export STARSHIP_CACHE="${XDG_CACHE_HOME:-${HOME}/.cache}/starship"
    export ZSH_THEME="jonathan"
}

## [ui.colorize] - Syntax highlighting for various tools
{
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [ui.colorize]" >&2

    export ZSH_COLORIZE_CHROMA_FORMATTER="terminal256"
    export ZSH_COLORIZE_STYLE="perldoc"
    export ZSH_COLORIZE_TOOL="chroma"
}

## [ui.vi-mode] - Vi mode cursor configuration
{
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [ui.vi-mode]" >&2

    export VI_MODE_SET_CURSOR=true
    export VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
    export VI_MODE_CURSOR_NORMAL=6  # Steady bar
    export VI_MODE_CURSOR_VISUAL=2  # Block
    export VI_MODE_CURSOR_INSERT=6  # Steady bar
    export VI_MODE_CURSOR_OPPEND=0  # Blinking block
}

## [ui.carapace] - Carapace completion styling
{
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [ui.carapace]" >&2

    export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
    zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
}

## [ui.thefuck] - The Fuck command correction
{
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [ui.thefuck]" >&2

    export THEFUCK_REQUIRE_CONFIRMATION=false
    export THEFUCK_WAIT_COMMAND=10
    export THEFUCK_NO_COLORS=false
}

## [ui.ssh-agent] - SSH agent configuration
{
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [ui.ssh-agent]" >&2

    export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR:-/tmp}/ssh-agent.sock"
    export SSH_AGENT_PID="${XDG_RUNTIME_DIR:-/tmp}/ssh-agent.pid"

    # Configure OMZ ssh-agent plugin
    zstyle :omz:plugins:ssh-agent agent-forwarding yes
    zstyle :omz:plugins:ssh-agent autoload yes
    zstyle :omz:plugins:ssh-agent identities ~/.ssh/id_ed25519
    zstyle :omz:plugins:ssh-agent lazy yes
    zstyle :omz:plugins:ssh-agent quiet yes
    zstyle :omz:plugins:ssh-agent ssh-add-args --apple-load-keychain --apple-use-keychain
}

## [ui.completion-styles] - Enhanced completion styling
{
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [ui.completion-styles]" >&2

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
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [ui.nvm-omz]" >&2

    zstyle ':omz:plugins:nvm' lazy yes
    zstyle ':omz:plugins:nvm' lazy-cmd eslint prettier typescript
    zstyle ':omz:plugins:nvm' autoload yes
}

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [prompt-ui] ✅ Prompt and UI configurations applied" >&2
