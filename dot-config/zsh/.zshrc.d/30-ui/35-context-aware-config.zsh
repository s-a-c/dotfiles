#!/opt/homebrew/bin/zsh
# ==============================================================================
# ZSH Configuration: Context-Aware Dynamic Configuration System
# ==============================================================================
# Purpose: Directory-sensitive configuration adaptation that automatically
#          loads and unloads configuration based on the current working
#          directory context, enabling project-specific settings, tools,
#          and environment variables with intelligent caching and performance.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-22
# Version: 1.0
# Load Order: 35th in 30-ui (after aliases, before final UI components)
# Dependencies: 01-source-execute-detection.zsh, 00-standard-helpers.zsh
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. SOURCE/EXECUTE DETECTION INTEGRATION
# ------------------------------------------------------------------------------

# Guard against multiple sourcing in non-testing environments
if [[ -n "${ZSH_CONTEXT_AWARE_LOADED:-}" && -z "${ZSH_CONTEXT_TESTING:-}" ]]; then
    return 0
fi

# Load source/execute detection system if not already loaded
if [[ -z "${ZSH_SOURCE_EXECUTE_LOADED:-}" ]]; then
    local detection_script="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00-core/01-source-execute-detection.zsh"
    if [[ -f "$detection_script" ]]; then
        source "$detection_script"
    else
        echo "WARNING: Source/execute detection system not found: $detection_script" >&2
        echo "Context-aware config will work but without context-aware features" >&2
    fi
fi

# Use context-aware logging if detection system is available
if declare -f context_echo >/dev/null 2>&1; then
    _context_log() {
        local msg="$1"
        local level="${2:-INFO}"
        local L=${level:u}
        # Only show WARN/ERROR by default. Show INFO/DEBUG if verbose/debug enabled.
        if [[ "$L" == "ERROR" || "$L" == "WARN" || "$ZSH_STARTUP_VERBOSE" == "true" || "$ZSH_DEBUG" == "1" ]]; then
            context_echo "$msg" "$L"
        fi
    }
    _context_error() {
        local message="$1"
        local exit_code="${2:-1}"
        if declare -f handle_error >/dev/null 2>&1; then
            handle_error "Context Config: $message" "$exit_code" "context"
        else
            echo "ERROR [context]: $message" >&2
            if declare -f is_being_executed >/dev/null 2>&1 && is_being_executed; then
                exit "$exit_code"
            else
                return "$exit_code"
            fi
        fi
    }
else
    # Fallback logging functions
    _context_log() {
        local msg="$1"
        local level="${2:-INFO}"
        local L=${level:u}
        if [[ "$L" == "ERROR" || "$L" == "WARN" || "$ZSH_STARTUP_VERBOSE" == "true" || "$ZSH_DEBUG" == "1" ]]; then
            echo "# [context][$L] $msg" >&2
        fi
    }
    _context_error() {
        echo "ERROR [context]: $1" >&2
        return "${2:-1}"
    }
fi

## 1. Global Configuration and Context Setup
#=============================================================================

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
    _context_log "Loading context-aware dynamic configuration system v1.0"
}

# 1.1. Set global context version for tracking
export ZSH_CONTEXT_AWARE_VERSION="1.0.0"
export ZSH_CONTEXT_AWARE_LOADED="$(command -v date >/dev/null && date -u '+%Y-%m-%d %H:%M:%S UTC' || echo 'loaded')"

# 1.2. Context configuration
export ZSH_CONTEXT_CONFIG_DIR="${ZDOTDIR:-$HOME/.config/zsh}/.context-configs"
export ZSH_CONTEXT_CACHE_DIR="${ZDOTDIR:-$HOME/.config/zsh}/.context-cache"
export ZSH_CONTEXT_CURRENT_FILE="$ZSH_CONTEXT_CACHE_DIR/current-context"

# Create context directories
mkdir -p "$ZSH_CONTEXT_CONFIG_DIR" "$ZSH_CONTEXT_CACHE_DIR" 2>/dev/null || true

# 1.3. Context management configuration
export ZSH_CONTEXT_ENABLE="${ZSH_CONTEXT_ENABLE:-true}"
export ZSH_CONTEXT_CACHE_ENABLE="${ZSH_CONTEXT_CACHE_ENABLE:-true}"
export ZSH_CONTEXT_DEBUG="${ZSH_CONTEXT_DEBUG:-false}"

