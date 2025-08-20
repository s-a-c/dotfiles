# Development Tools Configuration
# This file configures various development environments and tools
# Load time target: <150ms

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
}

# Go development environment
if command_exists go || [[ -d "$HOME/go" ]]; then
    export GOPATH="${GOPATH:-$HOME/go}"
    export GOROOT="${GOROOT:-$(command -v go >/dev/null && go env GOROOT 2>/dev/null)}"

    # Add Go paths
    [[ -d "$GOPATH/bin" ]] && _path_prepend "$GOPATH/bin"
    [[ -n "$GOROOT" && -d "$GOROOT/bin" ]] && _path_prepend "$GOROOT/bin"

    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [dev-tools] Go environment configured" >&2
fi

# Node.js and NPM environment
if command_exists node || command_exists npm; then
    # NPM global packages
    if command_exists npm; then
        npm_prefix="$(npm config get prefix 2>/dev/null)"
        [[ -n "$npm_prefix" && -d "$npm_prefix/bin" ]] && _path_prepend "$npm_prefix/bin"
    fi

    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [dev-tools] Node.js environment configured" >&2
fi

# Python development environment
if command_exists python3 || command_exists pip3; then
    # Python user base
    if command_exists python3; then
        python_user_base="$(python3 -m site --user-base 2>/dev/null)"
        [[ -n "$python_user_base" && -d "$python_user_base/bin" ]] && _path_prepend "$python_user_base/bin"
    fi

    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [dev-tools] Python environment configured" >&2
fi

# Rust development environment
if command_exists rustc || [[ -d "$HOME/.cargo" ]]; then
    export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
    export RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"

    # Optimize Rust builds
    export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-/tmp/cargo-builds}"
    [[ ! -d "$CARGO_TARGET_DIR" ]] && mkdir -p "$CARGO_TARGET_DIR" 2>/dev/null

    # Cargo bin path
    [[ -d "$CARGO_HOME/bin" ]] && _path_prepend "$CARGO_HOME/bin"

    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [dev-tools] Rust environment configured" >&2
fi

# Deno environment
if command_exists deno || [[ -d "$HOME/.deno" ]]; then
    export DENO_INSTALL="${DENO_INSTALL:-$HOME/.deno}"
    [[ -d "$DENO_INSTALL/bin" ]] && _path_prepend "$DENO_INSTALL/bin"

    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [dev-tools] Deno environment configured" >&2
fi

# Bun environment
if command_exists bun || [[ -d "$HOME/.bun" ]]; then
    export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
    [[ -d "$BUN_INSTALL/bin" ]] && _path_prepend "$BUN_INSTALL/bin"

    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [dev-tools] Bun environment configured" >&2
fi

# Docker environment optimizations
if command_exists docker; then
    # Docker completion will be handled by the completion system
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [dev-tools] Docker environment configured" >&2
fi

# PHP development (including Composer)
if command_exists php || command_exists composer; then
    # Composer global packages
    if command_exists composer; then
        composer_home="$(composer config --global home 2>/dev/null)"
        [[ -n "$composer_home" && -d "$composer_home/vendor/bin" ]] && _path_prepend "$composer_home/vendor/bin"
    fi

    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [dev-tools] PHP/Composer environment configured" >&2
fi

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [10-tools] Development tools configured" >&2
