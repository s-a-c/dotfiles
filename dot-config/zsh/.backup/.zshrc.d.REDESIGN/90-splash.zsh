#!/usr/bin/env zsh
# ==============================================================================
# 90-SPLASH.ZSH - Visual Startup Splash Screen (REDESIGN v2)
# ==============================================================================
# Purpose: Visual startup elements including fastfetch, colorscripts, welcome
#          banners, health checks, and performance tips
# Consolidates: splash functionality from disabled and backup modules
# Load Order: Late (90-) to display after all initialization is complete
# Author: ZSH Configuration Redesign System
# Created: 2025-09-22
# Version: 2.0.0
# ==============================================================================

# Prevent multiple loading
if [[ -n "${_SPLASH_SCREEN_REDESIGN:-}" ]]; then
    return 0
fi
export _SPLASH_SCREEN_REDESIGN=1

# Debug helper
_splash_debug() {
    [[ -n "${ZSH_DEBUG:-}" ]] && zf::debug "[SPLASH] $1" || true
}

_splash_debug "Loading visual startup splash screen (v2.0.0)"

# ==============================================================================
# SECTION 1: VISUAL SPLASH COMPONENTS
# ==============================================================================

# Main splash screen display
splash_screen() {
    # Skip if splash disabled
    if [[ "${ZSH_DISABLE_SPLASH:-0}" == "1" ]]; then
        _splash_debug "Splash disabled via ZSH_DISABLE_SPLASH=1"
        return 0
    fi

    # Only show splash screen on interactive terminals
    [[ ! -t 0 || ! -t 1 ]] && return 0

    # Skip if minimal startup requested
    if [[ "${ZSH_MINIMAL:-0}" == "1" ]]; then
        _splash_debug "Splash disabled via ZSH_MINIMAL=1"
        return 0
    fi

    # Skip if in CI or non-interactive contexts
    [[ -n "${CI:-}" ]] && return 0

    _splash_debug "Displaying visual splash screen"

    # Show visual elements by default unless explicitly disabled
    # ZSH_DISABLE_* = 1 means don't show, 0 (default) means show if available

    # Show colorful output with lolcat if not disabled
    if [[ "${ZSH_DISABLE_COLORSCRIPT:-0}" != "1" ]]; then
        if [[ "${ZSH_DISABLE_LOLCAT:-0}" != "1" ]] && zf::ensure_cmd lolcat >/dev/null 2>&1 && zf::ensure_cmd colorscript >/dev/null 2>&1; then
            colorscript random | lolcat
        elif zf::ensure_cmd colorscript >/dev/null 2>&1; then
            # Fallback to colorscript without lolcat
            colorscript random
        fi
    fi

    # Show system information with fastfetch if not disabled
    if [[ "${ZSH_DISABLE_FASTFETCH:-0}" != "1" ]] && zf::ensure_cmd fastfetch >/dev/null 2>&1; then
        echo ""
        fastfetch
        echo ""
    fi

    # Display welcome banner
    display_welcome_banner
}

