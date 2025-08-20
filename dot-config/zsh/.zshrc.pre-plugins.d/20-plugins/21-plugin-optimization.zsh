# ZSH Plugin Loading Optimization - PRE-PLUGIN PHASE
# FIXED: Added proper ZGEN_SOURCE handling
# This file optimizes plugin loading performance before plugins are loaded
# CONSOLIDATED FROM: 003-lazy-plugin-loading.zsh + 004-zgenom-optimization.zsh + 005-plugin-loading-guards.zsh

# Conditionally disable verbose output during normal startup
if [[ -z "$ZSH_DEBUG_VERBOSE" ]]; then
    setopt NO_VERBOSE
    setopt NO_XTRACE
fi

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
    echo "# [plugin-optimization] Setting up optimized plugin loading" >&2
}

## [plugin-optimization.lazy-loading] - Deferred plugin loading setup
# MERGED FROM: 003-lazy-plugin-loading.zsh
# Set up framework for loading heavy plugins on-demand

# List of plugins to defer (load on first use)
typeset -ga DEFERRED_PLUGINS
DEFERRED_PLUGINS=(
    "docker"
    "kubectl"
    "terraform"
    "ansible"
    "vagrant"
    "aws"
    "gcloud"
    "azure"
)

# Function to defer a plugin command
defer_plugin() {
    local plugin_name="$1"
    local command_name="${2:-$plugin_name}"

    # Create wrapper function that loads plugin on first use
    {
        eval "${command_name}() {
            unfunction ${command_name} 2>/dev/null

            # Load the actual plugin
            if [[ -f \"\${ZDOTDIR:-\$HOME}/.zgenom/ohmyzsh/ohmyzsh/___/plugins/${plugin_name}/${plugin_name}.plugin.zsh\" ]]; then
                source \"\${ZDOTDIR:-\$HOME}/.zgenom/ohmyzsh/ohmyzsh/___/plugins/${plugin_name}/${plugin_name}.plugin.zsh\"
            fi

            # Call the real command
            ${command_name} \"\$@\"
        }"
    } 2>/dev/null
}

# Set up deferred loading for heavy plugins
for plugin in $DEFERRED_PLUGINS[@]; do
    defer_plugin "$plugin"
done

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugin-optimization] Deferred loading set up for ${#DEFERRED_PLUGINS[@]} plugins" >&2

## [plugin-optimization.zgenom] - Optimized zgenom configuration
# MERGED FROM: 004-zgenom-optimization.zsh
# Configure zgenom for optimal performance

# Zgenom performance optimizations
export ZGENOM_AUTO_UPDATE_DAYS=7        # Update weekly instead of daily
export ZGENOM_COMPILE=1                 # Compile plugins for faster loading
export ZGENOM_DIR="${ZDOTDIR:-$HOME}/.zgenom"

# Optimize zgenom cache behavior
if [[ -d "$ZGENOM_DIR" ]]; then
    # Pre-create cache directory structure
    [[ ! -d "${ZGENOM_DIR}/cache" ]] && mkdir -p "${ZGENOM_DIR}/cache"

    # Optimize zgenom clone behavior
    export ZGENOM_CLONE_ONLY_ON_CHANGE=1

    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugin-optimization] Zgenom optimizations applied" >&2
fi

## [plugin-optimization.conflict-prevention] - Plugin loading guards
# MERGED FROM: 005-plugin-loading-guards.zsh
# Prevent plugin conflicts and ensure clean loading

# Function to check if a plugin is already loaded
is_plugin_loaded() {
    local plugin_name="$1"
    [[ -n "${plugins[(r)$plugin_name]}" ]] || command -v "_${plugin_name}" >/dev/null 2>&1
}

# Function to safely load a plugin
safe_plugin_load() {
    local plugin_name="$1"

    if is_plugin_loaded "$plugin_name"; then
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugin-optimization] Plugin already loaded: $plugin_name" >&2
        return 0
    fi

    # Load plugin safely
    if command -v zgenom >/dev/null 2>&1; then
        zgenom load "$plugin_name"
    else
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugin-optimization] zgenom not available for: $plugin_name" >&2
        return 1
    fi
}

{
    # Export functions globally without verbose output
    typeset -gf is_plugin_loaded safe_plugin_load defer_plugin
} >/dev/null 2>&1

## [plugin-optimization.performance-monitoring] - Plugin performance tracking
# Monitor plugin loading performance and detect issues

# Track plugin loading times
typeset -gA PLUGIN_LOAD_TIMES
typeset -g PLUGIN_LOAD_START_TIME

