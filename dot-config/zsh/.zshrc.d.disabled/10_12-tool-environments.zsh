#!/usr/bin/env zsh
# Tool Environment Configuration - POST-PLUGIN PHASE
# This file configures development tools AFTER plugins are loaded
# CONSOLIDATED FROM: 070-tools.zsh + enhanced tool integrations

[[ "$ZSH_DEBUG" == "1" ]] && {
        zsh_debug_echo "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
    zsh_debug_echo "# [tool-environments] Configuring development tools after plugins"
}

## [tool-environments.node] - Node.js ecosystem configuration
if command -v node >/dev/null 2>&1; then
    # Configure npm and related tools
    export NPM_CONFIG_PROGRESS=false
    export NPM_CONFIG_AUDIT=false
    export NPM_CONFIG_FUND=false

    # pnpm configuration
    if command -v pnpm >/dev/null 2>&1; then
        export PNPM_HOME="$HOME/.local/share/pnpm"
        _path_prepend "$PNPM_HOME"
    fi

    # Bun configuration
    if [[ -d "$BUN_INSTALL" ]]; then
        _path_prepend "$BUN_INSTALL/bin"
    fi

    [[ "$ZSH_DEBUG" == "1" ]] && zsh_debug_echo "# [tool-environments] Node.js ecosystem configured"
fi

## [tool-environments.python] - Python development configuration
if command -v python3 >/dev/null 2>&1; then
    # Configure pip and python tools
    export PIP_REQUIRE_VIRTUALENV=true
    export PYTHONDONTWRITEBYTECODE=1
    export PYTHONUNBUFFERED=1

    # Poetry configuration
    if command -v poetry >/dev/null 2>&1; then
        export POETRY_VENV_IN_PROJECT=1
        export POETRY_CACHE_DIR="$HOME/.cache/poetry"
    fi

    # Pipx configuration
    if [[ -d "$HOME/.local/bin" ]]; then
        export PIPX_HOME="$HOME/.local/share/pipx"
        export PIPX_BIN_DIR="$HOME/.local/bin"
    fi

    [[ "$ZSH_DEBUG" == "1" ]] && zsh_debug_echo "# [tool-environments] Python development configured"
fi

## [tool-environments.rust] - Rust development configuration
if command -v rustc >/dev/null 2>&1; then
    # Optimize Rust builds
    export CARGO_INCREMENTAL=1
    export RUST_BACKTRACE=1

    # Add cargo bin to path
    [[ -d "$HOME/.cargo/bin" ]] && _path_prepend "$HOME/.cargo/bin"

    # Sccache for faster builds
    if command -v sccache >/dev/null 2>&1; then
        export RUSTC_WRAPPER=sccache
    fi

    [[ "$ZSH_DEBUG" == "1" ]] && zsh_debug_echo "# [tool-environments] Rust development configured"
fi

## [tool-environments.go] - Go development configuration
if command -v go >/dev/null 2>&1; then
    # Configure Go environment
    export GOPATH="$HOME/go"
    export GOPROXY="direct"
    export GOSUMDB="off"

    # Add Go bin to path
    [[ -d "$GOPATH/bin" ]] && _path_prepend "$GOPATH/bin"
    [[ -d "/usr/local/go/bin" ]] && _path_prepend "/usr/local/go/bin"

    [[ "$ZSH_DEBUG" == "1" ]] && zsh_debug_echo "# [tool-environments] Go development configured"
fi

## [tool-environments.docker] - Docker and containerization
if command -v docker >/dev/null 2>&1; then
    # Docker configuration
    export DOCKER_BUILDKIT=1
    export COMPOSE_DOCKER_CLI_BUILD=1

    # Docker Desktop specific optimizations
    if [[ "$OSTYPE" == "darwin"* ]]; then
        export DOCKER_DEFAULT_PLATFORM=linux/amd64
    fi

    [[ "$ZSH_DEBUG" == "1" ]] && zsh_debug_echo "# [tool-environments] Docker configured"
fi

## [tool-environments.kubernetes] - Kubernetes tools
if command -v kubectl >/dev/null 2>&1; then
    # Kubectl configuration
    export KUBE_EDITOR="nvim"
    export KUBECTL_EXTERNAL_DIFF="diff -u"

    # Enable kubectl completion (only if not already done)
    if ! command -v _kubectl >/dev/null 2>&1; then
        source <(kubectl completion zsh)
    fi

    [[ "$ZSH_DEBUG" == "1" ]] && zsh_debug_echo "# [tool-environments] Kubernetes tools configured"
fi

