#!/usr/bin/env zsh
# ==============================================================================
# ZSH Configuration: Enhanced Plugin Metadata System
# ==============================================================================
# Purpose: Metadata-driven plugin registry with dependency resolution, conflict
#          detection, and intelligent plugin management for improved reliability
#          and maintainability of the ZSH plugin ecosystem.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-22
# Version: 1.0
# Load Order: 1st in 20-plugins (before plugin loading)
# Dependencies: 01-source-execute-detection.zsh, 00-standard-helpers.zsh
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. SOURCE/EXECUTE DETECTION INTEGRATION
# ------------------------------------------------------------------------------

# Guard against multiple sourcing in non-040-testing environments
if [[ -n "${ZSH_PLUGIN_METADATA_LOADED:-}" && -z "${ZSH_PLUGIN_TESTING:-}" ]]; then
    return 0
fi

# Load source/execute detection system if not already loaded
if [[ -z "${ZSH_SOURCE_EXECUTE_LOADED:-}" ]]; then
    local detection_script="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00_01-source-execute-detection.zsh"
    if [[ -f "$detection_script" ]]; then
        source "$detection_script"
    else
        zsh_debug_echo "WARNING: Source/execute detection system not found: $detection_script"
        zsh_debug_echo "Plugin metadata will work but without context-aware features"
    fi
fi

# Use context-aware logging if detection system is available
if declare -f context_zsh_debug_echo >/dev/null 2>&1; then
    _plugin_log() {
        local msg="$1"
        local level="${2:-INFO}"
        local L=${level:u}
        # Only show WARN/ERROR by default. Show INFO/DEBUG if verbose/debug enabled.
        if [[ "$L" == "ERROR" || "$L" == "WARN" || "$ZSH_STARTUP_VERBOSE" == "true" || "$ZSH_DEBUG" == "1" ]]; then
            context_zsh_debug_echo "$msg" "$L"
        fi
    }
    _plugin_error() {
        local message="$1"
        local exit_code="${2:-1}"
        if declare -f handle_error >/dev/null 2>&1; then
            handle_error "Plugin Metadata: $message" "$exit_code" "plugin"
        else
            zsh_debug_echo "ERROR [plugin]: $message"
            if declare -f is_being_executed >/dev/null 2>&1 && is_being_executed; then
                exit "$exit_code"
            else
                return "$exit_code"
            fi
        fi
    }
else
    # Fallback logging functions
    _plugin_log() {
        local msg="$1"
        local level="${2:-INFO}"
        local L=${level:u}
        if [[ "$L" == "ERROR" || "$L" == "WARN" || "$ZSH_STARTUP_VERBOSE" == "true" || "$ZSH_DEBUG" == "1" ]]; then
            zsh_debug_echo "# [plugin][$L] $msg"
        fi
    }
    _plugin_error() {
        zsh_debug_echo "ERROR [plugin]: $1"
        return "${2:-1}"
    }
fi

## 1. Global Configuration and Plugin Registry Setup
#=============================================================================

[[ "$ZSH_DEBUG" == "1" ]] && {
        zsh_debug_echo "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
    _plugin_log "Loading enhanced plugin metadata system v1.0"
}

# 1.1. Set global plugin metadata version for tracking
export ZSH_PLUGIN_METADATA_VERSION="1.0.0"
export ZSH_PLUGIN_METADATA_LOADED="$(command -v date >/dev/null && date -u '+    %FT%T %Z' || zsh_debug_echo 'loaded')"

# 1.2. Plugin registry configuration
export ZSH_PLUGIN_REGISTRY_DIR="${ZDOTDIR:-$HOME/.config/zsh}/.plugin-registry"
export ZSH_PLUGIN_METADATA_FILE="$ZSH_PLUGIN_REGISTRY_DIR/plugin-metadata.json"
export ZSH_PLUGIN_DEPENDENCY_CACHE="$ZSH_PLUGIN_REGISTRY_DIR/dependency-cache.zsh"

# Create plugin registry directory
mkdir -p "$ZSH_PLUGIN_REGISTRY_DIR" 2>/dev/null || true

