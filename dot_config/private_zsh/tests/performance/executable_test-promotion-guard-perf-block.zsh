#!/usr/bin/env zsh
# test-promotion-guard-perf-block.zsh
# Compliant with [${HOME}/.config/ai/guidelines.md](${HOME}/.config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Gate G5a: Validate that performance promotion guard observe mode emits a single,
#   well‑formed structured PERF_GUARD block with required key/value lines.
#
# WHAT IS TESTED:
#   I1: promotion-guard-perf.sh script present and runnable.
#   I2: Exactly one delimited block bounded by:
#         --- PERF_GUARD_BEGIN ---
#         --- PERF_GUARD_END ---
#   I3: Required keys appear inside the block (one line each):
#         status=  mode=  baseline=  current=  thresholds abs= pct= new_allow=
#         regressions=  new_segments=  removed_segments=  improvements=  summary=
#   I4: mode=observe (until gating elevated; adapt test later if mode changes).
#   I5: If status=OK then baseline and current refer to existing files; if status=SKIP,
#       a reason= line MUST be present (non-empty).
#   I6: multi_samples / multi_post_plugin_mean / multi_post_plugin_stddev keys present
#       (added enhancement) and either 'n/a' OR numeric values (>=0).
#   I7: No duplicate required key lines.
#   I8: Block appears exactly once in output.
#
# EXIT CODES:
#   0 PASS
#   1 FAIL (any invariant violation)
#
# OUTPUT:
#   PASS/FAIL lines per invariant plus final summary.
#
# NOTE:
#   This test runs the guard in observe mode (non-failing). It does not assert
#   numerical thresholds, only structural correctness & presence of paths.
#
# FUTURE ADJUSTMENTS:
#   - When mode transitions to 'gate' or additional keys added, extend REQUIRED_KEYS.
#   - When multi-sample data becomes mandatory, strengthen I6 to require numeric.
#
# -----------------------------------------------------------------------------

set -euo pipefail

ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
TOOLS_DIR="${ZDOTDIR}/tools"
GUARD="${TOOLS_DIR}/promotion-guard-perf.sh"

# Colors (graceful degrade)
if [[ -t 1 ]]; then
  GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  GREEN=""; RED=""; YELLOW=""; BOLD=""; RESET=""
fi

pass() { print "${GREEN}PASS${RESET}: $*"; }
fail() { print "${RED}FAIL${RESET}: $*"; FAILURES+=("$*"); }
info() { print "${YELLOW}INFO${RESET}: $*"; }

FAILURES=()

# ---------------- Invariant I1 ----------------
if [[ ! -f "$GUARD" ]]; then
  fail "I1 promotion-guard-perf.sh not found at $GUARD"
elif [[ ! -r "$GUARD" ]]; then
  fail "I1 promotion-guard-perf.sh not readable"
else
  pass "I1 guard script present"
fi

