#!/usr/bin/env zsh
# ==============================================================================
# ZSH Legacy Configuration: Environment & Options Module
# ==============================================================================
# Purpose: Shell options configuration, tool environments, and plugin 
#          environment setup for interactive shells
# 
# Consolidated from:
#   - ACTIVE-00_60-options.zsh
#   - DISABLED-10_12-tool-environments.zsh  
#   - DISABLED-20_02-plugin-environments.zsh
#
# Dependencies: 01-core-infrastructure.zsh (for logging functions)
# Load Order: Mid-range (50-59)
# Author: ZSH Legacy Consolidation System
# Created: 2025-09-14
# Version: 1.0.0
# ==============================================================================

# Prevent multiple loading
if [[ -n "${_ENVIRONMENT_OPTIONS_LOADED:-}" ]]; then
    return 0
fi
export _ENVIRONMENT_OPTIONS_LOADED=1

# Debug helper - use core infrastructure if available
_env_debug() {
    if command -v debug_log >/dev/null 2>&1; then
        debug_log "$1"
    elif [[ -n "${ZSH_DEBUG:-}" ]]; then
        echo "[ENV-DEBUG] $1" >&2
    fi
}

_env_debug "Loading environment & options module..."

# ==============================================================================
# SECTION 1: ZSH INTERACTIVE OPTIONS
# ==============================================================================
# From: ACTIVE-00_60-options.zsh
# Purpose: Shell options for interactive shells only

# Only apply to interactive shells
if [[ -o interactive ]]; then
    _env_debug "Configuring interactive shell options..."

    # === History Options ===
    setopt HIST_VERIFY              # Show command with history expansion to user before running it
    setopt HIST_EXPIRE_DUPS_FIRST   # Delete duplicates first when HISTFILE size exceeds HISTSIZE
    setopt HIST_IGNORE_DUPS         # Don't record an entry that was just recorded again
    setopt HIST_IGNORE_ALL_DUPS     # Delete old recorded entry if new entry is a duplicate
    setopt HIST_FIND_NO_DUPS        # Don't display a line previously found
    setopt HIST_IGNORE_SPACE        # Don't record an entry starting with a space
    setopt HIST_SAVE_NO_DUPS        # Don't write duplicate entries in the history file
    setopt HIST_REDUCE_BLANKS       # Remove superfluous blanks before recording entry
    setopt SHARE_HISTORY            # Share history between all sessions
    setopt EXTENDED_HISTORY         # Write the history file in the ":start:elapsed;command" format

    # === Directory Navigation ===
    setopt AUTO_CD                  # If command is a directory name, cd to it
    setopt AUTO_PUSHD               # Make cd push the old directory onto the directory stack
    setopt PUSHD_IGNORE_DUPS        # Don't push the same dir twice
    setopt PUSHD_MINUS              # Exchanges the meanings of '+' and '-' with pushd
    setopt CDABLE_VARS              # If argument to cd is not a directory, try expanding it as variable

    # === Completion Options ===
    setopt COMPLETE_IN_WORD         # Complete from both ends of a word
    setopt ALWAYS_TO_END            # Move cursor to the end of a completed word
    setopt PATH_DIRS                # Perform path search even on command names with slashes
    setopt AUTO_MENU                # Show completion menu on a successive tab press
    setopt AUTO_LIST                # Automatically list choices on ambiguous completion
    setopt AUTO_PARAM_SLASH         # If completed parameter is a directory, add a trailing slash
    setopt MENU_COMPLETE            # Insert the first completion match immediately

    # === Correction and Expansion ===
    setopt CORRECT                  # Try to correct the spelling of commands
    setopt CORRECT_ALL              # Try to correct the spelling of all arguments in a line
    setopt GLOB_COMPLETE            # Generate glob patterns as completion matches

    # === Job Control ===
    setopt LONG_LIST_JOBS           # List jobs in the long format by default
    setopt AUTO_RESUME              # Attempt to resume existing job before creating a new process
    setopt NOTIFY                   # Report status of background jobs immediately
    setopt BG_NICE                  # Run all background jobs at a lower priority
    setopt HUP                      # Send SIGHUP to running jobs when shell exits

    # === Input/Output ===
    setopt INTERACTIVE_COMMENTS     # Allow comments in interactive shell
    setopt RC_QUOTES               # Allow 'Henry''s Garage' instead of 'Henry'\''s Garage'
    setopt COMBINING_CHARS          # Combine zero-length punctuation characters (accents) with the base character

    _env_debug "Interactive shell options configured"