# 1.3. Plugin management configuration
export ZSH_PLUGIN_STRICT_DEPENDENCIES="${ZSH_PLUGIN_STRICT_DEPENDENCIES:-false}"
export ZSH_PLUGIN_AUTO_RESOLVE="${ZSH_PLUGIN_AUTO_RESOLVE:-true}"
export ZSH_PLUGIN_CONFLICT_RESOLUTION="${ZSH_PLUGIN_CONFLICT_RESOLUTION:-warn}"

## 2. Plugin Metadata Registry
#=============================================================================

# 2.1. Initialize plugin metadata registry
_init_plugin_registry() {
    _plugin_log "Initializing plugin metadata registry..."

    # Create metadata file if it doesn't exist
    if [[ ! -f "$ZSH_PLUGIN_METADATA_FILE" ]]; then
        cat > "$ZSH_PLUGIN_METADATA_FILE" << 'EOF'
{
  "registry_version": "1.0.0",
  "last_updated": "",
  "plugins": {}
}
EOF
        _plugin_log "Created new plugin metadata registry: $ZSH_PLUGIN_METADATA_FILE"
    fi

    # Initialize dependency cache
    if [[ ! -f "$ZSH_PLUGIN_DEPENDENCY_CACHE" ]]; then
        cat > "$ZSH_PLUGIN_DEPENDENCY_CACHE" << 'EOF'
#!/opt/homebrew/bin/zsh
# Plugin Dependency Cache - Auto-generated
# Do not edit manually

# Plugin dependency resolution cache
typeset -A ZSH_PLUGIN_DEPENDENCIES
typeset -A ZSH_PLUGIN_CONFLICTS
typeset -A ZSH_PLUGIN_LOAD_ORDER

EOF
        _plugin_log "Created plugin dependency cache: $ZSH_PLUGIN_DEPENDENCY_CACHE"
    fi
}

# 2.2. Register plugin metadata
register_plugin() {
    local plugin_name="$1"
    local plugin_source="$2"
    local plugin_type="${3:-oh-my-zsh}"
    local dependencies="${4:-}"
    local conflicts="${5:-}"
    local description="${6:-}"

    _plugin_log "Registering plugin: $plugin_name (type: $plugin_type)"

    # Validate required parameters
    if [[ -z "$plugin_name" || -z "$plugin_source" ]]; then
        _plugin_error "Plugin registration requires name and source"
        return 1
    fi

    # Create plugin metadata entry (with command availability checks)
    local deps_json=""
    local conflicts_json=""
    local timestamp=""

    if command -v sed >/dev/null 2>&1; then
        deps_json=$(zsh_debug_echo "$dependencies" | sed 's/,/", "/g' | sed 's/^/"/' | sed 's/$/"/')
        conflicts_json=$(zsh_debug_echo "$conflicts" | sed 's/,/", "/g' | sed 's/^/"/' | sed 's/$/"/')
    else
        deps_json="\"$dependencies\""
        conflicts_json="\"$conflicts\""
    fi

    if command -v date >/dev/null 2>&1; then
        timestamp=$(date -u '+    %FT%T %Z')
    else
        timestamp="unknown"
    fi

    local plugin_metadata="{\"name\":\"$plugin_name\",\"source\":\"$plugin_source\",\"type\":\"$plugin_type\",\"dependencies\":[$deps_json],\"conflicts\":[$conflicts_json],\"description\":\"$description\",\"registered_at\":\"$timestamp\",\"status\":\"registered\"}"

    # Store in global registry (simplified for this implementation)
    if [[ -z "${ZSH_PLUGIN_REGISTRY:-}" ]]; then
        typeset -gA ZSH_PLUGIN_REGISTRY
    fi

    ZSH_PLUGIN_REGISTRY[$plugin_name]="$plugin_metadata"

    _plugin_log "Plugin $plugin_name registered successfully"
    return 0
}

