#!/usr/bin/env zsh
# Deferred Plugin Loading Utilities
# Specific command wrappers and tool-specific deferred loading
# Author: Configuration Management System
# Created: 2025-08-25
# Version: 1.1 (split from 20_25-plugin-deferred-loading.zsh)
# Dependencies: 20_25-plugin-deferred-core.zsh

# Use log file from core module if available
# Fixed: Use safe_date wrapper for cross-platform compatibility
local _log_file="${ZSH_DEFER_LOG_FILE:-$HOME/.config/zsh/logs/$(safe_date '+%Y-%m-%d')/plugin-deferred-utils_$(safe_date '+%Y%m%d_%H%M%S').log}"
local _log_dir="${ZSH_DEFER_LOG_DIR:-$(command dirname "$_log_file")}"

# Ensure log directory exists
[[ ! -d "$_log_dir" ]] && command mkdir -p "$_log_dir"

# Function to log messages with timestamp
# Fixed: Use safe_date wrapper for cross-platform compatibility
_log_plugin_defer_utils() {
    zsh_debug_echo "[$(safe_date '+%Y-%m-%d %H:%M:%S UTC')] $*" >> "$_log_file"
}

_log_plugin_defer_utils "=== Starting deferred plugin utilities setup ==="

# Only proceed if zsh-defer is available
if ! command -v zsh-defer >/dev/null 2>&1; then
    _log_plugin_defer_utils "WARNING: zsh-defer not available, skipping deferred plugin utilities"
    return 0
fi