fi

# === Universal Options (always set) ===
_env_debug "Configuring universal shell options..."

# Globbing
setopt EXTENDED_GLOB            # Use extended globbing syntax
setopt GLOB_DOTS                # Include dotfiles in glob patterns
setopt NUMERIC_GLOB_SORT        # Sort filenames numerically when it makes sense
setopt NO_CASE_GLOB             # Case insensitive globbing

# Error handling
setopt NO_UNSET                 # Error when referencing undefined variables
setopt PIPE_FAIL                # Return exit code of rightmost command to exit with non-zero status

_env_debug "Universal shell options configured"

# ==============================================================================
# SECTION 2: TOOL ENVIRONMENTS
# ==============================================================================
# From: DISABLED-10_12-tool-environments.zsh
# Purpose: Development tool environment configuration

_env_debug "Configuring development tool environments..."

# === Node.js Environment ===
configure_nodejs_env() {
    _env_debug "Configuring Node.js environment..."
    
    # NVM configuration
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    export NVM_LAZY_LOAD="${NVM_LAZY_LOAD:-true}"
    export NVM_COMPLETION="${NVM_COMPLETION:-true}"
    
    # Node options
    export NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=4096}"
    export NODE_ENV="${NODE_ENV:-development}"
    
    # NPM configuration
    export NPM_CONFIG_PROGRESS="${NPM_CONFIG_PROGRESS:-true}"
    export NPM_CONFIG_COLOR="${NPM_CONFIG_COLOR:-always}"
    
    _env_debug "Node.js environment configured"
}

# === Python Environment ===
configure_python_env() {
    _env_debug "Configuring Python environment..."
    
    # Python path and options
    export PYTHONPATH="${PYTHONPATH:-}"
    export PYTHON_CONFIGURE_OPTS="${PYTHON_CONFIGURE_OPTS:---enable-shared}"
    export PYTHONDONTWRITEBYTECODE="${PYTHONDONTWRITEBYTECODE:-1}"
    
    # Virtual environment
    export VIRTUAL_ENV_DISABLE_PROMPT="${VIRTUAL_ENV_DISABLE_PROMPT:-1}"
    export WORKON_HOME="${WORKON_HOME:-$HOME/.virtualenvs}"
    
    # PyEnv configuration
    export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
    export PYENV_VIRTUALENV_DISABLE_PROMPT="${PYENV_VIRTUALENV_DISABLE_PROMPT:-1}"
    
    _env_debug "Python environment configured"
}

# === Ruby Environment ===
configure_ruby_env() {
    _env_debug "Configuring Ruby environment..."
    
    # RBEnv configuration
    export RBENV_ROOT="${RBENV_ROOT:-$HOME/.rbenv}"
    
    # Ruby options
    export RUBY_CONFIGURE_OPTS="${RUBY_CONFIGURE_OPTS:---with-openssl-dir=/usr/local/opt/openssl}"
    
    # Bundler configuration
    export BUNDLE_JOBS="${BUNDLE_JOBS:-$(nproc 2>/dev/null || echo 4)}"
    export BUNDLE_RETRY="${BUNDLE_RETRY:-3}"
    
    _env_debug "Ruby environment configured"
}

# === Go Environment ===
configure_go_env() {
    _env_debug "Configuring Go environment..."
    
    # Go paths
    export GOPATH="${GOPATH:-$HOME/go}"
    export GOROOT="${GOROOT:-/usr/local/go}"
    export GOPROXY="${GOPROXY:-https://proxy.golang.org,direct}"
    export GOSUMDB="${GOSUMDB:-sum.golang.org}"
    export GOPRIVATE="${GOPRIVATE:-}"
    
    # Go options
    export CGO_ENABLED="${CGO_ENABLED:-1}"
    export GO111MODULE="${GO111MODULE:-on}"
    
    _env_debug "Go environment configured"
}

# === Docker Environment ===
configure_docker_env() {
    _env_debug "Configuring Docker environment..."
    
    # Docker configuration
    export DOCKER_BUILDKIT="${DOCKER_BUILDKIT:-1}"
    export COMPOSE_DOCKER_CLI_BUILD="${COMPOSE_DOCKER_CLI_BUILD:-1}"
    export DOCKER_SCAN_SUGGEST="${DOCKER_SCAN_SUGGEST:-false}"
    
    # Docker host (if needed)
    if [[ -n "${DOCKER_HOST_OVERRIDE:-}" ]]; then
        export DOCKER_HOST="$DOCKER_HOST_OVERRIDE"
    fi
    
    _env_debug "Docker environment configured"
}

