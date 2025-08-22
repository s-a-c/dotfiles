#!/usr/bin/env zsh
# Deferred Plugin Loading System
# Implements zsh-defer-based asynchronous plugin loading for performance optimization
# Author: Configuration Management System
# Created: 2025-08-20
# Version: 1.0

# Save current working directory (required by user rules)
local _original_pwd="$PWD"

# Create log directory with UTC timestamp (required by user rules)
local _log_date=$(date -u '+%Y-%m-%d')
local _log_timestamp=$(date -u '+%Y%m%d_%H%M%S')
local _log_dir="$HOME/.config/zsh/logs/${_log_date}"
[[ ! -d "$_log_dir" ]] && mkdir -p "$_log_dir"
local _log_file="${_log_dir}/plugin-deferred-loading_${_log_timestamp}.log"

# Function to log messages with timestamp (required by user rules)
_log_plugin_defer() {
    echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] $*" >> "$_log_file" 2>&1
}

_log_plugin_defer "=== Starting deferred plugin loading setup ==="
_log_plugin_defer "Original PWD: $_original_pwd"
_log_plugin_defer "Log file: $_log_file"

# Only proceed if zsh-defer is available
if ! command -v zsh-defer >/dev/null 2>&1; then
    _log_plugin_defer "WARNING: zsh-defer not available, skipping deferred plugin loading"
    # Restore working directory before exit (required by user rules)
    cd "$_original_pwd" 2>/dev/null
    return 0
fi

_log_plugin_defer "zsh-defer is available, setting up deferred plugin loading"

# Define deferred plugin loading function
_setup_deferred_plugins() {
    _log_plugin_defer "Setting up deferred plugin loading triggers"
    
    # High-priority defer candidates from audit
    # These plugins provide specialized functionality not needed at startup
    
    # Git-related tools (only needed when working with git)
    _log_plugin_defer "Setting up git-related deferred plugins"
    
    # Create lazy wrapper for git-extra-commands
    if [[ -z "$_GIT_EXTRA_COMMANDS_LOADED" ]]; then
        _log_plugin_defer "Creating git-extra-commands lazy wrapper"
        function git() {
            if [[ -z "$_GIT_EXTRA_COMMANDS_LOADED" ]]; then
                _log_plugin_defer "Triggering git-extra-commands loading on first git usage"
                export _GIT_EXTRA_COMMANDS_LOADED=1
                # Load git-extra-commands immediately when git is first used
                if command -v zgenom >/dev/null 2>&1; then
                    zgenom load unixorn/git-extra-commands >> "$_log_file" 2>&1
                    _log_plugin_defer "git-extra-commands loaded successfully"
                fi
            fi
            # Call the real git command
            command git "$@"
        }
    fi
    
    # Docker-related tools (only needed when working with docker)
    _log_plugin_defer "Setting up docker-related deferred plugins"
    
    # Create lazy wrapper for docker completions
    if [[ -z "$_DOCKER_ZSH_LOADED" ]]; then
        _log_plugin_defer "Creating docker-zsh lazy wrapper"
        function docker() {
            if [[ -z "$_DOCKER_ZSH_LOADED" ]]; then
                _log_plugin_defer "Triggering docker-zsh loading on first docker usage"
                export _DOCKER_ZSH_LOADED=1
                # Load docker completions immediately when docker is first used
                if command -v zgenom >/dev/null 2>&1; then
                    zgenom load srijanshetty/docker-zsh >> "$_log_file" 2>&1
                    _log_plugin_defer "docker-zsh loaded successfully"
                fi
            fi
            # Call the real docker command
            command docker "$@"
        }
    fi
    
    # 1Password CLI (only needed when using op command)
    _log_plugin_defer "Setting up 1Password CLI deferred plugin"
    
    if [[ -z "$_1PASSWORD_OP_LOADED" ]]; then
        _log_plugin_defer "Creating 1password-op lazy wrapper"
        function op() {
            if [[ -z "$_1PASSWORD_OP_LOADED" ]]; then
                _log_plugin_defer "Triggering 1password-op loading on first op usage"
                export _1PASSWORD_OP_LOADED=1
                # Load 1Password plugin immediately when op is first used
                if command -v zgenom >/dev/null 2>&1; then
                    zgenom load unixorn/1password-op.plugin.zsh >> "$_log_file" 2>&1
                    _log_plugin_defer "1password-op loaded successfully"
                fi
            fi
            # Call the real op command
            command op "$@"
        }
    fi
    
    # Ruby/Rails tools (only needed for Ruby development)
    _log_plugin_defer "Setting up Ruby/Rails deferred plugins"
    
    if [[ -z "$_RAKE_COMPLETION_LOADED" ]]; then
        _log_plugin_defer "Creating rake completion lazy wrapper"
        function rake() {
            if [[ -z "$_RAKE_COMPLETION_LOADED" ]]; then
                _log_plugin_defer "Triggering rake completion loading on first rake usage"
                export _RAKE_COMPLETION_LOADED=1
                # Load rake completion immediately when rake is first used
                if command -v zgenom >/dev/null 2>&1; then
                    zgenom load unixorn/rake-completion.zshplugin >> "$_log_file" 2>&1
                    _log_plugin_defer "rake-completion loaded successfully"
                fi
            fi
            # Call the real rake command
            command rake "$@"
        }
    fi
    
    _log_plugin_defer "Deferred plugin loading setup complete"
}

