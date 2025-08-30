#!/usr/bin/env zsh
# test-compinit-single-run.zsh
# Verifies:
#    - minimal-completion-init runs compinit only once (guarded by _COMPINIT_DONE)
#    - second invocation does not rewrite compdump (timestamp unchanged)
#    - compdump path is consistent across invocations
set -euo pipefail

ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
[[ -f "${ZDOTDIR}/.zshenv" ]] && source "${ZDOTDIR}/.zshenv"

INIT_SCRIPT="${ZDOTDIR}/tools/minimal-completion-init.zsh"
if [[ ! -f $INIT_SCRIPT ]]; then
    echo "FAIL: init script missing: $INIT_SCRIPT" >&2
    exit 1
fi

# Ensure clean guard state for test (new subshell guarantees isolation)
unset _COMPINIT_DONE || true

# Determine expected compdump path (prefer ZGEN_CUSTOM_COMPDUMP, fallback)
COMPDUMP_PATH="${ZGEN_CUSTOM_COMPDUMP:-${ZSH_COMPDUMP:-${ZDOTDIR}/.zcompdump}}"

# Remove existing compdump to force creation
rm -f "$COMPDUMP_PATH" 2>/dev/null || true

# First run
source "$INIT_SCRIPT"
if [[ -z ${_COMPINIT_DONE:-} ]]; then
    echo "FAIL: _COMPINIT_DONE not set after first init" >&2
    exit 1
fi
if [[ ! -f "$COMPDUMP_PATH" ]]; then
    echo "FAIL: compdump not created at $COMPDUMP_PATH" >&2
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

# Second run (should no-op)
source "$INIT_SCRIPT"
if [[ ${_COMPINIT_DONE:-0} -ne 1 ]]; then
    echo "FAIL: _COMPINIT_DONE altered after second init" >&2
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
    echo "FAIL: compdump timestamp changed; compinit likely re-ran ($TS1 -> $TS2)" >&2
    exit 1
fi

# Basic sanity: ensure only one compdump file variant
COUNT=$(ls -1 "${COMPDUMP_PATH}"* 2>/dev/null | wc -l | tr -d ' ') || COUNT=1
if [[ $COUNT -gt 2 ]]; then
    echo "FAIL: Multiple compdump variants detected (${COUNT})" >&2
    exit 1
fi

echo "PASS: single compinit run; compdump stable at $COMPDUMP_PATH"
exit 0
