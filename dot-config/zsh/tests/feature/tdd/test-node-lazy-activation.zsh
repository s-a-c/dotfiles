#!/usr/bin/env zsh
# test-node-lazy-activation.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Validate lazy activation behavior for Node/NVM pre‑plugin environment (15-node-runtime-env.zsh).
#   Ensures heavy NVM scripts are NOT sourced until the first explicit nvm invocation.
#
# SCOPE:
#   Pre-plugin phase only. Does not require full redesign load; sources the node runtime module directly.
#
# INVARIANTS (when NVM available):
#   L1: Before first call, a stub nvm() function exists containing the marker 'unfunction nvm'.
#   L2: After first invocation, the nvm() function body no longer contains the stub marker.
#   L3: Second invocation returns consistent (non-stub) behavior.
#   L4: First invocation exit code is 0 (or acceptable success) and version output is non-empty.
#
# FALLBACK (when NVM not installed):
#   - If no nvm.sh present and first invocation yields 'command not found' (exit 127), test reports SKIP
#     because lazy activation cannot be validated without an actual NVM installation.
#
# EXIT CODES:
#   0 PASS
#   1 FAIL
#   2 SKIP (NVM not installed / environment unsupported)
#
# ENV OVERRIDES:
#   TDD_SKIP_NODE_LAZY_ACTIVATION=1  -> Force SKIP (never commit with this set)
#
# IMPLEMENTATION NOTES:
#   Current module defines a stub nvm() that self-replaces on first use. We detect replacement by
#   absence of the 'unfunction nvm' line in the post-invocation function body.
#
set -euo pipefail

if [[ "${TDD_SKIP_NODE_LAZY_ACTIVATION:-0}" == "1" ]]; then
    echo "SKIP: node lazy activation test skipped (TDD_SKIP_NODE_LAZY_ACTIVATION=1)"
    exit 2
fi

REPO_ROOT="$(cd "${0:A:h}/../../../.." && pwd -P)"
cd "$REPO_ROOT"

MODULE="./.zshrc.pre-plugins.d.REDESIGN/15-node-runtime-env.zsh"
if [[ ! -f "$MODULE" ]]; then
    echo "FAIL: node runtime module missing: $MODULE"
    exit 1
fi

# Run everything in a single subshell to capture pre + post invocation state.
raw_capture="$(
    ZDOTDIR="$REPO_ROOT" \
        HOME="$HOME" \
        zsh -c '
    set -euo pipefail
    [[ -f ./.zshenv ]] && source ./.zshenv
    source '"$MODULE"'

    # Record pre-invocation function body (if any)
    if typeset -f nvm >/dev/null 2>&1; then
      echo "__PRE_PRESENT=1"
      echo "__PRE_BODY_START"
      functions nvm
      echo "__PRE_BODY_END"
    else
      echo "__PRE_PRESENT=0"
    fi

    # Perform first invocation (quietly attempt version; fallback to `nvm current`)
    nvm_cmd="--version"
    if ! nvm "$nvm_cmd" >/tmp/nvm_out_1 2>&1; then
      rc=$?
      # If version flag unsupported try plain `nvm current`
      if [[ $rc -ne 0 ]]; then
        nvm current >/tmp/nvm_out_1 2>&1 || true
      fi
    fi
    rc1=$? || true
    echo "__EXIT1=$rc1"
    echo "__OUT1_START"
    cat /tmp/nvm_out_1 2>/dev/null || true
    echo "__OUT1_END"

    # Capture post first-call function body (if exists)
    if typeset -f nvm >/dev/null 2>&1; then
      echo "__POST_BODY_START"
      functions nvm
      echo "__POST_BODY_END"
    else
      echo "__POST_BODY_START"
      echo "# MISSING_AFTER_FIRST_CALL"
      echo "__POST_BODY_END"
    fi

    # Second invocation (sanity / idempotence)
    if nvm "$nvm_cmd" >/tmp/nvm_out_2 2>&1; then
      rc2=0
    else
      rc2=$?
    fi
    echo "__EXIT2=$rc2"
    echo "__OUT2_START"
    cat /tmp/nvm_out_2 2>/dev/null || true
    echo "__OUT2_END"
  '
)"

