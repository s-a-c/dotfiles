#!/usr/bin/env zsh
# Core Deferred Plugin Loading System
# Implements zsh-defer-based asynchronous plugin loading for performance optimization
# Author: Configuration Management System
# Created: 2025-08-25
# Version: 1.1 (split from 20_25-plugin-deferred-loading.zsh)

# Save current working directory (required by user rules)
local _original_pwd="$PWD"

# Create log directory with UTC timestamp (required by user rules)
# Fixed: Use safe_date wrapper for cross-platform compatibility
local _log_date=$(safe_date '+%Y-%m-%d')
local _log_timestamp=$(safe_date '+%Y%m%d_%H%M%S')
local _log_dir="$HOME/.config/zsh/logs/${_log_date}"
[[ ! -d "$_log_dir" ]] && /bin/mkdir -p "$_log_dir"
local _log_file="${_log_dir}/plugin-deferred-core_${_log_timestamp}.log"

# Function to log messages with timestamp (required by user rules)
# Fixed: Use safe_date wrapper for cross-platform compatibility
_log_plugin_defer() {
    zsh_debug_echo "[$(safe_date '+%Y-%m-%d %H:%M:%S UTC')] $*" >> "$_log_file"
}

_log_plugin_defer "=== Starting core deferred plugin loading setup ==="
_log_plugin_defer "Original PWD: $_original_pwd"
_log_plugin_defer "Log file: $_log_file"

# Only proceed if zsh-defer is available
if ! command -v zsh-defer >/dev/null 2>&1; then
    _log_plugin_defer "WARNING: zsh-defer not available, skipping deferred plugin loading"
    # Restore working directory before exit (required by user rules)
    cd "$_original_pwd" 2>/dev/null
    return 0
fi

_log_plugin_defer "zsh-defer is available, setting up core deferred plugin loading"

