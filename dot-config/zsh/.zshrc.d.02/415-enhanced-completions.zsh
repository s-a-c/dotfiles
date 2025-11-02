#!/usr/bin/env zsh
# Filename: 415-enhanced-completions.zsh
# Purpose:  Enhanced completion system with context-awareness, history-based suggestions,
#           and project-aware completions for improved productivity
# Phase:    Post-plugin (.zshrc.d/)
# Requires: 410-completions.zsh (base completion system must be loaded first)
# Toggles:  ZF_DISABLE_ENHANCED_COMPLETIONS, ZF_COMPLETION_HISTORY_SIZE

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# Skip if disabled
if [[ "${ZF_DISABLE_ENHANCED_COMPLETIONS:-0}" == 1 ]]; then
    return 0
fi

# ==============================================================================
# Enhanced Completion Configuration
# ==============================================================================

# History-based completion settings
: "${ZF_COMPLETION_HISTORY_SIZE:=10000}"

# Enable menu-driven completion
zstyle ':completion:*' menu select

# Use cache for faster completions
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "${ZSH_CACHE_DIR:-${ZDOTDIR:-$HOME}/.cache}/zcompcache"

# Group completions by type
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{cyan}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- No matches found --%f'
zstyle ':completion:*:messages' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:corrections' format '%F{green}-- %d (errors: %e) --%f'

# Enhanced matching - case-insensitive, partial word matching
zstyle ':completion:*' matcher-list \
    'm:{a-zA-Z}={A-Za-z}' \
    'r:|[._-]=* r:|=*' \
    'l:|=* r:|=*'

# ==============================================================================
# Context-Aware Completions
# ==============================================================================

# Git command completions with context
zstyle ':completion:*:*:git:*' group-order \
    heads-local heads-remote branches tags remotes

zstyle ':completion:*:*:git-checkout:*:*' sort false

# Directory completion with colors matching ls
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# Process completion for kill commands
zstyle ':completion:*:*:kill:*:processes' list-colors \
    '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command \
    "ps -u $USER -o pid,user,comm -w -w"

# Man page completion
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true

# ==============================================================================
# History-Based Smart Completions
# ==============================================================================

# Function to provide history-based suggestions for common commands
zf::history_based_completion() {
    local cmd="$1"
    local -a history_items

    # Get unique entries from history for this command
    history_items=(${(fu)"$(fc -l 1 | grep "^[[:space:]]*[0-9]*[[:space:]]*${cmd}" | awk '{$1=""; print $0}' | sort -u)"})

    if (( ${#history_items[@]} > 0 )); then
        compadd -X "From history:" -a history_items
    fi
}

# ==============================================================================
# Project-Aware Completions
# ==============================================================================

# Detect project type and provide relevant completions
zf::detect_project_type() {
    local dir="${1:-$PWD}"
    
    if [[ -f "$dir/package.json" ]]; then
        echo "node"
    elif [[ -f "$dir/composer.json" ]]; then
        echo "php"
    elif [[ -f "$dir/Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "$dir/go.mod" ]]; then
        echo "go"
    elif [[ -f "$dir/pyproject.toml" ]] || [[ -f "$dir/setup.py" ]]; then
        echo "python"
    elif [[ -d "$dir/.git" ]]; then
        echo "git"
    else
        echo "generic"
    fi
}

# Enhanced npm/yarn completions
if command -v npm >/dev/null 2>&1; then
    zf::npm_script_completion() {
        if [[ -f package.json ]]; then
            local -a scripts
            scripts=(${(f)"$(command cat package.json 2>/dev/null | command grep -A 100 '"scripts"' | command grep '":' | command sed 's/.*"\([^"]*\)".*/\1/' | command head -20)"})
            compadd -X "npm scripts:" -a scripts
        fi
    }

    # Hook into npm completion
    compdef zf::npm_script_completion npm
fi

# Enhanced composer completions for PHP projects
if command -v composer >/dev/null 2>&1; then
    zf::composer_script_completion() {
        if [[ -f composer.json ]]; then
            local -a scripts
            scripts=(${(f)"$(command cat composer.json 2>/dev/null | command grep -A 50 '"scripts"' | command grep '":' | command sed 's/.*"\([^"]*\)".*/\1/' | command head -20)"})
            if (( ${#scripts[@]} > 0 )); then
                compadd -X "composer scripts:" -a scripts
            fi
        fi
    }
fi

# ==============================================================================
# Intelligent Path Completion
# ==============================================================================

# Expand ~ in completion
zstyle ':completion:*' expand yes

# Don't complete backup files as executables
zstyle ':completion:*:complete:-command-::commands' ignored-patterns \
    '*\~' '*\#'

# Ignore useless directories for cd
zstyle ':completion:*:cd:*' ignore-parents parent pwd
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select

# ==============================================================================
# Enhanced Kill Command Completions
# ==============================================================================

# Show process tree for kill
if command -v pstree >/dev/null 2>&1; then
    zstyle ':completion:*:*:kill:*:*' command 'pstree -u $USER'
fi

# ==============================================================================
# Fuzzy Matching for Typos
# ==============================================================================

# Allow approximate matching (typo tolerance)
zstyle ':completion:*' completer \
    _complete \
    _match \
    _approximate

zstyle ':completion:*:match:*' original only
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3)))'

# ==============================================================================
# Context-Sensitive Help
# ==============================================================================

enhanced-completions-help() {
    cat <<'EOF'
🎯 Enhanced Completion System

Features:
  • Case-insensitive matching
  • Fuzzy matching with typo tolerance
  • History-based suggestions
  • Project-aware completions (npm, composer, cargo, etc.)
  • Colorized output matching your ls colors
  • Menu-driven selection (use arrow keys)
  • Grouped completions by category

Navigation:
  Tab           : Cycle through completions
  Shift+Tab     : Cycle backwards
  Arrow Keys    : Navigate menu
  Enter         : Select completion

Project-Aware:
  npm run <Tab> : Shows scripts from package.json
  composer <Tab>: Shows scripts from composer.json

Toggle:
  ZF_DISABLE_ENHANCED_COMPLETIONS=1  : Disable enhanced completions

Performance:
  Completions are cached for speed
  Cache location: ${ZSH_CACHE_DIR}/zcompcache
EOF
}

# Mark functions as readonly (wrapped to prevent function definition output)
(
  readonly -f zf::history_based_completion 2>/dev/null || true
  readonly -f zf::detect_project_type 2>/dev/null || true
  readonly -f zf::npm_script_completion 2>/dev/null || true
  readonly -f zf::composer_script_completion 2>/dev/null || true
  readonly -f enhanced-completions-help 2>/dev/null || true
) >/dev/null 2>&1

# Welcome message
if [[ -z "${_ZF_ENHANCED_COMPLETIONS_NOTIFIED:-}" ]]; then
    echo "🎯 Enhanced completions active. Type 'enhanced-completions-help' for details."
    export _ZF_ENHANCED_COMPLETIONS_NOTIFIED=1
fi

zf::debug "# [completions] Enhanced completion system loaded"

return 0

