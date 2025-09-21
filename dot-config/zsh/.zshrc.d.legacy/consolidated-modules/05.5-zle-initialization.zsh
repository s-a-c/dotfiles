#!/usr/bin/env zsh
# ==============================================================================
# ZSH Legacy Configuration: ZLE Initialization Module
# ==============================================================================
# Purpose: Initialize ZSH Line Editor (ZLE) system and core widgets
#          Must run before user interface and external integrations modules
#
# Dependencies: 01-core-infrastructure.zsh (for logging)
# Load Order: 05.5 (between completion and user interface)
# Author: ZSH Legacy Consolidation System
# Created: 2025-09-21
# Version: 1.0.0
# ==============================================================================

# Prevent multiple loading
if [[ -n "${_ZLE_INITIALIZATION_LOADED:-}" ]]; then
    return 0
fi
export _ZLE_INITIALIZATION_LOADED=1

# Debug helper - use core infrastructure if available
_zle_debug() {
    if command -v debug_log >/dev/null 2>&1; then
        debug_log "$1"
    elif [[ -n "${ZSH_DEBUG:-}" ]]; then
        echo "[ZLE-DEBUG] $1" >&2
    fi
}

_zle_debug "Loading ZLE initialization module..."

# ==============================================================================
# SECTION 1: ZLE CORE INITIALIZATION
# ==============================================================================

_zle_debug "Initializing ZLE core system..."

# Initialize ZLE if not already loaded
if [[ -z "${ZLE_VERSION:-}" ]]; then
    _zle_debug "Loading ZLE system..."
    autoload -Uz zle
fi

# Ensure ZLE is in the right mode for interactive use
if [[ -o interactive ]]; then
    # Set up basic ZLE configuration
    _zle_debug "Configuring ZLE for interactive use..."
    
    # Enable ZLE if not already enabled
    if [[ -z "${ZLE_VERSION:-}" ]]; then
        # ZLE should auto-initialize in interactive mode
        # Force initialization if needed
        zle || _zle_debug "ZLE initialization completed"
    fi
fi

# ==============================================================================
# SECTION 2: CORE WIDGET INITIALIZATION
# ==============================================================================

_zle_debug "Initializing core ZLE widgets..."

# Ensure critical widgets array is available
if [[ -z ${widgets+x} ]]; then
    _zle_debug "Widgets array not available - ZLE may not be fully initialized"
else
    _zle_debug "ZLE widgets array available with ${#widgets[@]} widgets"
fi

# Create essential widgets that external tools might expect
setup_essential_widgets() {
    _zle_debug "Setting up essential ZLE widgets..."
    
    # Only proceed if ZLE is available and we're in interactive mode
    if [[ -z "${ZLE_VERSION:-}" ]] || [[ ! -o interactive ]]; then
        _zle_debug "Skipping widget setup - ZLE not available or non-interactive"
        return 0
    fi
    
    # Check if critical widgets exist, and try to create them if missing
    local required_widgets=("zle-keymap-select" "zle-line-init" "zle-line-finish")
    
    for widget_name in "${required_widgets[@]}"; do
        if [[ -z "${widgets[$widget_name]:-}" ]]; then
            _zle_debug "Widget $widget_name missing - attempting to create..."
            
            # Create widget function dynamically
            case "$widget_name" in
                "zle-keymap-select")
                    eval "$widget_name() { case \$KEYMAP in vicmd) echo -n '\\e[1 q';; *) echo -n '\\e[5 q';; esac }"
                    ;;
                "zle-line-init")
                    eval "$widget_name() { echo -n '\\e[5 q' }"
                    ;;
                "zle-line-finish")
                    eval "$widget_name() { echo -n '\\e[0 q' }"
                    ;;
            esac
            
            # Register as ZLE widget
            if zle -N "$widget_name" 2>/dev/null; then
                _zle_debug "✅ Created widget: $widget_name"
            else
                _zle_debug "❌ Failed to create widget: $widget_name"
            fi
        else
            _zle_debug "✅ Widget exists: $widget_name"
        fi
    done
    
    _zle_debug "Essential widgets setup complete"
}

# Initialize essential widgets
setup_essential_widgets

# ==============================================================================
# SECTION 3: ZLE CONFIGURATION DEFAULTS
# ==============================================================================