# Define specific command-triggered deferred plugins
_setup_command_triggered_plugins() {
    _log_plugin_defer_utils "Setting up command-triggered deferred plugins"

    # Docker-related tools (only needed when working with docker)
    _log_plugin_defer_utils "Setting up docker-related deferred plugins"

    # Create lazy wrapper for docker completions
    if [[ -z "$_DOCKER_ZSH_LOADED" ]]; then
        _log_plugin_defer_utils "Creating docker-zsh lazy wrapper"
        function docker() {
            if [[ -z "$_DOCKER_ZSH_LOADED" ]]; then
                _log_plugin_defer_utils "Triggering docker-zsh loading on first docker usage"
                export _DOCKER_ZSH_LOADED=1
                # Load docker completions immediately when docker is first used
                if command -v zgenom >/dev/null 2>&1; then
                    zgenom load srijanshetty/docker-zsh >> "$_log_file" 2>&1
                    _log_plugin_defer_utils "docker-zsh loaded successfully"
                fi
                # Unset the wrapper function
                unfunction docker
            fi
            # Call the real docker command
            command docker "$@"
        }
    fi

    # 1Password CLI (only needed when using op command)
    _log_plugin_defer_utils "Setting up 1Password CLI deferred plugin"

    if [[ -z "$_1PASSWORD_OP_LOADED" ]]; then
        _log_plugin_defer_utils "Creating 1password-op lazy wrapper"
        function op() {
            if [[ -z "$_1PASSWORD_OP_LOADED" ]]; then
                _log_plugin_defer_utils "Triggering 1password-op loading on first op usage"
                export _1PASSWORD_OP_LOADED=1
                # Load 1Password plugin immediately when op is first used
                if command -v zgenom >/dev/null 2>&1; then
                    zgenom load unixorn/1password-op.plugin.zsh >> "$_log_file" 2>&1
                    _log_plugin_defer_utils "1password-op loaded successfully"
                fi
                # Unset the wrapper function
                unfunction op
            fi
            # Call the real op command
            command op "$@"
        }
    fi

    # Ruby/Rails tools (only needed for Ruby development)
    _log_plugin_defer_utils "Setting up Ruby/Rails deferred plugins"

    if [[ -z "$_RAKE_COMPLETION_LOADED" ]]; then
        _log_plugin_defer_utils "Creating rake completion lazy wrapper"
        function rake() {
            if [[ -z "$_RAKE_COMPLETION_LOADED" ]]; then
                _log_plugin_defer_utils "Triggering rake completion loading on first rake usage"
                export _RAKE_COMPLETION_LOADED=1
                # Load rake completion immediately when rake is first used
                if command -v zgenom >/dev/null 2>&1; then
                    zgenom load unixorn/rake-completion.zshplugin >> "$_log_file" 2>&1
                    _log_plugin_defer_utils "rake-completion loaded successfully"
                fi
                # Unset the wrapper function
                unfunction rake
            fi
            # Call the real rake command
            command rake "$@"
        }
    fi

    # Python development tools
    _log_plugin_defer_utils "Setting up Python development deferred plugins"

    if [[ -z "$_PYTHON_TOOLS_LOADED" ]]; then
        _log_plugin_defer_utils "Creating python tools lazy wrapper"
        function pip() {
            if [[ -z "$_PYTHON_TOOLS_LOADED" ]]; then
                _log_plugin_defer_utils "Triggering python tools loading on first pip usage"
                export _PYTHON_TOOLS_LOADED=1
                # Load python-related plugins when pip is first used
                if command -v zgenom >/dev/null 2>&1; then
                    zgenom load unixorn/autoupdate-zgen >> "$_log_file" 2>&1
                    _log_plugin_defer_utils "python tools loaded successfully"
                fi
                # Unset the wrapper function
                unfunction pip
            fi
            # Call the real pip command
            command pip "$@"
        }
    fi

    # Node.js/npm tools
    _log_plugin_defer_utils "Setting up Node.js development deferred plugins"

    if [[ -z "$_NODE_TOOLS_LOADED" ]]; then
        _log_plugin_defer_utils "Creating node tools lazy wrapper"
        function npm() {
            if [[ -z "$_NODE_TOOLS_LOADED" ]]; then
                _log_plugin_defer_utils "Triggering node tools loading on first npm usage"
                export _NODE_TOOLS_LOADED=1
                # Load node-related plugins when npm is first used
                if command -v zgenom >/dev/null 2>&1; then
                    # Load npm completion and utilities
                    zgenom oh-my-zsh plugins/npm >> "$_log_file" 2>&1
                    _log_plugin_defer_utils "node tools loaded successfully"
                fi
                # Unset the wrapper function
                unfunction npm
            fi
            # Call the real npm command
            command npm "$@"
        }
    fi

    _log_plugin_defer_utils "Command-triggered deferred plugins setup complete"
}

# Development environment specific plugins
_setup_dev_environment_plugins() {
    _log_plugin_defer_utils "Setting up development environment specific plugins"

    # Load development plugins with longer delay (5 seconds)
    zsh-defer -t 5 -c "
        _dev_log='$_log_dir/deferred-development_$(safe_date '+%Y%m%d_%H%M%S').log'

        zsh_debug_echo '[$(safe_date '+%Y-%m-%d %H:%M:%S UTC')] Loading development environment plugins' >> \"\$_dev_log\"

        if command -v zgenom >/dev/null 2>&1; then
            # Load development utilities that are nice to have but not essential
            zsh_debug_echo '[$(safe_date '+%Y-%m-%d %H:%M:%S UTC')] Loading git-flow completion' >> \"\$_dev_log\"
            zgenom load bobthecow/git-flow-completion >> \"\$_dev_log\"

            zsh_debug_echo '[$(safe_date '+%Y-%m-%d %H:%M:%S UTC')] Loading colorize plugin' >> \"\$_dev_log\"
            zgenom oh-my-zsh plugins/colorize >> \"\$_dev_log\"

            zsh_debug_echo '[$(safe_date '+%Y-%m-%d %H:%M:%S UTC')] Development plugins loaded' >> \"\$_dev_log\"
        else
            zsh_debug_echo '[$(safe_date '+%Y-%m-%d %H:%M:%S UTC')] ERROR: zgenom not available' >> \"\$_dev_log\"
        fi
    "

    _log_plugin_defer_utils "Development environment plugins scheduled for deferred loading"
}