## [tool-environments.cloud] - Cloud provider tools
# AWS CLI
if command -v aws >/dev/null 2>&1; then
    export AWS_PAGER=""
    export AWS_CLI_AUTO_PROMPT=on-partial
    [[ "$ZSH_DEBUG" == "1" ]] && zsh_debug_echo "# [tool-environments] AWS CLI configured"
fi

# Google Cloud SDK
if command -v gcloud >/dev/null 2>&1; then
    export CLOUDSDK_PYTHON_SITEPACKAGES=1
    [[ "$ZSH_DEBUG" == "1" ]] && zsh_debug_echo "# [tool-environments] Google Cloud SDK configured"
fi

# Azure CLI
if command -v az >/dev/null 2>&1; then
    export AZURE_CORE_OUTPUT=table
    [[ "$ZSH_DEBUG" == "1" ]] && zsh_debug_echo "# [tool-environments] Azure CLI configured"
fi

## [tool-environments.databases] - Database tools
if command -v psql >/dev/null 2>&1; then
    export PGUSER="postgres"
    export PGDATABASE="postgres"
    [[ "$ZSH_DEBUG" == "1" ]] && zsh_debug_echo "# [tool-environments] PostgreSQL configured"
fi

if command -v mysql >/dev/null 2>&1; then
    export MYSQL_PS1="(\u@\h) [\d]> "
    [[ "$ZSH_DEBUG" == "1" ]] && zsh_debug_echo "# [tool-environments] MySQL configured"
fi

## [tool-environments.editors] - Editor integrations
# Neovim configuration
if command -v nvim >/dev/null 2>&1; then
    export EDITOR="nvim"
    export VISUAL="nvim"
    export GIT_EDITOR="nvim"

    # Bob (Neovim version manager) integration
    if [[ -d "$HOME/.local/share/bob" ]]; then
        _path_prepend "$HOME/.local/share/bob"
    fi

    [[ "$ZSH_DEBUG" == "1" ]] && zsh_debug_echo "# [tool-environments] Neovim configured"
fi

# VS Code integration
if command -v code >/dev/null 2>&1; then
    export VSCODE_CWD="$PWD"
    [[ "$ZSH_DEBUG" == "1" ]] && zsh_debug_echo "# [tool-environments] VS Code configured"
fi

## [tool-environments.build-tools] - Build and development tools
# Make configuration
if command -v make >/dev/null 2>&1; then
    export MAKEFLAGS="-j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || zsh_debug_echo 4)"
fi

# CMake configuration
if command -v cmake >/dev/null 2>&1; then
    export CMAKE_EXPORT_COMPILE_COMMANDS=1
    export CMAKE_BUILD_PARALLEL_LEVEL="$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || zsh_debug_echo 4)"
fi

# Ninja build system
if command -v ninja >/dev/null 2>&1; then
    export CMAKE_GENERATOR="Ninja"
fi

## [tool-environments.version-control] - VCS tool configuration
# Git configuration (post-plugin)
if command -v git >/dev/null 2>&1; then
    # Configure git to use system tools
    export GIT_SSH_COMMAND="ssh -o ControlMaster=auto -o ControlPersist=60s"

    # Git LFS if available
    if command -v git-lfs >/dev/null 2>&1; then
        export GIT_LFS_SKIP_SMUDGE=1
    fi

    [[ "$ZSH_DEBUG" == "1" ]] && zsh_debug_echo "# [tool-environments] Git tools configured"
fi

## [tool-environments.performance] - Performance monitoring tools
# Configure tools for optimal performance
if command -v htop >/dev/null 2>&1; then
    export HTOPRC="$HOME/.config/htop/htoprc"
fi

if command -v btop >/dev/null 2>&1; then
    export BTOPRC="$HOME/.config/btop/btop.conf"
fi

## [tool-environments.platform-specific] - Platform-specific tool configurations
# MERGED FROM: 070-tools.zsh platform configurations