# 2.3. Get plugin metadata
get_plugin_metadata() {
    local plugin_name="$1"

    if [[ -n "${ZSH_PLUGIN_REGISTRY[$plugin_name]:-}" ]]; then
        zsh_debug_echo "${ZSH_PLUGIN_REGISTRY[$plugin_name]}"
        return 0
    else
        _plugin_log "Plugin metadata not found: $plugin_name" "WARN"
        return 1
    fi
}

## 3. Dependency Resolution System
#=============================================================================

# 3.1. Check plugin dependencies
check_plugin_dependencies() {
    local plugin_name="$1"
    local missing_deps=()

    _plugin_log "Checking dependencies for plugin: $plugin_name"

    # Get plugin metadata
    local metadata=$(get_plugin_metadata "$plugin_name")
    if [[ -z "$metadata" ]]; then
        _plugin_log "Cannot check dependencies - plugin not registered: $plugin_name" "WARN"
        return 1
    fi

    # Extract dependencies (simplified JSON parsing)
    local dependencies=$(zsh_debug_echo "$metadata" | grep '"dependencies"' | sed 's/.*"dependencies": \[\(.*\)\].*/\1/' | tr -d '"' | tr ',' ' ')

    if [[ -n "$dependencies" ]]; then
        for dep in ${=dependencies}; do
            if [[ -z "${ZSH_PLUGIN_REGISTRY[$dep]:-}" ]]; then
                missing_deps+=("$dep")
            fi
        done
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        _plugin_log "Missing dependencies for $plugin_name: ${missing_deps[*]}" "WARN"

        if [[ "$ZSH_PLUGIN_STRICT_DEPENDENCIES" == "true" ]]; then
            if [[ -n "${ZSH_PLUGIN_TESTING:-}" ]]; then
                _plugin_log "Strict dependency mode: Cannot load $plugin_name without dependencies: ${missing_deps[*]}" "ERROR"
                return 1
            else
                _plugin_error "Strict dependency mode: Cannot load $plugin_name without dependencies: ${missing_deps[*]}"
                return 1
            fi
        fi

        return 2  # Dependencies missing but not strict
    else
        _plugin_log "All dependencies satisfied for plugin: $plugin_name"
        return 0
    fi
}

# 3.2. Check plugin conflicts
check_plugin_conflicts() {
    local plugin_name="$1"
    local conflicting_plugins=()

    _plugin_log "Checking conflicts for plugin: $plugin_name"

    # Get plugin metadata
    local metadata=$(get_plugin_metadata "$plugin_name")
    if [[ -z "$metadata" ]]; then
        return 0  # No conflicts if not registered
    fi

    # Extract conflicts (simplified JSON parsing)
    local conflicts=$(zsh_debug_echo "$metadata" | grep '"conflicts"' | sed 's/.*"conflicts": \[\(.*\)\].*/\1/' | tr -d '"' | tr ',' ' ')

    if [[ -n "$conflicts" ]]; then
        for conflict in ${=conflicts}; do
            if [[ -n "${ZSH_PLUGIN_REGISTRY[$conflict]:-}" ]]; then
                conflicting_plugins+=("$conflict")
            fi
        done
    fi

    if [[ ${#conflicting_plugins[@]} -gt 0 ]]; then
        _plugin_log "Plugin conflicts detected for $plugin_name: ${conflicting_plugins[*]}" "WARN"

        case "$ZSH_PLUGIN_CONFLICT_RESOLUTION" in
            "error")
                if [[ -n "${ZSH_PLUGIN_TESTING:-}" ]]; then
                    _plugin_log "Plugin conflict: $plugin_name conflicts with: ${conflicting_plugins[*]}" "ERROR"
                    return 1
                else
                    _plugin_error "Plugin conflict: $plugin_name conflicts with: ${conflicting_plugins[*]}"
                    return 1
                fi
                ;;
            "warn")
                _plugin_log "WARNING: Plugin $plugin_name may conflict with: ${conflicting_plugins[*]}" "WARN"
                return 2
                ;;
            "ignore")
                _plugin_log "Ignoring conflicts for plugin: $plugin_name"
                return 0
                ;;
        esac
    else
        _plugin_log "No conflicts detected for plugin: $plugin_name"
        return 0
    fi
}

