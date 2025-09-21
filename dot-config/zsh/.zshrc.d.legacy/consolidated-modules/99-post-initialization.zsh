#!/usr/bin/env zsh
# ==============================================================================
# ZSH Legacy Configuration: Post-Initialization Module
# ==============================================================================
# Purpose: Final initialization tasks that require full ZSH environment
#          Including ZLE setup and Starship prompt initialization
#
# Dependencies: All other modules (runs last)
# Load Order: 99 (final module)
# Author: ZSH Legacy Consolidation System
# Created: 2025-09-21
# Version: 1.0.0
# ==============================================================================

# Prevent multiple loading
if [[ -n "${_POST_INITIALIZATION_LOADED:-}" ]]; then
    return 0
fi
export _POST_INITIALIZATION_LOADED=1

# Debug helper - use core infrastructure if available
_post_debug() {
    if command -v debug_log >/dev/null 2>&1; then
        debug_log "$1"
    elif [[ -n "${ZSH_DEBUG:-}" ]]; then
        echo "[POST-DEBUG] $1" >&2
    fi
}

_post_debug "Loading post-initialization module..."

# ==============================================================================
# SECTION 1: ZLE FINALIZATION
# ==============================================================================

_post_debug "Finalizing ZLE system..."

# At this point in startup, ZLE should be fully available
finalize_zle() {
    _post_debug "Checking ZLE system state..."
    
    if [[ -o interactive ]] && [[ -n "${ZLE_VERSION:-}" ]]; then
        _post_debug "✅ ZLE is available (version: $ZLE_VERSION)"
        
        # Verify critical widgets now exist
        local missing_widgets=()
        local critical_widgets=("zle-keymap-select" "zle-line-init" "zle-line-finish")
        
        for widget in "${critical_widgets[@]}"; do
            if [[ -z "${widgets[$widget]:-}" ]]; then
                missing_widgets+=("$widget")
            fi
        done
        
        if [[ ${#missing_widgets[@]} -eq 0 ]]; then
            _post_debug "✅ All critical ZLE widgets available"
            export ZLE_READY="1"
        else
            _post_debug "⚠️  Missing ZLE widgets: ${missing_widgets[*]}"
            export ZLE_READY="0"
        fi
        
        # Update ZLE status
        export ZLE_INIT_STATUS="ZLE Status: ZLE_VERSION=$ZLE_VERSION interactive=yes widgets_count=${#widgets[@]} ZLE_READY=$ZLE_READY"
    else
        _post_debug "❌ ZLE not available or not interactive"
        export ZLE_READY="0"
        export ZLE_INIT_STATUS="ZLE Status: ZLE_VERSION=${ZLE_VERSION:-not_set} interactive=$([[ -o interactive ]] && echo yes || echo no) ZLE_READY=0"
    fi
}

# Finalize ZLE
finalize_zle

# ==============================================================================
# SECTION 2: STARSHIP PROMPT INITIALIZATION
# ==============================================================================

_post_debug "Initializing Starship prompt system..."

# Initialize Starship prompt now that ZLE is ready
initialize_starship_prompt() {
    _post_debug "Checking Starship availability..."
    
    # Enhanced binary resolution with fallback
    local _starship_bin
    _starship_bin="$(command -v starship 2>/dev/null || true)"
    if [[ -z "$_starship_bin" && -x "$HOME/.local/share/cargo/bin/starship" ]]; then
        _starship_bin="$HOME/.local/share/cargo/bin/starship"
    fi
    
    if [[ -z "$_starship_bin" ]]; then
        _post_debug "❌ Starship not available"
        return 1
    fi
    
    _post_debug "✅ Starship available at $_starship_bin"
    
    # Allow a sentinel to explicitly force p10k (future-proofing)
    if [[ -f "${ZDOTDIR:-$HOME}/.zqs-prompt-powerlevel10k" || "${ZSH_PROMPT_BACKEND:-}" = "p10k" ]]; then
        _post_debug "⚠️  P10k forced via sentinel; skipping Starship init"
        return 1
    fi
    
    # Check if ZLE is ready (relaxed requirement for interactive shells)
    if [[ -o interactive ]] && [[ "${ZLE_READY:-0}" != "1" ]]; then
        _post_debug "⚠️  Interactive shell but ZLE not ready, proceeding anyway"
        _post_debug "ZLE Status: ${ZLE_INIT_STATUS:-not_available}"
        # Continue with initialization instead of returning
    fi
    
    _post_debug "✅ Proceeding with Starship initialization..."
    
    # Ensure cargo bin is visible to subshells
    case ":$PATH:" in
        *":$HOME/.local/share/cargo/bin:"*) ;;
        *) PATH="$HOME/.local/share/cargo/bin:$PATH" ;;
    esac
    
    # Export environment variables before eval
    export STARSHIP_SHELL="${STARSHIP_SHELL:-zsh}"
    [[ -f "$HOME/.config/starship.toml" ]] && export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$HOME/.config/starship.toml}"
    
    # Generate and execute starship initialization
    local starship_init
    starship_init="$("$_starship_bin" init zsh 2>/dev/null)"
    
    if [[ -n "$starship_init" ]]; then
        _post_debug "✅ Starship init script generated (${#starship_init} chars)"
        
        # Execute starship initialization
        if eval "$starship_init" 2>/dev/null; then
            _post_debug "✅ Starship prompt initialized successfully (STARSHIP_SHELL=$STARSHIP_SHELL)"
            export STARSHIP_INITIALIZED="1"
            return 0
        else
            _post_debug "❌ Starship eval failed"
            return 1
        fi
    else
        _post_debug "❌ Starship init script generation failed"
        return 1
    fi
}

