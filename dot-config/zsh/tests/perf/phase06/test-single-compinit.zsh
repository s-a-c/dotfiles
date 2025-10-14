#!/usr/bin/env zsh
# Phase 06 Test: Single compinit occurrence
# UPDATED: Consistent with .zshenv configuration
set -euo pipefail

# Source .zshenv to ensure consistent environment variables
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
[[ -f "${ZDOTDIR}/.zshenv" ]] && source "${ZDOTDIR}/.zshenv"

<<<<<<< HEAD
# Use zf::debug from .zshenv if available
if declare -f zf::debug >/dev/null 2>&1; then
    zf::debug "# [test-single-compinit] Testing single compinit execution"
=======
# Use zsh_debug_echo from .zshenv if available
if declare -f zsh_debug_echo >/dev/null 2>&1; then
    zsh_debug_echo "# [test-single-compinit] Testing single compinit execution"
>>>>>>> origin/develop
fi

# Create a temporary trace file to capture compinit calls
trace_file="${TMPDIR:-/tmp}/compinit-trace-$$"
trap "rm -f '$trace_file'" EXIT

# Run ZSH in interactive mode with xtrace to capture compinit calls
PS4='+TRACE+ %N:%i ' ZDOTDIR="$ZDOTDIR" zsh -xic 'echo READY' 2>"$trace_file" >/dev/null || true

# Count compinit occurrences in the trace
<<<<<<< HEAD
compinit_count=$(grep -c 'compinit' "$trace_file" 2>/dev/null || zf::debug "0")

if [[ "$compinit_count" -eq 0 ]]; then
        zf::debug "FAIL: No compinit calls found - completion system may not be initialized"
    exit 1
elif [[ "$compinit_count" -gt 1 ]]; then
        zf::debug "FAIL: Multiple compinit calls found ($compinit_count)"
        zf::debug "This indicates redundant completion initialization"

    # Show the actual compinit calls for debugging
        zf::debug "Compinit calls found:"
=======
compinit_count=$(grep -c 'compinit' "$trace_file" 2>/dev/null || zsh_debug_echo "0")

if [[ "$compinit_count" -eq 0 ]]; then
        zsh_debug_echo "FAIL: No compinit calls found - completion system may not be initialized"
    exit 1
elif [[ "$compinit_count" -gt 1 ]]; then
        zsh_debug_echo "FAIL: Multiple compinit calls found ($compinit_count)"
        zsh_debug_echo "This indicates redundant completion initialization"

    # Show the actual compinit calls for debugging
        zsh_debug_echo "Compinit calls found:"
>>>>>>> origin/develop
    grep 'compinit' "$trace_file" | head -5 >&2
    exit 1
fi

# Test that ZSH_COMPDUMP is set correctly from .zshenv
if [[ -z "$ZSH_COMPDUMP" ]]; then
<<<<<<< HEAD
        zf::debug "FAIL: ZSH_COMPDUMP not set in .zshenv"
=======
        zsh_debug_echo "FAIL: ZSH_COMPDUMP not set in .zshenv"
>>>>>>> origin/develop
    exit 1
fi

# Test that completion dump file uses the correct path pattern
expected_pattern="${ZSH_CACHE_DIR}/.zcompdump-*"
if [[ "$ZSH_COMPDUMP" != ${~expected_pattern} ]]; then
<<<<<<< HEAD
        zf::debug "FAIL: ZSH_COMPDUMP does not match expected pattern"
        zf::debug "  Expected pattern: $expected_pattern"
        zf::debug "  Actual: $ZSH_COMPDUMP"
=======
        zsh_debug_echo "FAIL: ZSH_COMPDUMP does not match expected pattern"
        zsh_debug_echo "  Expected pattern: $expected_pattern"
        zsh_debug_echo "  Actual: $ZSH_COMPDUMP"
>>>>>>> origin/develop
    exit 1
fi

# Test that completion dump directory is writable
compdump_dir="${ZSH_COMPDUMP:h}"
if [[ ! -d "$compdump_dir" ]]; then
<<<<<<< HEAD
        zf::debug "FAIL: Completion dump directory does not exist: $compdump_dir"
=======
        zsh_debug_echo "FAIL: Completion dump directory does not exist: $compdump_dir"
>>>>>>> origin/develop
    exit 1
fi

if [[ ! -w "$compdump_dir" ]]; then
<<<<<<< HEAD
        zf::debug "FAIL: Completion dump directory is not writable: $compdump_dir"
=======
        zsh_debug_echo "FAIL: Completion dump directory is not writable: $compdump_dir"
>>>>>>> origin/develop
    exit 1
fi

# Test that we can create the completion dump file
if ! touch "$ZSH_COMPDUMP" 2>/dev/null; then
<<<<<<< HEAD
        zf::debug "FAIL: Cannot create completion dump file: $ZSH_COMPDUMP"
    exit 1
fi

# Use zf::debug for success message
if declare -f zf::debug >/dev/null 2>&1; then
    zf::debug "# [test-single-compinit] Single compinit test passed"
    zf::debug "# [test-single-compinit] ZSH_COMPDUMP=$ZSH_COMPDUMP"
=======
        zsh_debug_echo "FAIL: Cannot create completion dump file: $ZSH_COMPDUMP"
    exit 1
fi

# Use zsh_debug_echo for success message
if declare -f zsh_debug_echo >/dev/null 2>&1; then
    zsh_debug_echo "# [test-single-compinit] Single compinit test passed"
    zsh_debug_echo "# [test-single-compinit] ZSH_COMPDUMP=$ZSH_COMPDUMP"
>>>>>>> origin/develop
fi

echo "PASS: Single compinit execution verified ($compinit_count occurrence)"
