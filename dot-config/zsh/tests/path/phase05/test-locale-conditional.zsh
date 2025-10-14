#!/usr/bin/env zsh
# Phase 05 Test: Locale Conditional Export
# UPDATED: Consistent with .zshenv configuration
set -euo pipefail

# Source .zshenv to ensure consistent environment variables
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
[[ -f "${ZDOTDIR}/.zshenv" ]] && source "${ZDOTDIR}/.zshenv"

<<<<<<< HEAD
# Use zf::debug from .zshenv if available
if declare -f zf::debug >/dev/null 2>&1; then
    zf::debug "# [test-locale-conditional] Testing locale configuration consistency"
=======
# Use zsh_debug_echo from .zshenv if available
if declare -f zsh_debug_echo >/dev/null 2>&1; then
    zsh_debug_echo "# [test-locale-conditional] Testing locale configuration consistency"
>>>>>>> origin/develop
fi

# Test that locale variables are set correctly from .zshenv
expected_lang='en_GB.UTF-8'
expected_lc_all='en_GB.UTF-8'

# Check LANG is set correctly
if [[ "$LANG" != "$expected_lang" ]]; then
<<<<<<< HEAD
        zf::debug "FAIL: LANG not set correctly in .zshenv"
        zf::debug "  Expected: $expected_lang"
        zf::debug "  Actual: $LANG"
=======
        zsh_debug_echo "FAIL: LANG not set correctly in .zshenv"
        zsh_debug_echo "  Expected: $expected_lang"
        zsh_debug_echo "  Actual: $LANG"
>>>>>>> origin/develop
    exit 1
fi

# Check LC_ALL is set correctly
if [[ "$LC_ALL" != "$expected_lc_all" ]]; then
<<<<<<< HEAD
        zf::debug "FAIL: LC_ALL not set correctly in .zshenv"
        zf::debug "  Expected: $expected_lc_all"
        zf::debug "  Actual: $LC_ALL"
=======
        zsh_debug_echo "FAIL: LC_ALL not set correctly in .zshenv"
        zsh_debug_echo "  Expected: $expected_lc_all"
        zsh_debug_echo "  Actual: $LC_ALL"
>>>>>>> origin/develop
    exit 1
fi

# Test that locale settings are properly available in subshells
subshell_lang=$(zsh -c 'echo $LANG')
if [[ "$subshell_lang" != "$expected_lang" ]]; then
<<<<<<< HEAD
        zf::debug "FAIL: LANG not properly exported to subshells"
        zf::debug "  Expected: $expected_lang"
        zf::debug "  Actual: $subshell_lang"
=======
        zsh_debug_echo "FAIL: LANG not properly exported to subshells"
        zsh_debug_echo "  Expected: $expected_lang"
        zsh_debug_echo "  Actual: $subshell_lang"
>>>>>>> origin/develop
    exit 1
fi

# Test that locale command works with our settings
if command -v locale >/dev/null 2>&1; then
    if ! locale -a | grep -q "en_GB.UTF-8" 2>/dev/null; then
<<<<<<< HEAD
            zf::debug "WARN: en_GB.UTF-8 locale may not be available on this system"
=======
            zsh_debug_echo "WARN: en_GB.UTF-8 locale may not be available on this system"
>>>>>>> origin/develop
        # This is a warning, not a failure, as locale availability varies by system
    fi
fi

# Test TIME_STYLE is set for consistent date formatting
if [[ -z "$TIME_STYLE" ]]; then
<<<<<<< HEAD
        zf::debug "FAIL: TIME_STYLE not set in .zshenv"
=======
        zsh_debug_echo "FAIL: TIME_STYLE not set in .zshenv"
>>>>>>> origin/develop
    exit 1
fi

if [[ "$TIME_STYLE" != "long-iso" ]]; then
<<<<<<< HEAD
        zf::debug "FAIL: TIME_STYLE not set to expected value"
        zf::debug "  Expected: long-iso"
        zf::debug "  Actual: $TIME_STYLE"
    exit 1
fi

# Use zf::debug for success message
if declare -f zf::debug >/dev/null 2>&1; then
    zf::debug "# [test-locale-conditional] Locale configuration test passed"
    zf::debug "# [test-locale-conditional] LANG=$LANG, LC_ALL=$LC_ALL, TIME_STYLE=$TIME_STYLE"
=======
        zsh_debug_echo "FAIL: TIME_STYLE not set to expected value"
        zsh_debug_echo "  Expected: long-iso"
        zsh_debug_echo "  Actual: $TIME_STYLE"
    exit 1
fi

# Use zsh_debug_echo for success message
if declare -f zsh_debug_echo >/dev/null 2>&1; then
    zsh_debug_echo "# [test-locale-conditional] Locale configuration test passed"
    zsh_debug_echo "# [test-locale-conditional] LANG=$LANG, LC_ALL=$LC_ALL, TIME_STYLE=$TIME_STYLE"
>>>>>>> origin/develop
fi

echo "PASS: Locale configuration working correctly"