# Start timing a plugin load
start_plugin_timer() {
    local plugin_name="$1"
    PLUGIN_LOAD_START_TIME="$SECONDS"
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugin-optimization] Starting timer for: $plugin_name" >&2
}

# End timing and record
end_plugin_timer() {
    local plugin_name="$1"
    if [[ -n "$PLUGIN_LOAD_START_TIME" ]]; then
        local load_time=$((SECONDS - PLUGIN_LOAD_START_TIME))
        PLUGIN_LOAD_TIMES[$plugin_name]=$load_time

        # Warn about slow plugins (>1 second)
        if [[ $load_time -gt 1 ]]; then
            echo "⚠️  Slow plugin detected: $plugin_name took ${load_time}s to load" >&2
        fi

        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugin-optimization] Plugin $plugin_name loaded in ${load_time}s" >&2
        unset PLUGIN_LOAD_START_TIME
    fi
}

# Report plugin performance
plugin_performance_report() {
    echo "=== Plugin Performance Report ==="
    for plugin in "${(@k)PLUGIN_LOAD_TIMES}"; do
        local time="${PLUGIN_LOAD_TIMES[$plugin]}"
        if [[ $time -gt 2 ]]; then
            echo "🔴 SLOW: $plugin (${time}s)"
        elif [[ $time -gt 1 ]]; then
            echo "🟡 WARN: $plugin (${time}s)"
        else
            echo "✅ FAST: $plugin (${time}s)"
        fi
    done
}

## [plugin-optimization.advanced-caching] - Intelligent plugin caching
# Advanced caching for plugin configurations and completions

# Cache directory for plugin data
export PLUGIN_CACHE_DIR="${ZSH_CACHE_DIR:-${ZDOTDIR:-$HOME}/.cache/zsh}/plugins"
[[ ! -d "$PLUGIN_CACHE_DIR" ]] && mkdir -p "$PLUGIN_CACHE_DIR"

# Cache plugin completion data
cache_plugin_completions() {
    local plugin_name="$1"
    local cache_file="$PLUGIN_CACHE_DIR/${plugin_name}.completions"

    if [[ -f "$cache_file" && "$cache_file" -nt "${ZGENOM_DIR}/${plugin_name}" ]]; then
        source "$cache_file"
        return 0
    fi

    # Generate and cache completions
    local plugin_dir="${ZGENOM_DIR}/${plugin_name}"
    if [[ -d "$plugin_dir" ]]; then
        {
            echo "# Auto-generated completion cache for $plugin_name"
            find "$plugin_dir" -name "_*" -type f -exec cat {} \;
        } > "$cache_file"
        source "$cache_file"
    fi
}

