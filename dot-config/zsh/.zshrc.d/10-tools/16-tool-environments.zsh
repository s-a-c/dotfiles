# Tool Environments - POST-PLUGIN PHASE
# Tool configuration and environment setup AFTER plugins are loaded
# ENHANCED FROM: 070-tools.zsh with comprehensive tool integrations

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
    echo "# [tool-environments] Configuring development tools after plugins" >&2
}

## [tool-environments.node] - Node.js ecosystem configuration
if command -v node >/dev/null 2>&1; then
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

    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [tool-environments] Node.js ecosystem configured" >&2
fi

## [tool-environments.python] - Python development configuration
if command -v python3 >/dev/null 2>&1; then
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

    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [tool-environments] Python development configured" >&2
fi

## [tool-environments.rust] - Rust development configuration
if command -v rustc >/dev/null 2>&1; then
    export CARGO_INCREMENTAL=1
    export RUST_BACKTRACE=1

    [[ -d "$HOME/.cargo/bin" ]] && _path_prepend "$HOME/.cargo/bin"

    if command -v sccache >/dev/null 2>&1; then
        export RUSTC_WRAPPER=sccache
    fi

    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [tool-environments] Rust development configured" >&2
fi

## [tool-environments.go] - Go development configuration
if command -v go >/dev/null 2>&1; then
    export GOPATH="$HOME/go"
    export GOPROXY="direct"
    export GOSUMDB="off"

    [[ -d "$GOPATH/bin" ]] && _path_prepend "$GOPATH/bin"
    [[ -d "/usr/local/go/bin" ]] && _path_prepend "/usr/local/go/bin"

    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [tool-environments] Go development configured" >&2
fi

## [tool-environments.docker] - Docker and containerization
if command -v docker >/dev/null 2>&1; then
    export DOCKER_BUILDKIT=1
    export COMPOSE_DOCKER_CLI_BUILD=1

    if [[ "$OSTYPE" == "darwin"* ]]; then
        export DOCKER_DEFAULT_PLATFORM=linux/amd64
    fi

    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [tool-environments] Docker configured" >&2
fi

## [tool-environments.kubernetes] - Kubernetes tools
if command -v kubectl >/dev/null 2>&1; then
    export KUBE_EDITOR="nvim"
    export KUBECTL_EXTERNAL_DIFF="diff -u"

    if ! command -v _kubectl >/dev/null 2>&1; then
        source <(kubectl completion zsh)
    fi

    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [tool-environments] Kubernetes tools configured" >&2
fi

## [tool-environments.cloud] - Cloud provider tools
if command -v aws >/dev/null 2>&1; then
    export AWS_PAGER=""
    export AWS_CLI_AUTO_PROMPT=on-partial
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [tool-environments] AWS CLI configured" >&2
fi

if command -v gcloud >/dev/null 2>&1; then
    export CLOUDSDK_PYTHON_SITEPACKAGES=1
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [tool-environments] Google Cloud SDK configured" >&2
fi

if command -v az >/dev/null 2>&1; then
    export AZURE_CORE_OUTPUT=table
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [tool-environments] Azure CLI configured" >&2
fi

## [tool-environments.editors] - Editor integrations
if command -v nvim >/dev/null 2>&1; then
    export EDITOR="nvim"
    export VISUAL="nvim"
    export GIT_EDITOR="nvim"

    if [[ -d "$HOME/.local/share/bob" ]]; then
        _path_prepend "$HOME/.local/share/bob"
    fi

    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [tool-environments] Neovim configured" >&2
fi

if command -v code >/dev/null 2>&1; then
    export VSCODE_CWD="$PWD"
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [tool-environments] VS Code configured" >&2
fi

## [tool-environments.macos-specific] - macOS-specific tool configuration
if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew >/dev/null 2>&1; then
        export HOMEBREW_NO_AUTO_UPDATE=1
        export HOMEBREW_NO_ANALYTICS=1
        export HOMEBREW_NO_INSECURE_REDIRECT=1
        export HOMEBREW_CASK_OPTS="--require-sha"

        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [tool-environments] Homebrew configured" >&2
    fi

    if command -v xcrun >/dev/null 2>&1; then
        export DEVELOPER_DIR="$(xcrun --show-sdk-platform-path)/Developer"
    fi
fi

## [tool-environments.cleanup] - Environment cleanup and validation
# path_validate_silent  # Function no longer available
typeset -gU fpath

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [tool-environments] ✅ Development tool environments configured" >&2
