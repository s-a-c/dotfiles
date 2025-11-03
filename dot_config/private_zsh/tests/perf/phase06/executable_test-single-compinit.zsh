#!/usr/bin/env zsh
# Phase 06 Test: Single compinit occurrence
# UPDATED: Consistent with .zshenv configuration
set -euo pipefail

# Source .zshenv to ensure consistent environment variables
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
[[ -f "${ZDOTDIR}/.zshenv" ]] && source "${ZDOTDIR}/.zshenv"

# Use zf::debug from .zshenv if available
if declare -f zf::debug >/dev/null 2>&1; then
    zf::debug "# [test-single-compinit] Testing single compinit execution"
fi

# Create a temporary trace file to capture compinit calls
trace_file="${TMPDIR:-/tmp}/compinit-trace-$$"
trap "rm -f '$trace_file'" EXIT

# Run ZSH in interactive mode with xtrace to capture compinit calls
PS4='+TRACE+ %N:%i ' ZDOTDIR="$ZDOTDIR" zsh -xic 'echo READY' 2>"$trace_file" >/dev/null || true

# Count compinit occurrences in the trace
compinit_count=$(grep -c 'compinit' "$trace_file" 2>/dev/null || zf::debug "0")

if [[ "$compinit_count" -eq 0 ]]; then
        zf::debug "FAIL: No compinit calls found - completion system may not be initialized"
    exit 1
elif [[ "$compinit_count" -gt 1 ]]; then
        zf::debug "FAIL: Multiple compinit calls found ($compinit_count)"
        zf::debug "This indicates redundant completion initialization"

    # Show the actual compinit calls for debugging
        zf::debug "Compinit calls found:"
    grep 'compinit' "$trace_file" | head -5 >&2
    exit 1
fi

# Test that ZSH_COMPDUMP is set correctly from .zshenv
if [[ -z "$ZSH_COMPDUMP" ]]; then
        zf::debug "FAIL: ZSH_COMPDUMP not set in .zshenv"
    exit 1
fi

# Test that completion dump file uses the correct path pattern
expected_pattern="${ZSH_CACHE_DIR}/.zcompdump-*"
if [[ "$ZSH_COMPDUMP" != ${~expected_pattern} ]]; then
        zf::debug "FAIL: ZSH_COMPDUMP does not match expected pattern"
        zf::debug "  Expected pattern: $expected_pattern"
        zf::debug "  Actual: $ZSH_COMPDUMP"
    exit 1
fi

# Test that completion dump directory is writable
compdump_dir="${ZSH_COMPDUMP:h}"
if [[ ! -d "$compdump_dir" ]]; then
        zf::debug "FAIL: Completion dump directory does not exist: $compdump_dir"
    exit 1
fi

if [[ ! -w "$compdump_dir" ]]; then
        zf::debug "FAIL: Completion dump directory is not writable: $compdump_dir"
    exit 1
fi

# Test that we can create the completion dump file
if ! touch "$ZSH_COMPDUMP" 2>/dev/null; then
        zf::debug "FAIL: Cannot create completion dump file: $ZSH_COMPDUMP"
    exit 1
fi

# Use zf::debug for success message
if declare -f zf::debug >/dev/null 2>&1; then
    zf::debug "# [test-single-compinit] Single compinit test passed"
    zf::debug "# [test-single-compinit] ZSH_COMPDUMP=$ZSH_COMPDUMP"
fi

echo "PASS: Single compinit execution verified ($compinit_count occurrence)"
