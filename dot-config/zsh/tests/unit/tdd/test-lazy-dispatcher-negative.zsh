#!/usr/bin/env zsh
# test-lazy-dispatcher-negative.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Validate negative / error paths AND successful paths of the enhanced lazy framework
#   (10-lazy-framework.zsh). This test now represents an ACTIVE gate — it must PASS
#   when the framework provides required semantics.
#
# COVERED SCENARIOS:
#   R1 Missing loader (invoking unregistered command) emits 'no loader'
#   R2 Recursion guard triggers and produces 'RECURSION_GUARD' + non-zero exit
#   R3 Failing loader (non-zero exit; no function) marks state failed and emits 'loader failed'
#   R4 Partial loader (defines function then returns non-zero) treated as failure; subsequent call still fails
#   R5 Successful loader defines function, subsequent calls bypass dispatcher (idempotent)
#   R6 list_lazy_commands reflects state 'loaded' for a successful command
#
# EXIT CODES (from framework reference):
#   3 no loader, 4 loader exit failure, 5 recursion guard, 6 loader missing definition
#
# TEST PASS CRITERIA:
#   All assertions satisfied (no accumulated violations).
#
# TEMPORARY SKIP (local only, do not commit with set):
#   export TDD_SKIP_LAZY_NEG=1
#
set -euo pipefail

if [[ "${TDD_SKIP_LAZY_NEG:-0}" == 1 ]]; then
    echo "SKIP: Lazy dispatcher negative test skipped (TDD_SKIP_LAZY_NEG=1)"
    exit 0
fi

REPO_ROOT="$(cd "${0:A:h}/../../../../" && pwd -P)"
cd "$REPO_ROOT"

violations=()

# Run in isolated subshell to avoid polluting parent shell; capture a structured dump.
diagnostics="$(
    zsh -c '
    set -euo pipefail
    source ./.zshenv 2>/dev/null || true
    fw="./.zshrc.pre-plugins.d.REDESIGN/10-lazy-framework.zsh"
    [[ -f $fw ]] || { echo "__ERROR:missing_framework__"; exit 99; }
    source "$fw"

    # ---- Define loaders ----
    # Recursion loader: calls the command while state=loading to trigger guard
    _rec_loader() {
      # Call stub inside loader to trigger recursion detection
      lazyrecursion inner 2>/dev/null || true
      # If guard worked, we should NOT reach real replacement path for first attempt
      lazyrecursion() { echo "lazyrecursion-real $*"; }
      return 0
    }
    lazy_register lazyrecursion _rec_loader >/dev/null 2>&1 || true
    rec_first_out="$(lazyrecursion first 2>&1 || echo "__EXIT_$?")"

    # Missing loader: just call an unknown command
    missing_out="$(ghostcmd 2>&1 || echo \"__EXIT_$?\")"

    # Failing loader: returns non-zero; defines nothing
    _fail_loader() { return 7; }
    lazy_register failcmd _fail_loader >/dev/null 2>&1 || true
    fail_out="$(failcmd 2>&1 || echo \"__EXIT_$?\")"
    fail_second="$(failcmd 2>&1 || echo \"__EXIT_$?\")"

    # Partial loader: defines function then returns non-zero (should count as failure)
    _partial_loader() {
      partialcmd() { echo partial-ok; }
      return 3
    }
    lazy_register partialcmd _partial_loader >/dev/null 2>&1 || true
    partial_first="$(partialcmd 2>&1 || echo \"__EXIT_$?\")"
    partial_second="$(partialcmd 2>&1 || echo \"__EXIT_$?\")"

    # Successful loader
    _ok_loader() {
      okcmd() { echo ok-success; }
      return 0
    }
    lazy_register okcmd _ok_loader >/dev/null 2>&1 || true
    ok_first="$(okcmd 2>&1 || echo \"__EXIT_$?\")"
    ok_second="$(okcmd 2>&1 || echo \"__EXIT_$?\")"

    # Capture list output (post loads)
    list_snapshot="$(list_lazy_commands 2>/dev/null || true)"

    echo "rec_first_out=$rec_first_out"
    echo "missing_out=$missing_out"
    echo "fail_out=$fail_out"
    echo "fail_second=$fail_second"
    echo "partial_first=$partial_first"
    echo "partial_second=$partial_second"
    echo "ok_first=$ok_first"
    echo "ok_second=$ok_second"
    echo "list_snapshot=$list_snapshot"
  '
)"

if [[ "$diagnostics" == "__ERROR:missing_framework__" ]]; then
    echo "FAIL: lazy framework file missing"
    exit 1
fi

typeset -A D
while IFS='=' read -r k v; do
    [[ -z $k ]] && continue
    D[$k]="$v"
done <<<"$diagnostics"

# R1: Missing loader
if [[ "${D[missing_out]}" != *"no loader registered"* ]]; then
    violations+="+ R1 missing loader message absent (got='${D[missing_out]}')"
fi

# R2: Recursion guard
if [[ "${D[rec_first_out]}" != *"RECURSION_GUARD"* ]]; then
    violations+="+ R2 recursion guard marker missing (out='${D[rec_first_out]}')"
fi

# R3: Failing loader (non-zero exit, no function). Expect loader failed or __EXIT_4 or similar message.
if [[ "${D[fail_out]}" != *"loader failed"* && "${D[fail_out]}" != *__EXIT_4* ]]; then
    violations+="+ R3 failing loader did not surface expected error (out='${D[fail_out]}')"
fi
# Subsequent call should not succeed (still error)
if [[ "${D[fail_second]}" != *"prior load failed"* && "${D[fail_second]}" != *__EXIT_4* ]]; then
    violations+="+ R3 second failing loader call not persistent failure (out='${D[fail_second]}')"
fi

# R4: Partial loader failure pattern
if [[ "${D[partial_first]}" != *"loader failed"* && "${D[partial_first]}" != *__EXIT_4* ]]; then
    violations+="+ R4 partial loader first call not treated as failure (out='${D[partial_first]}')"
fi
if [[ "${D[partial_second]}" != *"prior load failed"* && "${D[partial_second]}" != *__EXIT_4* ]]; then
    violations+="+ R4 partial loader second call not persistent failure (out='${D[partial_second]}')"
fi

# R5: Successful loader idempotence
if [[ "${D[ok_first]}" != "ok-success" ]]; then
    violations+="+ R5 ok loader first call incorrect output (${D[ok_first]})"
fi
if [[ "${D[ok_second]}" != "ok-success" ]]; then
    violations+="+ R5 ok loader second call incorrect output (${D[ok_second]})"
fi

# R6: list snapshot includes okcmd:loaded
if [[ "${D[list_snapshot]}" != *"okcmd:loaded"* ]]; then
    violations+="+ R6 list_lazy_commands snapshot missing okcmd:loaded (snapshot='${D[list_snapshot]}')"
fi

if ((${#violations[@]} == 0)); then
    echo "PASS: Lazy framework negative & success path validation passed"
    exit 0
fi

echo "FAIL: Lazy framework negative test violations:"
for v in "${violations[@]}"; do
    echo "  $v"
done
echo ""
echo "---- Diagnostics ----"
echo "$diagnostics" | sed 's/^/  /'
exit 1
