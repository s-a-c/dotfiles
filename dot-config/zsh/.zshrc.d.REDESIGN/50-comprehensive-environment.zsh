#!/usr/bin/env zsh
# ==============================================================================
# 20-COMPREHENSIVE-ENVIRONMENT.ZSH - Complete Environment Setup (REDESIGN v2)
# ==============================================================================
# Purpose: Consolidated environment setup including UI, development tools,
#          performance monitoring, aliases, legacy compatibility, and integrations
# Consolidates: 02-performance-monitoring.zsh, 04-environment-options.zsh,
#              06-user-interface.zsh, 07-development-tools.zsh,
#              08-legacy-compatibility.zsh, 09-external-integrations.zsh,
#              90-zqs-quickstart-compat.zsh, 99-external-tools.zsh,
#              99-post-initialization.zsh
# Load Order: Final (20-) comprehensive setup
# Author: ZSH Configuration Redesign System
# Created: 2025-09-22
# Version: 2.0.0
# ==============================================================================

# Prevent multiple loading
if [[ -n "${_COMPREHENSIVE_ENV_REDESIGN:-}" ]]; then
    return 0
fi
export _COMPREHENSIVE_ENV_REDESIGN=1

# Debug helper
# Use direct zf:: debug calls
zf::debug "[COMPREHENSIVE-ENV] Loading comprehensive environment setup (v2.0.0)"

# ==============================================================================
# SECTION 1: PERFORMANCE MONITORING
# ==============================================================================

# Performance tracking variables
export ZSH_PERF_TRACK="${ZSH_PERF_TRACK:-1}"
export ZSH_PERF_LOG="${ZSH_PERF_LOG:-$ZDOTDIR/logs/performance.log}"

# Performance monitoring functions
perf_start() {
    local name="${1:-default}"
    export PERF_START_${name}="$(date +%s%3N 2>/dev/null || date +%s000)"
}

perf_end() {
    local name="${1:-default}"
    local start_var="PERF_START_${name}"
    local start_time="${(P)start_var}"

    if [[ -n "$start_time" ]]; then
        local current_time="$(date +%s%3N 2>/dev/null || date +%s000)"
        local elapsed=$((current_time - start_time))
        echo "Performance $name: ${elapsed}ms"

        if [[ "${ZSH_PERF_TRACK}" == "1" ]] && [[ -n "$ZSH_PERF_LOG" ]]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') $name: ${elapsed}ms" >> "$ZSH_PERF_LOG"
        fi
    fi
}

zf::debug "[COMPREHENSIVE-ENV] Performance monitoring configured"

# ==============================================================================
# SECTION 2: ENVIRONMENT OPTIONS AND VARIABLES
# ==============================================================================

# XDG Base Directory specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# History configuration
export HISTFILE="${HISTFILE:-$ZDOTDIR/.zsh_history}"
export HISTSIZE="${HISTSIZE:-50000}"
export SAVEHIST="${SAVEHIST:-50000}"

# Pager configuration
if command -v less >/dev/null 2>&1; then
    export PAGER="less"
    export LESS="-R -F -X -i -M -w -z-4"
elif command -v more >/dev/null 2>&1; then
    export PAGER="more"
fi

# Editor configuration (fallback if not already set)
if [[ -z "${EDITOR:-}" ]]; then
    for editor in nvim vim nano; do
        if command -v "$editor" >/dev/null 2>&1; then
            export EDITOR="$editor"
            export VISUAL="$editor"
            break
        fi
    done
fi

# Language and locale
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

zf::debug "[COMPREHENSIVE-ENV] Environment options configured"

# ==============================================================================
# SECTION 3: USER INTERFACE AND PROMPT
# ==============================================================================

# Color support
if [[ -t 1 ]]; then
    export CLICOLOR=1
    export LSCOLORS="ExFxBxDxCxegedabagacad"

    # Modern ls colors
    if command -v dircolors >/dev/null 2>&1; then
        test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    fi
fi

# Prompt configuration will be set after Starship initialization (see end of file)

zf::debug "[COMPREHENSIVE-ENV] User interface configured"