# === Git Environment ===
configure_git_env() {
    _env_debug "Configuring Git environment..."
    
    # Git configuration
    export GIT_PAGER="${GIT_PAGER:-less -R}"
    export GIT_EDITOR="${GIT_EDITOR:-$EDITOR}"
    export GIT_MERGE_AUTOEDIT="${GIT_MERGE_AUTOEDIT:-no}"
    
    # Git LFS
    export GIT_LFS_SKIP_SMUDGE="${GIT_LFS_SKIP_SMUDGE:-0}"
    
    _env_debug "Git environment configured"
}

# === Database Environments ===
configure_database_env() {
    _env_debug "Configuring database environments..."
    
    # PostgreSQL
    export PGUSER="${PGUSER:-postgres}"
    export PGDATABASE="${PGDATABASE:-development}"
    export PGHOST="${PGHOST:-localhost}"
    export PGPORT="${PGPORT:-5432}"
    
    # MySQL
    export MYSQL_HOST="${MYSQL_HOST:-localhost}"
    export MYSQL_PORT="${MYSQL_PORT:-3306}"
    
    # Redis
    export REDIS_URL="${REDIS_URL:-redis://localhost:6379}"
    
    _env_debug "Database environments configured"
}

# Initialize all tool environments
init_tool_environments() {
    _env_debug "Initializing all tool environments..."
    
    configure_nodejs_env
    configure_python_env
    configure_ruby_env
    configure_go_env
    configure_docker_env
    configure_git_env
    configure_database_env
    
    _env_debug "All tool environments initialized"
}

# ==============================================================================
# SECTION 3: PLUGIN ENVIRONMENTS
# ==============================================================================
# From: DISABLED-20_02-plugin-environments.zsh
# Purpose: Plugin-specific environment configuration

_env_debug "Configuring plugin environments..."

# === FZF Environment ===
configure_fzf_env() {
    _env_debug "Configuring FZF environment..."
    
    # FZF default options
    export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-"
        --height 40%
        --layout=reverse
        --border
        --inline-info
        --preview-window=:wrap
        --bind ctrl-u:preview-up,ctrl-d:preview-down
        --bind ctrl-f:preview-page-down,ctrl-b:preview-page-up
        --bind ctrl-a:select-all,ctrl-n:deselect-all
        --bind alt-up:preview-up,alt-down:preview-down
    "}"
    
    # FZF file search
    export FZF_DEFAULT_COMMAND="${FZF_DEFAULT_COMMAND:-fd --type f --hidden --follow --exclude .git}"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="${FZF_ALT_C_COMMAND:-fd --type d --hidden --follow --exclude .git}"
    
    # FZF completion
    export FZF_COMPLETION_TRIGGER="${FZF_COMPLETION_TRIGGER:-'**'}"
    export FZF_COMPLETION_OPTS="${FZF_COMPLETION_OPTS:---border --info=inline}"
    
    _env_debug "FZF environment configured"
}

# === Zoxide Environment ===
configure_zoxide_env() {
    _env_debug "Configuring Zoxide environment..."
    
    export _ZO_ECHO="${_ZO_ECHO:-1}"
    export _ZO_EXCLUDE_DIRS="${_ZO_EXCLUDE_DIRS:-$HOME/.Trash:$HOME/.cache}"
    export _ZO_MAXAGE="${_ZO_MAXAGE:-10000}"
    
    _env_debug "Zoxide environment configured"
}

# === Starship Environment ===
configure_starship_env() {
    _env_debug "Configuring Starship environment..."
    
    export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$HOME/.config/starship.toml}"
    export STARSHIP_CACHE="${STARSHIP_CACHE:-$HOME/.cache/starship}"
    
    _env_debug "Starship environment configured"
}

# === Bat Environment ===
configure_bat_env() {
    _env_debug "Configuring Bat environment..."
    
    export BAT_THEME="${BAT_THEME:-TwoDark}"
    export BAT_STYLE="${BAT_STYLE:-numbers,changes,header}"
    export BAT_PAGER="${BAT_PAGER:-less -R}"
    
    _env_debug "Bat environment configured"
}

# === Exa/Eza Environment ===
configure_exa_env() {
    _env_debug "Configuring Exa/Eza environment..."
    
    export EXA_COLORS="${EXA_COLORS:-reset}"
    export EZA_COLORS="${EZA_COLORS:-$EXA_COLORS}"
    
    # Time style
    export TIME_STYLE="${TIME_STYLE:-long-iso}"
    
    _env_debug "Exa/Eza environment configured"
}

