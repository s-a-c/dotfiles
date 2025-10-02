#!/usr/bin/env zsh
# ==============================================================================
# ZSH Legacy Configuration: Development Tools Module
# ==============================================================================
# Purpose: Comprehensive development environment setup with language-specific
#          configurations, tool integrations, and productivity optimizations
#
# Consolidated from:
#   - ACTIVE-99-external-tools.zsh (external tool additions with timeout protection)
#   - DISABLED-10_00-development-tools.zsh (comprehensive tool configs)
#   - DISABLED-10_50-development.zsh (development environment setup)
#   - DISABLED-10_12-tool-environments.zsh (post-plugin tool configuration)
#   - DISABLED-00_74-tool-functions.zsh (health check and docs functions)
#
# Dependencies: 01-core-infrastructure.zsh (for path helpers and logging)
# Load Order: Late (80-89 range)
# Author: ZSH Legacy Consolidation System
# Created: 2025-09-15
# Version: 1.0.0
# ==============================================================================

# Prevent multiple loading
if [[ -n "${_DEVELOPMENT_TOOLS_LOADED:-}" ]]; then
    return 0
fi
export _DEVELOPMENT_TOOLS_LOADED=1

# Debug helper - use core infrastructure if available
_dev_debug() {
    if command -v debug_log >/dev/null 2>&1; then
        debug_log "$1"
    elif [[ -n "${ZSH_DEBUG:-}" ]]; then
        echo "[DEV-DEBUG] $1" >&2
    fi
}

_dev_debug "Loading development tools module..."

# ==============================================================================
# SECTION 1: EXTERNAL TOOLS INTEGRATION
# ==============================================================================
# Purpose: Safe loading of external tool additions with timeout protection

_dev_debug "Setting up external tools integration..."

# External tools control variables
export SKIP_EXTERNAL_TOOLS="${SKIP_EXTERNAL_TOOLS:-0}"

# Safe external tool loading function
load_external_tools() {
    local external_file="$1"
    local timeout_seconds="${2:-2}"

    if [[ ! -f "$external_file" ]]; then
        _dev_debug "External tools file not found: $external_file"
        return 1
    fi

    _dev_debug "Loading external tools from: $external_file"

    # Use timeout protection if available
    if command -v timeout >/dev/null 2>&1; then
        timeout "$timeout_seconds" zsh -c "source '$external_file'" 2>/dev/null || {
            _dev_debug "External tool loading timed out or failed: $external_file"
            return 1
        }
    else
        source "$external_file" 2>/dev/null || {
            _dev_debug "External tool loading failed: $external_file"
            return 1
        }
    fi

    _dev_debug "External tools loaded successfully"
    return 0
}

