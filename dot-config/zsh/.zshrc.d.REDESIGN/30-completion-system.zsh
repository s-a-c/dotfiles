#!/usr/bin/env zsh
# ==============================================================================
# 15-COMPLETION-SYSTEM.ZSH - Comprehensive Completion System (REDESIGN v2)
# ==============================================================================
# Purpose: Complete completion system setup with performance optimization
# Consolidates: 05-completion-system.zsh and completion-related modules
# Load Order: Mid (15-) after security
# Author: ZSH Configuration Redesign System
# Created: 2025-09-22
# Version: 2.0.0
# ==============================================================================

# Prevent multiple loading
if [[ -n "${_COMPLETION_SYSTEM_REDESIGN:-}" ]]; then
    return 0
fi
export _COMPLETION_SYSTEM_REDESIGN=1

# Debug helper
_completion_debug() {
    [[ -n "${ZSH_DEBUG:-}" ]] && zf::debug "[COMPLETION] $1" || true
}

_completion_debug "Loading comprehensive completion system (v2.0.0)"

# ==============================================================================
# SECTION 1: COMPLETION DIRECTORIES AND CACHE
# ==============================================================================

# Set up completion directories
export ZSH_COMPLETION_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
export ZSH_COMPDUMP="${ZSH_COMPDUMP:-$ZSH_COMPLETION_CACHE_DIR/.zcompdump-$HOST-$ZSH_VERSION}"

# Ensure directories exist
mkdir -p "$ZSH_COMPLETION_CACHE_DIR" 2>/dev/null || true
mkdir -p "${ZSH_COMPDUMP%/*}" 2>/dev/null || true

# Add custom completion directories to fpath
if [[ -d "$ZDOTDIR/completions" ]]; then
    fpath=("$ZDOTDIR/completions" $fpath)
    _completion_debug "Added custom completions directory to fpath"
fi

# Add Homebrew completions if available
if command -v brew >/dev/null 2>&1; then
    local homebrew_completions="$(brew --prefix)/share/zsh/site-functions"
    if [[ -d "$homebrew_completions" ]]; then
        fpath=("$homebrew_completions" $fpath)
        _completion_debug "Added Homebrew completions to fpath"
    fi
fi

_completion_debug "Completion directories configured"

# ==============================================================================
# SECTION 2: COMPLETION SYSTEM INITIALIZATION
# ==============================================================================

# Completion system configuration
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$ZSH_COMPLETION_CACHE_DIR"
zstyle ':completion:*' rehash true

# Enhanced completion matching
zstyle ':completion:*' matcher-list \
    'm:{a-zA-Z}={A-Za-z}' \
    'r:|[._-]=* r:|=*' \
    'l:|=* r:|=*'

# Menu and selection behavior
zstyle ':completion:*' menu select
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s

# Error correction
zstyle ':completion:*' max-errors 2 numeric
zstyle ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3))numeric)'

_completion_debug "Basic completion system configured"

# ==============================================================================
# SECTION 3: COMMAND-SPECIFIC COMPLETIONS
# ==============================================================================

# Kill command completion
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# SSH/SCP completion
zstyle ':completion:*:(ssh|scp|sftp):*' hosts $(awk '/^Host / {print $2}' ~/.ssh/config 2>/dev/null)

# CD completion
zstyle ':completion:*:cd:*' ignored-patterns '(*/)#CVS'
zstyle ':completion:*:(cd|mv|cp):*' ignore-parents parent pwd

# Git completion optimizations
zstyle ':completion:*:git:*' script ~/.zsh/git-completion.zsh 2>/dev/null
zstyle ':completion:*:git*:*' ignored-patterns '*ORIG_HEAD'

# Docker completion
if command -v docker >/dev/null 2>&1; then
    zstyle ':completion:*:docker:*' option-stacking yes
    zstyle ':completion:*:docker-*:*' option-stacking yes
fi

_completion_debug "Command-specific completions configured"

# ==============================================================================
# SECTION 4: PERFORMANCE OPTIMIZATIONS
# ==============================================================================

# Completion performance settings
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*:functions' ignored-patterns '_*'

# Reduce completion candidates for better performance
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:corrections' format ' %F{green}-- %d (errors: %e) --%f'
zstyle ':completion:*:descriptions' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'

# Speed up completion for large directories
zstyle ':completion:*' accept-exact-dirs true

_completion_debug "Performance optimizations applied"

# ==============================================================================
# SECTION 5: MODERN TOOL COMPLETIONS
# ==============================================================================

