# NVM (Node Version Manager) Pre-Plugin Configuration
# This file configures NVM settings before plugins are loaded
# Load time target: <10ms

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
}

# =============================================================================
# NVM CONFIGURATION AND OPTIMIZATION
# =============================================================================

## [nvm.environment] - NVM Environment Variables
# Configure NVM behavior for optimal performance and usability

# Enable automatic .nvmrc usage when entering directories
export NVM_AUTO_USE=true

# Enable lazy loading for faster shell startup
export NVM_LAZY_LOAD=true

# Enable tab completion for NVM commands
export NVM_COMPLETION=true

# Set NVM lazy loading timeout (in seconds)
export NVM_LAZY_LOAD_TIMEOUT=2

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [nvm-config] NVM environment variables configured" >&2

## [nvm.directory-detection] - Smart NVM Directory Detection
# Detect NVM installation directory with fallback priority

detect_nvm_directory() {
    # Force override any existing NVM_DIR to ensure correct detection
    unset NVM_DIR

    local nvm_candidates=(
        # 1. Herd-managed NVM (if using Laravel Herd ecosystem)
        "${HOME}/Library/Application Support/Herd/config/nvm"

        # 2. Homebrew-managed NVM (most common on macOS)
        "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/nvm"

        # 3. Manual installation in user home
        "${HOME}/.nvm"

        # 4. System-wide installation
        "/usr/local/opt/nvm"

        # 5. Alternative Homebrew location (Intel Macs)
        "/usr/local/Homebrew/opt/nvm"
    )

    for candidate in "${nvm_candidates[@]}"; do
        if [[ -d "$candidate" ]] && [[ -f "$candidate/nvm.sh" ]]; then
            export NVM_DIR="$candidate"
            # CRITICAL: Unset NPM_CONFIG_PREFIX to allow NVM to work properly
            # NVM is incompatible with NPM_CONFIG_PREFIX being set
            unset NPM_CONFIG_PREFIX
            [[ "$ZSH_DEBUG" == "1" ]] && echo "# [nvm-config] NVM directory detected and set: $candidate" >&2
            [[ "$ZSH_DEBUG" == "1" ]] && echo "# [nvm-config] NPM_CONFIG_PREFIX unset for NVM compatibility" >&2
            return 0
        fi
    done

    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [nvm-config] WARNING: No valid NVM directory found in standard locations" >&2
    return 1
}

# Detect and set NVM_DIR
detect_nvm_directory

## [nvm.path-setup] - Ensure Node.js binaries are in PATH
# This ensures tools like Herd can detect node/npm even with lazy loading

setup_nvm_path() {
    # Only proceed if NVM_DIR is set and valid
    if [[ -z "${NVM_DIR:-}" ]] || [[ ! -d "$NVM_DIR" ]]; then
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [nvm-config] No NVM directory, skipping PATH setup" >&2
        return 1
    fi

    # Determine the current/default Node.js version path
    local node_version_path
    if [[ -L "$NVM_DIR/current" ]] && [[ -d "$NVM_DIR/current" ]]; then
        # Use the current symlink if it exists and is valid
        node_version_path="$NVM_DIR/current/bin"
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [nvm-config] Using current symlink: $node_version_path" >&2
    elif [[ -f "$NVM_DIR/alias/default" ]]; then
        # Use the default alias if available
        local default_version=$(cat "$NVM_DIR/alias/default")
        if [[ -n "$default_version" ]] && [[ -d "$NVM_DIR/versions/node/$default_version" ]]; then
            node_version_path="$NVM_DIR/versions/node/$default_version/bin"
            [[ "$ZSH_DEBUG" == "1" ]] && echo "# [nvm-config] Using default version: $default_version" >&2
        fi
    fi

    # Fallback: find the latest installed version
    if [[ -z "${node_version_path:-}" ]] || [[ ! -d "$node_version_path" ]]; then
        local latest_version
        if [[ -d "$NVM_DIR/versions/node" ]]; then
            # Find the highest version number
            latest_version=$(ls -1 "$NVM_DIR/versions/node" | sort -V | tail -1)
            if [[ -n "$latest_version" ]] && [[ -d "$NVM_DIR/versions/node/$latest_version" ]]; then
                node_version_path="$NVM_DIR/versions/node/$latest_version/bin"
                [[ "$ZSH_DEBUG" == "1" ]] && echo "# [nvm-config] Using latest version: $latest_version" >&2
            fi
        fi
    fi

    # Add to PATH if we found a valid node version
    if [[ -n "${node_version_path:-}" ]] && [[ -d "$node_version_path" ]]; then
        # Remove any existing node paths from PATH to avoid duplicates
        PATH=$(echo "$PATH" | sed -E "s|:?[^:]*nvm[^:]*versions[^:]*node[^:]*bin:?||g")
        PATH=$(echo "$PATH" | sed -E "s|^:+||; s|:+$||; s|:+|:|g")
        
        # Add the node version path to the beginning of PATH
        export PATH="$node_version_path:$PATH"
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [nvm-config] Added to PATH: $node_version_path" >&2
        
        # Export additional Node.js environment variables for tool detection
        export NODE_PATH="$node_version_path/../lib/node_modules"
        export NVM_BIN="$node_version_path"
        
        return 0
    else
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [nvm-config] ⚠️  No valid Node.js installation found in NVM" >&2
        return 1
    fi
}