# Load external tools if not disabled
if [[ "$SKIP_EXTERNAL_TOOLS" != "1" ]]; then
    # Try common external tools locations
    local external_tools_paths=(
        "${ZDOTDIR}/.zshrc.d/99-external-tools.zsh.original"
        "${ZDOTDIR}/99-external-tools.zsh"
        "${HOME}/.zshrc.d/99-external-tools.zsh"
    )

    for external_path in "${external_tools_paths[@]}"; do
        if load_external_tools "$external_path"; then
            break
        fi
    done

    # Herd PHP environment (from external tools)
    # Herd Integration (PHP + Node.js management) - PRIORITY OVER NVM
    if [[ -d "$HOME/Library/Application Support/Herd" ]]; then
        _dev_debug "Herd detected - setting up PHP and Node.js environment"

        # Herd environment variables
        export HERD_APP="/Applications/Herd.app"
        export HERD_TOOLS_HOME="$HOME/Library/Application Support/Herd"
        export HERD_TOOLS_BIN="$HERD_TOOLS_HOME/bin"
        export HERD_TOOLS_CONFIG="$HERD_TOOLS_HOME/config"

        # PHP version-specific configurations
        export HERD_PHP_82_INI_SCAN_DIR="$HERD_TOOLS_CONFIG/php/82/"
        export HERD_PHP_83_INI_SCAN_DIR="$HERD_TOOLS_CONFIG/php/83/"
        export HERD_PHP_84_INI_SCAN_DIR="$HERD_TOOLS_CONFIG/php/84/"
        export HERD_PHP_85_INI_SCAN_DIR="$HERD_TOOLS_CONFIG/php/85/"

        # Add Herd paths (highest priority)
        export PATH="$HERD_TOOLS_BIN:$HERD_TOOLS_HOME:$PATH"

        # Add Herd resources if available
        [[ -d "$HERD_APP/Contents/Resources" ]] &&
            export PATH="$HERD_APP/Contents/Resources:$PATH"

        # Herd includes its own Node.js management - check if NVM should be Herd's
        [[ -d "$HERD_TOOLS_CONFIG/nvm" ]] && {
            export NVM_DIR="$HERD_TOOLS_CONFIG/nvm"
            _dev_debug "Using Herd's NVM: $NVM_DIR"
        }

        _dev_debug "Herd environment configured (supersedes standard PHP/Node setup)"
    else
        _dev_debug "Herd not found - will use standard Node.js/PHP setup"
    fi

    # NVM (Node Version Manager) with Lazy Loading - AFTER Herd check
    # Custom NVM directory detection
    # Fallback: If no NVM_DIR was set by Herd, try to find standard NVM locations
    _dev_debug "# [dev-env] No NVM_DIR found, searching for standard NVM installations"
    [[ -n "${BREW_PREFIX:-}" && -d "${BREW_PREFIX}/opt/nvm" ]] && \
        export NVM_DIR="${NVM_DIR:-${BREW_PREFIX}/opt/nvm}"
    [[ -d "${XDG_CONFIG_HOME:-${HOME}/.config}/nvm" ]] && \
        export NVM_DIR="${NVM_DIR:-${XDG_CONFIG_HOME:-${HOME}/.config}/nvm}"
    [[ -d "${HOME}/.nvm" ]] && \
        export NVM_DIR="${NVIM_DIR:-${HOME}/.nvm}"

    # NVM Lazy Loading Setup (works for ALL NVM versions - standard or Herd)
    _dev_debug "Setting up NVM lazy loading for: $NVM_DIR"

    # Always set up lazy loading if we have an NVM_DIR (from Herd or standard locations)
    if [[ -n "$NVM_DIR" && -d "$NVM_DIR" ]]; then
        _dev_debug "Found standard NVM at: $NVM_DIR"

        # NVM environment setup
        export NVM_AUTO_USE=true
        export NVM_LAZY_LOAD=true
        export NVM_COMPLETION=true

        # CRITICAL: Unset NPM_CONFIG_PREFIX for NVM compatibility
        unset NPM_CONFIG_PREFIX

        # Lazy load nvm function for faster startup (works for ALL NVM types)
        # Use explicit typeset to ensure proper function scoping
        typeset -f nvm >/dev/null 2>&1 && unfunction nvm 2>/dev/null
        nvm() {
            # Remove the lazy loader function
            unfunction nvm 2>/dev/null
            unset NPM_CONFIG_PREFIX

            # Source NVM scripts
            [[ -s "$NVM_DIR/nvm.sh" ]] && builtin source "$NVM_DIR/nvm.sh"
            [[ -s "$NVM_DIR/bash_completion" ]] && builtin source "$NVM_DIR/bash_completion"

            # Call nvm with original arguments
            nvm "$@"
        }

        # Explicitly export the function
        typeset -f nvm >/dev/null 2>&1 && _dev_debug "# [dev-env] NVM function properly defined"

        _dev_debug "NVM lazy loader configured for: $NVM_DIR"

        # Set up minimal path for immediate node access (if default exists)
        [[ -d "$NVM_DIR/versions/node" ]] && {
            local node_dir="$(ls -1d "$NVM_DIR"/versions/node/v* 2>/dev/null | tail -1)"
            [[ -d "$node_dir/bin" ]] && export PATH="$node_dir/bin:$PATH"
            _dev_debug "Added immediate Node.js access: $node_dir/bin"
        }
    else
        _dev_debug "NVM not found in any standard locations"
    fi

    # LM Studio CLI integration
    if [[ -d "${HOME}/.lmstudio/bin" ]]; then
        _path_append "${HOME}/.lmstudio/bin"
        _dev_debug "LM Studio CLI configured"
    fi
fi

# ==============================================================================
# SECTION 2: LANGUAGE-SPECIFIC ENVIRONMENTS
# ==============================================================================
# Purpose: Configure development environments for various programming languages

_dev_debug "Setting up language-specific environments..."

## [2.1] JavaScript/TypeScript Ecosystem
{
    _dev_debug "Configuring JavaScript/TypeScript ecosystem..."

    # Bun - JavaScript runtime and package manager
    export BUN_INSTALL="${BUN_INSTALL:-${XDG_DATA_HOME:-${HOME/.local/share}}/bun}"
    [[ -d "$BUN_INSTALL/bin" ]] && {
        _path_prepend "$BUN_INSTALL/bin"
        _dev_debug "Bun environment configured"
    }

    # Deno - JavaScript/TypeScript runtime
    export DENO_INSTALL="${DENO_INSTALL:-${XDG_DATA_HOME:-${HOME/.local/share}}/deno}"
    export DENO_INSTALL="${DENO_INSTALL:-${HOME}/.deno}"
    [[ -d "$DENO_INSTALL/bin" ]] && {
        _path_prepend "$DENO_INSTALL/bin"
        _dev_debug "Deno environment configured"
    }

    # pnpm - Node.js package manager
    export PNPM_HOME="${PNPM_HOME:-${XDG_DATA_HOME:-${HOME/.local/share}}/pnpm}"
    [[ -d "$PNPM_HOME" ]] && {
        _path_prepend "$PNPM_HOME"
        _dev_debug "pnpm environment configured"
    }

    # Node.js environment optimizations
    if command -v node >/dev/null 2>&1; then
        export NPM_CONFIG_PROGRESS=false
        export NPM_CONFIG_AUDIT=false
        export NPM_CONFIG_FUND=false

        # NPM global packages
        if command -v npm >/dev/null 2>&1; then
            local npm_prefix
            npm_prefix="$(npm config get prefix 2>/dev/null)"
            if [[ -n "$npm_prefix" && -d "$npm_prefix/bin" ]]; then
                _path_prepend "$npm_prefix/bin"
            fi
        fi

        _dev_debug "Node.js environment optimized"
    fi

    # Console Ninja - Browser debugging
    if [[ -d "${HOME}/.console-ninja/.bin" ]]; then
        _path_prepend "${HOME}/.console-ninja/.bin"
        _dev_debug "Console Ninja configured"
    fi
}

