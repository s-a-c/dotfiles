# Startup Message and Performance Summary
# This file provides startup completion message and performance statistics
# Load time target: <10ms

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
}

# Calculate total startup time if profiling is enabled
if [[ -n "$ZSH_PROF" || -n "$ZSH_DEBUG" ]]; then
    startup_end=$SECONDS
    total_time=${startup_end:-0}

    if [[ "$ZSH_DEBUG" == "1" ]]; then
        echo "" >&2
        echo "🚀 ZSH Startup Complete!" >&2
        echo "⏱️  Total startup time: ${total_time}s" >&2
        echo "📁 Configuration: ~/.config/zsh/.zshrc.d.ng (Next Generation)" >&2
        echo "" >&2
    fi
fi

# Optional: Display shell information
if [[ "$ZSH_DEBUG" == "1" ]]; then
    echo "🔧 System Information:" >&2
    echo "   Shell: $SHELL ($ZSH_VERSION)" >&2
    echo "   OS: $(uname -s) $(uname -r)" >&2
    echo "   Terminal: ${TERM:-unknown}" >&2
    echo "   PATH entries: $(echo "$PATH" | grep -o ':' | wc -l | tr -d ' ')" >&2
    echo "   Functions loaded: $(typeset -f | grep -c '^[a-zA-Z_][a-zA-Z0-9_]* ()')" >&2
    echo "" >&2
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

    # Check essential commands
    local essential_commands=(sed tr uname dirname basename cat cc make ld)
    for cmd in "${essential_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            [[ "$ZSH_DEBUG" == "1" ]] && echo "⚠️  Missing essential command: $cmd" >&2
            ((issues++))
        fi
    done

    # Check completion system
    if ! (( ${+functions[compinit]} )); then
        [[ "$ZSH_DEBUG" == "1" ]] && echo "⚠️  Completion system not loaded" >&2
        ((issues++))
    fi

    # Check plugin system
    if ! command -v zgenom >/dev/null 2>&1; then
        [[ "$ZSH_DEBUG" == "1" ]] && echo "⚠️  Plugin system (zgenom) not available" >&2
        ((issues++))
    fi

    if [[ $issues -eq 0 && -n "$ZSH_DEBUG" ]]; then
        echo "✅ Shell health check passed!" >&2
    elif [[ $issues -gt 0 ]]; then
        echo "⚠️  $issues issues detected. Run with ZSH_DEBUG=1 for details." >&2
    fi

    return $issues
}

# Performance tips
show_performance_tips() {
    if [[ -n "$ZSH_DEBUG" && -n "$total_time" && $total_time -gt 2 ]]; then
        printf "💡 Performance Tips:\n" >&2
        printf "   - Run 'zgenom reset' to rebuild plugin cache\n" >&2
        printf "   - Check for slow plugins with 'time exec zsh'\n" >&2
        printf "   - Consider removing unused plugins\n" >&2
        printf "\n" >&2
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
        today=$(date +%Y%m%d)
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
        printf "\n🎉 Welcome to your optimized ZSH environment!\n" >&2
        printf "   Type 'help' or check aliases with 'alias'\n" >&2
        # Mark welcome as shown for today
        touch "$welcome_marker" 2>/dev/null
    fi
}

# Run the startup finalization
splash_main

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [90-finalize] Startup message complete" >&2