# Welcome banner with shell information
display_welcome_banner() {
    local shell_version="ZSH $ZSH_VERSION"
    local config_version="${ZDOTDIR##*/} (REDESIGN)"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'unknown')
    local term_info="${TERM_PROGRAM:-${TERM:-unknown}}"

    echo ""
    echo "╭─────────────────────────────────────────────────────────╮"
    echo "│  🚀 Enhanced ZSH Configuration - REDESIGN v2            │"
    echo "│                                                         │"
    echo "│  Shell: $shell_version"
    printf "│%*s│\n" $((57 - ${#shell_version})) ""
    echo "│  Config: $config_version"
    printf "│%*s│\n" $((57 - ${#config_version})) ""
    echo "│  Terminal: $term_info"
    printf "│%*s│\n" $((57 - ${#term_info})) ""
    echo "│  Time: $timestamp"
    printf "│%*s│\n" $((57 - ${#timestamp})) ""
    echo "│                                                         │"
    echo "│  💡 Enhanced features active:                           │"
    echo "│    • Core infrastructure with zf:: namespace           │"
    echo "│    • Security and integrity validation                 │"
    echo "│    • Modern shell options and completion               │"
    echo "│    • Visual startup elements                           │"
    echo "│    • Warp terminal compatibility                       │"
    echo "╰─────────────────────────────────────────────────────────╯"
    echo ""
}

# ==============================================================================
# SECTION 2: HEALTH CHECKS AND DIAGNOSTICS
# ==============================================================================

# Perform basic shell health check
shell_health_check() {
    local issues=0
    local warnings=()

    _splash_debug "Running shell health check"

    # Check essential commands
    local essential_commands=(git curl wget ssh zsh)
    for cmd in "${essential_commands[@]}"; do
        if ! zf::ensure_cmd "$cmd" >/dev/null 2>&1; then
            warnings+=("Missing essential command: $cmd")
            ((issues++))
        fi
    done

    # Check shell options
    if ! setopt | grep -q EXTENDED_GLOB; then
        warnings+=("EXTENDED_GLOB not set - some features may not work")
        ((issues++))
    fi

    # Check for modern tools
    local modern_tools=(eza bat fd rg fastfetch lolcat colorscript)
    local modern_count=0
    for tool in "${modern_tools[@]}"; do
        if zf::ensure_cmd "$tool" >/dev/null 2>&1; then
            ((modern_count++))
        fi
    done

    # Report results
    if [[ $issues -gt 0 ]]; then
        echo "⚠️  Shell Health Issues Detected ($issues):"
        for warning in "${warnings[@]}"; do
            echo "   • $warning"
        done
        echo ""
    fi

    if [[ $modern_count -gt 0 ]]; then
        echo "✨ Modern tools available: $modern_count/${#modern_tools[@]} (eza, bat, fd, rg, fastfetch, lolcat, colorscript)"
        echo ""
    fi

    return $issues
}

# ==============================================================================
# SECTION 3: PERFORMANCE TIPS AND HELP
# ==============================================================================

# Show rotating performance tips
show_performance_tips() {
    # Skip if tips disabled
    if [[ "${ZSH_DISABLE_TIPS:-0}" == "1" ]]; then
        return 0
    fi

    local tips=(
        "Use the 'zf::' namespace functions for enhanced logging and timing"
        "Set ZSH_DEBUG=1 to see detailed module loading information"
        "Modern tools like eza, bat, fd, and rg provide enhanced functionality"
        "The REDESIGN system uses numbered modules for predictable load order"
        "Warp compatibility fixes are automatically applied for optimal performance"
        "Use '..' '...' '....' for quick directory navigation"
        "Set ZSH_DISABLE_SPLASH=1 to skip this startup screen"
    )

    # Select random tip (1-based indexing for ZSH arrays)
    local tip_index=$((RANDOM % ${#tips[@]} + 1))
    echo "💡 Tip: ${tips[$tip_index]}"
    echo ""
}

# ==============================================================================
# SECTION 4: DAILY SPLASH CONTROL
# ==============================================================================

# Check if splash should be shown (once per day)
should_show_splash() {
    local today
    local splash_marker

    # Get current date
    if zf::ensure_cmd date >/dev/null 2>&1; then
        today=$(date +%Y-%m-%d 2>/dev/null || echo "unknown")
    else
        today="unknown"
    fi

    # Create daily marker file path
    local cache_dir="${ZSH_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/zsh}"
    splash_marker="$cache_dir/.splash_shown_${today}"

    # Check if already shown today
    if [[ ! -f "$splash_marker" ]]; then
        # Create marker file
        mkdir -p "$cache_dir" 2>/dev/null
        touch "$splash_marker" 2>/dev/null
        return 0  # Show splash
    fi

    return 1  # Don't show splash
}

# ==============================================================================
# SECTION 5: MAIN SPLASH ORCHESTRATION
# ==============================================================================

# Main splash function - orchestrates all startup display elements
show_startup_splash() {
    # Only show splash in interactive shells
    if [[ ! -o interactive ]]; then
        return 0
    fi

    # Skip if explicitly disabled
    if [[ "${ZSH_DISABLE_SPLASH:-0}" == "1" ]]; then
        _splash_debug "Splash disabled via ZSH_DISABLE_SPLASH"
        return 0
    fi

    # Skip in SSH sessions unless forced
    if [[ -n "${SSH_CONNECTION:-}" && -z "${FORCE_SPLASH:-}" ]]; then
        _splash_debug "Splash skipped in SSH session"
        return 0
    fi

    # Check daily display control
    if ! should_show_splash && [[ -z "${FORCE_SPLASH:-}" ]]; then
        _splash_debug "Splash already shown today"
        return 0
    fi

    _splash_debug "Showing startup splash"

    # Show the visual splash screen
    splash_screen

    # Perform health check if enabled
    if [[ "${ZSH_ENABLE_HEALTH_CHECK:-0}" == "1" ]]; then
        shell_health_check
    fi

    # Show a performance tip
    show_performance_tips
}

# ==============================================================================
# SECTION 6: STARTUP EXECUTION
# ==============================================================================

# Show startup splash when module loads (only in interactive shells)
if [[ -o interactive ]] && [[ -z "${_SPLASH_SHOWN:-}" ]]; then
    export _SPLASH_SHOWN=1

    # Delay splash slightly to allow shell to fully initialize
    # Use background process to avoid blocking
    if command -v sleep >/dev/null 2>&1; then
        (
            # Preserve ZDOTDIR in background process
            export ZDOTDIR="${ZDOTDIR}"
            sleep 0.1
            show_startup_splash
        ) &!
    else
        # Fallback: show splash immediately if sleep not available
        show_startup_splash
    fi

    _splash_debug "Splash screen scheduled"
fi

# ==============================================================================
# MODULE COMPLETION
# ==============================================================================

export SPLASH_SCREEN_VERSION="2.0.0"
if zf::ensure_cmd date >/dev/null 2>&1; then
    export SPLASH_SCREEN_LOADED_AT="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'unknown')"
else
    export SPLASH_SCREEN_LOADED_AT="unknown"
fi

_splash_debug "Visual splash screen module ready"

# Clean up helper function
unset -f _splash_debug

# ==============================================================================
# END OF SPLASH SCREEN MODULE
# ==============================================================================