## [2.2] Go Development Environment
{
    _dev_debug "Configuring Go development environment..."

    export GOPATH="${XDG_DATA_HOME:-${HOME}/.local/share}/go"
    export GOROOT="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/go/libexec"
    export GOPROXY="direct"
    export GOSUMDB="off"

    # Ensure GOPATH exists
    [[ ! -d "$GOPATH" ]] && mkdir -p "$GOPATH/bin" 2>/dev/null

    # Add Go paths
    [[ -d "$GOPATH/bin" ]] && _path_prepend "$GOPATH/bin"
    [[ -d "/usr/local/go/bin" ]] && _path_prepend "/usr/local/go/bin"

    # Legacy support
    if command -v go >/dev/null 2>&1; then
        local go_root
        go_root="$(go env GOROOT 2>/dev/null)"
        if [[ -n "$go_root" && -d "$go_root/bin" ]]; then
            _path_prepend "$go_root/bin"
        fi
        _dev_debug "Go environment configured"
    fi
}

## [2.3] Rust Development Environment
{
    _dev_debug "Configuring Rust development environment..."

    export RUSTUP_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/rustup"
    export CARGO_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/cargo"
    export CARGO_TARGET_DIR="${CARGO_HOME}/target"
    export RUSTUP_LOCATION="${CARGO_HOME}/bin/rustup"

    # Optimize Rust builds
    export CARGO_INCREMENTAL=1
    export RUST_BACKTRACE=1

    # Legacy locations support
    if [[ -d "${HOME}/.cargo" ]]; then
        export CARGO_HOME="${CARGO_HOME:-${HOME}/.cargo}"
        export RUSTUP_HOME="${RUSTUP_HOME:-${HOME}/.rustup}"
    fi

    # Optimize target directory location
    if [[ -z "$CARGO_TARGET_DIR" ]]; then
        export CARGO_TARGET_DIR="/tmp/cargo-builds"
        [[ ! -d "$CARGO_TARGET_DIR" ]] && mkdir -p "$CARGO_TARGET_DIR" 2>/dev/null
    fi

    # Cargo bin path
    [[ -d "$CARGO_HOME/bin" ]] && _path_prepend "$CARGO_HOME/bin"

    # Sccache for faster builds
    if command -v sccache >/dev/null 2>&1; then
        export RUSTC_WRAPPER=sccache
        _dev_debug "Sccache wrapper configured"
    fi

    _dev_debug "Rust environment configured"
}

## [2.4] Python Development Environment
{
    _dev_debug "Configuring Python development environment..."

    # Python optimizations
    export PYTHONDONTWRITEBYTECODE=1
    export PYTHONUNBUFFERED=1
    export PIP_REQUIRE_VIRTUALENV=true
    export PIPENV_VENV_IN_PROJECT=1

    # Python user base path
    if command -v python3 >/dev/null 2>&1; then
        local python_user_base
        python_user_base="$(python3 -m site --user-base 2>/dev/null)"
        if [[ -n "$python_user_base" && -d "$python_user_base/bin" ]]; then
            _path_prepend "$python_user_base/bin"
        fi
    fi

    # Poetry configuration
    if command -v poetry >/dev/null 2>&1; then
        export POETRY_VENV_IN_PROJECT=1
        export POETRY_CACHE_DIR="${HOME}/.cache/poetry"
        _dev_debug "Poetry configured"
    fi

    # Pipx configuration
    if [[ -d "${HOME}/.local/bin" ]]; then
        export PIPX_HOME="${HOME}/.local/share/pipx"
        export PIPX_BIN_DIR="${HOME}/.local/bin"
        _dev_debug "Pipx configured"
    fi

    _dev_debug "Python environment configured"
}

## [2.5] Ruby Development Environment
{
    _dev_debug "Configuring Ruby development environment..."

    export GEM_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/gem/ruby/3.3.0"
    export GEM_PATH="${GEM_HOME}/bin"
    [[ -d "$GEM_HOME/bin" ]] && _path_prepend "$GEM_HOME/bin"

    # Perlbrew for Perl development
    export PERLBREW_ROOT="${XDG_DATA_HOME:-${HOME}/.local/share}/perl5/perlbrew"

    _dev_debug "Ruby/Perl environments configured"
}