_zle_debug "Setting ZLE configuration defaults..."

# Set up default keymap (emacs mode)
if [[ -n "${ZLE_VERSION:-}" ]] && [[ -o interactive ]]; then
    # Use emacs key bindings by default (can be overridden by user interface module)
    bindkey -e 2>/dev/null || _zle_debug "bindkey -e failed"
    
    # Set basic ZLE options
    setopt AUTO_MENU         # Show menu after successive tabs
    setopt AUTO_LIST         # List choices on ambiguous completion
    setopt AUTO_PARAM_SLASH  # Add trailing slash to directory names
    setopt COMPLETE_IN_WORD  # Complete from both ends of word
    setopt ALWAYS_TO_END     # Move cursor to end after completion
    
    _zle_debug "ZLE configuration defaults applied"
fi

# ==============================================================================
# SECTION 4: ZLE STATUS VERIFICATION
# ==============================================================================

# Verify ZLE is properly initialized
verify_zle_status() {
    _zle_debug "Verifying ZLE initialization status..."
    
    local zle_status="ZLE Status:"
    zle_status="$zle_status ZLE_VERSION=${ZLE_VERSION:-not_set}"
    zle_status="$zle_status interactive=$([[ -o interactive ]] && echo yes || echo no)"
    zle_status="$zle_status widgets_count=${#widgets[@]}"
    
    # Check for critical widgets
    local critical_widgets=("zle-keymap-select" "zle-line-init" "zle-line-finish")
    local missing_widgets=()
    
    for widget in "${critical_widgets[@]}"; do
        if [[ -z "${widgets[$widget]:-}" ]]; then
            missing_widgets+=("$widget")
        fi
    done
    
    if [[ ${#missing_widgets[@]} -gt 0 ]]; then
        zle_status="$zle_status missing_widgets=[${missing_widgets[*]}]"
        _zle_debug "⚠️  $zle_status"
    else
        zle_status="$zle_status critical_widgets=✅"
        _zle_debug "✅ $zle_status"
    fi
    
    # Export status for other modules to check
    export ZLE_INIT_STATUS="$zle_status"
    export ZLE_READY=$([[ ${#missing_widgets[@]} -eq 0 ]] && echo "1" || echo "0")
}

# Verify ZLE status
verify_zle_status

# ==============================================================================
# MODULE INITIALIZATION COMPLETE
# ==============================================================================

_zle_debug "ZLE initialization module ready"
_zle_debug "ZLE_READY=$ZLE_READY"

# Export module status
export ZLE_INITIALIZATION_VERSION="1.0.0"
export ZLE_INITIALIZATION_LOADED="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'startup')"

# ==============================================================================
# MODULE SELF-TEST
# ==============================================================================

test_zle_initialization() {
    local tests_passed=0
    local tests_total=4
    
    echo "=== ZLE Initialization Self-Test ==="
    
    # Test 1: ZLE_VERSION available
    if [[ -n "${ZLE_VERSION:-}" ]]; then
        ((tests_passed++))
        echo "✅ ZLE version available: $ZLE_VERSION"
    else
        echo "❌ ZLE version not available"
    fi
    
    # Test 2: Widgets array exists
    if [[ -n "${widgets+x}" ]]; then
        ((tests_passed++))
        echo "✅ Widgets array available (${#widgets[@]} widgets)"
    else
        echo "❌ Widgets array not available"
    fi
    
    # Test 3: Critical widgets present
    if [[ "$ZLE_READY" == "1" ]]; then
        ((tests_passed++))
        echo "✅ Critical widgets available"
    else
        echo "❌ Critical widgets missing"
    fi
    
    # Test 4: Module metadata
    if [[ -n "$ZLE_INITIALIZATION_VERSION" ]]; then
        ((tests_passed++))
        echo "✅ Module metadata available"
    else
        echo "❌ Module metadata missing"
    fi
    
    echo ""
    echo "ZLE Initialization Self-Test: $tests_passed/$tests_total tests passed"
    echo "ZLE Status: $ZLE_INIT_STATUS"
    
    return $(( tests_total - tests_passed ))
}

# ==============================================================================
# END OF ZLE INITIALIZATION MODULE
# ==============================================================================