# ==============================================================================
# SECTION 4: ALIASES AND SHORTCUTS
# ==============================================================================

# Core aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Modern tool aliases (if available)
if command -v eza >/dev/null 2>&1; then
    alias ls='eza'
    alias ll='eza -la'
    alias tree='eza --tree'
elif command -v exa >/dev/null 2>&1; then
    alias ls='exa'
    alias ll='exa -la'
    alias tree='exa --tree'
fi

if command -v bat >/dev/null 2>&1; then
    alias cat='bat'
fi

# if command -v rg >/dev/null 2>&1; then
#     alias grep='rg'
# fi

if command -v fd >/dev/null 2>&1; then
    alias find='fd'
fi

# Git aliases
alias g='git'
alias ga='git add'
alias gc='git commit'
alias gd='git diff'
alias gs='git status'
alias gl='git log --oneline'
alias gp='git push'
alias gpl='git pull'

# Network aliases
alias ping='ping -c 5'
alias ports='netstat -tulan'

zf::debug "[COMPREHENSIVE-ENV] Aliases and shortcuts configured"

# ==============================================================================
# SECTION 5: DEVELOPMENT TOOLS INTEGRATION
# ==============================================================================

# Node.js development
if command -v node >/dev/null 2>&1; then
    export NODE_ENV="${NODE_ENV:-development}"
fi

# Python development
if command -v python3 >/dev/null 2>&1; then
    alias python='python3'
    alias pip='pip3'

    # Virtual environment helpers
    venv_activate() {
        local venv_path="${1:-venv}"
        if [[ -f "$venv_path/bin/activate" ]]; then
            source "$venv_path/bin/activate"
            echo "Activated virtual environment: $venv_path"
        else
            echo "Virtual environment not found: $venv_path"
            return 1
        fi
    }
fi

# Docker helpers
if command -v docker >/dev/null 2>&1; then
    alias dps='docker ps'
    alias dpsa='docker ps -a'
    alias di='docker images'
    alias drmi='docker rmi'
    alias dex='docker exec -it'

    # Docker cleanup
    docker_cleanup() {
        echo "Cleaning up Docker containers and images..."
        docker container prune -f
        docker image prune -f
        docker volume prune -f
        docker network prune -f
    }
fi

# Kubernetes helpers
if command -v kubectl >/dev/null 2>&1; then
    # Post-plugin k alias handling - check if k plugin function exists first
    if [[ -z "${functions[k]:-}" ]]; then
        # k plugin function doesn't exist, safe to set kubectl alias
        alias k='kubectl'
        zf::debug "[COMPREHENSIVE-ENV] Set kubectl k alias (no k plugin function found)"
    else
        # k plugin function exists, preserve it for directory listings
        zf::debug "[COMPREHENSIVE-ENV] Preserved k plugin function for directory listings"
    fi

    # Set all kubectl aliases (moved from pre-plugin to prevent conflicts)
    alias kg='kubectl get'
    alias kd='kubectl describe'
    alias ka='kubectl apply'
    alias kdel='kubectl delete'

    # Additional kubectl convenience aliases
    alias kgp='kubectl get pods'
    alias kgs='kubectl get services'
    alias kgd='kubectl get deployments'
    alias kdp='kubectl describe pod'
    alias kds='kubectl describe service'
    alias kdd='kubectl describe deployment'
fi

zf::debug "[COMPREHENSIVE-ENV] Development tools integrated"

# ==============================================================================
# SECTION 6: EXTERNAL INTEGRATIONS
# ==============================================================================

# FZF integration (if available and not already loaded)
if command -v fzf >/dev/null 2>&1 && [[ -z "${FZF_DEFAULT_COMMAND:-}" ]]; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

    # FZF options
    export FZF_DEFAULT_OPTS='
        --height 40%
        --layout=reverse
        --border
        --inline-info
        --color=fg:#d0d0d0,bg:#121212,hl:#5f87af
        --color=fg+:#d0d0d0,bg+:#262626,hl+:#5fd7ff
        --color=info:#afaf87,prompt:#d7005f,pointer:#af5fff
        --color=marker:#87ff00,spinner:#af5fff,header:#87afaf
    '