## [2.6] .NET Development Environment
{
    _dev_debug "Configuring .NET development environment..."

    export DOTNET_CLI_FORCE_UTF8_ENCODING="true"
    export DOTNET_CLI_HOME="${DOTNET_CLI_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/dotnet}"
    export DOTNET_CLI_TELEMETRY_OPTOUT="true"
    export DOTNET_ROOT="${DOTNET_ROOT:-/usr/local/share/dotnet}"
    export DOTNET_SYSTEM_CONSOLE_ALLOW_ANSI_COLOR_REDIRECTION="true"

    [[ -d "$DOTNET_CLI_HOME/tools" ]] && _path_prepend "$DOTNET_CLI_HOME/tools"

    _dev_debug ".NET environment configured"
}

## [2.7] PHP Development Environment
{
    _dev_debug "Configuring PHP development environment..."

    # Herd PHP development environment
    export HERD_APP="/Applications/Herd.app"
    export HERD_TOOLS_HOME="${HOME}/Library/Application Support/Herd"
    export HERD_TOOLS_BIN="${HERD_TOOLS_HOME}/bin"
    export HERD_TOOLS_CONFIG="${HERD_TOOLS_HOME}/config"

    # PHP version-specific configurations
    export HERD_PHP_82_INI_SCAN_DIR="${HERD_TOOLS_CONFIG}/php/82/"
    export HERD_PHP_83_INI_SCAN_DIR="${HERD_TOOLS_CONFIG}/php/83/"
    export HERD_PHP_84_INI_SCAN_DIR="${HERD_TOOLS_CONFIG}/php/84/"
    export HERD_PHP_85_INI_SCAN_DIR="${HERD_TOOLS_CONFIG}/php/85/"

    [[ -d "$HERD_TOOLS_BIN" ]] && _path_prepend "$HERD_TOOLS_BIN"

    # Composer configuration
    export COMPOSER_MEMORY_LIMIT=-1
    if command -v composer >/dev/null 2>&1; then
        local composer_home
        composer_home="$(composer config --global home 2>/dev/null)"
        if [[ -n "$composer_home" && -d "$composer_home/vendor/bin" ]]; then
            _path_prepend "$composer_home/vendor/bin"
        fi
        _dev_debug "Composer configured"
    fi

    _dev_debug "PHP environment configured"
}

# ==============================================================================
# SECTION 3: DEVELOPMENT TOOLS & UTILITIES
# ==============================================================================
# Purpose: Configure development tools, editors, and utilities

_dev_debug "Setting up development tools and utilities..."

## [3.1] Version Control Systems
{
    _dev_debug "Configuring version control systems..."

    # Git configuration (post-plugin)
    if command -v git >/dev/null 2>&1; then
        export GIT_SSH_COMMAND="ssh -o ControlMaster=auto -o ControlPersist=60s"

        # Git LFS optimization
        if command -v git-lfs >/dev/null 2>&1; then
            export GIT_LFS_SKIP_SMUDGE=1
        fi

        _dev_debug "Git tools configured"
    fi

    # GitHub CLI
    export GH_CONFIG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/gh"
}

## [3.2] Editors & IDEs
{
    _dev_debug "Configuring editors and IDEs..."

    # Neovim configuration
    if command -v nvim >/dev/null 2>&1; then
        export EDITOR="nvim"
        export VISUAL="nvim"
        export GIT_EDITOR="nvim"

        # Bob (Neovim version manager) integration
        if [[ -d "${HOME}/.local/share/bob" ]]; then
            _path_prepend "${HOME}/.local/share/bob"
        fi

        # Handle Bob alias conflict with Laravel Sail
        if command -v bob >/dev/null 2>&1; then
            if (( ${+aliases[bob]} )); then
                unalias bob 2>/dev/null
            fi
            export BOB_CONFIG="${XDG_CONFIG_HOME:-${HOME}/.config}/bob/config.json"

            # Source bob environment if it exists
            if [[ -f "${XDG_DATA_HOME:-${HOME}/.local/share}/bob/env/env.sh" ]]; then
                builtin source "${XDG_DATA_HOME:-${HOME}/.local/share}/bob/env/env.sh"
            fi
        fi

        _dev_debug "Neovim configured"
    fi

    # VS Code integration
    if command -v code >/dev/null 2>&1; then
        export VSCODE_CWD="$PWD"
        _dev_debug "VS Code configured"
    fi

    # Emacs configuration
    export EMACS_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}/emacs"
    export EMACS_SERVER_NAME="emacs-server"
    [[ -d "$EMACS_HOME/bin" ]] && _path_prepend "$EMACS_HOME/bin"
}

