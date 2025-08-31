#!/usr/bin/env zsh
# test-postplugin-compinit-single-run.zsh
# Verifies:
#    - Post-plugin redesign path runs compinit only once (guarded by _COMPINIT_DONE)
#    - ZSH_ENABLE_POSTPLUGIN_REDESIGN=1 enables redesigned completion module
#    - second invocation does not rewrite compdump (timestamp unchanged)
#    - compdump path is consistent across invocations
set -euo pipefail

ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
[[ -f "${ZDOTDIR}/.zshenv" ]] && source "${ZDOTDIR}/.zshenv"

# Enable post-plugin redesign for this test
export ZSH_ENABLE_POSTPLUGIN_REDESIGN=1

# Check that redesigned completion module exists
COMPLETION_MODULE="${ZDOTDIR}/.zshrc.d.REDESIGN/50-completion-history.zsh"
if [[ ! -f "$COMPLETION_MODULE" ]]; then
    echo "FAIL: redesigned completion module missing: $COMPLETION_MODULE" >&2
    exit 1
fi

# Ensure clean guard state for test (new subshell guarantees isolation)
unset _COMPINIT_DONE || true

# Determine expected compdump path (prefer ZGEN_CUSTOM_COMPDUMP, fallback)
COMPDUMP_PATH="${ZGEN_CUSTOM_COMPDUMP:-${ZSH_COMPDUMP:-${ZDOTDIR}/.zcompdump}}"

# Remove existing compdump to force creation
rm -f "$COMPDUMP_PATH" 2>/dev/null || true

# First run: source the redesigned completion module directly
source "$COMPLETION_MODULE"

if [[ -z ${_COMPINIT_DONE:-} ]]; then
    echo "FAIL: _COMPINIT_DONE not set after first init (redesign path)" >&2
    exit 1
fi

if [[ ! -f "$COMPDUMP_PATH" ]]; then
    echo "FAIL: compdump not created at $COMPDUMP_PATH (redesign path)" >&2
    exit 1
fi

# Capture timestamp
if stat -f %m "$COMPDUMP_PATH" >/dev/null 2>&1; then
    TS1=$(stat -f %m "$COMPDUMP_PATH")
elif stat -c %Y "$COMPDUMP_PATH" >/dev/null 2>&1; then
    TS1=$(stat -c %Y "$COMPDUMP_PATH")
else
    TS1=0
fi

# Second run: source again (should no-op due to sentinel)
source "$COMPLETION_MODULE"

if [[ ${_COMPINIT_DONE:-0} -ne 1 ]]; then
    echo "FAIL: _COMPINIT_DONE altered after second init (redesign path)" >&2
    exit 1
fi

# Re-check timestamp
if stat -f %m "$COMPDUMP_PATH" >/dev/null 2>&1; then
    TS2=$(stat -f %m "$COMPDUMP_PATH")
elif stat -c %Y "$COMPDUMP_PATH" >/dev/null 2>&1; then
    TS2=$(stat -c %Y "$COMPDUMP_PATH")
else
    TS2=$TS1
fi

if [[ "$TS1" != "$TS2" ]]; then
    echo "FAIL: compdump timestamp changed; compinit likely re-ran ($TS1 -> $TS2) (redesign path)" >&2
    exit 1
fi

# Basic sanity: ensure only one compdump file variant
COUNT=$(ls -1 "${COMPDUMP_PATH}"* 2>/dev/null | wc -l | tr -d ' ') || COUNT=1
if [[ $COUNT -gt 2 ]]; then
    echo "FAIL: Multiple compdump variants detected (${COUNT}) (redesign path)" >&2
    exit 1
fi

# Verify that the module loaded sentinel is set
if [[ -z ${_LOADED_POST_PLUGIN_50_COMPLETION_HISTORY:-} ]]; then
    echo "FAIL: redesigned completion module sentinel not set" >&2
    exit 1
fi

echo "PASS: single compinit run via post-plugin redesign; compdump stable at $COMPDUMP_PATH"
unset ZSH_ENABLE_POSTPLUGIN_REDESIGN
exit 0
