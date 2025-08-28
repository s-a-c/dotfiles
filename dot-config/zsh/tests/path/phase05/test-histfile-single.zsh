#!/usr/bin/env zsh
# Phase 05 Test: Single HISTFILE Definition
# UPDATED: Consistent with .zshenv configuration
set -euo pipefail

# Source .zshenv to ensure consistent environment variables
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
[[ -f "${ZDOTDIR}/.zshenv" ]] && source "${ZDOTDIR}/.zshenv"

# Use zsh_debug_echo from .zshenv if available
if declare -f zsh_debug_echo >/dev/null 2>&1; then
    zsh_debug_echo "# [test-histfile-single] Testing HISTFILE configuration consistency"
fi

# Test that HISTFILE is set consistently across configuration files
expected_histfile="${ZDOTDIR}/.zsh_history"

# Check .zshenv sets HISTFILE correctly
if [[ "$HISTFILE" != "$expected_histfile" ]]; then
        zsh_debug_echo "FAIL: HISTFILE not set correctly in .zshenv"
        zsh_debug_echo "  Expected: $expected_histfile"
        zsh_debug_echo "  Actual: $HISTFILE"
    exit 1
fi

# Test that HISTFILE directory exists and is writable
histfile_dir="${HISTFILE:h}"
if [[ ! -d "$histfile_dir" ]]; then
        zsh_debug_echo "FAIL: HISTFILE directory does not exist: $histfile_dir"
    exit 1
fi

if [[ ! -w "$histfile_dir" ]]; then
        zsh_debug_echo "FAIL: HISTFILE directory is not writable: $histfile_dir"
    exit 1
fi

# Test that we can create/touch the history file
if ! touch "$HISTFILE" 2>/dev/null; then
        zsh_debug_echo "FAIL: Cannot create/touch HISTFILE: $HISTFILE"
    exit 1
fi

# Test that HISTSIZE and SAVEHIST are set to reasonable values from .zshenv
if [[ -z "$HISTSIZE" ]] || [[ "$HISTSIZE" -lt 100000 ]]; then
        zsh_debug_echo "FAIL: HISTSIZE not set or too small: $HISTSIZE"
    exit 1
fi

if [[ -z "$SAVEHIST" ]] || [[ "$SAVEHIST" -lt 100000 ]]; then
        zsh_debug_echo "FAIL: SAVEHIST not set or too small: $SAVEHIST"
    exit 1
fi

# Use zsh_debug_echo for success message
if declare -f zsh_debug_echo >/dev/null 2>&1; then
    zsh_debug_echo "# [test-histfile-single] HISTFILE configuration test passed"
    zsh_debug_echo "# [test-histfile-single] HISTFILE=$HISTFILE, HISTSIZE=$HISTSIZE, SAVEHIST=$SAVEHIST"
fi

echo "PASS: HISTFILE configuration working correctly"