## [3.3] Containerization & Orchestration
{
    _dev_debug "Configuring containerization tools..."

    # Docker configuration
    export DOCKER_CONFIG="${XDG_CONFIG_HOME:-${HOME}/.config}/docker"
    if command -v docker >/dev/null 2>&1; then
        export DOCKER_BUILDKIT=1
        export COMPOSE_DOCKER_CLI_BUILD=1

        # Docker Desktop specific optimizations
        if [[ "$OSTYPE" == "darwin"* ]]; then
            export DOCKER_DEFAULT_PLATFORM=linux/amd64
        fi

        # Docker Desktop completions
        if [[ -d "$HOME/.docker/completions" ]]; then
            fpath=("$HOME/.docker/completions" $fpath)
            _dev_debug "Docker completions added to fpath"
        fi

        _dev_debug "Docker configured"
    fi

    # Kubernetes tools
    if command -v kubectl >/dev/null 2>&1; then
        export KUBE_EDITOR="nvim"
        export KUBECTL_EXTERNAL_DIFF="diff -u"
        _dev_debug "Kubernetes tools configured"
    fi
}

## [3.4] Cloud Provider Tools
{
    _dev_debug "Configuring cloud provider tools..."

    # AWS CLI
    if command -v aws >/dev/null 2>&1; then
        export AWS_PAGER=""
        export AWS_CLI_AUTO_PROMPT=on-partial
        _dev_debug "AWS CLI configured"
    fi

    # Google Cloud SDK
    if command -v gcloud >/dev/null 2>&1; then
        export CLOUDSDK_PYTHON_SITEPACKAGES=1
        _dev_debug "Google Cloud SDK configured"
    fi

    # Google Cloud SDK integration
    if [[ -d "$HOME/google-cloud-sdk" ]]; then
        source "$HOME/google-cloud-sdk/path.zsh.inc" 2>/dev/null
        source "$HOME/google-cloud-sdk/completion.zsh.inc" 2>/dev/null
        _dev_debug "Google Cloud SDK integrated"
    fi

    # Azure CLI
    if command -v az >/dev/null 2>&1; then
        export AZURE_CORE_OUTPUT=table
        _dev_debug "Azure CLI configured"
    fi
}

## [3.5] Database Tools
{
    _dev_debug "Configuring database tools..."

    # PostgreSQL
    if command -v psql >/dev/null 2>&1; then
        export PGUSER="postgres"
        export PGDATABASE="postgres"
        _dev_debug "PostgreSQL configured"
    fi

    # MySQL
    if command -v mysql >/dev/null 2>&1; then
        export MYSQL_PS1="(\\u@\\h) [\\d]> "
        _dev_debug "MySQL configured"
    fi
}

## [3.6] Build Tools & Systems
{
    _dev_debug "Configuring build tools..."

    # Make configuration
    if command -v make >/dev/null 2>&1; then
        local cpu_count
        cpu_count=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
        export MAKEFLAGS="-j$cpu_count"
    fi

    # CMake configuration
    if command -v cmake >/dev/null 2>&1; then
        export CMAKE_EXPORT_COMPILE_COMMANDS=1
        local cpu_count
        cpu_count=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
        export CMAKE_BUILD_PARALLEL_LEVEL="$cpu_count"
    fi

    # Ninja build system
    if command -v ninja >/dev/null 2>&1; then
        export CMAKE_GENERATOR="Ninja"
    fi
}

# ==============================================================================
# SECTION 4: ENHANCED FUZZY FINDER (FZF) CONFIGURATION
# ==============================================================================
# Purpose: Advanced FZF configuration for development workflows

_dev_debug "Setting up enhanced FZF configuration..."

if command -v fzf >/dev/null 2>&1; then
    export FZF_BASE="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/fzf"
    export FZF_COMPLETION_TRIGGER='**'
    export FZF_TMUX_HEIGHT=40%
    export FZF_TMUX=1
    export LESSOPEN='| lessfilter-fzf %s'

    # Default commands with fd if available
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND='fd --type f --hidden --follow --exclude .git'
    fi

    # Enhanced options with bat integration
    export FZF_DEFAULT_OPTS='--ansi --bind=ctrl-j:down,ctrl-k:up,ctrl-h:preview-up,ctrl-l:preview-down --border --color --cycle --height 40% --ignore-case --layout=reverse --multi --nth=2 --preview="bat --color=always --line-range :500 --style=grid,header,numbers {}" --preview-window=right:60%:wrap --prompt="Q> " --wrap'

    # Bat integration for previews
    if command -v bat >/dev/null 2>&1; then
        export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range=:500 {}'"
        export FZF_ALT_C_OPTS='--preview-window=right:60%:wrap'
    fi

    export FZF_CTRL_R_OPTS="--sort --exact"

    _dev_debug "FZF configured with enhanced features"
fi

# ==============================================================================
# SECTION 5: PERFORMANCE MONITORING TOOLS
# ==============================================================================
# Purpose: Configure system monitoring and performance tools

_dev_debug "Setting up performance monitoring tools..."