fi

# Zoxide integration (if available)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
    alias cd='z'
fi

# Starship prompt integration - deferred to end of initialization
# This is moved to the completion section to avoid conflicts with other initialization

zf::debug "[COMPREHENSIVE-ENV] External integrations configured"

# ==============================================================================
# SECTION 7: LEGACY COMPATIBILITY
# ==============================================================================

# Bash compatibility functions
if [[ "${BASH_COMPAT:-0}" == "1" ]]; then
    # Bash-style array handling
    setopt BASH_REMATCH
    setopt KSH_ARRAYS

    zf::debug "[COMPREHENSIVE-ENV] Bash compatibility mode enabled"
fi

# Old ZSH compatibility
if [[ "${ZSH_VERSION%%.*}" -lt 5 ]]; then
    # Compatibility for older ZSH versions
    setopt NO_BANG_HIST  # Disable ! history expansion for older shells
    zf::debug "[COMPREHENSIVE-ENV] Old ZSH compatibility enabled"
fi

# macOS compatibility
if command -v uname >/dev/null 2>&1 && [[ "$(uname -s 2>/dev/null)" == "Darwin" ]]; then
    # macOS-specific aliases
    alias o='open'
    alias finder='open -a Finder'

    # Homebrew integration
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

zf::debug "[COMPREHENSIVE-ENV] Legacy compatibility configured"

# ==============================================================================
# SECTION 8: QUICKSTART COMPATIBILITY
# ==============================================================================

# ZQS (ZSH Quickstart) compatibility layer
if [[ "${ZQS_COMPAT:-0}" == "1" ]]; then
    # Provide compatibility functions for ZQS scripts
    zqs_load() {
        local module="$1"
        zf::debug "[COMPREHENSIVE-ENV] ZQS compatibility: loading $module"
        # Stub implementation
        return 0
    }

    zqs_plugin() {
        local plugin="$1"
        zf::debug "[COMPREHENSIVE-ENV] ZQS compatibility: plugin $plugin"
        # Stub implementation
        return 0
    }

    zf::debug "[COMPREHENSIVE-ENV] ZQS compatibility layer enabled"
fi

# ==============================================================================
# SECTION 9: FINAL OPTIMIZATIONS
# ==============================================================================

# Rehash command completion (disabled - causes PATH issues)
# if [[ -o interactive ]]; then
#     # Rehash on command not found
#     command_not_found_handler() {
#         local cmd="$1"
#         echo "Command '$cmd' not found. Rehashing and retrying..."
#         rehash
#         if command -v "$cmd" >/dev/null 2>&1; then
#             "$cmd" "${@[2,-1]}"
#         else
#             echo "Command '$cmd' still not found after rehash."
#             return 127
#         fi
#     }
# fi

# Final PATH cleanup - FIXED: Use proper ZSH path array handling
if [[ "${PATH_CLEANUP:-1}" == "1" ]]; then
    zf::debug "[COMPREHENSIVE-ENV] PATH deduplication starting"

    # CRITICAL FIX: Ensure path array is properly synchronized with PATH
    # The issue was typeset -U was applied when path array was out of sync

    # First, rebuild path array from PATH string to ensure sync
    local -a new_path
    new_path=(${(s.:.)PATH})

    # Now apply uniqueness to the synchronized array
    typeset -U new_path

    # Rebuild PATH from the deduplicated path array
    export PATH="${(j.:.)new_path}"

    zf::debug "[COMPREHENSIVE-ENV] PATH deduplication complete: ${#new_path} entries"
fi

# Post-initialization hooks (comma-separated list of hook files)
if [[ -n "${POST_INIT_HOOKS:-}" ]]; then
    for hook in ${(s/:/)POST_INIT_HOOKS}; do
        if [[ -f "$hook" ]]; then
            source "$hook"
            zf::debug "[COMPREHENSIVE-ENV] Executed post-init hook: $hook"
        fi
    done
fi

zf::debug "[COMPREHENSIVE-ENV] Final optimizations applied"