# System administration plugins
_setup_sysadmin_plugins() {
    _log_plugin_defer_utils "Setting up system administration plugins"

    # Load sysadmin plugins with even longer delay (7 seconds)
    zsh-defer -t 7 -c "
        _sysadmin_log='$_log_dir/deferred-sysadmin_$(safe_date '+%Y%m%d_%H%M%S').log'

        zsh_debug_echo '[$(safe_date '+%Y-%m-%d %H:%M:%S UTC')] Loading system administration plugins' >> \"\$_sysadmin_log\"

        if command -v zgenom >/dev/null 2>&1; then
            # Load system administration utilities
            zsh_debug_echo '[$(safe_date '+%Y-%m-%d %H:%M:%S UTC')] Loading systemd plugin' >> \"\$_sysadmin_log\"
            zgenom oh-my-zsh plugins/systemd >> \"\$_sysadmin_log\"

            zsh_debug_echo '[$(safe_date '+%Y-%m-%d %H:%M:%S UTC')] Loading sudo plugin' >> \"\$_sysadmin_log\"
            zgenom oh-my-zsh plugins/sudo >> \"\$_sysadmin_log\"

            zsh_debug_echo '[$(safe_date '+%Y-%m-%d %H:%M:%S UTC')] System administration plugins loaded' >> \"\$_sysadmin_log\"
        else
            zsh_debug_echo '[$(safe_date '+%Y-%m-%d %H:%M:%S UTC')] ERROR: zgenom not available' >> \"\$_sysadmin_log\"
        fi
    "

    _log_plugin_defer_utils "System administration plugins scheduled for deferred loading"
}

# Utility functions for managing deferred plugins
deferred_plugin_status() {
    zsh_debug_echo "Deferred Plugin Loading Status"
    zsh_debug_echo "=============================="
    zsh_debug_echo "Log File: $_log_file"
    zsh_debug_echo ""

    zsh_debug_echo "Command Wrappers Active:"
    [[ -n "$_DOCKER_ZSH_LOADED" ]] && zsh_debug_echo "  ✅ Docker tools loaded" || zsh_debug_echo "  ⏳ Docker tools (loads on first 'docker' command)"
    [[ -n "$_1PASSWORD_OP_LOADED" ]] && zsh_debug_echo "  ✅ 1Password CLI loaded" || zsh_debug_echo "  ⏳ 1Password CLI (loads on first 'op' command)"
    [[ -n "$_RAKE_COMPLETION_LOADED" ]] && zsh_debug_echo "  ✅ Rake completion loaded" || zsh_debug_echo "  ⏳ Rake completion (loads on first 'rake' command)"
    [[ -n "$_PYTHON_TOOLS_LOADED" ]] && zsh_debug_echo "  ✅ Python tools loaded" || zsh_debug_echo "  ⏳ Python tools (loads on first 'pip' command)"
    [[ -n "$_NODE_TOOLS_LOADED" ]] && zsh_debug_echo "  ✅ Node.js tools loaded" || zsh_debug_echo "  ⏳ Node.js tools (loads on first 'npm' command)"

    zsh_debug_echo ""
    zsh_debug_echo "Recent Activity:"
    if [[ -f "$_log_file" ]]; then
        tail -10 "$_log_file" | sed 's/^/  /' || zsh_debug_echo "  (no recent activity)"
    else
        zsh_debug_echo "  (log file not found)"
    fi
}

# Execute the setup functions
_setup_command_triggered_plugins
_setup_dev_environment_plugins
_setup_sysadmin_plugins

_log_plugin_defer_utils "=== Deferred plugin utilities setup complete ==="

[[ "$ZSH_DEBUG" == "1" ]] && {
    zsh_debug_echo "# [performance] Deferred plugin utilities initialized"
    zsh_debug_echo "# ------ $0 --------------------------------"
}
