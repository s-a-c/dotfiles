#!/usr/bin/env zsh
# ==============================================================================
# 99-WARP-COMPATIBILITY.ZSH - Warp Terminal Compatibility Fixes (REDESIGN v2)
# ==============================================================================
# Purpose: Warp terminal specific compatibility and performance optimizations
# Load Order: Final (99-) to handle any remaining compatibility issues
# Author: ZSH Configuration Redesign System
# Created: 2025-09-22
# Version: 1.0.0
# ==============================================================================

# Prevent multiple loading
if [[ -n "${_WARP_COMPATIBILITY_LOADED:-}" ]]; then
    return 0
fi
export _WARP_COMPATIBILITY_LOADED=1

# Only apply Warp-specific fixes if we're in Warp
if [[ "${TERM_PROGRAM}" == "WarpTerminal" ]]; then
    
    # Debug helper
    _warp_debug() {
        [[ -n "${ZSH_DEBUG:-}" ]] && echo "[WARP-COMPAT] $1" >&2 || true
    }
    
    _warp_debug "Loading Warp terminal compatibility fixes (v1.0.0)"
    
    # ==============================================================================
    # SECTION 1: PARAMETER SAFETY FOR WARP
    # ==============================================================================
    
    # Set safe defaults for parameters that Warp expects but might be undefined
    : ${GOPATH:=""}
    : ${POWERLEVEL9K_PROMPT_ADD_NEWLINE:=""}
    : ${INSIDE_EMACS:=""}
    : ${vcs_info_msg_0_:=""}
    : ${linux_distribution:="macos"}
    : ${ZGEN_RESET_ON_CHANGE:=""}
    : ${WSL_DISTRO_NAME:=""}
    : ${RUBY_AUTO_VERSION:=""}
    : ${RBENV_VERSION:=""}
    : ${RUBY_VERSION:=""}
    
    # Warp terminal internal parameters
    : ${_WARP_GENERATOR_COMMAND:=""}
    : ${WARP_PRECMD_EXECUTED:=""}
    : ${_WARP_SESSION_ID:=""}
    : ${WARP_HONOR_PS1:=""}
    : ${WARP_IS_LOCAL_SHELL_SESSION:=1}
    
    # Handle widgets array carefully - may be readonly in Warp
    if ! readonly -p 2>/dev/null | grep -q '^widgets'; then
        # widgets is not readonly, safe to modify
        typeset -A widgets 2>/dev/null || true
        : ${widgets[zle-keymap-select]:=""}
        _warp_debug "Set widgets array defaults"
    else
        _warp_debug "Skipped widgets array (readonly in Warp)"
    fi
    
    _warp_debug "Set safe parameter defaults"
    
    # ==============================================================================
    # SECTION 2: PERFORMANCE OPTIMIZATIONS FOR WARP
    # ==============================================================================
    
    # Disable expensive operations that can hang in Warp
    export DISABLE_AUTO_UPDATE=true
    export DISABLE_UPDATE_PROMPT=true
    
    # Speed up completions in Warp
    export ZSH_COMPDUMP_FPATH="${ZSH_COMPDUMP_FPATH:-${ZDOTDIR:-$HOME}/.zcompdump-warp}"
    
    # Disable problematic features that can hang
    unset HIST_STAMPS  # Can cause hanging in some configurations
    
    _warp_debug "Applied performance optimizations"
    
    # ==============================================================================
    # SECTION 3: PROMPT COMPATIBILITY
    # ==============================================================================
    
    # Ensure basic prompt functionality works in Warp
    if [[ -z "${PROMPT:-}" ]] && [[ -z "${PS1:-}" ]]; then
        # Fallback prompt if nothing else is set
        PROMPT='%F{blue}%n@%m%f:%F{green}%~%f%# '
        _warp_debug "Set fallback prompt"
    fi
    
    # Fix common prompt variable issues
    if command -v starship >/dev/null 2>&1; then
        # Starship is already initialized, ensure it works properly in Warp
        _warp_debug "Starship detected and compatible with Warp"
    fi
    
    # ==============================================================================
    # SECTION 4: PLUGIN COMPATIBILITY
    # ==============================================================================
    
    # Disable problematic plugins/features for Warp
    # Clean up any problematic integration functions that might have been loaded
    local -a problematic_functions=(
        "iterm2_shell_integration"
        "iterm2_before_cmd_executes"
        "iterm2_after_cmd_executes"
        "iterm2_precmd"
        "iterm2_preexec"
        "iterm2_print_state_data"
        "iterm2_prompt_mark"
        "iterm2_prompt_end"
        "iterm2_decorate_prompt"
        "iterm2_set_user_var"
        "iterm2_print_user_vars"
        "warp_precmd"
        "warp_preexec"
        "_warp_precmd"
        "_warp_preexec"
    )
    
    local cleaned_functions=0
    for func in "${problematic_functions[@]}"; do
        if [[ -n "${functions[$func]:-}" ]]; then
            unfunction "$func" 2>/dev/null || true
            cleaned_functions=$((cleaned_functions + 1))
        fi
    done
    
    if [[ $cleaned_functions -gt 0 ]]; then
        _warp_debug "Cleaned up $cleaned_functions problematic terminal functions for Warp compatibility"
    fi
    
    # Remove problematic hooks from hook arrays if present
    if [[ -n "${precmd_functions:-}" ]]; then
        precmd_functions=(${precmd_functions:#iterm2_precmd})
        precmd_functions=(${precmd_functions:#_macos_defaults_audit_run})
        precmd_functions=(${precmd_functions:#warp_precmd})
        _warp_debug "Cleaned precmd_functions: removed iterm2, macos-defaults, and warp hooks"
    fi
    if [[ -n "${preexec_functions:-}" ]]; then
        preexec_functions=(${preexec_functions:#iterm2_preexec})
        _warp_debug "Cleaned preexec_functions: removed iterm2 hooks"
    fi
    
    # Clean up problematic environment variables
    unset ITERM_SHELL_INTEGRATION_INSTALLED 2>/dev/null || true
    unset ITERM2_SHOULD_DECORATE_PROMPT 2>/dev/null || true
    unset ITERM2_PRECMD_PS1 2>/dev/null || true
    unset ITERM2_DECORATED_PS1 2>/dev/null || true
    unset ITERM2_SQUELCH_MARK 2>/dev/null || true
    
    # Clean up any problematic Warp variables that might cause conflicts
    # Note: We keep the essential ones we set above for parameter safety
    # WARP_IS_LOCAL_SHELL_SESSION and WARP_HONOR_PS1 are kept as they're required
    
    # ==============================================================================
    # SECTION 5: COMPLETION OPTIMIZATIONS
    # ==============================================================================
    
    # Speed up completions specifically for Warp
    zstyle ':completion:*' accept-exact '*(N)'
    zstyle ':completion:*' cache-policy _warp_completion_caching_policy
    
    # Warp-specific completion caching policy (more aggressive)
    _warp_completion_caching_policy() {
        local -a oldp
        oldp=( "$1"(Nm+1) )     # 1 minute cache for Warp
        (( $#oldp ))
    }
    
    _warp_debug "Applied Warp-specific completion optimizations"
    
    # ==============================================================================
    # SECTION 6: SPECIAL WARP CONFLICT HANDLING
    # ==============================================================================
    
    # Handle k plugin conflicts with pre-plugin coordination
    if [[ "${WARP_PRE_PLUGIN_COMPAT_APPLIED:-0}" == "1" ]]; then
        _warp_debug "Pre-plugin Warp compatibility was applied"
        
        # Check if we created a stub function that needs to be replaced
        if [[ "${WARP_K_STUB_CREATED:-0}" == "1" ]]; then
            # Remove our stub function first
            unfunction k 2>/dev/null || true
            _warp_debug "Removed k stub function"
        fi
        
        # Check if k function was loaded by the plugin after our stub was removed
        if [[ -n "${functions[k]:-}" ]]; then
            _warp_debug "k plugin function loaded successfully - preserving for directory listings"
            # Keep k function for directory listings, it's useful in Warp too
        elif [[ "${WARP_KUBECTL_AVAILABLE:-0}" == "1" ]]; then
            # Set kubectl alias as intended since k plugin didn't load
            alias k='kubectl'
            _warp_debug "Set kubectl k alias as planned (k plugin didn't load)"
        else
            # Neither k plugin nor kubectl available, provide helpful message
            # First ensure no k alias exists before defining function
            unalias k 2>/dev/null || true
            k() {
                echo "k command not available. Install kubectl for k=kubectl alias, or use 'ls' for directory listings."
                return 1
            }
            _warp_debug "Created fallback k function with helpful message"
        fi
    else
        # Legacy handling for when pre-plugin compat didn't run
        _warp_debug "Pre-plugin compatibility not applied, using legacy conflict handling"
        
        # Clean up any k aliases that loaded
        if [[ -n "${aliases[k]:-}" ]]; then
            _warp_debug "Found k alias from plugin - unsetting to prevent Warp conflict"
            unalias k 2>/dev/null || true
        fi
        
        # Handle k function conflicts
        if [[ -n "${functions[k]:-}" ]]; then
            _warp_debug "k plugin function available - preserved for directory listings"
        else
            # Set kubectl alias if available
            if command -v kubectl >/dev/null 2>&1; then
                alias k='kubectl'
                _warp_debug "Set kubectl k alias as fallback"
            fi
        fi
    fi
    
    # Always ensure k plugin function is available for directory listings in Warp
    _warp_debug "k plugin function available - preserved for directory listings"
    
    # ==============================================================================
    # SECTION 7: CLEANUP AND FINALIZATION
    # ==============================================================================
    
    # Set flag to indicate Warp compatibility is active
    export WARP_COMPATIBILITY_ACTIVE=1
    
    _warp_debug "Warp terminal compatibility fixes applied"
    
    # Clean up debug function
    unset -f _warp_debug
    
fi

# ==============================================================================
# MODULE COMPLETION
# ==============================================================================

export WARP_COMPATIBILITY_VERSION="1.0.0"
if command -v date >/dev/null 2>&1; then
    export WARP_COMPATIBILITY_LOADED_AT="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'unknown')"
else
    export WARP_COMPATIBILITY_LOADED_AT="unknown"
fi

# ==============================================================================
# END OF WARP COMPATIBILITY MODULE
# ==============================================================================