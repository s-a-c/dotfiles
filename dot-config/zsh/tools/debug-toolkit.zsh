#!/usr/bin/env zsh
# ==============================================================================
# ZSH Debugging Toolkit
# ==============================================================================
#
# This script provides a collection of functions to help diagnose and debug
# issues with the zsh configuration, such as hangs, slow startup, and early
# terminations.
#
# To use this toolkit, source it in your shell:
#
#   source tools/debug-toolkit.zsh
#
# Then, run the desired debugging function, for example:
#
#   debug::hang
#
# ==============================================================================

# Namespace for all debugging functions
namespace debug {

# ==============================================================================
# SECTION 1: HANG DETECTION
# ==============================================================================

# Function to trace execution points
trace_point() {
    local point="$1"
    echo "[$(date +%H:%M:%S.%N)] TRACE: $point"
}

# Run a command with a timeout
with_timeout() {
    local timeout_duration=$1
    shift
    local command_to_run="$@"
    timeout "$timeout_duration" zsh -c "$command_to_run"
}

hang() {
    echo "=== ZSH Debug Hang Detection ==="
    echo "This test will attempt to identify the source of a hang during startup."
    echo ""

    echo "--- Test 1: Source .zshrc without plugins ---"
    if with_timeout 5 'source $ZDOTDIR/.zshrc && echo "SUCCESS: .zshrc sourced without plugins"'; then
        echo "PASS: .zshrc sources without plugins"
    else
        echo "FAIL: Timeout sourcing .zshrc even with plugins disabled"
    fi
    echo ""

    echo "--- Test 2: Check pre-plugin loading ---"
    if with_timeout 5 'source $ZDOTDIR/.zshrc 2>&1 | head -100 && echo "Pre-plugin loading complete"'; then
        echo "PASS: Pre-plugin loading works"
    else
        echo "FAIL: Timeout in pre-plugin loading"
    fi
    echo ""

    echo "--- Test 3: Check for infinite loops in fragments ---"
    for dir in "$ZDOTDIR/.zshrc.pre-plugins.d.00" "$ZDOTDIR/.zshrc.d.00"; do
        if [[ -d "$dir" ]]; then
            echo "Checking directory: $dir"
            for file in "$dir"/*(.N); do
                if [[ -f "$file" ]]; then
                    echo -n "  Testing $file ... "
                    if with_timeout 2 "source '$file'"; then
                        echo "OK"
                    else
                        echo "TIMEOUT - potential infinite loop!"
                    fi
                fi
            done
        fi
    done
    echo ""

    echo "--- Test 4: Profile with zprof ---"
    with_timeout 5 'zmodload zsh/zprof && source $ZDOTDIR/.zshrc && zprof | head -20'
    echo ""

    echo "=== Debug Hang Detection Complete ==="
}

# ==============================================================================
# SECTION 2: EARLY TERMINATION DETECTION
# ==============================================================================

early_termination() {
    echo "=== ZSH Early Termination Debug ==="
    echo "This test will attempt to identify the source of an early termination during startup."
    echo ""

    echo "--- Test 1: .zshenv only ---"
    if with_timeout 5 'source $ZDOTDIR/.zshenv && echo "SUCCESS: .zshenv completed"'; then
        echo "PASS: .zshenv completed"
    else
        echo "FAIL: .zshenv did not complete"
    fi
    echo ""

    echo "--- Test 2: .zshrc first 100 lines ---"
    if with_timeout 5 'head -100 $ZDOTDIR/.zshrc | zsh && echo "SUCCESS: First 100 lines OK"'; then
        echo "PASS: First 100 lines of .zshrc are OK"
    else
        echo "FAIL: Problem in first 100 lines of .zshrc"
    fi
    echo ""

    echo "--- Test 3: Looking for syntax errors ---"
    zsh -n "$ZDOTDIR/.zshenv" && echo ".zshenv syntax OK" || echo ".zshenv syntax ERROR"
    zsh -n "$ZDOTDIR/.zshrc" && echo ".zshrc syntax OK" || echo ".zshrc syntax ERROR"
    echo ""

    echo "--- Test 4: Looking for exit/return commands ---"
    grep -n "exit\|return.*[0-9]" "$ZDOTDIR/.zshrc" | head -5
    echo ""

    echo "--- Test 5: Looking for set -e or errexit ---"
    grep -n "set -e\|errexit\|set.*-.*e" "$ZDOTDIR/.zshrc" "$ZDOTDIR/.zshenv" 2>/dev/null | head -5
    echo ""

    echo "=== Early Termination Debug Complete ==="
}

# ==============================================================================
# SECTION 3: STARTUP TRACE
# ==============================================================================

trace() {
    echo "=== Comprehensive ZSH Startup Trace ==="
    local trace_file="/tmp/zsh-startup-trace-$(date +%s).log"
    echo "Trace output will be saved to: $trace_file"
    echo ""

    timeout 30 env ZDOTDIR="$ZDOTDIR" ZSH_DEBUG=1 PS4='+[%D{%H:%M:%S}] %N:%i> ' zsh -x -i -c 'echo "===ZSH STARTUP COMPLETED===" && sleep 2 && echo "===EXITING ZSH===" && exit 0' > "$trace_file" 2>&1

    echo "--- Trace Analysis ---"
    echo "Trace file size: $(wc -l < "$trace_file") lines"
    echo ""

    echo "--- First 20 lines of trace ---"
    head -20 "$trace_file"
    echo ""

    echo "--- Last 20 lines of trace ---"
    tail -20 "$trace_file"
    echo ""

    echo "--- Looking for key events ---"
    echo "Lines containing 'error', 'failed', 'exit':"
    grep -i -n "error\|failed\|exit" "$trace_file" | head -10 || echo "No error/exit patterns found"
    echo ""

    echo "Lines containing startup completion markers:"
    grep -n "ZSH STARTUP COMPLETED\|baseline=\|SUCCESS" "$trace_file" || echo "No completion markers found"
    echo ""

    echo "=== Startup Trace Complete ==="
}

} # end of namespace

echo "ZSH Debugging Toolkit loaded."
echo "Available commands:"
echo "  debug::hang"
echo "  debug::early_termination"
echo "  debug::trace"