# Modern CLI tools completion setup
local -a modern_completions=(
    "fd" "rg" "bat" "exa" "delta" "fzf" "gh" "hub"
    "kubectl" "helm" "terraform" "aws" "gcloud"
)

# Only generate completions if not in Warp (to prevent hanging)
if [[ "${TERM_PROGRAM}" != "WarpTerminal" ]]; then
    for tool in "${modern_completions[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            case "$tool" in
                kubectl)
                    if [[ ! -f "$ZSH_COMPLETION_CACHE_DIR/_kubectl" ]]; then
                        kubectl completion zsh > "$ZSH_COMPLETION_CACHE_DIR/_kubectl" 2>/dev/null &
                    fi
                    ;;
                helm)
                    if [[ ! -f "$ZSH_COMPLETION_CACHE_DIR/_helm" ]]; then
                        helm completion zsh > "$ZSH_COMPLETION_CACHE_DIR/_helm" 2>/dev/null &
                    fi
                    ;;
                gh)
                    if [[ ! -f "$ZSH_COMPLETION_CACHE_DIR/_gh" ]]; then
                        gh completion -s zsh > "$ZSH_COMPLETION_CACHE_DIR/_gh" 2>/dev/null &
                    fi
                    ;;
            esac
        fi
    done
else
    _completion_debug "Skipping background completion generation in Warp terminal"
fi

_completion_debug "Modern tool completions configured"

# ==============================================================================
# SECTION 6: INITIALIZATION AND COMPINIT
# ==============================================================================

# Check if ZLE deferred compinit (prevents widget errors)
if [[ "${ZLE_COMPINIT_DEFERRED:-0}" == "1" ]]; then
    _completion_debug "ZLE deferred compinit detected - proceeding with safe initialization"

    # Ensure ZLE system is ready before initializing completions
    if [[ "${ZLE_EARLY_INIT_SUCCESS:-0}" != "1" ]]; then
        _completion_debug "Warning: ZLE not properly initialized, loading minimal ZLE support"
        zmodload -F zsh/zle 2>/dev/null || true
        autoload -Uz zle 2>/dev/null || true
    fi
else
    _completion_debug "Standard compinit mode (no ZLE deferral)"
fi

# Smart compinit - only rebuild if necessary
autoload -Uz compinit

# Check if we need to rebuild completions
_need_compinit_rebuild() {
    local compdump="$ZSH_COMPDUMP"

    # Always rebuild if no dump exists
    [[ ! -f "$compdump" ]] && return 0

    # Rebuild if dump is older than 24 hours
    if [[ -n "${compdump}(#qN.mh+24)" ]]; then
        return 0
    fi

    # Rebuild if any completion files are newer than dump
    if [[ -n "${fpath[1]}"/*(#qN.m"${compdump}") ]]; then
        return 0
    fi

    return 1
}

# Initialize completions (with timeout safety)
if _need_compinit_rebuild; then
    _completion_debug "Rebuilding completion database (background mode)"
    # Use -C flag to skip security checks for faster initialization
    # The security checks can cause hanging with large completion sets
    compinit -C -d "$ZSH_COMPDUMP"
    # Update modification time
    touch "$ZSH_COMPDUMP"
else
    _completion_debug "Using cached completions"
    compinit -C -d "$ZSH_COMPDUMP"
fi

# Post-compinit optimizations
[[ -f "$ZSH_COMPDUMP.zwc" ]] || {
    zcompile "$ZSH_COMPDUMP" &!
    _completion_debug "Compiling completion dump in background"
}

_completion_debug "Completion system initialized"

# Restore normal ZLE widget loading now that completion system is ready
if [[ -n "${ZLE_WIDGET_LOADING_PHASE:-}" ]]; then
    unset ZLE_WIDGET_LOADING_PHASE

    # Restore original zle function if we wrapped it
    if typeset -f zle >/dev/null 2>&1; then
        unfunction zle 2>/dev/null || true
    fi

    _completion_debug "ZLE widget loading phase ended - normal ZLE function restored"
fi

# ==============================================================================
# MODULE COMPLETION
# ==============================================================================

export COMPLETION_SYSTEM_VERSION="2.0.0"
export COMPLETION_SYSTEM_LOADED_AT="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'unknown')"

_completion_debug "Comprehensive completion system ready"

# Clean up helper function
unset -f _completion_debug _need_compinit_rebuild

# ==============================================================================
# END OF COMPLETION SYSTEM MODULE
# ==============================================================================