# Helper to extract block content between markers
_extract_block() {
    local start="$1" end="$2"
    echo "$raw_capture" | awk -v s="$start" -v e="$end" '
    $0==s {flag=1; next} $0==e {flag=0} flag {print}'
}

# Parse markers
pre_present=$(echo "$raw_capture" | sed -n 's/^__PRE_PRESENT=//p' | tail -1)
exit1=$(echo "$raw_capture" | sed -n 's/^__EXIT1=//p' | tail -1)
exit2=$(echo "$raw_capture" | sed -n 's/^__EXIT2=//p' | tail -1)

pre_body=$(_extract_block "__PRE_BODY_START" "__PRE_BODY_END")
post_body=$(_extract_block "__POST_BODY_START" "__POST_BODY_END")
out1=$(_extract_block "__OUT1_START" "__OUT1_END")
out2=$(_extract_block "__OUT2_START" "__OUT2_END")

violations=()

# Detect presence of nvm.sh (for SKIP decision)
nvm_dir_detected="${NVM_DIR:-}"
# Try to detect NVM_DIR used during subshell (scrape from pre-body if unknown)
if [[ -z "$nvm_dir_detected" ]]; then
    nvm_dir_detected=$(echo "$pre_body" | grep -Eo 'NVM_DIR=["'\''][^"'\'']+' | head -1 | sed 's/.*NVM_DIR=[\"\x27]//')
fi

stub_marker_present=0
[[ "$pre_body" == *"unfunction nvm"* ]] && stub_marker_present=1

post_stub_still_present=0
[[ "$post_body" == *"unfunction nvm"* ]] && post_stub_still_present=1

# Case: NVM not installed (no function & not present)
if [[ "$pre_present" != "1" ]]; then
    echo "SKIP: nvm function not defined (NVM not installed / no lazy stub present)"
    exit 2
fi

# If first invocation exit indicates command-not-found (127) and no nvm.sh, SKIP
if [[ "$exit1" == "127" ]]; then
    echo "SKIP: nvm not installed (first call exit 127)"
    exit 2
fi

# L1: Pre body must contain stub marker
if ((stub_marker_present == 0)); then
    violations+="+ L1 expected stub marker 'unfunction nvm' in pre-body"
fi

# L2: Post body should NOT contain stub marker (should be replaced)
if ((post_stub_still_present == 1)); then
    violations+="+ L2 post-invocation function still contains stub marker"
fi

# L3: Second invocation exit should be success (0) OR equal to first (some nvm versions non-zero on version command)
if [[ "$exit2" != "0" && "$exit2" != "$exit1" ]]; then
    violations+="+ L3 second invocation exit mismatch (exit1=$exit1 exit2=$exit2)"
fi

# L4: First invocation output must be non-empty (some form of version/current)
if [[ -z "$out1" ]]; then
    violations+="+ L4 first invocation produced empty output"
fi

# Additional sanity: out2 should also be non-empty if first was
if [[ -n "$out1" && -z "$out2" ]]; then
    violations+="+ L4 second invocation unexpectedly empty output"
fi

if ((${#violations[@]} == 0)); then
    echo "PASS: Node/NVM lazy activation invariants satisfied (stub→real transition validated)"
    exit 0
fi

echo "FAIL: Node/NVM lazy activation violations:"
for v in "${violations[@]}"; do
    echo "  $v"
done

echo ""
echo "---- Diagnostics (truncated) ----"
echo "Pre body (first 10 lines):"
echo "$pre_body" | head -10 | sed 's/^/  /'
echo ""
echo "Post body (first 10 lines):"
echo "$post_body" | head -10 | sed 's/^/  /'
echo ""
echo "Exit1=$exit1 Exit2=$exit2"
echo "Output1 (first 5 lines):"
echo "$out1" | head -5 | sed 's/^/  /'
echo "Output2 (first 5 lines):"
echo "$out2" | head -5 | sed 's/^/  /'
echo "---------------------------------"

exit 1