# htop configuration
if command -v htop >/dev/null 2>&1; then
    export HTOPRC="${HOME}/.config/htop/htoprc"
fi

# btop configuration
if command -v btop >/dev/null 2>&1; then
    export BTOPRC="${HOME}/.config/btop/btop.conf"
fi

# Screen terminal multiplexer
export SCREENRC="${XDG_CONFIG_HOME:-${HOME}/.config}/screen/screenrc"

# Desk workspace management
export DESK_TEMPLATES_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/desk"
export DESK_DESKDIR="${XDG_DATA_HOME:-${HOME}/.local/share}/desk"
export DESK_DESKSET_DIR="${DESK_DESKDIR}"

# GPG configuration
export GPG_AGENT_INFO_FILE="${XDG_RUNTIME_DIR:-/tmp}/gpg-agent-info"

# ==============================================================================
# SECTION 6: PLATFORM-SPECIFIC OPTIMIZATIONS
# ==============================================================================
# Purpose: Platform-specific tool configurations and optimizations

_dev_debug "Applying platform-specific optimizations..."

case "$(uname -s 2>/dev/null || echo Unknown)" in
    Darwin)
        # macOS-specific optimizations
        if command -v defaults >/dev/null 2>&1; then
            # Optimize macOS for development (non-interactive)
            defaults write -g NSWindowShouldDragOnGesture -bool true 2>/dev/null || true
            defaults write NSGlobalDomain AppleHighlightColor -string "0.615686 0.823529 0.454902" 2>/dev/null || true
        fi

        # Homebrew optimizations
        if command -v brew >/dev/null 2>&1; then
            export HOMEBREW_NO_AUTO_UPDATE=1
            export HOMEBREW_NO_ANALYTICS=1
            export HOMEBREW_NO_INSECURE_REDIRECT=1
        fi

        _dev_debug "macOS optimizations applied"
        ;;
    Linux)
        # Linux-specific optimizations
        if command -v apt >/dev/null 2>&1; then
            export DEBIAN_FRONTEND=noninteractive
        fi

        if command -v systemctl >/dev/null 2>&1; then
            export SYSTEMD_PAGER=""
        fi

        _dev_debug "Linux optimizations applied"
        ;;
    MINGW32_NT*|MINGW64_NT*)
        # Windows/Git Bash optimizations
        export MSYS2_PATH_TYPE=inherit
        _dev_debug "Windows optimizations applied"
        ;;
esac

# ==============================================================================
# SECTION 7: SPECIALIZED INTEGRATIONS
# ==============================================================================
# Purpose: Specialized tool integrations and completions

_dev_debug "Setting up specialized integrations..."

# Bun completions
if [[ -s "${XDG_DATA_HOME:-${HOME}/.local/share}/bun/_bun" ]]; then
    source "${XDG_DATA_HOME:-${HOME}/.local/share}/bun/_bun"
    _dev_debug "Bun completions loaded"
fi

# MCP Environment Setup for AugmentCode
if [[ -f "$HOME/.mcp-environment.sh" ]]; then
    builtin source "$HOME/.mcp-environment.sh"
    _dev_debug "MCP AugmentCode environment loaded"
fi

# Ensure fpath is unique and properly ordered
typeset -gU fpath

# ==============================================================================
# SECTION 8: DEVELOPMENT HEALTH CHECK FUNCTIONS
# ==============================================================================
# Purpose: Health check and diagnostics functions for development environment

_dev_debug "Setting up development health check functions..."

