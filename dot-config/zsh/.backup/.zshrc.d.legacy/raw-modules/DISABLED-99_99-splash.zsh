#!/usr/bin/env zsh
# Startup Message and Performance Summary
# This file provides startup completion message and performance statistics
# Load time target: <10ms

[[ "$ZSH_DEBUG" == "1" ]] && {
        zf::debug "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
}

# Calculate total startup time if profiling is enabled
if [[ -n "$ZSH_PROF" || -n "$ZSH_DEBUG" ]]; then
    startup_end=$SECONDS
    total_time=${startup_end:-0}

    if [[ "$ZSH_DEBUG" == "1" ]]; then
        zf::debug ""
        zf::debug "🚀 ZSH Startup Complete!"
        zf::debug "⏱️  Total startup time: ${total_time}s"
        zf::debug "📁 Configuration: ~/.config/zsh/.zshrc (Next Generation)"
        zf::debug ""
    fi
fi

# Optional: Display shell information
if [[ "$ZSH_DEBUG" == "1" ]]; then
    zf::debug "🔧 System Information:"
    zf::debug "   Shell: $SHELL ($ZSH_VERSION)"
    zf::debug "   OS: $(uname -s) $(uname -r)"
    zf::debug "   Terminal: ${TERM:-unknown}"
    zf::debug "   PATH entries: $(zf::debug "$PATH" | grep -o ':' | wc -l | tr -d ' ')"
    zf::debug "   Functions loaded: $(typeset -f | grep -c '^[a-zA-Z_][a-zA-Z0-9_]* ()')"
    zf::debug ""
fi

# Splash screen display
splash_screen() {
    # Only show splash screen on interactive terminals
    [[ ! -t 0 || ! -t 1 ]] && return 0

    # Skip if minimal startup requested
    [[ -n "$ZSH_MINIMAL" ]] && return 0

    # Show colorful splash if commands are available
    if [[ -n "${commands[lolcat]}" ]]; then
        [[ -n "${commands[colorscript]}" ]] && colorscript random | lolcat
    else
        [[ -n "${commands[colorscript]}" ]] && colorscript random
    fi

    # Show system information with fastfetch if available
    # Temporarily disabled for performance testing
    # [[ -n "${commands[fastfetch]}" ]] && fastfetch
}

# Quick health check
shell_health_check() {
    local issues=0

    # Debug: Show PATH before checks
    zf::debug "[health_check]  PATH: $PATH"

    # Check essential commands
    local essential_commands=(sed tr uname dirname basename cat cc make ld)
    for cmd in "${essential_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            # Fallback: check if binary exists in /usr/bin or /bin
            if [[ -x "/usr/bin/$cmd" || -x "/bin/$cmd" ]]; then
                zf::debug "⚠️ [health_check]  $cmd not found in PATH, but exists in /usr/bin or /bin"
            else
                zf::debug "⚠️ [health_check]  Missing essential command: $cmd"
                ((issues++))
            fi
        fi
    done

    # Check completion system
    if ! (( ${+functions[compinit]} )); then
        zf::debug "⚠️ [health_check]  Completion system not loaded"
        ((issues++))
    fi

    # Check plugin system
    if ! command -v zgenom >/dev/null 2>&1; then
        zf::debug "⚠️ [health_check]  Plugin system (zgenom) not available"
        ((issues++))
    fi

    if [[ $issues -eq 0 && -n "$ZSH_DEBUG" ]]; then
        zf::debug "✅ [health_check]  Shell health check passed!"
    elif [[ $issues -gt 0 ]]; then
        zf::debug "⚠️ [health_check]  $issues issues detected. Run with ZSH_DEBUG=1 for details."
    fi

    return $issues
}

# Performance tips
show_performance_tips() {
    if [[ -n "$ZSH_DEBUG" && -n "$total_time" && $total_time -gt 2 ]]; then
        zf::debug "💡 Performance Tips:"
        zf::debug "   - Run 'zgenom reset' to rebuild plugin cache"
        zf::debug "   - Check for slow plugins with 'time exec zsh'"
        zf::debug "   - Consider removing unused plugins"
        zf::debug ""
    fi
}

# Main splash function
splash_main() {
    # Only run health check if debugging or if there might be issues
    if [[ "$ZSH_DEBUG" == "1" ]] || [[ ! -f "$ZSH_COMPDUMP" ]]; then
        shell_health_check
        show_performance_tips
    fi

    # Show splash screen only on first interactive shell of the day
    local today
    if command -v date >/dev/null 2>&1; then
        today=$(date -unknown +%F)
    else
        today="unknown"
    fi
    local splash_marker="$ZSH_CACHE_DIR/.splash_${today}"

    # Show splash screen only once per day
    if [[ ! -f "$splash_marker" && -t 0 && -t 1 ]]; then
        splash_screen
        touch "$splash_marker" 2>/dev/null
    fi

    # Show welcome screen only on first interactive shell of the day (reuse today variable)
    local welcome_marker="$ZSH_CACHE_DIR/.welcome_${today}"

    # Show welcome message only once per day and only if not suppressed
    if [[ "${ZSH_SUPPRESS_WELCOME}" != "true" && ! -f "$welcome_marker" && -t 0 && -t 1 ]]; then
        zf::debug "\n🎉 Welcome to your optimized ZSH environment!\n"
        zf::debug "   Type 'help' or check aliases with 'alias'\n"
        # Mark welcome as shown for today
        touch "$welcome_marker" 2>/dev/null
    fi
}

# Run the startup finalization
splash_main

zf::debug "# [90_] Startup message complete"
