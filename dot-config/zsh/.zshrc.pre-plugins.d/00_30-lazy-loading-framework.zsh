#!/usr/bin/env zsh
#=============================================================================
# File: 00_30-lazy-loading-framework.zsh
# Purpose: Core lazy loading framework for heavy security modules and components
# Author: Configuration management system
# Created: 2025-08-25
# Version: 1.0
# Category: 00 (Core) - Essential framework for performance optimization
#=============================================================================


# Prevent multiple loading
[[ -n "${_LOADED_00_30_LAZY_LOADING_FRAMEWORK:-}" ]] && return 0

zsh_debug_echo "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
zsh_debug_echo "# [performance] Loading lazy loading framework"

# 1. Lazy Loading Configuration
#=============================================================================

# Global lazy loading settings
export ZSH_LAZY_LOADING_ENABLED="${ZSH_LAZY_LOADING_ENABLED:-true}"
export ZSH_LAZY_LOADING_TIMEOUT="${ZSH_LAZY_LOADING_TIMEOUT:-30}"  # 30 seconds default timeout
export ZSH_LAZY_LOADING_LOG="${HOME}/.config/zsh/logs/$(safe_date +%Y-%m-%d)/lazy-loading.log"

# Create log directory
[[ ! -d "$(safe_dirname "$ZSH_LAZY_LOADING_LOG")" ]] && safe_mkdir -p "$(safe_dirname "$ZSH_LAZY_LOADING_LOG")"

# 2. Core Lazy Loading Functions
#=============================================================================

# Log lazy loading events
_lazy_log() {
    local level="$1"
    local message="$2"
    local timestamp="$(safe_date -u '+    %FT%T %Z')"

        zsh_debug_echo "[$timestamp] [$level] $message" >> "$ZSH_LAZY_LOADING_LOG" 2>/dev/null || true
}

# Create a lazy wrapper for a function
lazy_function() {
    local func_name="$1"
    local loader_command="$2"
    local description="${3:-$func_name}"

    if [[ -z "$func_name" ]] || [[ -z "$loader_command" ]]; then
        _lazy_log "ERROR" "lazy_function requires function name and loader command"
        return 1
    fi

    _lazy_log "INFO" "Creating lazy wrapper for function: $func_name ($description)"

    # Create the lazy wrapper function
    eval "
    $func_name() {
        _lazy_log 'TRIGGER' 'Loading $description on first call to $func_name'

        # Remove the lazy wrapper
        unfunction $func_name 2>/dev/null || true

        # Execute the loader command
        if eval '$loader_command'; then
            _lazy_log 'SUCCESS' '$description loaded successfully'

            # Call the real function if it now exists
            if command -v $func_name >/dev/null 2>&1; then
                $func_name \"\$@\"
            else
                _lazy_log 'WARN' 'Function $func_name not available after loading $description'
                return 1
            fi
        else
            _lazy_log 'ERROR' 'Failed to load $description'
            return 1
        fi
    }
    "
}

# Create a lazy wrapper for a command
lazy_command() {
    local cmd_name="$1"
    local loader_command="$2"
    local description="${3:-$cmd_name}"

    if [[ -z "$cmd_name" ]] || [[ -z "$loader_command" ]]; then
        _lazy_log "ERROR" "lazy_command requires command name and loader command"
        return 1
    fi

    _lazy_log "INFO" "Creating lazy wrapper for command: $cmd_name ($description)"

    # Create the lazy wrapper function
    eval "
    $cmd_name() {
        _lazy_log 'TRIGGER' 'Loading $description on first call to $cmd_name'

        # Remove the lazy wrapper
        unfunction $cmd_name 2>/dev/null || true

        # Execute the loader command
        if eval '$loader_command'; then
            _lazy_log 'SUCCESS' '$description loaded successfully'
        else
            _lazy_log 'ERROR' 'Failed to load $description'
        fi

        # Call the real command
        command $cmd_name \"\$@\"
    }
    "
}

# Create a lazy wrapper for sourcing a file
lazy_source() {
    local file_path="$1"
    local trigger_function="$2"
    local description="${3:-$(basename "$file_path")}"

    if [[ -z "$file_path" ]] || [[ -z "$trigger_function" ]]; then
        _lazy_log "ERROR" "lazy_source requires file path and trigger function name"
        return 1
    fi

    if [[ ! -f "$file_path" ]]; then
        _lazy_log "ERROR" "File not found for lazy loading: $file_path"
        return 1
    fi

    _lazy_log "INFO" "Creating lazy source wrapper for: $file_path -> $trigger_function ($description)"

    # Create the lazy wrapper function
    eval "
    $trigger_function() {
        _lazy_log 'TRIGGER' 'Loading $description on first call to $trigger_function'

        # Remove the lazy wrapper
        unfunction $trigger_function 2>/dev/null || true

        # Source the file
        if source '$file_path'; then
            _lazy_log 'SUCCESS' '$description loaded successfully from $file_path'

            # Call the real function if it now exists
            if command -v $trigger_function >/dev/null 2>&1; then
                $trigger_function \"\$@\"
            else
                _lazy_log 'WARN' 'Function $trigger_function not available after sourcing $file_path'
                return 1
            fi
        else
            _lazy_log 'ERROR' 'Failed to source $file_path for $description'
            return 1
        fi
    }
    "
}

