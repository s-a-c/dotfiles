#!/usr/bin/env zsh
# test-perf-segment-budget-overrides.zsh
# Compliant with [${HOME}/.config/ai/guidelines.md](${HOME}/.config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Validate that perf-segment-budget.sh correctly applies per‑segment budget
#   overrides via environment variables (BUDGET_<LABEL>) and that these overrides
#   affect PASS / FAIL evaluation independently per invocation.
#
# SCOPE:
#   - Confirms baseline segment file exists and includes compinit segment.
#   - Runs perf-segment-budget.sh three ways (non-enforcing observe mode):
#       1) With a deliberately too‑small override (BUDGET_COMPINIT=1) → expect FAIL
#       2) With a very large override (BUDGET_COMPINIT=999999) → expect PASS
#       3) Without override (optional informational check) → should PASS given current ms <= interim budget
#   - Ensures the override only affects its own invocation (no persistent state).
#
# INVARIANTS:
#   I1: Segment file present.
#   I2: compinit segment present in segment file.
#   I3: Small override causes FAIL for compinit line.
#   I4: Large override causes PASS for compinit line.
#   I5: (Informational) Default run (no override) produces compinit status=PASS (not required to pass test).
#
# EXIT CODES:
#   0 All required invariants satisfied (I1–I4).
#   0 (Skip) If segment file or compinit segment missing (prints SKIP).
#   1 Any required invariant fails.
#
# NOTES:
#   - ENFORCE=0 is used so the tool never exits 2; we evaluate textual block.
#   - We force OUTPUT_MODE=text for deterministic parsing (block markers).
#
# -----------------------------------------------------------------------------

set -euo pipefail

ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
SEG_FILE_CANDIDATES=(
  "${ZDOTDIR}/docs/redesignv2/artifacts/metrics/perf-current-segments.txt"
  "${ZDOTDIR}/docs/redesign/metrics/perf-current-segments.txt"
)

SEG_FILE=""
for f in "${SEG_FILE_CANDIDATES[@]}"; do
  if [[ -f "$f" ]]; then
    SEG_FILE="$f"
    break
  fi
done

if [[ -z "$SEG_FILE" ]]; then
  echo "SKIP: No perf-current-segments.txt found (run perf capture first)."
  exit 0
fi

# I1
echo "Found segment file: $SEG_FILE"

# Ensure compinit segment present (I2)
if ! grep -q '^SEGMENT name=compinit ' "$SEG_FILE"; then
  echo "SKIP: compinit segment not present (instrumentation not active yet)."
  exit 0
fi
echo "compinit segment present."

TOOLS_DIR="${ZDOTDIR}/tools"
BUDGET_SCRIPT="${TOOLS_DIR}/perf-segment-budget.sh"

if [[ ! -x "$BUDGET_SCRIPT" ]]; then
  echo "FAIL: perf-segment-budget.sh not executable or missing at $BUDGET_SCRIPT" >&2
  exit 1
fi

FAILURES=()

run_budget() {
  # args: override_value label_output_var
  local override="$1" outvar="$2"
  local tmp
  tmp=$(mktemp)
  PERF_SEGMENTS_FILE="$SEG_FILE" BUDGET_COMPINIT="$override" ENFORCE=0 OUTPUT_MODE=text \
    "$BUDGET_SCRIPT" > "$tmp" 2>/dev/null || true
  # Extract just the budget block for clarity
  local block
  block=$(sed -n '/--- PERF_BUDGET_BEGIN ---/,/--- PERF_BUDGET_END ---/p' "$tmp")
  eval "$outvar=\"\$block\""
  rm -f "$tmp" || true
}

# 1) Small override (force FAIL)
SMALL_OVERRIDE=1
run_budget "$SMALL_OVERRIDE" BUDGET_BLOCK_FAIL

if ! print -- "$BUDGET_BLOCK_FAIL" | grep -q '^segment=compinit .* status=FAIL'; then
  echo "DEBUG (small override output):"
  print -- "$BUDGET_BLOCK_FAIL"
  FAILURES+=("I3 expected compinit status=FAIL with BUDGET_COMPINIT=${SMALL_OVERRIDE}")
else
  echo "I3 PASS: small override produced compinit status=FAIL"
fi

# 2) Large override (force PASS)
LARGE_OVERRIDE=999999
run_budget "$LARGE_OVERRIDE" BUDGET_BLOCK_PASS

if ! print -- "$BUDGET_BLOCK_PASS" | grep -q '^segment=compinit .* status=PASS'; then
  echo "DEBUG (large override output):"
  print -- "$BUDGET_BLOCK_PASS"
  FAILURES+=("I4 expected compinit status=PASS with BUDGET_COMPINIT=${LARGE_OVERRIDE}")
else
  echo "I4 PASS: large override produced compinit status=PASS"
fi

# 3) Default (no override) informational (I5, not required)
run_budget "" BUDGET_BLOCK_DEFAULT || true
if print -- "$BUDGET_BLOCK_DEFAULT" | grep -q '^segment=compinit .* status=PASS'; then
  echo "I5 INFO: default compinit status=PASS (within interim budget)"
else
  echo "I5 INFO: default compinit status not PASS (may exceed interim budget; investigate optimization)"
fi

# Summary
if (( ${#FAILURES[@]} == 0 )); then
  echo "PASS: Budget override behavior validated (I1–I4)."
  exit 0
else
  echo "FAIL: ${#FAILURES[@]} invariant(s) failed:"
  for f in "${FAILURES[@]}"; do
    echo "  - $f"
  done
  exit 1
fi