# Set up Node.js PATH immediately after NVM detection
setup_nvm_path

## [nvm.plugin-configuration] - Oh My Zsh NVM Plugin Configuration
# Configure the nvm plugin for optimal performance and features

# Enable lazy loading for the nvm plugin
zstyle ':omz:plugins:nvm' lazy yes

# Define commands that should trigger NVM loading automatically
# This includes common Node.js development tools
zstyle ':omz:plugins:nvm' lazy-cmd \
    node npm npx yarn pnpm \
    eslint prettier typescript tsc \
    vue-cli create-react-app \
    next gatsby nuxt \
    jest vitest cypress \
    webpack vite rollup \
    serverless sls \
    vercel netlify

# Enable automatic .nvmrc file detection and usage
zstyle ':omz:plugins:nvm' autoload yes

# Silent mode for faster loading (reduces startup noise)
zstyle ':omz:plugins:nvm' silent-autoload yes

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [nvm-config] Oh My Zsh NVM plugin styles configured" >&2

## [nvm.performance] - Performance Optimizations
# Additional optimizations for NVM usage

# Cache NVM version detection for faster switching
export NVM_SYMLINK_CURRENT=true

# Set default Node.js version to avoid repeated prompts
# (This will be used if no .nvmrc is found)
export NVM_DEFAULT_VERSION="node"  # Latest stable

# Optimize NVM for CI/CD environments if detected
if [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]] || [[ -n "${GITLAB_CI:-}" ]]; then
    export NVM_LAZY_LOAD=false  # Disable lazy loading in CI
    export NVM_AUTO_USE=false   # Disable auto-use in CI
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [nvm-config] CI environment detected, adjusted NVM settings" >&2
fi

## [nvm.aliases] - Convenient NVM Aliases
# Define helpful aliases for common NVM operations

# Only define aliases if NVM directory exists
if [[ -n "${NVM_DIR:-}" ]] && [[ -d "$NVM_DIR" ]]; then
    # Quick version switching aliases
    alias nvmls='nvm list'
    alias nvmla='nvm list available'
    alias nvmuse='nvm use'
    alias nvminstall='nvm install'
    alias nvmcurrent='nvm current'
    alias nvmdefault='nvm alias default'

    # Node.js project shortcuts
    alias nvmrc='echo "$(nvm current)" > .nvmrc && echo "Created .nvmrc with $(nvm current)"'
    alias nvmauto='nvm use && npm install'  # Switch version and install deps

    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [nvm-config] NVM convenience aliases defined" >&2
fi

## [nvm.validation] - Installation Validation
# Validate NVM setup and provide helpful feedback

validate_nvm_setup() {
    if [[ -z "${NVM_DIR:-}" ]]; then
        echo "# [nvm-config] ⚠️  NVM_DIR not set - NVM may not be available" >&2
        return 1
    fi

    if [[ ! -d "$NVM_DIR" ]]; then
        echo "# [nvm-config] ⚠️  NVM directory not found: $NVM_DIR" >&2
        return 1
    fi

    # Check for NVM script (different locations for different install methods)
    local nvm_script_locations=(
        "$NVM_DIR/nvm.sh"           # Standard installation
        "$NVM_DIR/nvm"              # Some package manager installs
        "$NVM_DIR/bin/nvm"          # Alternative structure
    )

    for script in "${nvm_script_locations[@]}"; do
        if [[ -f "$script" ]]; then
            [[ "$ZSH_DEBUG" == "1" ]] && echo "# [nvm-config] ✅ NVM script found: $script" >&2
            return 0
        fi
    done

    echo "# [nvm-config] ⚠️  NVM script not found in $NVM_DIR" >&2
    return 1
}

# Run validation in debug mode or if explicitly requested
if [[ "$ZSH_DEBUG" == "1" ]] || [[ -n "${NVM_VALIDATE_SETUP:-}" ]]; then
    validate_nvm_setup
fi

## [nvm.integration] - Tool Integration Hints
# Prepare for integration with other development tools

# Set environment variables that other tools may use
export NODE_VERSION_MANAGER="nvm"
export NVM_CONFIGURED="true"

# Export functions for use by other configuration files
{
    typeset -gf detect_nvm_directory validate_nvm_setup setup_nvm_path
} >/dev/null 2>&1

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [nvm-config] NVM pre-plugin configuration completed" >&2

# =============================================================================
# NVM CONFIGURATION STATUS
# =============================================================================
export _NVM_CONFIG_LOADED="true"
export _NVM_CONFIG_VERSION="1.0.0"