# 3. Lazy Loading for Heavy Security Modules
#=============================================================================

# Lazy load advanced SSH agent security features
lazy_function "secure_ssh_restart_advanced" \
    "source '$ZDOTDIR/.zshrc.pre-plugins.d/20_11-ssh-agent-security.zsh'" \
    "Advanced SSH Agent Security"

lazy_function "secure_ssh_status" \
    "source '$ZDOTDIR/.zshrc.pre-plugins.d/20_11-ssh-agent-security.zsh'" \
    "SSH Agent Status Functions"

# Lazy load advanced plugin integrity verification
lazy_function "plugin_security_status_advanced" \
    "source '$ZDOTDIR/.zshrc.pre-plugins.d/20_21-plugin-integrity-advanced.zsh'" \
    "Advanced Plugin Security Status"

lazy_function "plugin_security_scan_all" \
    "source '$ZDOTDIR/.zshrc.pre-plugins.d/20_21-plugin-integrity-advanced.zsh'" \
    "Plugin Security Scanner"

lazy_function "plugin_security_update_registry" \
    "source '$ZDOTDIR/.zshrc.pre-plugins.d/20_21-plugin-integrity-advanced.zsh'" \
    "Plugin Registry Management"

# 4. Lazy Loading Status and Management
#=============================================================================

# Show lazy loading status
lazy_loading_status() {
    zsh_debug_echo "Lazy Loading Framework Status"
    zsh_debug_echo "============================="
    zsh_debug_echo "Enabled: $ZSH_LAZY_LOADING_ENABLED"
    zsh_debug_echo "Timeout: $ZSH_LAZY_LOADING_TIMEOUT seconds"
    zsh_debug_echo "Log File: $ZSH_LAZY_LOADING_LOG"
    zsh_debug_echo ""

    zsh_debug_echo "Lazy Wrappers Active:"

    # Check which lazy wrappers are still active (not yet triggered)
    local lazy_functions=(
        "secure_ssh_restart_advanced"
        "secure_ssh_status"
        "plugin_security_status_advanced"
        "plugin_security_scan_all"
        "plugin_security_update_registry"
    )

    for func in "${lazy_functions[@]}"; do
        if command -v "$func" >/dev/null 2>&1; then
            # Check if it's still a lazy wrapper by looking for our trigger pattern
            if functions "$func" | grep -q "_lazy_log.*TRIGGER"; then
                    zsh_debug_echo "  ⏳ $func (not yet loaded)"
            else
                    zsh_debug_echo "  ✅ $func (loaded)"
            fi
        else
                zsh_debug_echo "  ❌ $func (not available)"
        fi
    done

        zsh_debug_echo ""
        zsh_debug_echo "Recent Activity:"
    if [[ -f "$ZSH_LAZY_LOADING_LOG" ]]; then
        tail -10 "$ZSH_LAZY_LOADING_LOG" 2>/dev/null | sed 's/^/  /' || zsh_debug_echo "  (no recent activity)"
    else
            zsh_debug_echo "  (log file not found)"
    fi
}

# Force load all lazy components (for testing or immediate use)
lazy_loading_force_all() {
        zsh_debug_echo "Force loading all lazy components..."

    local lazy_functions=(
        "secure_ssh_restart_advanced"
        "secure_ssh_status"
        "plugin_security_status_advanced"
        "plugin_security_scan_all"
        "plugin_security_update_registry"
    )

    for func in "${lazy_functions[@]}"; do
        if command -v "$func" >/dev/null 2>&1; then
            if functions "$func" | grep -q "_lazy_log.*TRIGGER"; then
                    zsh_debug_echo "  Loading: $func"
                # Trigger the lazy loading by calling the function with --help or similar
                "$func" --version >/dev/null 2>&1 || true
            fi
        fi
    done

    zsh_debug_echo "✅ Force loading complete"
}

# 5. Initialization
#=============================================================================

# Initialize lazy loading framework
if [[ "$ZSH_LAZY_LOADING_ENABLED" == "true" ]]; then
    _lazy_log "INFO" "Lazy loading framework initialized"
    _lazy_log "INFO" "Created lazy wrappers for heavy security modules"
else
    _lazy_log "INFO" "Lazy loading framework disabled"
fi

zsh_debug_echo "# [performance] Lazy loading framework loaded"
zsh_debug_echo "# ------ $0 --------------------------------"

# Mark as loaded
readonly _LOADED_00_30_LAZY_LOADING_FRAMEWORK=1