# 1.4. Context state tracking
typeset -gA ZSH_CONTEXT_LOADED_CONFIGS
typeset -gA ZSH_CONTEXT_ACTIVE_VARS
typeset -g ZSH_CONTEXT_CURRENT_DIR=""
typeset -g ZSH_CONTEXT_PREVIOUS_DIR=""

## 2. Context Detection and Classification
#=============================================================================

# 2.1. Detect directory context type
_detect_directory_context() {
    local dir="${1:-$PWD}"
    local context_types=()

    [[ "$ZSH_CONTEXT_DEBUG" == "true" ]] && _context_log "Detecting context for directory: $dir" "DEBUG"

    # Git repository detection
    if [[ -d "$dir/.git" ]] || git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
        context_types+=("git")

        # Specific project types within git repos
        if [[ -f "$dir/package.json" ]]; then
            context_types+=("nodejs")
        fi
        if [[ -f "$dir/Cargo.toml" ]]; then
            context_types+=("rust")
        fi
        if [[ -f "$dir/go.mod" ]]; then
            context_types+=("golang")
        fi
        if [[ -f "$dir/requirements.txt" ]] || [[ -f "$dir/pyproject.toml" ]] || [[ -f "$dir/setup.py" ]]; then
            context_types+=("python")
        fi
        if [[ -f "$dir/Dockerfile" ]]; then
            context_types+=("docker")
        fi
    fi

    # Home directory
    if [[ "$dir" == "$HOME" ]]; then
        context_types+=("home")
    fi

    # Dotfiles directory
    if [[ "$dir" == *"dotfiles"* ]] || [[ -f "$dir/.dotfiles" ]]; then
        context_types+=("dotfiles")
    fi

    # Work/Projects directory patterns
    if [[ "$dir" == *"/work/"* ]] || [[ "$dir" == *"/projects/"* ]] || [[ "$dir" == *"/dev/"* ]]; then
        context_types+=("work")
    fi

    # Temporary directories
    if [[ "$dir" == "/tmp"* ]] || [[ "$dir" == *"/temp/"* ]]; then
        context_types+=("temp")
    fi

    # Default context if no specific type detected
    if [[ ${#context_types[@]} -eq 0 ]]; then
        context_types+=("default")
    fi

    echo "${context_types[*]}"
}

# 2.2. Find applicable context configurations
_find_context_configs() {
    local dir="$1"
    local context_types=($(_detect_directory_context "$dir"))
    local config_files=()

    [[ "$ZSH_CONTEXT_DEBUG" == "true" ]] && _context_log "Finding configs for contexts: ${context_types[*]}" "DEBUG"

    # Look for context-specific configuration files
    for context_type in "${context_types[@]}"; do
        local config_file="$ZSH_CONTEXT_CONFIG_DIR/${context_type}.zsh"
        if [[ -f "$config_file" ]]; then
            config_files+=("$config_file")
            [[ "$ZSH_CONTEXT_DEBUG" == "true" ]] && _context_log "Found config for $context_type: $config_file" "DEBUG"
        fi
    done

    # Look for directory-specific configuration
    local dir_config="$dir/.zshrc.local"
    if [[ -f "$dir_config" ]]; then
        config_files+=("$dir_config")
        [[ "$ZSH_CONTEXT_DEBUG" == "true" ]] && _context_log "Found directory-specific config: $dir_config" "DEBUG"
    fi

    echo "${config_files[*]}"
}

## 3. Configuration Loading and Management
#=============================================================================

# 3.1. Load context configuration
_load_context_config() {
    local config_file="$1"
    local context_id="$2"

    _context_log "Loading context config: $config_file (ID: $context_id)"

    if [[ ! -f "$config_file" ]]; then
        _context_log "Context config file not found: $config_file" "WARN"
        return 1
    fi

    # Check if already loaded
    if [[ -n "${ZSH_CONTEXT_LOADED_CONFIGS[$context_id]:-}" ]]; then
        _context_log "Context config already loaded: $context_id" "DEBUG"
        return 0
    fi

    # Source the configuration file
    local load_start_time
    if command -v date >/dev/null 2>&1; then
        load_start_time=$(date +%s.%N 2>/dev/null || date +%s)
    else
        load_start_time="0"
    fi

    # Capture environment before loading (if commands available)
    local env_before=""
    if command -v env >/dev/null 2>&1 && command -v sort >/dev/null 2>&1; then
        env_before=$(env | sort)
    fi

    if source "$config_file"; then
        local load_end_time load_duration env_after env_changes

        if command -v date >/dev/null 2>&1; then
            load_end_time=$(date +%s.%N 2>/dev/null || date +%s)
            if command -v bc >/dev/null 2>&1; then
                load_duration=$(echo "scale=3; ($load_end_time - $load_start_time) * 1000" | bc 2>/dev/null || echo "unknown")
            else
                load_duration="<1"
            fi
        else
            load_duration="<1"
        fi

        # Capture environment after loading (if commands available)
        if command -v env >/dev/null 2>&1 && command -v sort >/dev/null 2>&1; then
            env_after=$(env | sort)

            # Track what changed (if comm and wc available)
            if command -v comm >/dev/null 2>&1 && command -v wc >/dev/null 2>&1 && [[ -n "$env_before" ]]; then
                env_changes=$(comm -13 <(echo "$env_before") <(echo "$env_after") | wc -l)
            else
                env_changes="unknown"
            fi
        else
            env_changes="unknown"
        fi

        # Mark as loaded
        ZSH_CONTEXT_LOADED_CONFIGS[$context_id]="$config_file"

        _context_log "Context config loaded successfully: $context_id (${load_duration}ms, $env_changes env changes)"
        return 0
    else
        _context_log "Failed to load context config: $config_file" "ERROR"
        return 1
    fi
}

# 3.2. Unload context configuration
_unload_context_config() {
    local context_id="$1"

    _context_log "Unloading context config: $context_id"

    if [[ -z "${ZSH_CONTEXT_LOADED_CONFIGS[$context_id]:-}" ]]; then
        _context_log "Context config not loaded: $context_id" "DEBUG"
        return 0
    fi

    # Remove from loaded configs
    unset "ZSH_CONTEXT_LOADED_CONFIGS[$context_id]"

    # Note: We don't try to undo environment changes as it's complex and potentially dangerous
    # Instead, we rely on the fact that most context configs should be additive

    _context_log "Context config unloaded: $context_id"
    return 0
}

# 3.3. Apply context configuration
_apply_context_configuration() {
    local dir="${1:-$PWD}"

    if [[ "$ZSH_CONTEXT_ENABLE" != "true" ]]; then
        _context_log "Context-aware configuration disabled" "DEBUG"
        return 0
    fi

    _context_log "Applying context configuration for: $dir"

    # Get context configurations
    local config_files=($(_find_context_configs "$dir"))

    if [[ ${#config_files[@]} -eq 0 ]]; then
        _context_log "No context configurations found for: $dir" "DEBUG"
        return 0
    fi

    # Load each configuration
    local loaded_count=0
    for config_file in "${config_files[@]}"; do
        local context_id
        if command -v basename >/dev/null 2>&1; then
            context_id=$(basename "$config_file" .zsh)
        else
            context_id="${config_file##*/}"
            context_id="${context_id%.zsh}"
        fi
        if _load_context_config "$config_file" "$context_id"; then
            loaded_count=$((loaded_count + 1))
        fi
    done

    _context_log "Applied $loaded_count context configurations for: $dir"

    # Update current context tracking
    ZSH_CONTEXT_CURRENT_DIR="$dir"
    echo "$dir" > "$ZSH_CONTEXT_CURRENT_FILE" 2>/dev/null || true

    return 0
}

## 4. Directory Change Hooks
#=============================================================================

# 4.1. Directory change handler
_context_chpwd_handler() {
    local new_dir="$PWD"
    local old_dir="$ZSH_CONTEXT_CURRENT_DIR"

    # Skip if directory hasn't actually changed
    if [[ "$new_dir" == "$old_dir" ]]; then
        return 0
    fi

    _context_log "Directory changed: $old_dir -> $new_dir" "DEBUG"

    # Update previous directory tracking
    ZSH_CONTEXT_PREVIOUS_DIR="$old_dir"

    # Apply new context configuration
    _apply_context_configuration "$new_dir"
}

# 4.2. Register directory change hook
if [[ "$ZSH_CONTEXT_ENABLE" == "true" ]]; then
    # Add to chpwd_functions array if it doesn't already exist
    if [[ -z "${chpwd_functions[(r)_context_chpwd_handler]}" ]]; then
        chpwd_functions+=(_context_chpwd_handler)
        _context_log "Registered directory change handler"
    fi
fi

## 5. Context Management Commands
#=============================================================================

# 5.1. Show current context
context-status() {
    echo "========================================================"
    echo "Context-Aware Configuration Status"
    echo "========================================================"
    echo "Version: $ZSH_CONTEXT_AWARE_VERSION"
    echo "Enabled: $ZSH_CONTEXT_ENABLE"
    echo "Current Directory: $PWD"
    echo "Previous Directory: ${ZSH_CONTEXT_PREVIOUS_DIR:-none}"
    echo ""

    echo "Detected Contexts:"
    local contexts=($(_detect_directory_context "$PWD"))
    for context in "${contexts[@]}"; do
        echo "  - $context"
    done
    echo ""

    echo "Loaded Configurations:"
    if [[ ${#ZSH_CONTEXT_LOADED_CONFIGS[@]} -eq 0 ]]; then
        echo "  (none)"
    else
        for context_id in "${(@k)ZSH_CONTEXT_LOADED_CONFIGS}"; do
            echo "  - $context_id: ${ZSH_CONTEXT_LOADED_CONFIGS[$context_id]}"
        done
    fi
    echo ""

    echo "Available Context Configs:"
    if [[ -d "$ZSH_CONTEXT_CONFIG_DIR" ]]; then
        local config_count=$(find "$ZSH_CONTEXT_CONFIG_DIR" -name "*.zsh" -type f | wc -l)
        echo "  Total: $config_count configurations"
        find "$ZSH_CONTEXT_CONFIG_DIR" -name "*.zsh" -type f -exec basename {} .zsh \; | sed 's/^/  - /'
    else
        echo "  (directory not found: $ZSH_CONTEXT_CONFIG_DIR)"
    fi
}

# 5.2. Reload context configuration
context-reload() {
    _context_log "Reloading context configuration..."

    # Clear loaded configurations
    for context_id in "${(@k)ZSH_CONTEXT_LOADED_CONFIGS}"; do
        _unload_context_config "$context_id"
    done

    # Reapply current context
    _apply_context_configuration "$PWD"

    echo "Context configuration reloaded"
}

# 5.3. Create context configuration template
context-create() {
    local context_name="$1"

    if [[ -z "$context_name" ]]; then
        echo "Usage: context-create <context-name>"
        echo "Example: context-create nodejs"
        return 1
    fi

    local config_file="$ZSH_CONTEXT_CONFIG_DIR/${context_name}.zsh"

    if [[ -f "$config_file" ]]; then
        echo "Context configuration already exists: $config_file"
        return 1
    fi

    cat > "$config_file" << EOF
#!/opt/homebrew/bin/zsh
# Context-Aware Configuration: $context_name
# Auto-generated on $(date -u '+%Y-%m-%d %H:%M:%S UTC')

# Example: Set environment variables
# export PROJECT_TYPE="$context_name"

# Example: Add to PATH
# export PATH="\$PWD/bin:\$PATH"

# Example: Set aliases
# alias build="make build"
# alias test="make test"

# Example: Load project-specific tools
# if command -v docker-compose >/dev/null 2>&1; then
#     alias dc="docker-compose"
# fi

echo "Loaded $context_name context configuration"
EOF

    echo "Created context configuration: $config_file"
    echo "Edit the file to customize the configuration for $context_name contexts"
}

## 6. Initialization
#=============================================================================

# 6.1. Initialize context system
if [[ "$ZSH_CONTEXT_ENABLE" == "true" ]]; then
    # Apply initial context configuration
    _apply_context_configuration "$PWD"
fi

[[ "$ZSH_DEBUG" == "1" ]] && _context_log "✅ Context-aware dynamic configuration system loaded successfully"

# ------------------------------------------------------------------------------
# 7. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

# Main function for when script is executed directly
context_main() {
    echo "========================================================"
    echo "ZSH Context-Aware Dynamic Configuration System"
    echo "========================================================"
    echo "Version: $ZSH_CONTEXT_AWARE_VERSION"
    echo "Loaded: $ZSH_CONTEXT_AWARE_LOADED"
    echo ""

    if declare -f get_execution_context >/dev/null 2>&1; then
        echo "Execution Context: $(get_execution_context)"
        echo ""
    fi

    context-status

    if declare -f safe_exit >/dev/null 2>&1; then
        safe_exit 0
    else
        exit 0
    fi
}

# Use context-aware execution if detection system is available
if declare -f is_being_executed >/dev/null 2>&1; then
    if is_being_executed; then
        context_main "$@"
    fi
elif [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${(%):-%N}" == *"context-aware-config"* ]]; then
    # Fallback detection for direct execution
    context_main "$@"
fi

# ==============================================================================
# END: Context-Aware Dynamic Configuration System
# ==============================================================================
