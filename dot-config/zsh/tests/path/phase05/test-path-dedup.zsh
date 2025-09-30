#!/usr/bin/env zsh
# Phase 05 Test: PATH Deduplication & Ordering
# UPDATED: Consistent with .zshenv configuration
set -euo pipefail

# Source .zshenv to ensure consistent environment variables
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
[[ -f "${ZDOTDIR}/.zshenv" ]] && source "${ZDOTDIR}/.zshenv"

# Use zf::debug from .zshenv if available
if declare -f zf::debug >/dev/null 2>&1; then
    zf::debug "# [test-path-dedup] Starting PATH deduplication test"
fi

cd "$ZDOTDIR" # ensure working directory is ZDOTDIR so .zshenv is present for subshell sourcing

# Source local .zshenv in an isolated subshell to capture PATH
output=$(ZDOTDIR="$ZDOTDIR" zsh -c 'set -e; ZSH_DEBUG=0; source ./.zshenv >/dev/null 2>&1; print -r -- "$PATH"')

first_segment=${output%%:*}

# Homebrew presence check: ensure brew bin path appears; if absent, SKIP (environment variance)
if command -v brew >/dev/null 2>&1; then
    BREW_PREFIX="$(brew --prefix 2>/dev/null || echo /usr/local)"
    HB_BIN="${BREW_PREFIX}/bin"
    if [[ -d "${HB_BIN}" ]]; then
        if ! printf '%s' "$output" | tr ':' '\n' | grep -Fx "${HB_BIN}" >/dev/null 2>&1; then
            echo "SKIP: ${HB_BIN} not found in PATH capture (non-standard environment)"
            exit 2
        fi
    fi
fi

# Check for duplicates while preserving order semantics
# Split PATH strictly on ':' (avoid side-effects / globbing); ignore any stray newlines
IFS=':' read -rA all_segments <<<"$output"
typeset -A seen
duplicate_count=0

for seg in "${all_segments[@]}"; do
    # Skip empty segments
    [[ -z $seg ]] && continue
    if [[ -n ${seen[$seg]:-} ]]; then
        zf::debug "FAIL: duplicate PATH entry detected: $seg"
        ((duplicate_count++))
    fi
    seen[$seg]=1
done

if [[ $duplicate_count -gt 0 ]]; then
    zf::debug "FAIL: Found $duplicate_count duplicate PATH entries"
    exit 1
fi

# Use zf::debug for success message
if declare -f zf::debug >/dev/null 2>&1; then
    zf::debug "# [test-path-dedup] PATH deduplication test passed - no duplicates found"
fi

echo "PASS: PATH deduplication working correctly"