# Defer the general utility plugins that don't need command-specific triggers
_defer_utility_plugins() {
    _log_plugin_defer "Setting up utility plugins for deferred loading"
    
    # Use zsh-defer to load utility plugins asynchronously
    # These don't need command-specific triggers but can load in background
    
    # General utilities - defer with 1 second delay for background loading
    zsh-defer -t 1 -c "
        _log_timestamp=\$(date -u '+%Y%m%d_%H%M%S')
        _defer_log='$_log_dir/deferred-utilities_\${_log_timestamp}.log'
        
        echo '[$(date -u \"+%Y-%m-%d %H:%M:%S UTC\")] Loading deferred utility plugins' >> \"\$_defer_log\"
        
        # Load utility plugins that enhance but don't provide essential functionality
        if command -v zgenom >/dev/null 2>&1; then
            echo '[$(date -u \"+%Y-%m-%d %H:%M:%S UTC\")] Loading JPB utilities' >> \"\$_defer_log\"
            zgenom load unixorn/jpb.zshplugin >> \"\$_defer_log\" 2>&1
            
            echo '[$(date -u \"+%Y-%m-%d %H:%M:%S UTC\")] Loading Warhol colorization' >> \"\$_defer_log\"
            zgenom load unixorn/warhol.plugin.zsh >> \"\$_defer_log\" 2>&1
            
            echo '[$(date -u \"+%Y-%m-%d %H:%M:%S UTC\")] Loading Tumult macOS utilities' >> \"\$_defer_log\"
            zgenom load unixorn/tumult.plugin.zsh >> \"\$_defer_log\" 2>&1
            
            echo '[$(date -u \"+%Y-%m-%d %H:%M:%S UTC\")] Loading DNS fix plugin' >> \"\$_defer_log\"
            zgenom load eventi/noreallyjustfuckingstopalready >> \"\$_defer_log\" 2>&1
            
            echo '[$(date -u \"+%Y-%m-%d %H:%M:%S UTC\")] Loading Bitbucket helpers' >> \"\$_defer_log\"
            zgenom load unixorn/bitbucket-git-helpers.plugin.zsh >> \"\$_defer_log\" 2>&1
            
            echo '[$(date -u \"+%Y-%m-%d %H:%M:%S UTC\")] Loading sysadmin utilities' >> \"\$_defer_log\"
            zgenom load skx/sysadmin-util >> \"\$_defer_log\" 2>&1
            
            echo '[$(date -u \"+%Y-%m-%d %H:%M:%S UTC\")] Loading BlackBox encryption' >> \"\$_defer_log\"
            zgenom load StackExchange/blackbox >> \"\$_defer_log\" 2>&1
            
            echo '[$(date -u \"+%Y-%m-%d %H:%M:%S UTC\")] Loading pip-app utilities' >> \"\$_defer_log\"
            zgenom load sharat87/pip-app >> \"\$_defer_log\" 2>&1
            
            echo '[$(date -u \"+%Y-%m-%d %H:%M:%S UTC\")] Loading 256 color support' >> \"\$_defer_log\"
            zgenom load chrissicool/zsh-256color >> \"\$_defer_log\" 2>&1
            
            echo '[$(date -u \"+%Y-%m-%d %H:%M:%S UTC\")] Loading k directory listing' >> \"\$_defer_log\"
            zgenom load supercrabtree/k >> \"\$_defer_log\" 2>&1
            
            echo '[$(date -u \"+%Y-%m-%d %H:%M:%S UTC\")] Loading completion generator' >> \"\$_defer_log\"
            zgenom load RobSis/zsh-completion-generator >> \"\$_defer_log\" 2>&1
            
            echo '[$(date -u \"+%Y-%m-%d %H:%M:%S UTC\")] All deferred utility plugins loaded' >> \"\$_defer_log\"
        else
            echo '[$(date -u \"+%Y-%m-%d %H:%M:%S UTC\")] ERROR: zgenom not available for deferred loading' >> \"\$_defer_log\"
        fi
    "
    
    _log_plugin_defer "Utility plugins scheduled for deferred loading"
}

