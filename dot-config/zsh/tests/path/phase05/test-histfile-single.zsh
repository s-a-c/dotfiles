#!/usr/bin/env zsh
# Phase 05 Test: Single HISTFILE Definition
# UPDATED: Consistent with .zshenv configuration
set -euo pipefail

# Source .zshenv to ensure consistent environment variables
<<<<<<< HEAD
# Unset HISTSIZE / SAVEHIST so .zshenv default exports (very large values) are applied
# rather than any lower pre-existing shell/session values that would cause a false FAIL.
unset HISTSIZE SAVEHIST || true
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
[[ -f "${ZDOTDIR}/.zshenv" ]] && source "${ZDOTDIR}/.zshenv"

# Use zf::debug from .zshenv if available
if declare -f zf::debug >/dev/null 2>&1; then
    zf::debug "# [test-histfile-single] Testing HISTFILE configuration consistency"
=======
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
[[ -f "${ZDOTDIR}/.zshenv" ]] && source "${ZDOTDIR}/.zshenv"

# Use zsh_debug_echo from .zshenv if available
if declare -f zsh_debug_echo >/dev/null 2>&1; then
    zsh_debug_echo "# [test-histfile-single] Testing HISTFILE configuration consistency"
>>>>>>> origin/develop
fi

# Test that HISTFILE is set consistently across configuration files
expected_histfile="${ZDOTDIR}/.zsh_history"

# Check .zshenv sets HISTFILE correctly
if [[ "$HISTFILE" != "$expected_histfile" ]]; then
<<<<<<< HEAD
    zf::debug "FAIL: HISTFILE not set correctly in .zshenv"
    zf::debug "  Expected: $expected_histfile"
    zf::debug "  Actual: $HISTFILE"
=======
        zsh_debug_echo "FAIL: HISTFILE not set correctly in .zshenv"
        zsh_debug_echo "  Expected: $expected_histfile"
        zsh_debug_echo "  Actual: $HISTFILE"
>>>>>>> origin/develop
    exit 1
fi

# Test that HISTFILE directory exists and is writable
histfile_dir="${HISTFILE:h}"
if [[ ! -d "$histfile_dir" ]]; then
<<<<<<< HEAD
    zf::debug "FAIL: HISTFILE directory does not exist: $histfile_dir"
=======
        zsh_debug_echo "FAIL: HISTFILE directory does not exist: $histfile_dir"
>>>>>>> origin/develop
    exit 1
fi

if [[ ! -w "$histfile_dir" ]]; then
<<<<<<< HEAD
    zf::debug "FAIL: HISTFILE directory is not writable: $histfile_dir"
=======
        zsh_debug_echo "FAIL: HISTFILE directory is not writable: $histfile_dir"
>>>>>>> origin/develop
    exit 1
fi

# Test that we can create/touch the history file
if ! touch "$HISTFILE" 2>/dev/null; then
<<<<<<< HEAD
    zf::debug "FAIL: Cannot create/touch HISTFILE: $HISTFILE"
=======
        zsh_debug_echo "FAIL: Cannot create/touch HISTFILE: $HISTFILE"
>>>>>>> origin/develop
    exit 1
fi

# Test that HISTSIZE and SAVEHIST are set to reasonable values from .zshenv
if [[ -z "$HISTSIZE" ]] || [[ "$HISTSIZE" -lt 100000 ]]; then
<<<<<<< HEAD
    zf::debug "FAIL: HISTSIZE not set or too small: $HISTSIZE"
=======
        zsh_debug_echo "FAIL: HISTSIZE not set or too small: $HISTSIZE"
>>>>>>> origin/develop
    exit 1
fi

if [[ -z "$SAVEHIST" ]] || [[ "$SAVEHIST" -lt 100000 ]]; then
<<<<<<< HEAD
    zf::debug "FAIL: SAVEHIST not set or too small: $SAVEHIST"
    exit 1
fi

# Use zf::debug for success message
if declare -f zf::debug >/dev/null 2>&1; then
    zf::debug "# [test-histfile-single] HISTFILE configuration test passed"
    zf::debug "# [test-histfile-single] HISTFILE=$HISTFILE, HISTSIZE=$HISTSIZE, SAVEHIST=$SAVEHIST"
=======
        zsh_debug_echo "FAIL: SAVEHIST not set or too small: $SAVEHIST"
    exit 1
fi

# Use zsh_debug_echo for success message
if declare -f zsh_debug_echo >/dev/null 2>&1; then
    zsh_debug_echo "# [test-histfile-single] HISTFILE configuration test passed"
    zsh_debug_echo "# [test-histfile-single] HISTFILE=$HISTFILE, HISTSIZE=$HISTSIZE, SAVEHIST=$SAVEHIST"
>>>>>>> origin/develop
fi

echo "PASS: HISTFILE configuration working correctly"