# Main health check function
zsh_health_check() {
    local FAILURES=()
    _dev_debug "Starting ZSH configuration health check..."

    echo "🔍 Zsh Configuration Health Check"
    echo "================================"

    _check_syntax_errors FAILURES
    _check_exposed_credentials FAILURES
    _check_path_sanity FAILURES
    _check_zgenom_setup FAILURES
    _display_startup_time
    _check_docs_links FAILURES
    _display_health_summary FAILURES

    return $((${#FAILURES[@]} > 0 ? 1 : 0))
}

# Syntax error checking
_check_syntax_errors() {
    local -n failures_ref=$1
    local config_files=(
        "${ZDOTDIR:-$HOME/.config/zsh}/.zshenv"
        "${ZDOTDIR:-$HOME/.config/zsh}/.zshrc"
        "${ZDOTDIR:-$HOME/.config/zsh}"/.zshrc.d/*.zsh(N)
    )

    for file in "${config_files[@]}"; do
        if [[ -f "$file" ]]; then
            if zsh -n "$file" 2>/dev/null; then
                echo "✅ $(basename "$file") - Syntax OK"
            else
                echo "❌ $(basename "$file") - Syntax Error"
                failures_ref+=("syntax:$(basename "$file")")
            fi
        fi
    done
}

# Credential exposure checking
_check_exposed_credentials() {
    local -n failures_ref=$1
    if grep -r "sk-" "${ZDOTDIR:-$HOME/.config/zsh}/" --exclude-dir=.env 2>/dev/null >/dev/null; then
        echo "⚠️  Possible exposed API keys found!"
        failures_ref+=("secrets")
    else
        echo "✅ No exposed API keys detected"
    fi
}

# PATH sanity checking
_check_path_sanity() {
    local -n failures_ref=$1
    if echo "$PATH" | grep -q "/usr/bin"; then
        echo "✅ System PATH includes /usr/bin"
    else
        echo "❌ System PATH missing /usr/bin"
        failures_ref+=("path:usrbin")
    fi
}

# Zgenom setup checking
_check_zgenom_setup() {
    local -n failures_ref=$1
    if [[ -n "$ZGEN_DIR" && -d "$ZGEN_DIR" ]]; then
        echo "✅ zgenom directory exists: $ZGEN_DIR"
    else
        echo "⚠️  zgenom directory not found"
        failures_ref+=("zgenom:missing")
    fi
}

# Startup time display
_display_startup_time() {
    local startup_time
    startup_time=$( (time zsh -i -c exit) 2>&1 | grep real | awk '{print $2}' 2>/dev/null || echo "unknown")
    echo "⏱️  Startup time: $startup_time"
}

# Documentation links checking
_check_docs_links() {
    local -n failures_ref=$1
    if typeset -f zsh_docs_link_lint >/dev/null 2>&1; then
        if zsh_docs_link_lint >/dev/null 2>&1; then
            echo "📚 Docs links: OK"
        else
            echo "📚 Docs links: FAIL"
            failures_ref+=("docs-links")
        fi
    else
        echo "📚 Docs links: Skipped (function not available)"
    fi
}

# Health summary display
_display_health_summary() {
    local -n failures_ref=$1
    if (( ${#failures_ref[@]} )); then
        echo ""
        echo "❌ Health check failures: ${failures_ref[*]}"
        echo "Exit code: 1 (failures present)"
    else
        echo ""
        echo "✅ Health check passed (no failures)"
    fi

    echo ""
    echo "💡 Recommendations:"
    echo "- Run 'zsh_health_check' monthly"
    echo "- Keep startup time under 2 seconds"
    echo "- Update plugins quarterly: 'zgenom update'"
    echo "- Backup config before major changes"
    echo "- Address any failures promptly"
}

# Documentation link linter
zsh_docs_link_lint() {
    local VERBOSE=0
    [[ ${1:-} == --verbose ]] && VERBOSE=1
    local DOCS_DIR="docs"

    if [[ ! -d $DOCS_DIR ]]; then
        echo "[docs-link-lint] ERROR: docs directory not found"
        return 2
    fi

    local md_files missing checked
    md_files=($(find "$DOCS_DIR" -type f -name '*.md' -print 2>/dev/null))
    (( ! ${#md_files[@]} )) && {
        echo "[docs-link-lint] No markdown files found"
        return 0
    }

    missing=()
    checked=0

    for f in "${md_files[@]}"; do
        _process_markdown_file "$f" "$DOCS_DIR" "$VERBOSE" missing checked
    done

    _report_link_check_results "$checked" "${#md_files[@]}" missing
}

# Markdown file processing helper
_process_markdown_file() {
    local file="$1" docs_dir="$2" verbose="$3"
    local -n missing_ref="$4" checked_ref="$5"
    local in_code=0 line

    while IFS= read -r line; do
        if [[ $line == '```'* ]]; then
            in_code=$(( in_code ^ 1 ))
            continue
        fi
        (( in_code )) && continue

        if [[ $line == *']('* ]]; then
            for link in $(echo "$line" | grep -Eo '\[[^]]+\]\([^)]+\)' 2>/dev/null); do
                [[ $link == '!'* ]] && continue
                local target=${link#*(}
                target=${target%)}

                if _is_external_or_anchor_link "$target"; then
                    continue
                fi

                if ! _link_target_exists "$target" "$docs_dir"; then
                    missing_ref+=("$file:$target")
                fi

                ((checked_ref++))
                (( verbose )) && echo "[docs-link-lint] $file => $target"
            done
        fi
    done < "$file"
}

# Link type detection helper
_is_external_or_anchor_link() {
    local target="$1"
    [[ $target == http://* || $target == https://* || $target == mailto:* || $target == \#* ]]
}

# Link target existence checking
_link_target_exists() {
    local target="$1" docs_dir="$2"
    local base_file=${target%%#*}
    [[ -n $base_file ]] && [[ -f $docs_dir/$base_file || -f $base_file ]]
}

# Link check results reporting
_report_link_check_results() {
    local checked="$1" files_count="$2"
    local -n missing_ref="$3"

    if (( ${#missing_ref[@]} )); then
        echo "[docs-link-lint] Missing link targets (${#missing_ref[@]}):"
        for m in "${missing_ref[@]}"; do
            echo "  - $m"
        done
        echo "[docs-link-lint] Checked $checked links"
        return 1
    fi

    echo "[docs-link-lint] All $checked links OK (files scanned: $files_count)"
    return 0
}

# ==============================================================================
# MODULE INITIALIZATION
# ==============================================================================

_dev_debug "Initializing development tools module..."

# PATH deduplication using zsh builtin
typeset -aU path

# Set development tools metadata
export DEVELOPMENT_TOOLS_VERSION="1.0.0"
export DEVELOPMENT_TOOLS_LOADED="$(/usr/bin/date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'unknown')"

# Count configured languages and tools
local configured_languages=0
local configured_tools=0

# Count languages
command -v node >/dev/null 2>&1 && ((configured_languages++))
command -v go >/dev/null 2>&1 && ((configured_languages++))
command -v rustc >/dev/null 2>&1 && ((configured_languages++))
command -v python3 >/dev/null 2>&1 && ((configured_languages++))
command -v ruby >/dev/null 2>&1 && ((configured_languages++))
command -v php >/dev/null 2>&1 && ((configured_languages++))
command -v dotnet >/dev/null 2>&1 && ((configured_languages++))

# Count tools
command -v docker >/dev/null 2>&1 && ((configured_tools++))
command -v git >/dev/null 2>&1 && ((configured_tools++))
command -v nvim >/dev/null 2>&1 && ((configured_tools++))
command -v fzf >/dev/null 2>&1 && ((configured_tools++))
command -v kubectl >/dev/null 2>&1 && ((configured_tools++))

export DEVELOPMENT_LANGUAGES_COUNT=$configured_languages
export DEVELOPMENT_TOOLS_COUNT=$configured_tools

_dev_debug "Development tools module ready ($configured_languages languages, $configured_tools tools)"

# ==============================================================================
# MODULE SELF-TEST
# ==============================================================================

test_development_tools() {
    local tests_passed=0
    local tests_total=10

    # Test 1: PATH helpers available
    if command -v _path_prepend >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ PATH helper functions available"
    else
        echo "❌ PATH helper functions missing"
    fi

    # Test 2: Health check function
    if command -v zsh_health_check >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Health check function loaded"
    else
        echo "❌ Health check function not loaded"
    fi

    # Test 3: Documentation linter
    if command -v zsh_docs_link_lint >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Documentation linter loaded"
    else
        echo "❌ Documentation linter not loaded"
    fi

    # Test 4: Language environments configured
    if [[ -n "$GOPATH" ]] && [[ -n "$CARGO_HOME" ]]; then
        ((tests_passed++))
        echo "✅ Language environments configured"
    else
        echo "❌ Language environments not configured"
    fi

    # Test 5: Editor configuration
    if [[ "$EDITOR" == "nvim" ]] || [[ -n "$EMACS_HOME" ]]; then
        ((tests_passed++))
        echo "✅ Editor configuration set"
    else
        echo "❌ Editor configuration missing"
    fi

    # Test 6: FZF configuration
    if [[ -n "$FZF_DEFAULT_OPTS" ]]; then
        ((tests_passed++))
        echo "✅ FZF configuration loaded"
    else
        echo "❌ FZF configuration missing"
    fi

    # Test 7: Docker configuration
    if [[ -n "$DOCKER_BUILDKIT" ]]; then
        ((tests_passed++))
        echo "✅ Docker configuration set"
    else
        echo "❌ Docker configuration missing"
    fi

    # Test 8: Cloud tools configured
    if [[ -n "$AWS_PAGER" ]] || [[ -n "$CLOUDSDK_PYTHON_SITEPACKAGES" ]]; then
        ((tests_passed++))
        echo "✅ Cloud tools configuration set"
    else
        echo "❌ Cloud tools configuration missing"
    fi

    # Test 9: Module metadata
    if [[ -n "$DEVELOPMENT_TOOLS_VERSION" ]]; then
        ((tests_passed++))
        echo "✅ Module metadata available"
    else
        echo "❌ Module metadata missing"
    fi

    # Test 10: PATH deduplication working
    local path_entries path_unique_entries
    path_entries=$(echo "$PATH" | tr ':' '\n' | wc -l)
    path_unique_entries=$(echo "$PATH" | tr ':' '\n' | sort -u | wc -l)

    if [[ "$path_entries" -eq "$path_unique_entries" ]]; then
        ((tests_passed++))
        echo "✅ PATH deduplication working"
    else
        echo "❌ PATH has duplicate entries"
    fi

    echo ""
    echo "Development Tools Self-Test: $tests_passed/$tests_total tests passed"
    echo "📊 Languages configured: $DEVELOPMENT_LANGUAGES_COUNT"
    echo "🛠️  Tools configured: $DEVELOPMENT_TOOLS_COUNT"
    echo "🗂️  Module version: $DEVELOPMENT_TOOLS_VERSION"

    if [[ $tests_passed -eq $tests_total ]]; then
        return 0
    else
        return 1
    fi
}

# ==============================================================================
# END OF DEVELOPMENT TOOLS MODULE
# ==============================================================================