# ==============================================================================
# PLUGIN COMPATIBILITY FIXES (POST-PLUGIN)
# ==============================================================================

# Note: autopair parameter initialization now handled in pre-plugin phase
# (25-lazy-integrations.zsh) to ensure parameters are available during plugin loading
zf::debug "[COMPREHENSIVE-ENV] Plugin compatibility handled in pre-plugin phase"

# ==============================================================================
# MODULE COMPLETION MARKER
# ==============================================================================
export COMPREHENSIVE_ENVIRONMENT_VERSION="2.1.0"
export COMPREHENSIVE_ENVIRONMENT_LOADED_AT="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'unknown')"
if command -v date >/dev/null 2>&1; then
    export COMPREHENSIVE_ENV_LOADED_AT="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'unknown')"
else
    export COMPREHENSIVE_ENV_LOADED_AT="unknown"
fi
export POST_PLUGIN_COMPLETE=1

# Starship prompt is available but disabled during startup to prevent hanging
# Harden starship against strict nounset and ensure prompt hooks run safely
_zqs__harden_starship_hooks() {
    # Helper only reasserts declarations if missing. Primary declarations live in .zshenv.
    _zqs__seed_starship_min() {
        if ! (( ${+STARSHIP_CMD_STATUS} )); then typeset -gi STARSHIP_CMD_STATUS=0; fi
        if ! (( ${+STARSHIP_PIPE_STATUS} )); then typeset -ga STARSHIP_PIPE_STATUS; STARSHIP_PIPE_STATUS=(); fi
    }
    _zqs__seed_starship_min

    if typeset -f starship_precmd >/dev/null 2>&1; then
        _zqs_starship_precmd() { setopt localoptions; unsetopt nounset; _zqs__seed_starship_min; starship_precmd "$@"; }
        typeset -ga precmd_functions 2>/dev/null || true
        if (( ${precmd_functions[(I)starship_precmd]} )); then
            precmd_functions=(${precmd_functions/starship_precmd/_zqs_starship_precmd})
        else
            precmd_functions=( _zqs_starship_precmd ${precmd_functions[@]} )
        fi
    fi
    if typeset -f starship_preexec >/dev/null 2>&1; then
        _zqs_starship_preexec() { setopt localoptions; unsetopt nounset; _zqs__seed_starship_min; starship_preexec "$@"; }
        typeset -ga preexec_functions 2>/dev/null || true
        if (( ${preexec_functions[(I)starship_preexec]} )); then
            preexec_functions=(${preexec_functions/starship_preexec/_zqs_starship_preexec})
        else
            preexec_functions=( _zqs_starship_preexec ${preexec_functions[@]} )
        fi
    fi
}

# Use 'init-starship' command to manually initialize starship prompt
if command -v starship >/dev/null 2>&1 && [[ -z "${ZSH_THEME:-}" ]]; then
    # Create manual starship initialization function
    init-starship() {
        echo "Initializing starship prompt..."

        # Ensure widgets array exists
        if ! readonly -p 2>/dev/null | grep -q '^widgets'; then
            typeset -gA widgets 2>/dev/null || true
        fi

        # Initialize starship (protect against nounset and missing widgets[] keys)
        typeset -gA widgets 2>/dev/null || true
        local __had_nounset=0
        if [[ -o nounset ]]; then
            set +u
            __had_nounset=1
        fi
    # Minimal reseed (robust against nounset/unset)
    if ! (( ${+STARSHIP_CMD_STATUS} )); then typeset -gi STARSHIP_CMD_STATUS=0; fi
    if ! (( ${+STARSHIP_PIPE_STATUS} )); then typeset -ga STARSHIP_PIPE_STATUS; STARSHIP_PIPE_STATUS=(); fi
        if eval "$(starship init zsh)"; then
            _zqs__harden_starship_hooks
            echo "✅ Starship prompt initialized successfully"
            echo "🚀 Enhanced prompt is now active"
        else
            echo "❌ Starship initialization failed"
            echo "📝 Keeping fallback prompt"
        fi
        (( __had_nounset )) && set -u
    }

    # Inform user about manual starship option only when auto-init is disabled
    if [[ -o interactive ]] && [[ "${ZSH_ENABLE_STARSHIP_AUTO:-1}" != "1" ]]; then
        echo "💫 Starship prompt available - run 'init-starship' to enable"
    fi