# 3.3. Resolve plugin load order
resolve_plugin_load_order() {
    local -a plugins=("$@")
    local -a resolved_order=()
    local -a processing=()

    _plugin_log "Resolving load order for plugins: ${plugins[*]}"

    # Simple topological sort for dependency resolution
    for plugin in "${plugins[@]}"; do
        _resolve_plugin_recursive "$plugin"
    done

    zsh_debug_echo "${resolved_order[*]}"
}

_resolve_plugin_recursive() {
    local plugin="$1"

    # Check if already resolved
    if [[ " ${resolved_order[*]} " == *" $plugin "* ]]; then
        return 0
    fi

    # Check for circular dependencies
    if [[ " ${processing[*]} " == *" $plugin "* ]]; then
        _plugin_log "Circular dependency detected involving: $plugin" "WARN"
        return 1
    fi

    # Mark as processing
    processing+=("$plugin")

    # Get dependencies
    local metadata=$(get_plugin_metadata "$plugin")
    if [[ -n "$metadata" ]]; then
        local dependencies=$(zsh_debug_echo "$metadata" | grep '"dependencies"' | sed 's/.*"dependencies": \[\(.*\)\].*/\1/' | tr -d '"' | tr ',' ' ')

        # Resolve dependencies first
        for dep in ${=dependencies}; do
            if [[ -n "$dep" ]]; then
                _resolve_plugin_recursive "$dep"
            fi
        done
    fi

    # Add to resolved order
    resolved_order+=("$plugin")

    # Remove from processing (ZSH array filtering)
    processing=(${processing[@]/$plugin})
}

## 4. Plugin Management Functions
#=============================================================================

# 4.1. Enhanced plugin loading with metadata
load_plugin_with_metadata() {
    local plugin_name="$1"
    local plugin_source="$2"
    local plugin_type="${3:-oh-my-zsh}"

    _plugin_log "Loading plugin with metadata: $plugin_name"

    # Check dependencies
    if ! check_plugin_dependencies "$plugin_name"; then
        local dep_result=$?
        if [[ $dep_result -eq 1 ]]; then
            return 1  # Strict mode failure
        fi
        # Continue with warnings in non-strict mode
    fi

    # Check conflicts
    if ! check_plugin_conflicts "$plugin_name"; then
        local conflict_result=$?
        if [[ $conflict_result -eq 1 ]]; then
            return 1  # Error mode failure
        fi
        # Continue with warnings or ignore
    fi

    # Load the plugin based on type
    case "$plugin_type" in
        "oh-my-zsh")
            if command -v zgenom >/dev/null 2>&1; then
                zgenom oh-my-zsh "$plugin_source"
                _plugin_log "Loaded Oh My Zsh plugin: $plugin_name"
            else
                _plugin_log "zgenom not available for Oh My Zsh plugin: $plugin_name" "WARN"
                return 1
            fi
            ;;
        "github")
            if command -v zgenom >/dev/null 2>&1; then
                zgenom load "$plugin_source"
                _plugin_log "Loaded GitHub plugin: $plugin_name"
            else
                _plugin_log "zgenom not available for GitHub plugin: $plugin_name" "WARN"
                return 1
            fi
            ;;
        "local")
            if [[ -f "$plugin_source" ]]; then
                source "$plugin_source"
                _plugin_log "Loaded local plugin: $plugin_name"
            else
                _plugin_error "Local plugin file not found: $plugin_source"
                return 1
            fi
            ;;
        *)
            _plugin_error "Unknown plugin type: $plugin_type"
            return 1
            ;;
    esac

    return 0
}