# === Ripgrep Environment ===
configure_ripgrep_env() {
    _env_debug "Configuring Ripgrep environment..."
    
    export RIPGREP_CONFIG_PATH="${RIPGREP_CONFIG_PATH:-$HOME/.ripgreprc}"
    
    _env_debug "Ripgrep environment configured"
}

# Initialize all plugin environments
init_plugin_environments() {
    _env_debug "Initializing all plugin environments..."
    
    configure_fzf_env
    configure_zoxide_env
    configure_starship_env
    configure_bat_env
    configure_exa_env
    configure_ripgrep_env
    
    _env_debug "All plugin environments initialized"
}

# ==============================================================================
# SECTION 4: ENVIRONMENT UTILITIES
# ==============================================================================

# Check if environment variable is set and non-empty
env_is_set() {
    [[ -n "${(P)1}" ]]
}

# Set environment variable if not already set
env_set_default() {
    local var_name="$1"
    local default_value="$2"
    
    if ! env_is_set "$var_name"; then
        export "$var_name"="$default_value"
        _env_debug "Set default: $var_name=$default_value"
    fi
}

# Export path-like variable with deduplication
env_export_path() {
    local var_name="$1"
    local new_path="$2"
    local existing_path="${(P)var_name}"
    
    # Remove duplicates and export
    local deduplicated_path=$(echo "$existing_path:$new_path" | tr ':' '\n' | awk '!seen[$0]++' | paste -sd':')
    export "$var_name"="${deduplicated_path#:}"
    _env_debug "Updated PATH-like variable: $var_name"
}

# Check tool availability and set environment accordingly
check_and_configure_tool() {
    local tool="$1"
    local config_function="$2"
    
    if command -v "$tool" >/dev/null 2>&1; then
        _env_debug "Tool '$tool' available, configuring environment..."
        if command -v "$config_function" >/dev/null 2>&1; then
            "$config_function"
        else
            _env_debug "Configuration function '$config_function' not found"
        fi
    else
        _env_debug "Tool '$tool' not available, skipping configuration"
    fi
}

# ==============================================================================
# MODULE INITIALIZATION
# ==============================================================================

_env_debug "Initializing environment & options module..."

# Initialize tool environments
init_tool_environments

# Initialize plugin environments  
init_plugin_environments

# Set module metadata
export ENVIRONMENT_OPTIONS_VERSION="1.0.0"
export ENVIRONMENT_OPTIONS_LOADED="$(date '+%Y-%m-%d %H:%M:%S')"

_env_debug "Environment & options module ready"

# ==============================================================================
# MODULE SELF-TEST
# ==============================================================================

test_environment_options() {
    local tests_passed=0
    local tests_total=6
    
    # Test 1: ZSH options are set
    if [[ -o EXTENDED_GLOB ]]; then
        ((tests_passed++))
        echo "✅ ZSH options configured"
    else
        echo "❌ ZSH options not configured"
    fi
    
    # Test 2: Tool environment functions exist
    if command -v configure_nodejs_env >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Tool environment functions loaded"
    else
        echo "❌ Tool environment functions not loaded"
    fi
    
    # Test 3: Plugin environment functions exist
    if command -v configure_fzf_env >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Plugin environment functions loaded"
    else
        echo "❌ Plugin environment functions not loaded"
    fi
    
    # Test 4: Environment utilities exist
    if command -v env_is_set >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Environment utilities loaded"
    else
        echo "❌ Environment utilities not loaded"
    fi
    
    # Test 5: Module metadata set
    if [[ -n "$ENVIRONMENT_OPTIONS_VERSION" ]]; then
        ((tests_passed++))
        echo "✅ Module metadata available"
    else
        echo "❌ Module metadata missing"
    fi
    
    # Test 6: Basic environment variables set
    if [[ -n "$FZF_DEFAULT_OPTS" ]] || [[ -n "$NODE_OPTIONS" ]]; then
        ((tests_passed++))
        echo "✅ Environment variables configured"
    else
        echo "❌ Environment variables not configured"
    fi
    
    echo ""
    echo "Environment & Options Self-Test: $tests_passed/$tests_total tests passed"
    
    if [[ $tests_passed -eq $tests_total ]]; then
        return 0
    else
        return 1
    fi
}

# ==============================================================================
# END OF ENVIRONMENT & OPTIONS MODULE
# ==============================================================================