fi
# Optional auto-init for Starship behind a toggle
if command -v starship >/dev/null 2>&1 && [[ -z "${ZSH_THEME:-}" ]]; then
    if [[ "${ZSH_ENABLE_STARSHIP_AUTO:-1}" == "1" ]]; then
        # Ensure widgets param exists to avoid parameter errors in some environments
        typeset -gA widgets 2>/dev/null || true
        local __had_nounset=0
        if [[ -o nounset ]]; then
            set +u
            __had_nounset=1
        fi
    # Minimal reseed (robust against nounset/unset)
    if ! (( ${+STARSHIP_CMD_STATUS} )); then typeset -gi STARSHIP_CMD_STATUS=0; fi
    if ! (( ${+STARSHIP_PIPE_STATUS} )); then typeset -ga STARSHIP_PIPE_STATUS; STARSHIP_PIPE_STATUS=(); fi
        if eval "$(starship init zsh)"; then
            _zqs__harden_starship_hooks
            # Ensure promptsubst remains enabled after Starship init and after every precmd
            setopt PROMPT_SUBST
            # Add a precmd hook to ensure promptsubst stays enabled
            _zqs__ensure_promptsubst() { setopt PROMPT_SUBST 2>/dev/null || true; }
            if (( ${+precmd_functions} )); then
                precmd_functions+=(_zqs__ensure_promptsubst)
            else
                precmd_functions=(_zqs__ensure_promptsubst)
            fi
            export STARSHIP_INITIALIZED=1
            zf::debug "[COMPREHENSIVE-ENV] Starship auto-initialized (toggle on)"
        else
            zf::debug "[COMPREHENSIVE-ENV] Starship auto-init failed; keeping fallback prompt"
        fi
        (( __had_nounset )) && set -u
    fi
fi


# Set up completion of environment
if [[ -o interactive ]]; then
    # Final message
    local current_time
    if command -v date >/dev/null 2>&1; then
        current_time="$(date '+%H:%M:%S' 2>/dev/null || echo 'unknown')"
    else
        current_time="unknown"
    fi
    echo "🚀 ZSH environment ready! ($current_time)"
fi

# Fallback prompt configuration (only if Starship initialization failed)
if [[ -z "${ZSH_THEME:-}" && -z "${STARSHIP_INITIALIZED:-}" ]]; then
    zf::debug "[COMPREHENSIVE-ENV] Starship not initialized, setting fallback prompt"
    # Simple, fast prompt
    autoload -U colors && colors

    PROMPT='%F{blue}%n@%m%f:%F{green}%~%f%# '
    RPROMPT='%F{yellow}[%?]%f'

    # Git integration for prompt
    autoload -Uz vcs_info
    precmd_functions+=(vcs_info)
    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' formats ' (%b)'
    zstyle ':vcs_info:*' actionformats ' (%b|%a)'

    PROMPT='%F{blue}%n@%m%f:%F{green}%~%f${vcs_info_msg_0_:-}%# '
    zf::debug "[COMPREHENSIVE-ENV] Fallback prompt configured"
else
    zf::debug "[COMPREHENSIVE-ENV] Using Starship or theme prompt"
fi

zf::debug "[COMPREHENSIVE-ENV] Comprehensive environment setup complete"

# Optional diagnostics: load starship status debugger if present & debug mode
if [[ ${ZSH_DEBUG:-0} == 1 && -r ${ZDOTDIR:-$HOME}/tools/debug-starship-status.zsh ]]; then
    source ${ZDOTDIR:-$HOME}/tools/debug-starship-status.zsh 2>/dev/null || true
fi

# Legacy functions removed - using zf:: namespace directly

# ==============================================================================
# END OF COMPREHENSIVE ENVIRONMENT MODULE
# ==============================================================================