# Initialize Starship
if initialize_starship_prompt; then
    _post_debug "✅ Starship initialization completed"
else
    _post_debug "❌ Starship initialization failed, keeping fallback prompt"
fi

# ==============================================================================
# SECTION 3: FINAL SYSTEM VERIFICATION
# ==============================================================================

_post_debug "Running final system verification..."

# System health check
verify_system_health() {
    _post_debug "Verifying system health..."
    
    local health_report="System Health:"
    
    # Check ZLE
    if [[ "${ZLE_READY:-0}" == "1" ]]; then
        health_report="$health_report ZLE=✅"
    else
        health_report="$health_report ZLE=❌"
    fi
    
    # Check Starship
    if [[ "${STARSHIP_INITIALIZED:-0}" == "1" ]]; then
        health_report="$health_report Starship=✅"
    else
        health_report="$health_report Starship=❌"
    fi
    
    # Check prompt
    if [[ -n "${STARSHIP_SHELL:-}" ]]; then
        health_report="$health_report Prompt=Starship"
    else
        health_report="$health_report Prompt=Fallback"
    fi
    
    _post_debug "$health_report"
    export SYSTEM_HEALTH_STATUS="$health_report"
}

# Run health check
verify_system_health

# ==============================================================================
# MODULE INITIALIZATION COMPLETE
# ==============================================================================

_post_debug "Post-initialization module ready"

# Export module metadata
export POST_INITIALIZATION_VERSION="1.0.0"
export POST_INITIALIZATION_LOADED="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'startup')"

# ==============================================================================
# MODULE SELF-TEST
# ==============================================================================

test_post_initialization() {
    echo "=== Post-Initialization Self-Test ==="
    
    local tests_passed=0
    local tests_total=4
    
    # Test 1: ZLE status
    if [[ "${ZLE_READY:-0}" == "1" ]]; then
        ((tests_passed++))
        echo "✅ ZLE system ready"
    else
        echo "❌ ZLE system not ready"
    fi
    
    # Test 2: Starship availability
    if command -v starship >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Starship command available"
    else
        echo "❌ Starship command not available"
    fi
    
    # Test 3: Starship initialization
    if [[ "${STARSHIP_INITIALIZED:-0}" == "1" ]]; then
        ((tests_passed++))
        echo "✅ Starship initialized successfully"
    else
        echo "❌ Starship initialization failed"
    fi
    
    # Test 4: Module metadata
    if [[ -n "$POST_INITIALIZATION_VERSION" ]]; then
        ((tests_passed++))
        echo "✅ Module metadata available"
    else
        echo "❌ Module metadata missing"
    fi
    
    echo ""
    echo "Post-Initialization Self-Test: $tests_passed/$tests_total tests passed"
    echo "$SYSTEM_HEALTH_STATUS"
    echo "ZLE Status: $ZLE_INIT_STATUS"
    
    return $(( tests_total - tests_passed ))
}

# ==============================================================================
# END OF POST-INITIALIZATION MODULE
# ==============================================================================