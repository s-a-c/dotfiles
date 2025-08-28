#!/usr/bin/env zsh
# Phase 05 Test: PATH Deduplication & Ordering
# UPDATED: Consistent with .zshenv configuration
set -euo pipefail

# Source .zshenv to ensure consistent environment variables
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
[[ -f "${ZDOTDIR}/.zshenv" ]] && source "${ZDOTDIR}/.zshenv"

# Use zsh_debug_echo from .zshenv if available
if declare -f zsh_debug_echo >/dev/null 2>&1; then
    zsh_debug_echo "# [test-path-dedup] Starting PATH deduplication test"
fi

cd "${0:A:h}/../../../.."  # move to repo root (dot-config/zsh)

# Source local .zshenv in an isolated subshell to capture PATH
output=$(ZDOTDIR="$ZDOTDIR" zsh -c 'set -e; source ./.zshenv; print -r -- $PATH')

first_segment=${output%%:*}

# Use dynamic Homebrew detection consistent with .zshenv
if command -v brew >/dev/null 2>&1; then
    BREW_PREFIX="$(brew --prefix 2>/dev/null || zsh_debug_echo '/opt/homebrew')"
    if [[ -d "${BREW_PREFIX}/bin" ]]; then
        if [[ $first_segment != "${BREW_PREFIX}/bin" ]]; then
                zsh_debug_echo "FAIL: ${BREW_PREFIX}/bin expected first, got $first_segment"
            exit 1
        fi
    fi
fi

# Check for duplicates while preserving order semantics
nl=$'\n'
all_segments=(${(s/:/)output})
typeset -A seen
duplicate_count=0

for seg in "${all_segments[@]}"; do
    # Skip empty segments
    [[ -z $seg ]] && continue
    if [[ -n ${seen[$seg]:-} ]]; then
            zsh_debug_echo "FAIL: duplicate PATH entry detected: $seg"
        ((duplicate_count++))
    fi
    seen[$seg]=1
done

if [[ $duplicate_count -gt 0 ]]; then
        zsh_debug_echo "FAIL: Found $duplicate_count duplicate PATH entries"
    exit 1
fi

# Use zsh_debug_echo for success message
if declare -f zsh_debug_echo >/dev/null 2>&1; then
    zsh_debug_echo "# [test-path-dedup] PATH deduplication test passed - no duplicates found"
fi

echo "PASS: PATH deduplication working correctly"