# 4.2. List registered plugins
list_plugins() {
    local format="${1:-simple}"

    _plugin_log "Listing registered plugins (format: $format)"

    if [[ -z "${ZSH_PLUGIN_REGISTRY:-}" ]]; then
        zsh_debug_echo "No plugins registered"
        return 0
    fi

    case "$format" in
        "simple")
            for plugin in "${(@k)ZSH_PLUGIN_REGISTRY}"; do
                zsh_debug_echo "$plugin"
            done
            ;;
        "detailed")
            for plugin in "${(@k)ZSH_PLUGIN_REGISTRY}"; do
                zsh_debug_echo "Plugin: $plugin"
                zsh_debug_echo "${ZSH_PLUGIN_REGISTRY[$plugin]}" | sed 's/^/  /'
                zsh_debug_echo ""
            done
            ;;
        "json")
            zsh_debug_echo "{"
            local first=true
            for plugin in "${(@k)ZSH_PLUGIN_REGISTRY}"; do
                if [[ "$first" == "true" ]]; then
                    first=false
                else
                    zsh_debug_echo ","
                fi
                zsh_debug_echo "  \"$plugin\": ${ZSH_PLUGIN_REGISTRY[$plugin]}"
            done
            zsh_debug_echo "}"
            ;;
    esac
}

## 5. Initialization and Default Plugin Registration
#=============================================================================

# 5.1. Initialize the plugin metadata system
_init_plugin_registry

# 5.2. Register common Oh My Zsh plugins with metadata
if [[ "$ZSH_PLUGIN_AUTO_REGISTER" != "false" ]]; then
    _plugin_log "Auto-registering common plugins..."

    # Core plugins
    register_plugin "git" "plugins/git" "oh-my-zsh" "" "" "Git integration and aliases"
    register_plugin "history" "plugins/history" "oh-my-zsh" "" "" "Enhanced history management"
    register_plugin "colored-man-pages" "plugins/colored-man-pages" "oh-my-zsh" "" "" "Colorized man pages"

    # Development tools
    register_plugin "nvm" "plugins/nvm" "oh-my-zsh" "" "npm" "Node Version Manager integration"
    register_plugin "npm" "plugins/npm" "oh-my-zsh" "" "nvm" "NPM integration and aliases"
    register_plugin "docker" "plugins/docker" "oh-my-zsh" "" "" "Docker integration and completion"

    # Enhanced plugins
    register_plugin "zsh-syntax-highlighting" "zsh-users/zsh-syntax-highlighting" "github" "" "" "Syntax highlighting for ZSH"
    register_plugin "zsh-autosuggestions" "zsh-users/zsh-autosuggestions" "github" "" "" "Fish-like autosuggestions"
    register_plugin "zsh-history-substring-search" "zsh-users/zsh-history-substring-search" "github" "zsh-syntax-highlighting" "" "History substring search"
fi

[[ "$ZSH_DEBUG" == "1" ]] && _plugin_log "✅ Enhanced plugin metadata system loaded successfully"

# ------------------------------------------------------------------------------
# 6. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

# Main function for when script is executed directly
_plugin_metadata_main() {
    zsh_debug_echo "========================================================"
    zsh_debug_echo "ZSH Enhanced Plugin Metadata System"
    zsh_debug_echo "========================================================"
    zsh_debug_echo "Version: $ZSH_PLUGIN_METADATA_VERSION"
    zsh_debug_echo "Loaded: $ZSH_PLUGIN_METADATA_LOADED"
    zsh_debug_echo ""

    if declare -f get_execution_context >/dev/null 2>&1; then
        zsh_debug_echo "Execution Context: $(get_execution_context)"
        zsh_debug_echo ""
    fi

    zsh_debug_echo "Plugin Registry: $ZSH_PLUGIN_REGISTRY_DIR"
    zsh_debug_echo "Registered Plugins:"
    list_plugins "simple"

    if declare -f safe_exit >/dev/null 2>&1; then
        safe_exit 0
    else
        exit 0
    fi
}

# Use context-aware execution if detection system is available
if declare -f is_being_executed >/dev/null 2>&1; then
    if is_being_executed; then
        main "$@"
    fi
elif [[ "${(%):-%N}" == "$0" ]] || [[ "${(%):-%N}" == *"plugin-metadata"* ]]; then
    # Fallback detection for direct execution
    main "$@"
fi

# ==============================================================================
# END: Enhanced Plugin Metadata System
# ==============================================================================
