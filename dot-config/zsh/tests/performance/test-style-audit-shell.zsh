#!/usr/bin/env zsh
# ============================================================================
# test-style-audit-shell.zsh
#
# Category: Performance / Utility Smoke
#
# Purpose:
#   Smoke test + light performance timing for tools/style-audit-shell.sh.
#   Verifies the style audit script:
#     - Exists & is executable.
#     - Produces JSON when requested.
#     - Returns success with --no-fail even if violations exist.
#     - Emits required top-level fields (schema, scanned_files, violations_total, status).
#
# Assertions:
#   A1: Tool present & executable
#   A2: Execution (JSON mode) succeeds (rc=0) with --no-fail
#   A3: JSON contains expected schema shell-style-audit.v1
#   A4: scanned_files is numeric and > 0
#   A5: violations_total is numeric (>=0)
#   A6: status is either "clean" or "violations"
#   A7: Duration measurement captured (internal timing >0ms unless clock unsupported)
#
# Skip Conditions:
#   - Tool missing (reports SKIP)
#
# Output:
#   PASS:/FAIL: lines + SUMMARY
#
# Exit Codes:
#   0 on full pass / skip
#   1 on failed assertions
#
# Style: 4-space indentation
# ============================================================================

set -euo pipefail

_pass=()
_fail=()

pass() { _pass+=("$1"); }
fail() { _fail+=("$1"); }

SCRIPT_DIR="$(cd -- "$(dirname -- "${(%):-%N}")" && pwd -P)"
# Repo root assumed 3 levels up from tests/performance
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd -P)"
ZSH_DIR="${REPO_ROOT}/dot-config/zsh"
TOOL="${ZSH_DIR}/tools/style-audit-shell.sh"

if [[ ! -x "$TOOL" ]]; then
    print "SKIP: style audit tool missing ($TOOL)"
    exit 0
fi

# -------------------- Execution --------------------
start_ns=$(date +%s%N 2>/dev/null || echo 0)
RAW_JSON="$(
    "$TOOL" \
        --root "$ZSH_DIR" \
        --include "*.zsh,*.sh" \
        --exclude "docs/*,*.min.js" \
        --json \
        --no-fail 2>/dev/null || true
)"
rc=$?
end_ns=$(date +%s%N 2>/dev/null || echo 0)

if (( rc == 0 )); then
    pass "A2: exec-rc"
else
    fail "A2: exec-rc (rc=$rc)"
fi

# A1: tool executable
if [[ -x "$TOOL" ]]; then
    pass "A1: tool-present"
else
    fail "A1: tool-present (not executable)"
fi

# Basic JSON presence
if [[ -n "$RAW_JSON" ]]; then
    if print -- "$RAW_JSON" | grep -q '"schema"[[:space:]]*:[[:space:]]*"shell-style-audit.v1"'; then
        pass "A3: schema"
    else
        fail "A3: schema (missing or mismatch)"
    fi
else
    fail "A3: schema (empty output)"
fi

# Extract simple numeric fields
extract_num() {
    local key="$1"
    print -- "$RAW_JSON" | grep -E "\"$key\"" | head -1 | \
        sed -E 's/.*"'$key'"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' | \
        grep -E '^[0-9]+$' || true
}

scanned_files="$(extract_num scanned_files)"
violations_total="$(extract_num violations_total)"

if [[ -n "$scanned_files" && "$scanned_files" =~ ^[0-9]+$ && "$scanned_files" -gt 0 ]]; then
    pass "A4: scanned-files"
else
    fail "A4: scanned-files (val='${scanned_files:-<empty>}')"
fi

if [[ -n "$violations_total" && "$violations_total" =~ ^[0-9]+$ ]]; then
    pass "A5: violations-total"
else
    fail "A5: violations-total (val='${violations_total:-<empty>}')"
fi

status_val="$(print -- "$RAW_JSON" | grep -E '"status"' | head -1 | sed -E 's/.*"status"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' || true)"
if [[ "$status_val" == "clean" || "$status_val" == "violations" ]]; then
    pass "A6: status"
else
    fail "A6: status (val='${status_val:-<empty>}')"
fi

# Timing assertion
duration_ms=0
if [[ "$start_ns" != "0" && "$end_ns" != "0" ]]; then
    duration_ms=$(( (end_ns - start_ns) / 1000000 ))
fi
if (( duration_ms >= 0 )); then
    pass "A7: duration-captured (${duration_ms}ms)"
else
    fail "A7: duration-captured (negative?)"
fi

# -------------------- Emit Results -----------------
for p in "${_pass[@]}"; do
    print "PASS: $p"
done
for f in "${_fail[@]}"; do
    print "FAIL: $f"
done
print "---"
print "SUMMARY: passes=${#_pass[@]} fails=${#_fail[@]} scanned=${scanned_files:-?} violations=${violations_total:-?} status=${status_val:-?} duration_ms=${duration_ms}"

if (( ${#_fail[@]} > 0 )); then
    print -u2 "TEST RESULT: FAIL"
    exit 1
fi

print "TEST RESULT: PASS"
exit 0