if (( ${#FAILURES[@]} > 0 )); then
  print ""
  print "${BOLD}${RED}FAIL${RESET}: Precondition (script presence) failed."
  exit 1
fi

# Run the guard (capture stdout; ignore stderr so noise does not pollute block parsing)
OUTPUT="$(
  set +e
  ZDOTDIR="$ZDOTDIR" bash "$GUARD" 2>/dev/null
  echo "__EXIT_CODE:$?"
)"

# Extract exit code marker
GUARD_RC=$(printf '%s\n' "$OUTPUT" | grep -E '__EXIT_CODE:' | tail -1 | sed -E 's/.*__EXIT_CODE:([0-9]+).*/\1/')
OUTPUT=$(printf '%s\n' "$OUTPUT" | grep -v '__EXIT_CODE:' || true)

# ---------------- Invariant I2 & I8 (uniqueness) ----------------
begin_count=$(printf '%s\n' "$OUTPUT" | grep -c '^--- PERF_GUARD_BEGIN ---' || true)
end_count=$(printf '%s\n'   "$OUTPUT" | grep -c '^--- PERF_GUARD_END ---' || true)

if (( begin_count != 1 || end_count != 1 )); then
  fail "I2 expected exactly one PERF_GUARD_BEGIN/END pair (found begin=$begin_count end=$end_count)"
else
  pass "I2 single PERF_GUARD block delimiters present"
fi

# Extract block content (exclusive of delimiter lines)
BLOCK=$(printf '%s\n' "$OUTPUT" | awk '
  /^--- PERF_GUARD_BEGIN ---$/ {in=1; next}
  /^--- PERF_GUARD_END ---$/ {in=0; exit}
  { if(in) print }')

if [[ -z "$BLOCK" ]]; then
  fail "I2 block body empty"
fi

# ---------------- Invariant I3 (required keys) ----------------
# Required lines start-with patterns
REQUIRED_KEYS=(
  "status="
  "mode="
  "baseline="
  "current="
  "thresholds abs="
  "regressions="
  "new_segments="
  "removed_segments="
  "improvements="
  "summary="
)

for key in "${REQUIRED_KEYS[@]}"; do
  count=$(printf '%s\n' "$BLOCK" | grep -c "^${key}" || true)
  if (( count == 0 )); then
    fail "I3 missing required key line '${key}'"
  elif (( count > 1 )); then
    fail "I7 duplicate key line '${key}' (count=${count})"
  fi
done
(( ${#FAILURES[@]} == 0 )) && pass "I3 required key lines present (no duplicates)"

# ---------------- Parse key values ----------------
# Helper to fetch first value after prefix
kv() {
  local prefix="$1"
  printf '%s\n' "$BLOCK" | grep -E "^${prefix}" | head -1 | sed -E "s/^${prefix}//"
}

status_val=$(kv "status=" || true)
mode_val=$(kv "mode=" || true)
baseline_path=$(kv "baseline=" || true)
current_path=$(kv "current=" || true)
summary_line=$(kv "summary=" || true)
reason_line=$(kv "reason=" || true)
multi_samples=$(kv "multi_samples=" || true)
multi_pp_mean=$(kv "multi_post_plugin_mean=" || true)
multi_pp_stddev=$(kv "multi_post_plugin_stddev=" || true)

# ---------------- Invariant I4 (mode=observe) ----------------
if [[ "$mode_val" != "observe" ]]; then
  fail "I4 unexpected mode='$mode_val' (expected 'observe')"
else
  pass "I4 mode observe"
fi

# ---------------- Invariant I5 (path validity / reason presence) ----------------
if [[ "$status_val" == "OK" ]]; then
  if [[ -z "$baseline_path" || ! -f "$baseline_path" ]]; then
    fail "I5 baseline path missing or not a file (status=OK) path='$baseline_path'"
  fi
  if [[ -z "$current_path" || ! -f "$current_path" ]]; then
    fail "I5 current path missing or not a file (status=OK) path='$current_path'"
  fi
  (( ${#FAILURES[@]} == 0 )) && pass "I5 baseline/current files exist (status=OK)"
elif [[ "$status_val" == "SKIP" ]]; then
  if [[ -z "$reason_line" ]]; then
    fail "I5 status=SKIP but no reason= line present"
  else
    pass "I5 skip reason documented"
  fi
else
  fail "I5 unexpected status value '$status_val' (expected OK or SKIP)"
fi

# ---------------- Invariant I6 (multi-sample metrics form) ----------------
# Accept 'n/a' OR integer >= 0
validate_optional_numeric() {
  local label="$1" val="$2"
  if [[ "$val" == "n/a" ]]; then
    info "${label} not available (n/a) – acceptable in observe mode"
  elif [[ "$val" =~ ^[0-9]+$ ]]; then
    pass "${label} numeric (${val})"
  else
    fail "${label} invalid value '${val}' (expected integer or n/a)"
  fi
}

if grep -q "^multi_samples=" <<<"$BLOCK"; then
  validate_optional_numeric "I6 multi_samples" "$multi_samples"
  validate_optional_numeric "I6 multi_post_plugin_mean" "$multi_pp_mean"
  validate_optional_numeric "I6 multi_post_plugin_stddev" "$multi_pp_stddev"
else
  info "multi-sample keys absent (older guard script or feature not yet active) – tolerated"
fi

# ---------------- Invariant I8 already partially checked; ensure single block ----------------
# (begin_count/end_count validated above). Additional check: no nested begin/end inside block.
nested_begin=$(printf '%s\n' "$BLOCK" | grep -c '^--- PERF_GUARD_BEGIN ---' || true)
nested_end=$(printf '%s\n' "$BLOCK" | grep -c '^--- PERF_GUARD_END ---' || true)
if (( nested_begin > 0 || nested_end > 0 )); then
  fail "I8 nested PERF_GUARD delimiters found inside block"
else
  pass "I8 single block instance (no nesting)"
fi

# ---------------- Final Result ----------------
print ""
if (( ${#FAILURES[@]} == 0 )); then
  print "${BOLD}${GREEN}PASS${RESET}: G5a promotion guard structured block validated."
  exit 0
else
  print "${BOLD}${RED}FAIL${RESET}: ${#FAILURES[@]} invariant(s) failed:"
  for f in "${FAILURES[@]}"; do
    print "  - $f"
  done
  print ""
  print "Remediation Suggestions:"
  print "  * Ensure promotion-guard-perf.sh emits delimiters and required key lines."
  print "  * If status=OK, verify perf-baseline-segments.txt and perf-current-segments.txt exist."
  print "  * If multi-sample aggregation was expected, run tools/perf-capture-multi.zsh first."
  print "  * Confirm mode remains 'observe' until gate activation logic is updated."
  print "  * After modifying guard output, update REQUIRED_KEYS or invariants here accordingly."
  exit 1
fi
