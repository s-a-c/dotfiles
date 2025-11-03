#!/usr/bin/env zsh
# test-required-segment-labels.zsh
# Compliant with [${HOME}/.config/ai/guidelines.md](${HOME}/.config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Gate / assert presence of REQUIRED performance instrumentation segment labels
#   emitted to perf-current-segments.txt (established during early Stage 5
#   instrumentation pulled forward). Complements existing structural segment
#   format test (test-segment-lines-present.zsh) by focusing specifically on
#   semantic coverage of the critical baseline labels needed for:
#     - Gate G5a (observe block meaningfulness)
#     - Future regression gating & absolute budget enforcement (G6 / budgets)
#     - Accurate A/B deltas (startup & hotspot segmentation)
#
# SCOPE:
#   Validates that the canonical segment file includes the minimum required
#   lifecycle + hotspot labels. Emits soft warnings for recommended-but-optional
#   labels (e.g., gitstatus_init) so missing optional coverage does not fail CI
#   prematurely while instrumentation is being expanded.
#
# REQUIRED LABEL SET (Hard Fail If Missing):
#   pre_plugin_total
#   post_plugin_total
#   prompt_ready
#   compinit
#   p10k_theme
#
# OPTIONAL (Warn Only If Missing):
#   gitstatus_init          (VCS prompt backend instrumentation)
#   policy_guidelines_checksum (meta correlation segment; encouraged)
#
# INVARIANTS:
#   I1: Segment file exists.
#   I2: Required labels all present at least once.
#   I3: Each required label has a well‑formed SEGMENT line (regex validated).
#   I4: No duplicate malformed entries for required labels.
#   I5: If policy_guidelines_checksum present, includes checksum=<64hex>.
#
# OUTPUT:
#   PASS / FAIL lines per invariant; summary at end.
#
# EXIT CODE:
#   0 if all required invariants pass (warnings allowed)
#   1 if any required invariant fails (I1–I4 / I5 only if checksum segment malformed)
#
# NOTES:
#   - This test is intentionally lightweight (pure shell + grep/awk).
#   - Does NOT enforce performance timing magnitudes (separate tests handle budgets).
#   - Designed to remain stable even as additional segments are added.
#
# FUTURE EXTENSIONS:
#   - Add variance / stability checks once multi-sample capture integrated.
#   - Promote gitstatus_init from optional to required once consistently emitted.
#
# ------------------------------------------------------------------------------

set -euo pipefail

ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
METRICS_DIR_V2="${ZDOTDIR}/docs/redesignv2/artifacts/metrics"
METRICS_DIR_V1="${ZDOTDIR}/docs/redesign/metrics"

SEG_FILE=""
if [[ -f "${METRICS_DIR_V2}/perf-current-segments.txt" ]]; then
  SEG_FILE="${METRICS_DIR_V2}/perf-current-segments.txt"
elif [[ -f "${METRICS_DIR_V1}/perf-current-segments.txt" ]]; then
  SEG_FILE="${METRICS_DIR_V1}/perf-current-segments.txt"
fi

# Color helpers (graceful degrade)
if [[ -t 1 ]]; then
  GREEN=$'\033[32m'
  RED=$'\033[31m'
  YELLOW=$'\033[33m'
  BOLD=$'\033[1m'
  RESET=$'\033[0m'
else
  GREEN=""; RED=""; YELLOW=""; BOLD=""; RESET=""
fi

pass() { print "${GREEN}PASS${RESET}: $*"; }
fail() { print "${RED}FAIL${RESET}: $*"; FAILURES+=("$*"); }
warn() { print "${YELLOW}WARN${RESET}: $*"; WARNINGS+=("$*"); }
info() { print "${YELLOW}INFO${RESET}: $*"; }

FAILURES=()
WARNINGS=()

REQUIRED_LABELS=(pre_plugin_total post_plugin_total prompt_ready compinit p10k_theme)
OPTIONAL_LABELS=(gitstatus_init policy_guidelines_checksum)

