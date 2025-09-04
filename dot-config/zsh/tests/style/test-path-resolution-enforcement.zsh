#!/usr/bin/env zsh
# =============================================================================
# test-path-resolution-enforcement.zsh
#
# Style / Lint Test: Enforce path resolution rule (ban raw `${0:A:h}` usage)
#
# Purpose:
#   Ensures no non‑test Zsh source files (outside tests directories) use the
#   brittle `${0:A:h}` (or `${0:a:h}`) expansion directly. All new / refactored
#   code must instead use the resilient helpers:
#       zf::script_dir    or    resolve_script_dir
#
# Rationale:
#   Plugin managers and compilation phases can rewrite $0, making `${0:A:h}`
#   unreliable. Central helpers avoid mis-resolution and keep path logic
#   consistent.
#
# Mechanism:
#   Invokes tools/enforce-path-resolution.zsh in JSON mode (default excludes
#   /tests/). Fails if reported violations > 0.
#
# Skip Conditions:
#   - PATH_RESOLUTION_ENFORCE_SKIP=1 (temporary local skip; NEVER commit set)
#   - Enforcement script missing (treated as SKIP to avoid blocking early bootstraps)
#
# Assertions:
#   A1: Enforcement tool present (else SKIP)
#   A2: Invocation succeeded (non-empty JSON with expected schema)
#   A3: Violations count == 0
#
# Exit Codes:
#   0 = PASS or SKIP
#   1 = FAIL (violations detected or malformed run)
#
# Allowlist Note:
#   Individual lines can add the marker `# ALLOW_0_A_H` if an unavoidable edge
#   case arises (should be rare and justified in code review).
#
# =============================================================================

set -euo pipefail

PASS=()
FAIL=()
SKIPPED=0

pass() { PASS+=("$1"); }
fail() { FAIL+=("$1"); }
skip() { print "SKIP: $1"; SKIPPED=1; }

# Optional global debug echo (no-op fallback)
typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }

# Respect developer override (temporary only)
if [[ "${PATH_RESOLUTION_ENFORCE_SKIP:-0}" == "1" ]]; then
  skip "enforcement skip flag set (PATH_RESOLUTION_ENFORCE_SKIP=1)"
  exit 0
fi

# Determine repository root (walk up from this test file)
SCRIPT_SRC="${(%):-%N}"
if typeset -f zf::script_dir >/dev/null 2>&1; then
  TEST_DIR="$(zf::script_dir "$SCRIPT_SRC")"
else
  TEST_DIR="${SCRIPT_SRC:h}"
fi
REPO_ROOT="$(cd "${TEST_DIR}/../../.." && pwd -P)"

TOOL="${REPO_ROOT}/dot-config/zsh/tools/enforce-path-resolution.zsh"

# A1: Tool presence
if [[ ! -x "$TOOL" ]]; then
  skip "enforcement tool missing (${TOOL})"
  exit 0
else
  pass "A1: tool-present"
fi

# Run tool (exclude tests by default, JSON mode)
RAW_JSON="$(
  ZDOTDIR="${REPO_ROOT}/dot-config/zsh" \
  "$TOOL" --root "$REPO_ROOT" --json 2>/dev/null || true
)"

if [[ -z "$RAW_JSON" ]]; then
  fail "A2: tool-output-empty"
else
  if print -- "$RAW_JSON" | grep -q '"schema"[[:space:]]*:[[:space:]]*"path-resolution-enforce.v1"'; then
    pass "A2: schema"
  else
    fail "A2: schema-missing"
  fi
fi

# Extract violations (prefer jq if present)
extract_num() {
  local key="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$RAW_JSON" | jq -r --arg k "$key" '.[$k]' 2>/dev/null || true
  else
    printf '%s' "$RAW_JSON" | grep -E "\"$key\"" | head -1 | sed -E 's/.*"'$key'"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' || true
  fi
}

violations=""
if [[ -n "$RAW_JSON" ]]; then
  violations="$(extract_num violations)"
fi

if [[ -n "$violations" && "$violations" =~ ^[0-9]+$ ]]; then
  if (( violations == 0 )); then
    pass "A3: no-violations"
  else
    fail "A3: violations-present (${violations})"
    # Emit offending file summaries if jq present
    if command -v jq >/dev/null 2>&1; then
      printf '%s\n' "$RAW_JSON" | jq -r '.files[] | "VIOLATION: \(.path):\(.line) -> \(.match)"'
    else
      # Lightweight fallback grep summary
      printf '%s\n' "$RAW_JSON" | grep -E '"path"|\"line\"|\"match\"' | sed 's/[",]//g' || true
    fi
  fi
else
  fail "A3: violations-parse-error (raw='${violations:-<empty>}')"
fi

# Emit results
for p in "${PASS[@]}"; do
  print "PASS: $p"
done
for f in "${FAIL[@]}"; do
  print "FAIL: $f"
done

print "---"
print "SUMMARY: passes=${#PASS[@]} fails=${#FAIL[@]} violations=${violations:-unknown}"

if (( ${#FAIL[@]} > 0 )); then
  print -u2 "TEST RESULT: FAIL"
  exit 1
fi

if (( SKIPPED == 1 )); then
  print "TEST RESULT: SKIP"
  exit 0
fi

print "TEST RESULT: PASS"
exit 0