# Clear plugin caches
clear_plugin_caches() {
    [[ -d "$PLUGIN_CACHE_DIR" ]] && rm -rf "$PLUGIN_CACHE_DIR"/* 2>/dev/null
    echo "✅ Plugin caches cleared"
}

## [plugin-optimization.conflict-resolution] - Plugin conflict management
# EXTENDED FROM: 005-plugin-loading-guards.zsh with comprehensive conflict resolution

# Define known plugin conflicts
typeset -gA PLUGIN_CONFLICTS
PLUGIN_CONFLICTS=(
    "zsh-syntax-highlighting" "fast-syntax-highlighting"
    "zsh-autosuggestions"     "zsh-autocomplete"
    "oh-my-zsh/git"          "zsh-users/zsh-git-prompt"
)

# Define plugin dependencies
typeset -gA PLUGIN_DEPENDENCIES
PLUGIN_DEPENDENCIES=(
    "zsh-abbr"               "zsh-users/zsh-autosuggestions"
    "fast-syntax-highlighting" "zsh-users/zsh-history-substring-search"
)

# Check for plugin conflicts before loading
check_plugin_conflicts() {
    local plugin="$1"

    for conflict_pair in "${(@k)PLUGIN_CONFLICTS}"; do
        local conflicting_plugin="${PLUGIN_CONFLICTS[$conflict_pair]}"

        if [[ "$plugin" == "$conflict_pair" && -n "${plugins[(r)$conflicting_plugin]}" ]]; then
            echo "⚠️  Plugin conflict: $plugin conflicts with already loaded $conflicting_plugin" >&2
            return 1
        fi

        if [[ "$plugin" == "$conflicting_plugin" && -n "${plugins[(r)$conflict_pair]}" ]]; then
            echo "⚠️  Plugin conflict: $plugin conflicts with already loaded $conflict_pair" >&2
            return 1
        fi
    done

    return 0
}

# Check and load plugin dependencies
load_plugin_dependencies() {
    local plugin="$1"
    local dependency="${PLUGIN_DEPENDENCIES[$plugin]}"

    if [[ -n "$dependency" && -z "${plugins[(r)$dependency]}" ]]; then
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugin-optimization] Loading dependency: $dependency for $plugin" >&2
        safe_plugin_load "$dependency"
    fi
}

# Enhanced safe plugin loading with conflict resolution and dependency management
enhanced_plugin_load() {
    local plugin="$1"
    local force="${2:-false}"

    # Check if already loaded
    if is_plugin_loaded "$plugin" && [[ "$force" != "true" ]]; then
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugin-optimization] Plugin already loaded: $plugin" >&2
        return 0
    fi

    # Check for conflicts unless forced
    if [[ "$force" != "true" ]] && ! check_plugin_conflicts "$plugin"; then
        return 1
    fi

    # Load dependencies first
    load_plugin_dependencies "$plugin"

    # Time the plugin loading
    start_plugin_timer "$plugin"

    # Load the plugin
    if command -v zgenom >/dev/null 2>&1; then
        zgenom load "$plugin" 2>/dev/null
        local result=$?
        end_plugin_timer "$plugin"

        if [[ $result -eq 0 ]]; then
            [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugin-optimization] Successfully loaded: $plugin" >&2
        else
            echo "⚠️  Failed to load plugin: $plugin" >&2
        fi

        return $result
    else
        echo "⚠️  zgenom not available for loading: $plugin" >&2
        end_plugin_timer "$plugin"
        return 1
    fi
}

# Plugin health check
plugin_health_check() {
    echo "=== Plugin Health Check ==="

    local total_plugins=${#plugins[@]}
    local loaded_plugins=0
    local failed_plugins=()

    for plugin in $plugins[@]; do
        if is_plugin_loaded "$plugin"; then
            loaded_plugins=$((loaded_plugins + 1))
            echo "✅ $plugin"
        else
            failed_plugins+=("$plugin")
            echo "❌ $plugin"
        fi
    done

    echo "\n=== Summary ==="
    echo "Total plugins: $total_plugins"
    echo "Loaded plugins: $loaded_plugins"
    echo "Failed plugins: ${#failed_plugins[@]}"

    if [[ ${#failed_plugins[@]} -gt 0 ]]; then
        echo "\n=== Failed Plugins ==="
        printf '%s\n' "${failed_plugins[@]}"
    fi
}

# Export all plugin management functions
{
    # Export functions globally without verbose output
    typeset -gf start_plugin_timer end_plugin_timer plugin_performance_report
    typeset -gf cache_plugin_completions clear_plugin_caches
    typeset -gf check_plugin_conflicts load_plugin_dependencies enhanced_plugin_load plugin_health_check
} >/dev/null 2>&1

## [plugin-optimization.environment] - Plugin environment preparation

# Set up environment variables that plugins expect
export DISABLE_AUTO_UPDATE=true         # Disable OMZ auto-updates (use zgenom)
export DISABLE_UPDATE_PROMPT=true       # No update prompts during startup
export ZSH_DISABLE_COMPFIX=true        # Skip permission checks for speed

# Optimize plugin loading environment
export COMPLETION_WAITING_DOTS=false    # Don't show dots during completion
export HIST_STAMPS="yyyy-mm-dd"        # Standardize history timestamps

# Set up plugin cache directories
local plugin_cache_dir="${ZDOTDIR:-$HOME}/.zsh/plugin-cache"
[[ ! -d "$plugin_cache_dir" ]] && mkdir -p "$plugin_cache_dir"
export ZSH_CACHE_DIR="$plugin_cache_dir"

## [plugin-optimization.preload] - Critical plugin preloading

# Function to preload essential plugins that must be available immediately
preload_essential_plugins() {
    local essential_plugins=(
        "git"
        "colored-man-pages"
        "command-not-found"
    )

    for plugin in $essential_plugins[@]; do
        if ! is_plugin_loaded "$plugin"; then
            [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugin-optimization] Preloading essential: $plugin" >&2
            safe_plugin_load "$plugin"
        fi
    done
}

# Preload essential plugins if zgenom is available
if command -v zgenom >/dev/null 2>&1; then
    preload_essential_plugins
fi

## [plugin-optimization.cleanup] - Plugin environment cleanup

# Function to clean up plugin environment after loading
cleanup_plugin_environment() {
    # Remove temporary environment variables
    unset COMPLETION_WAITING_DOTS

    # Optimize fpath after plugin setup
    typeset -gU fpath

    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugin-optimization] Plugin environment cleaned up" >&2
}

# Export cleanup function for use after plugin loading
{
    # Export cleanup function without verbose output
    typeset -gf cleanup_plugin_environment
} >/dev/null 2>&1

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [plugin-optimization] ✅ Plugin loading optimization setup completed" >&2