# I1: File exists
if [[ -z "${SEG_FILE}" ]]; then
  fail "I1 perf-current-segments.txt not found (run perf capture tooling first)"
  print ""
  print "${BOLD}${RED}FAIL${RESET}: Required segment file missing."
  exit 1
else
  pass "I1 segment file found: ${SEG_FILE}"
fi

# Collect all SEGMENT lines into an array
SEGMENT_LINES=("${(@f)$(grep -E '^SEGMENT ' "${SEG_FILE}" || true)}")
if (( ${#SEGMENT_LINES[@]} == 0 )); then
  fail "No SEGMENT lines found (instrumentation not active?)"
fi

# Index by label for quick lookup (only storing first occurrence)
typeset -A SEGMENT_BY_LABEL
for line in "${SEGMENT_LINES[@]}"; do
  # Extract name= token
  name=$(print -- "$line" | sed -n 's/.* name=\([^ ]*\).*/\1/p')
  [[ -z $name ]] && continue
  # Preserve first occurrence
  [[ -n ${SEGMENT_BY_LABEL[$name]:-} ]] && continue
  SEGMENT_BY_LABEL[$name]="$line"
done

# Regex pattern for a valid segment (excluding optional checksum kv)
VALID_SEG_REGEX='^SEGMENT name=[A-Za-z0-9_.:-]+ ms=[0-9]+ phase=[a-z_]+ sample=[A-Za-z0-9_.:-]+( .*|)$'

# I2 / I3 / I4: Validate required labels presence & format
for req in "${REQUIRED_LABELS[@]}"; do
  line="${SEGMENT_BY_LABEL[$req]:-}"
  if [[ -z $line ]]; then
    fail "I2 missing required label: ${req}"
    continue
  fi
  # Format validation
  if ! print -- "$line" | grep -Eq "${VALID_SEG_REGEX}"; then
    fail "I3 malformed SEGMENT line for required label '${req}': $line"
    continue
  fi
  # ms token integrity
  ms=$(print -- "$line" | sed -n 's/.* ms=\([0-9]\+\).*/\1/p')
  if [[ -z $ms || ! $ms =~ ^[0-9]+$ ]]; then
    fail "I4 non-numeric ms for required label '${req}' (line: $line)"
    continue
  fi
  pass "Required label '${req}' present (ms=${ms})"
done

# Optional labels (warn only)
for opt in "${OPTIONAL_LABELS[@]}"; do
  line="${SEGMENT_BY_LABEL[$opt]:-}"
  if [[ -z $line ]]; then
    warn "Optional segment '${opt}' not present"
    continue
  fi
  # Special validation for policy checksum segment
  if [[ "$opt" == "policy_guidelines_checksum" ]]; then
    if ! print -- "$line" | grep -Eq 'checksum=[0-9a-f]{64}'; then
      fail "I5 policy_guidelines_checksum present but missing checksum=<64hex> token"
    else
      pass "Policy checksum segment present (valid checksum token)"
    fi
  else
    info "Optional segment '${opt}' present"
  fi
done

# Summary
print ""
if (( ${#FAILURES[@]} == 0 )); then
  print "${BOLD}${GREEN}PASS${RESET}: All required segment labels present & valid."
  if (( ${#WARNINGS[@]} > 0 )); then
    print "${YELLOW}Warnings:${RESET}"
    for w in "${WARNINGS[@]}"; do
      print "  - $w"
    done
  fi
  exit 0
else
  print "${BOLD}${RED}FAIL${RESET}: ${#FAILURES[@]} required invariant(s) failed."
  for f in "${FAILURES[@]}"; do
    print "  - $f"
  done
  print ""
  print "Remediation:"
  print "  * Ensure instrumentation modules (55-compinit-instrument, 60-p10k-instrument,"
  print "    65-vcs-gitstatus-instrument) are sourced in the redesigned post-plugin path."
  print "  * Run tools/perf-capture.zsh to regenerate perf-current-segments.txt."
  print "  * Verify PERF_SEGMENT_LOG is being set during harnessed startup for capture."
  print "  * Confirm segment-lib.zsh is sourced before hotspot instrumentation modules."
  exit 1
fi