# Defer Oh-My-Zsh plugins that are tool-specific
_defer_omz_plugins() {
    _log_plugin_defer "Setting up Oh-My-Zsh plugins for deferred loading"
    
    # Defer specialized Oh-My-Zsh plugins with 2 second delay
    zsh-defer -t 2 -c "
        _log_timestamp=\$(date -u '+%Y%m%d_%H%M%S')
        _defer_log='$_log_dir/deferred-omz_\${_log_timestamp}.log'
        
        echo '[$(date -u \"+%Y-%m-%d %H:%M:%S UTC\")] Loading deferred Oh-My-Zsh plugins' >> \"\$_defer_log\"
        
        if command -v zgenom >/dev/null 2>&1; then
            echo '[$(date -u \"+%Y-%m-%d %H:%M:%S UTC\")] Loading AWS plugin' >> \"\$_defer_log\"
            zgenom oh-my-zsh plugins/aws >> \"\$_defer_log\" 2>&1
            
            echo '[$(date -u \"+%Y-%m-%d %H:%M:%S UTC\")] Loading chruby plugin' >> \"\$_defer_log\"
            zgenom oh-my-zsh plugins/chruby >> \"\$_defer_log\" 2>&1
            
            echo '[$(date -u \"+%Y-%m-%d %H:%M:%S UTC\")] Loading rsync plugin' >> \"\$_defer_log\"
            zgenom oh-my-zsh plugins/rsync >> \"\$_defer_log\" 2>&1
            
            echo '[$(date -u \"+%Y-%m-%d %H:%M:%S UTC\")] Loading screen plugin' >> \"\$_defer_log\"
            zgenom oh-my-zsh plugins/screen >> \"\$_defer_log\" 2>&1
            
            echo '[$(date -u \"+%Y-%m-%d %H:%M:%S UTC\")] Loading vagrant plugin' >> \"\$_defer_log\"
            zgenom oh-my-zsh plugins/vagrant >> \"\$_defer_log\" 2>&1
            
            # macOS plugin only on Darwin
            if [[ \"\$(uname)\" == \"Darwin\" ]]; then
                echo '[$(date -u \"+%Y-%m-%d %H:%M:%S UTC\")] Loading macOS plugin' >> \"\$_defer_log\"
                zgenom oh-my-zsh plugins/macos >> \"\$_defer_log\" 2>&1
            fi
            
            echo '[$(date -u \"+%Y-%m-%d %H:%M:%S UTC\")] All deferred Oh-My-Zsh plugins loaded' >> \"\$_defer_log\"
        else
            echo '[$(date -u \"+%Y-%m-%d %H:%M:%S UTC\")] ERROR: zgenom not available for OMZ deferred loading' >> \"\$_defer_log\"
        fi
    "
    
    _log_plugin_defer "Oh-My-Zsh plugins scheduled for deferred loading"
}

# Initialize deferred plugin loading
_log_plugin_defer "Initializing deferred plugin loading system"

# Set up command-specific lazy loading wrappers
_setup_deferred_plugins

# Schedule utility plugins for background loading
_defer_utility_plugins

# Schedule Oh-My-Zsh plugins for background loading
_defer_omz_plugins

_log_plugin_defer "Deferred plugin loading initialization complete"

# Restore working directory (required by user rules)
cd "$_original_pwd" 2>/dev/null || {
    _log_plugin_defer "ERROR: Failed to restore working directory to $_original_pwd"
    _log_plugin_defer "Current directory: $(pwd)"
}

_log_plugin_defer "=== Deferred plugin loading setup finished ==="
