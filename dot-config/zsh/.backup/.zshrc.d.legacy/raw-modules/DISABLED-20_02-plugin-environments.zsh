#!/usr/bin/env zsh
# Plugin Environment Configuration - POST-PLUGIN PHASE
# Comprehensive plugin environment setup from refactored zsh configuration
# This file consolidates plugin-specific environment variables and configurations

[[ "$ZSH_DEBUG" == "1" ]] && {
        zf::debug "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
    zf::debug "# [plugin-environments] Setting up plugin-specific environments"
}

## [plugins.zsh-abbr] - Abbreviation expansion system
{
    zf::debug "# [plugins.zsh-abbr]"

    export ABBR_AUTOLOAD=1                    # Auto-load abbreviations on startup
    export ABBR_DEFAULT_BINDINGS=1            # Enable default key bindings
    export ABBR_DEBUG=0                       # Disable debug output
    export ABBR_DRY_RUN=0                     # Disable dry-run mode
    export ABBR_FORCE=0                       # Don't force operations without confirmation
    export ABBR_QUIET=1                       # Enable quiet mode
    export ABBR_QUIETER=1                     # Enable quieter mode
    export ABBR_PRECMD_LOGS=0                 # Disable precmd logging
    export ABBR_SET_EXPANSION_CURSOR=1        # Enable cursor positioning after expansion
    export ABBR_SET_LINE_CURSOR=1             # Set cursor position in line
    unset NO_COLOR                            # Enable color output

    # Create placeholder widgets (will be properly defined by plugin)
    abbr-expand-and-space() { zle .self-insert }
    abbr-expand-and-accept() { zle .self-insert }
    abbr-expand-and-insert() { zle .self-insert }
    zle -N abbr-expand-and-space 2>/dev/null || true
    zle -N abbr-expand-and-accept 2>/dev/null || true
    zle -N abbr-expand-and-insert 2>/dev/null || true
}

## [plugins.zsh-alias-tips] - Alias suggestion system
{
    zf::debug "# [plugins.zsh-alias-tips]"

    export ZSH_PLUGINS_ALIAS_TIPS_REVEAL=1
    export ZSH_PLUGINS_ALIAS_TIPS_REVEAL_TEXT="Alias tip: "
    # export ZSH_PLUGINS_ALIAS_TIPS_REVEAL_EXCLUDES=(_ ll vi)
}

## [plugins.zsh-async] - Asynchronous command execution
{
    zf::debug "# [plugins.zsh-async]"

    export ASYNC_PROMPT="async> "
    export ASYNC_SHOW_ON_COMMAND=1
    export ASYNC_SHOW_PID=1
    export ASYNC_SHOW_TIME=1
    export ASYNC_SHOW_WAIT=1
}

## [plugins.zsh-autopair] - Automatic bracket/quote pairing
{
    zf::debug "# [plugins.zsh-autopair]"

    typeset -gA AUTOPAIR_PAIRS
    AUTOPAIR_PAIRS+=("<" ">")
}

## [plugins.zsh-autosuggestions] - Command autosuggestions
{
    zf::debug "# [plugins.zsh-autosuggestions]"

    export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"
    export ZSH_AUTOSUGGEST_USE_ASYNC=1
    ZSH_AUTOSUGGEST_STRATEGY=( abbreviations $ZSH_AUTOSUGGEST_STRATEGY )
}

## [plugins.zsh-defer] - Deferred command execution
{
    zf::debug "# [plugins.zsh-defer]"

    export ZSH_DEFER_PROMPT="defer> "
    export ZSH_DEFER_SHOW_ON_COMMAND=1
    export ZSH_DEFER_SHOW_PID=1
    export ZSH_DEFER_SHOW_TIME=1
    export ZSH_DEFER_SHOW_WAIT=1
}

## [plugins.zsh-navigation-tools] - Enhanced navigation
{
    zf::debug "# [plugins.zsh-navigation-tools]"

    export ZNT_HISTORY_ACTIVE_TEXT="reverse"
    export ZNT_HISTORY_NLIST_COLORING_PATTERN="*"
    export ZNT_BUFFER_ACTIVE_TEXT="reverse"

    # Key bindings (will be enhanced by plugin)
    zle -N znt-history-widget 2>/dev/null || true
    bindkey '^R' znt-history-widget 2>/dev/null || true
}

## [plugins.fast-syntax-highlighting] - Syntax highlighting
{
    zf::debug "# [plugins.fast-syntax-highlighting]"

    typeset -gxA FAST_HIGHLIGHT_STYLES
    FAST_HIGHLIGHT_STYLES[command]='fg=green,bold'
    FAST_HIGHLIGHT_STYLES[path]='fg=blue,bold'
    FAST_HIGHLIGHT_STYLES[variable]='fg=cyan'

    export FAST_WORK_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/fsh"

    typeset -gxA FAST_HIGHLIGHT
    FAST_HIGHLIGHT[chroma-docker]=1
    FAST_HIGHLIGHT[chroma-git]=1
    FAST_HIGHLIGHT[chroma-man]=1
    FAST_HIGHLIGHT[chroma-ssh]=1
    FAST_HIGHLIGHT[no_theme_messages]=1
    FAST_HIGHLIGHT[no_unknown_widget_warning]=1
    FAST_HIGHLIGHT[use_brackets]=1
}

## [plugins.forgit] - Interactive git with fzf
{
    zf::debug "# [plugins.forgit]"

    export FORGIT_NO_ALIASES="1"
    export FORGIT_LOG_GRAPH_ENABLE="true"
    export FORGIT_COPY_CMD="pbcopy"
}

## [plugins.globalias] - Global alias expansion
{
    zf::debug "# [plugins.globalias]"

    GLOBALIAS_FILTER_VALUES=(
        ls
        ll
        la
        cd
        git
    )
}

## [plugins.you-should-use] - Alias usage reminder
{
    zf::debug "# [plugins.you-should-use]"

    export YSU_HARDCORE=1
    export YSU_MESSAGE_POSITION="after"
    export YSU_MESSAGE_FORMAT="$(command -v tput >/dev/null 2>&1 && tput setaf 1 || zf::debug '')Hey! I found this %alias_type for %command: %alias$(command -v tput >/dev/null 2>&1 && tput sgr0 || zf::debug '')"
    export YSU_IGNORE_ALIASES=(
        g
        ll
        la
        please
    )
}

## [plugins.evalcache] - Command evaluation caching
{
    zf::debug "# [plugins.evalcache]"

    export ZSH_EVALCACHE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/zsh-evalcache"
}

## [plugins.enhancd] - Enhanced cd command
{
    zf::debug "# [plugins.enhancd]"

    export ENHANCD_COMMAND='cd'
    export ENHANCD_DOT_ARG='..'
    export ENHANCD_DOT_SHOW_FULLPATH=1
    export ENHANCD_DOT_SHOW_HIDDEN=1
    export ENHANCD_FILTER="fzf --height 40%:fzy"
    export ENHANCD_HYPHEN_ARG='-'
    export ENHANCD_USE_ABBREV="${ENHANCD_USE_ABBREV:-true}"
}

## [plugins.zoxide] - Smart directory jumping
{
    zf::debug "# [plugins.zoxide]"

    export _ZO_DATA_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/zoxide"
    export _ZO_zf::debug=1
    export _ZO_RESOLVE_SYMLINKS=1
}

zf::debug "# [plugin-environments] ✅ Plugin environments configured"
