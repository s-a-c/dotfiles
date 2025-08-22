#!/opt/homebrew/bin/zsh
# Load source/execute detection utils if present (optional)
{
    DETECTION_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00-core/01-source-execute-detection.zsh"
    if [ -r "$DETECTION_SCRIPT" ]; then
        export ZSH_SOURCE_EXECUTE_TESTING=false
        source "$DETECTION_SCRIPT"
    fi
}
#=============================================================================
# File: 04-lazy-direnv.zsh
# Purpose: 2.2.1 Lazy loading wrapper for direnv hook initialization
# Dependencies: direnv (if available)
# Author: Configuration management system
# Last Modified: 2025-08-20
#=============================================================================

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
}

# 2.2.1 direnv lazy loading implementation
if command -v direnv >/dev/null 2>&1; then
    # 2.2.1.1 Working Directory Management - Save current working directory
    local original_cwd="$(pwd)"
    
    # 2.2.1.2 Configuration and logging setup
    local config_base="/Users/s-a-c/.config/zsh"
    local log_date=$(date -u +%Y-%m-%d)
    local log_time=$(date -u +%H-%M-%S)
    local log_dir="$config_base/logs/$log_date"
    local log_file="$log_dir/lazy-direnv_$log_time.log"
    
    # 2.2.1.3 Setup logging directory
    mkdir -p "$log_dir"
    
    # 2.2.1.4 Initialize lazy loading state
    typeset -g _DIRENV_HOOKED=0
    
    # 2.2.1.5 Lazy direnv hook function
    _init_direnv_hook() {
        # Skip if already initialized
        [[ $_DIRENV_HOOKED -eq 1 ]] && return 0
        
        # Log initialization
        {
            echo "=============================================================================="
            echo "Lazy Direnv Hook Initialization"  
            echo "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
            echo "Triggered by: ${funcstack[2]:-unknown}"
            echo "=============================================================================="
            echo ""
            
            # Initialize direnv hook
            if eval "$(direnv hook zsh)" 2>/dev/null; then
                _DIRENV_HOOKED=1
                echo "✅ direnv hook initialized successfully"
            else
                echo "❌ direnv hook initialization failed"
                return 1
            fi
            
            echo ""
            echo "=============================================================================="
            echo "Lazy direnv hook initialization completed at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
            echo "=============================================================================="
            
        } 2>&1 | tee -a "$log_file"
        
        return 0
    }
    
    # 2.2.1.6 Lazy direnv wrapper function
    direnv() {
        # Initialize hook on first use
        _init_direnv_hook || return 1
        
        # Remove our wrapper function (replace with real direnv)
        unfunction direnv
        
        # Call the real direnv command
        command direnv "$@"
    }
    
    # 2.2.1.7 Hook into directory changes to trigger direnv when needed
    _lazy_direnv_chpwd() {
        if [[ -f ".envrc" ]] && [[ $_DIRENV_HOOKED -eq 0 ]]; then
            [[ "$ZSH_DEBUG" == "1" ]] && echo "# Lazy loading direnv due to .envrc presence" >&2
            _init_direnv_hook
        fi
    }
    
    # Add to chpwd hooks for automatic .envrc detection
    autoload -U add-zsh-hook
    add-zsh-hook chpwd _lazy_direnv_chpwd
    
    # Check current directory for .envrc
    _lazy_direnv_chpwd
    
    # 2.2.1.8 Working Directory Restoration
    if ! cd "$original_cwd" 2>/dev/null; then
        echo "⚠️  Warning: Could not restore original directory: $original_cwd" >&2
        return 1
    fi
    
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [lazy-direnv] Lazy direnv wrapper initialized" >&2
else
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [lazy-direnv] direnv not found, skipping" >&2
fi