# Core deferred loading framework
_setup_deferred_framework() {
    _log_plugin_defer "Setting up deferred loading framework"

    # Export log file path for use by deferred utilities
    export ZSH_DEFER_LOG_FILE="$_log_file"
    export ZSH_DEFER_LOG_DIR="$_log_dir"

    # Create helper function for deferred plugin loading
    _defer_plugin_load() {
        local plugin_name="$1"
        local delay="${2:-1}"
        local log_message="${3:-Loading deferred plugin: $plugin_name}"

        _log_plugin_defer "Scheduling deferred load: $plugin_name (delay: ${delay}s)"

        zsh-defer -t "$delay" -c "
            zsh_debug_echo '[$(safe_date '+%Y-%m-%d %H:%M:%S UTC')] $log_message' >> '$_log_file'
            if command -v zgenom >/dev/null 2>&1; then
                zgenom load '$plugin_name' >> '$_log_file'
                zsh_debug_echo '[$(safe_date '+%Y-%m-%d %H:%M:%S UTC')] Successfully loaded: $plugin_name' >> '$_log_file'
            else
                zsh_debug_echo '[$(safe_date '+%Y-%m-%d %H:%M:%S UTC')] ERROR: zgenom not available for loading $plugin_name' >> '$_log_file'
            fi
        "
    }

    # Create helper function for command-triggered deferred loading
    _defer_command_wrapper() {
        local command_name="$1"
        local plugin_name="$2"
        local load_flag="$3"

        _log_plugin_defer "Creating command wrapper for: $command_name -> $plugin_name"

        eval "
        function $command_name() {
            if [[ -z \"\$$load_flag\" ]]; then
                _log_plugin_defer \"Triggering deferred load on first $command_name usage: $plugin_name\"
                export $load_flag=1
                if command -v zgenom >/dev/null 2>&1; then
                    zgenom load '$plugin_name' >> '$_log_file' 2>&1
                    _log_plugin_defer \"$plugin_name loaded successfully via $command_name trigger\"
                fi
                # Unset the wrapper function and call the real command
                unfunction $command_name
            fi
            command $command_name \"\$@\"
        }
        "
    }

    _log_plugin_defer "Deferred loading framework setup complete"
}

# Initialize the framework
_setup_deferred_framework

# Defer general utility plugins that don't need command-specific triggers
_defer_utility_plugins() {
    _log_plugin_defer "Setting up utility plugins for deferred loading"

    # Use zsh-defer to load utility plugins asynchronously
    # These don't need command-specific triggers but can load in background

    # General utilities - defer with 1 second delay for background loading
    zsh-defer -t 1 -c "
        _log_timestamp=\$(safe_date '+%Y%m%d_%H%M%S')
        _defer_log='$_log_dir/deferred-utilities_\${_log_timestamp}.log'

        zsh_debug_echo '[$(safe_date '+%Y-%m-%d %H:%M:%S UTC')] Loading deferred utility plugins' >> \"\$_defer_log\"

        # Load utility plugins that enhance but don't provide essential functionality
        if command -v zgenom >/dev/null 2>&1; then
            zsh_debug_echo '[$(safe_date '+%Y-%m-%d %H:%M:%S UTC')] Loading JPB utilities' >> \"\$_defer_log\"
            zgenom load unixorn/jpb.zshplugin >> \"\$_defer_log\"

            zsh_debug_echo '[$(safe_date '+%Y-%m-%d %H:%M:%S UTC')] Loading Warhol colorization' >> \"\$_defer_log\"
            zgenom load unixorn/warhol.plugin.zsh >> \"\$_defer_log\"

            zsh_debug_echo '[$(safe_date '+%Y-%m-%d %H:%M:%S UTC')] Loading tumult utilities' >> \"\$_defer_log\"
            zgenom load unixorn/tumult.plugin.zsh >> \"\$_defer_log\"

            zsh_debug_echo '[$(safe_date '+%Y-%m-%d %H:%M:%S UTC')] Utility plugins loaded' >> \"\$_defer_log\"
        else
            zsh_debug_echo '[$(safe_date '+%Y-%m-%d %H:%M:%S UTC')] ERROR: zgenom not available' >> \"\$_defer_log\"
        fi
    "

    _log_plugin_defer "Utility plugins scheduled for deferred loading"
}

# Performance monitoring plugins - defer with longer delay
_defer_performance_plugins() {
    _log_plugin_defer "Setting up performance monitoring plugins for deferred loading"

    # These plugins are useful but not essential for daily work
    zsh-defer -t 3 -c "
        _perf_log='$_log_dir/deferred-performance_\$(safe_date '+%Y%m%d_%H%M%S').log'

        zsh_debug_echo '[$(safe_date '+%Y-%m-%d %H:%M:%S UTC')] Loading performance monitoring plugins' >> \"\$_perf_log\"

        if command -v zgenom >/dev/null 2>&1; then
            # Load performance and monitoring utilities
            zsh_debug_echo '[$(safe_date '+%Y-%m-%d %H:%M:%S UTC')] Loading zsh-bench for performance testing' >> \"\$_perf_log\"
            zgenom load romkatv/zsh-bench >> \"\$_perf_log\"

            zsh_debug_echo '[$(safe_date '+%Y-%m-%d %H:%M:%S UTC')] Performance plugins loaded' >> \"\$_perf_log\"
        else
            zsh_debug_echo '[$(safe_date '+%Y-%m-%d %H:%M:%S UTC')] ERROR: zgenom not available' >> \"\$_perf_log\"
        fi
    "

    _log_plugin_defer "Performance plugins scheduled for deferred loading"
}

# Execute the deferred loading setup
_defer_utility_plugins
_defer_performance_plugins

# Cleanup and finalization
_finalize_deferred_core() {
    _log_plugin_defer "Core deferred plugin loading setup complete"
    _log_plugin_defer "Framework functions available: _defer_plugin_load, _defer_command_wrapper"

    # Restore working directory (required by user rules)
    cd "$_original_pwd" 2>/dev/null

    _log_plugin_defer "=== Core deferred plugin loading setup finished ==="
}

# Finalize
_finalize_deferred_core

[[ "$ZSH_DEBUG" == "1" ]] && {
    zsh_debug_echo "# [performance] Core deferred plugin loading initialized"
    zsh_debug_echo "# ------ $0 --------------------------------"
}
