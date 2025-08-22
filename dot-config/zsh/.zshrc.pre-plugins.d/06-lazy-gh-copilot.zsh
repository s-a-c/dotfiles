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
# File: 06-lazy-gh-copilot.zsh
# Purpose: 2.2.2 Lazy loading wrapper for GitHub Copilot CLI aliases
# Dependencies: gh (GitHub CLI)
# Author: Configuration management system
# Last Modified: 2025-08-20
#=============================================================================

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
}

# 2.2.2 GitHub Copilot CLI lazy loading
if command -v gh >/dev/null 2>&1; then
    # 2.2.2.1 Working Directory Management - Save current working directory
    local original_cwd="$(pwd)"
    
    # 2.2.2.2 Configuration and logging setup
    local config_base="/Users/s-a-c/.config/zsh"
    local log_date=$(date -u +%Y-%m-%d)
    local log_time=$(date -u +%H-%M-%S)
    local log_dir="$config_base/logs/$log_date"
    local log_file="$log_dir/lazy-gh-copilot_$log_time.log"
    
    # 2.2.2.3 Setup logging directory
    mkdir -p "$log_dir"
    
    # 2.2.2.4 Initialize lazy loading state
    typeset -g _GH_COPILOT_LOADED=0
    
    # 2.2.2.5 GitHub Copilot initialization function
    _init_gh_copilot() {
        # Skip if already initialized
        [[ $_GH_COPILOT_LOADED -eq 1 ]] && return 0
        
        # Check if gh copilot is available
        if ! gh copilot --help >/dev/null 2>&1; then
            [[ "$ZSH_DEBUG" == "1" ]] && echo "# gh copilot extension not available" >&2
            return 1
        fi
        
        # Log initialization
        {
            echo "=============================================================================="
            echo "Lazy GitHub Copilot CLI Initialization"  
            echo "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
            echo "Triggered by: ${funcstack[2]:-unknown}"
            echo "=============================================================================="
            echo ""
            
            # Initialize GitHub Copilot aliases
            if eval "$(gh copilot alias -- zsh)" 2>/dev/null; then
                _GH_COPILOT_LOADED=1
                echo "✅ GitHub Copilot CLI aliases initialized successfully"
            else
                echo "❌ GitHub Copilot CLI aliases initialization failed"
                return 1
            fi
            
            echo ""
            echo "=============================================================================="
            echo "Lazy GitHub Copilot CLI initialization completed at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
            echo "=============================================================================="
            
        } 2>&1 | tee -a "$log_file"
        
        return 0
    }
    
    # 2.2.2.6 Lazy copilot wrapper functions
    ghcs() {
        # Initialize on first use
        _init_gh_copilot || return 1
        
        # Remove our wrapper function (should be replaced by real alias)
        if functions ghcs >/dev/null 2>&1; then
            unfunction ghcs
        fi
        
        # Try to call the real ghcs command
        if functions ghcs >/dev/null 2>&1; then
            ghcs "$@"
        else
            gh copilot suggest "$@"
        fi
    }
    
    ghce() {
        # Initialize on first use
        _init_gh_copilot || return 1
        
        # Remove our wrapper function
        if functions ghce >/dev/null 2>&1; then
            unfunction ghce
        fi
        
        # Try to call the real ghce command
        if functions ghce >/dev/null 2>&1; then
            ghce "$@"
        else
            gh copilot explain "$@"
        fi
    }
    
    # 2.2.2.7 Working Directory Restoration
    if ! cd "$original_cwd" 2>/dev/null; then
        echo "⚠️  Warning: Could not restore original directory: $original_cwd" >&2
        return 1
    fi
    
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [lazy-gh-copilot] Lazy GitHub Copilot wrapper initialized" >&2
else
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [lazy-gh-copilot] gh CLI not found, skipping" >&2
fi