case "$(safe_uname -s)" in
    Darwin)
        # macOS-specific tool optimizations
        if command -v defaults >/dev/null 2>&1; then
            # Optimize macOS for development
            defaults write -g NSWindowShouldDragOnGesture -bool true 2>/dev/null || true
            defaults write NSGlobalDomain AppleHighlightColor -string "0.615686 0.823529 0.454902" 2>/dev/null || true
        fi

        # Homebrew optimizations for macOS
        if command -v brew >/dev/null 2>&1; then
            export HOMEBREW_NO_AUTO_UPDATE=1
            export HOMEBREW_NO_ANALYTICS=1
            export HOMEBREW_NO_INSECURE_REDIRECT=1
        fi

        [[ "$ZSH_DEBUG" == "1" ]] && zsh_debug_echo "# [tool-environments] macOS optimizations applied"
        ;;
    Linux)
        # Linux-specific optimizations
        if command -v apt >/dev/null 2>&1; then
            export DEBIAN_FRONTEND=noninteractive
        fi

        if command -v systemctl >/dev/null 2>&1; then
            export SYSTEMD_PAGER=""
        fi

        [[ "$ZSH_DEBUG" == "1" ]] && zsh_debug_echo "# [tool-environments] Linux optimizations applied"
        ;;
    MINGW32_NT*|MINGW64_NT*)
        # Windows/Git Bash optimizations
        export MSYS2_PATH_TYPE=inherit
        [[ "$ZSH_DEBUG" == "1" ]] && zsh_debug_echo "# [tool-environments] Windows optimizations applied"
        ;;
esac

## [tool-environments.specialized-tools] - Specialized development tools
# MERGED FROM: 070-tools.zsh specialized configurations

# Composer (PHP)
if command -v composer >/dev/null 2>&1; then
    composer_home="$(composer config --global home 2>/dev/null)"
    if [[ -n "$composer_home" && -d "$composer_home/vendor/bin" ]]; then
        _path_prepend "$composer_home/vendor/bin"
    fi
    export COMPOSER_MEMORY_LIMIT=-1
    unset composer_home
    [[ "$ZSH_DEBUG" == "1" ]] && zsh_debug_echo "# [tool-environments] Composer configured"
fi

# Bob Neovim version manager
if command -v bob >/dev/null 2>&1; then
    # Remove conflicting bob alias if it exists (Laravel/PHP development)
    if (( ${+aliases[bob]} )); then
        unalias bob
    fi

    export BOB_CONFIG="${XDG_CONFIG_HOME}/bob/config.json"

    # Source bob environment if it exists
    if [[ -f "${XDG_DATA_HOME}/bob/env/env.sh" ]]; then
        builtin source "${XDG_DATA_HOME}/bob/env/env.sh"
    fi

    [[ "$ZSH_DEBUG" == "1" ]] && zsh_debug_echo "# [tool-environments] Bob (Neovim manager) configured"
fi

# Bun completions and environment
if [[ -s "${XDG_DATA_HOME}/bun/_bun" ]]; then
    source "${XDG_DATA_HOME}/bun/_bun"
    [[ "$ZSH_DEBUG" == "1" ]] && zsh_debug_echo "# [tool-environments] Bun completions loaded"
fi

# Docker Desktop completions
if [[ -d "$HOME/.docker/completions" ]]; then
    fpath=("$HOME/.docker/completions" $fpath)
    [[ "$ZSH_DEBUG" == "1" ]] && zsh_debug_echo "# [tool-environments] Docker completions added to fpath"
fi

# Google Cloud SDK integration
if [[ -d "$HOME/google-cloud-sdk" ]]; then
    source "$HOME/google-cloud-sdk/path.zsh.inc" 2>/dev/null
    source "$HOME/google-cloud-sdk/completion.zsh.inc" 2>/dev/null
    [[ "$ZSH_DEBUG" == "1" ]] && zsh_debug_echo "# [tool-environments] Google Cloud SDK integrated"
fi

# MCP Environment Setup for AugmentCode
if [[ -f "$HOME/.mcp-environment.sh" ]]; then
    builtin source "$HOME/.mcp-environment.sh"
    [[ "$ZSH_DEBUG" == "1" ]] && zsh_debug_echo "# [tool-environments] MCP AugmentCode environment loaded"
fi

## [tool-environments.path-helpers] - PATH management utilities
# PATH management functions are defined in 00_04-functions-core.zsh
# This section ensures they're available for use in this file

# NOTE: _path_prepend and _path_append functions are defined in core functions
# and exported globally. They should not be redefined here to avoid conflicts.

## [tool-environments.environment-cleanup] - Clean up temporary variables
# Clean up any temporary variables used during tool configuration

# Ensure fpath is unique and properly ordered
typeset -gU fpath

# Final PATH deduplication
if command -v awk >/dev/null 2>&1; then
    local new_path
    new_path=$(zsh_debug_echo -n "$PATH" | awk -v RS=: '!($0 in a) {a[$0]; printf("%s%s", length(a) > 1 ? ":" : "", $0)}')
    export PATH="$new_path"
fi

[[ "$ZSH_DEBUG" == "1" ]] && zsh_debug_echo "# [tool-environments] ✅ All development tools configured and optimized"
