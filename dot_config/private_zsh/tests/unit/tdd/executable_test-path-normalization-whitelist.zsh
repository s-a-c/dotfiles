#!/usr/bin/env zsh
# test-path-normalization-whitelist.zsh
# Compliant with [${HOME}/.config/ai/guidelines.md](${HOME}/.config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Validate whitelist behavior in enhanced PATH normalization (00-path-safety.zsh):
#     - Whitelisted nonexistent absolute path is retained (I2 exception).
#     - Non-whitelisted nonexistent path is removed.
#     - Relative paths are removed even if placed in whitelist (cannot override I3/I8).
#
# SCOPE:
#   Unit-style test (no heavy plugin sourcing). Targets invariants described in test-path-normalization-edges.zsh.
#
# SUCCESS CRITERIA:
#   1. Kept path: /tmp/zsh-whitelist-keep-A must appear exactly once in normalized PATH.
#   2. Dropped path: /tmp/zsh-whitelist-drop-B must NOT appear.
#   3. Relative whitelist entry ./rel-should-drop is NOT retained.
#
# ENV FLAGS:
#   Uses ZSH_PATH_WHITELIST for retention and default pruning settings (ZSH_PATH_ALLOW_NONEXISTENT=0).
#
# EXIT CODES:
#   0 PASS
#   1 FAIL
#   2 SKIP (if debug skip variable set)
#
# OPTIONAL SKIP (local only – do not commit with set):
#   export TDD_SKIP_PATH_WHITELIST=1
#
set -euo pipefail

if [[ "${TDD_SKIP_PATH_WHITELIST:-0}" == 1 ]]; then
    echo "SKIP: Path whitelist behavior test skipped (TDD_SKIP_PATH_WHITELIST=1)"
    exit 2
fi

# Repo root (assumes test lives under dot-config/zsh/tests/...) - use resilient helper (avoid brittle ${0:A:h})
if typeset -f zf::script_dir >/dev/null 2>&1; then
REPO_ROOT="$(cd "$(zf::script_dir "${(%):-%N}")/../../../.." && pwd -P)"
else
REPO_ROOT="$(cd "${(%):-%N:h}/../../../.." && pwd -P)"
fi
cd "$REPO_ROOT"

KEEP_PATH="/tmp/zsh-whitelist-keep-A"
DROP_PATH="/tmp/zsh-whitelist-drop-B"
REL_PATH="./rel-should-drop"

# Ensure the test paths DO NOT exist (we are testing nonexistent behavior)
rm -f "$KEEP_PATH" "$DROP_PATH" 2>/dev/null || true
rmdir "$KEEP_PATH" "$DROP_PATH" 2>/dev/null || true

# Build synthetic PATH deliberately including:
#  - keep path (should remain due to whitelist)
#  - drop path (should be pruned)
#  - relative path (should be pruned even if whitelisted attempt)
#  - standard system paths for stability
SYN_PATH="/usr/bin:${KEEP_PATH}:${DROP_PATH}:${REL_PATH}:/usr/local/bin"

# Run normalization in isolated subshell capturing PATH result and debug output
RESULT="$(
    ZSH_PATH_WHITELIST="${KEEP_PATH}:${REL_PATH}" \
        ZSH_PATH_ALLOW_NONEXISTENT=0 \
        ZSH_PATH_ALLOW_RELATIVE=0 \
        PATH="$SYN_PATH" \
        ZDOTDIR="$REPO_ROOT" \
        HOME="$HOME" \
        zsh -c '
    set -euo pipefail
    # Source .zshenv (if exists) then path module only
    [[ -f ./.zshenv ]] && source ./.zshenv
    source ./.zshrc.pre-plugins.d.REDESIGN/00-path-safety.zsh
    print -r -- "$PATH"
  ' 2>/dev/null
)"

if [[ -z "${RESULT:-}" ]]; then
    echo "FAIL: Normalization produced empty PATH"
    exit 1
fi

# Function: check presence count
count_occurrences() {
    local needle="$1"
    local haystack="$2"
    # Replace colons with newlines and grep exact match
    echo "$haystack" | tr ':' '\n' | grep -Fx "$needle" | wc -l | tr -d ' '
}

keep_count=$(count_occurrences "$KEEP_PATH" "$RESULT")
drop_count=$(count_occurrences "$DROP_PATH" "$RESULT")
rel_count=$(count_occurrences "$REL_PATH" "$RESULT")

violations=()

# Expect keep path exactly once
if [[ "$keep_count" != "1" ]]; then
    violations+="+ Expected whitelist path retained exactly once (got count=$keep_count)"
fi

# Expect drop path removed
if [[ "$drop_count" != "0" ]]; then
    violations+="+ Non-whitelisted nonexistent path present (count=$drop_count)"
fi

# Relative path must not appear (whitelist cannot override)
if [[ "$rel_count" != "0" ]]; then
    violations+="+ Relative path unexpectedly retained (count=$rel_count)"
fi

if ((${#violations[@]} > 0)); then
    echo "FAIL: Whitelist invariants not satisfied:"
    for v in "${violations[@]}"; do
        echo "  $v"
    done
    echo "---- Diagnostic ----"
    echo "Original SYN_PATH: $SYN_PATH"
    echo "Result PATH:       $RESULT"
    echo "Keep count: $keep_count | Drop count: $drop_count | Rel count: $rel_count"
    exit 1
fi

echo "PASS: Path whitelist behavior correct (keep=$KEEP_PATH retained, drop pruned, relative suppressed)"
exit 0
