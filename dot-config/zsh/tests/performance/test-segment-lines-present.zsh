#!/usr/bin/env zsh
# test-segment-lines-present.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Validate existence and basic integrity of the perf-current-segments.txt artifact
#   emitted by perf-capture tooling. Ensures downstream perf-diff gating has the
#   required normalized SEGMENT lines plus key high-level segments.
#
# INVARIANTS (I1–I9):
#   I1: perf-current-segments.txt exists in redesignv2 or redesign metrics path
#   I2: File non-empty (>0 bytes)
#   I3: At least N >= 3 SEGMENT lines present
#   I4: Each SEGMENT line matches required key/value tokens:
#         SEGMENT name=<label> ms=<integer> phase=<word> sample=<word>
#   I5: Required labels present: pre_plugin_total, post_plugin_total, prompt_ready
#   I6: ms values are non-negative integers
#   I7: No duplicate (label,phase,sample) triplets (dedup check)
#   I8: If policy_guidelines_checksum present, includes checksum=<64hex>
#   I9: (Informational) compinit or p10k_theme segments logged if instrumentation enabled
#
# EXIT CODES:
#   0 PASS (all required invariants)
#   1 FAIL (any required invariant violated)
#
# OUTPUT:
#   Human-readable PASS/FAIL lines. Final summary + guidance if remediation needed.
#
# NOTES:
#   - This test is tolerant of absence of optional segments (compinit / p10k_theme),
#     but reports them as informational to encourage coverage.
#   - Does not enforce performance thresholds (handled elsewhere).
#
# -----------------------------------------------------------------------------

set -euo pipefail

# Resolve metrics directory (prefer redesignv2)
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
METRICS_DIR_V2="${ZDOTDIR}/docs/redesignv2/artifacts/metrics"
METRICS_DIR_V1="${ZDOTDIR}/docs/redesign/metrics"

SEG_FILE=""
if [[ -f "${METRICS_DIR_V2}/perf-current-segments.txt" ]]; then
  SEG_FILE="${METRICS_DIR_V2}/perf-current-segments.txt"
elif [[ -f "${METRICS_DIR_V1}/perf-current-segments.txt" ]]; then
  SEG_FILE="${METRICS_DIR_V1}/perf-current-segments.txt"
fi

# Colors (graceful degrade)
if [[ -t 1 ]]; then
  GREEN=$'\033[32m'
  RED=$'\033[31m'
  YELLOW=$'\033[33m'
  BOLD=$'\033[1m'
  RESET=$'\033[0m'
else
  GREEN=""; RED=""; YELLOW=""; BOLD=""; RESET=""
fi

failures=()
info_msgs=()

pass_msg() {
  print "${GREEN}PASS${RESET}: $1"
}
fail_msg() {
  print "${RED}FAIL${RESET}: $1"
  failures+=("$1")
}
info_msg() {
  print "${YELLOW}INFO${RESET}: $1"
  info_msgs+=("$1")
}

# I1: File exists
if [[ -z "${SEG_FILE}" ]]; then
  fail_msg "I1 perf-current-segments.txt not found in redesignv2 or redesign metrics directories"
  print "\n${RED}Aborting further checks due to missing file.${RESET}"
  exit 1
else
  pass_msg "I1 segment file found at ${SEG_FILE}"
fi

# I2: Non-empty
if [[ ! -s "${SEG_FILE}" ]]; then
  fail_msg "I2 segment file is empty"
else
  pass_msg "I2 segment file non-empty (size $(stat -f '%z' "${SEG_FILE}" 2>/dev/null || stat -c '%s' "${SEG_FILE}" 2>/dev/null) bytes)"
fi

# Collect SEGMENT lines
segment_lines=("${(@f)$(grep -E '^SEGMENT ' "${SEG_FILE}" || true)}")
segment_count=${#segment_lines[@]}

# I3: At least 3 lines (pre, post, prompt)
if (( segment_count < 3 )); then
  fail_msg "I3 expected >=3 SEGMENT lines, found ${segment_count}"
else
  pass_msg "I3 SEGMENT line count >= 3 (found ${segment_count})"
fi

# I4 / I6 / I7 parse & validate
typeset -A seen_triplets
required_labels=(pre_plugin_total post_plugin_total prompt_ready)
typeset -A have_label
policy_checksum_value=""
policy_checksum_present=0
parse_fail=0

for line in "${segment_lines[@]}"; do
  # Basic pattern
  if ! print -- "$line" | grep -Eq '^SEGMENT name=[A-Za-z0-9_.:-]+ ms=[0-9]+ phase=[a-z_]+ sample=[A-Za-z0-9_.:-]+'; then
    fail_msg "I4 malformed SEGMENT line: $line"
    parse_fail=1
    continue
  fi
  # Extract tokens
  name=$(print -- "$line" | sed -n 's/.* name=\([^ ]*\).*/\1/p')
  ms=$(print -- "$line" | sed -n 's/.* ms=\([0-9]\+\).*/\1/p')
  phase=$(print -- "$line" | sed -n 's/.* phase=\([^ ]*\).*/\1/p')
  sample=$(print -- "$line" | sed -n 's/.* sample=\([^ ]*\).*/\1/p')

  triplet="${name}|${phase}|${sample}"
  if [[ -n ${seen_triplets[$triplet]:-} ]]; then
    fail_msg "I7 duplicate segment triplet: $triplet"
  else
    seen_triplets[$triplet]=1
  fi

  # I6 ms non-negative already ensured by regex; double-check numeric
  if ! [[ $ms =~ ^[0-9]+$ ]]; then
    fail_msg "I6 non-numeric ms for $name: $ms"
  fi

  # Track required labels (label can appear with phase differences; only need any)
  for r in "${required_labels[@]}"; do
    if [[ "$name" == "$r" ]]; then
      have_label[$r]=1
    fi
  done

  # Policy checksum optional
  if [[ "$name" == "policy_guidelines_checksum" ]]; then
    policy_checksum_present=1
    policy_checksum_value=$(print -- "$line" | sed -n 's/.* checksum=\([0-9a-f]\{64\}\).*/\1/p')
    if [[ -z $policy_checksum_value ]]; then
      fail_msg "I8 policy_guidelines_checksum segment lacks checksum=<64hex>"
    fi
  fi
done

# Report parse success for I4 if no earlier failures from malformed lines
if (( parse_fail == 0 )); then
  pass_msg "I4 segment line format valid"
fi

# I5: Required labels present
missing_req=()
for r in "${required_labels[@]}"; do
  [[ -n ${have_label[$r]:-} ]] || missing_req+=("$r")
done
if (( ${#missing_req[@]} > 0 )); then
  fail_msg "I5 missing required segment labels: ${missing_req[*]}"
else
  pass_msg "I5 required segment labels present (${required_labels[*]})"
fi

# I8: Policy checksum segment (optional but recommended)
if (( policy_checksum_present )); then
  if [[ -n $policy_checksum_value ]]; then
    pass_msg "I8 policy_guidelines_checksum segment present (checksum=$policy_checksum_value)"
  else
    # Already failed above if invalid; do nothing here
    :
  fi
else
  info_msg "Policy checksum segment absent (add for richer perf-diff correlation)"
fi

# I9: Informational optional instrumentation segments
optional_hits=()
optional_missing=()
for opt in compinit p10k_theme; do
  if grep -q "SEGMENT name=${opt} " "${SEG_FILE}"; then
    optional_hits+=("$opt")
  else
    optional_missing+=("$opt")
  fi
done
if (( ${#optional_hits[@]} > 0 )); then
  info_msg "Optional segments present: ${optional_hits[*]}"
fi
if (( ${#optional_missing[@]} > 0 )); then
  info_msg "Optional segments missing (ok): ${optional_missing[*]}"
fi

# Summary / Exit
print ""
if (( ${#failures[@]} == 0 )); then
  print "${BOLD}${GREEN}PASS${RESET}: All required SEGMENT file invariants satisfied."
  exit 0
else
  print "${BOLD}${RED}FAIL${RESET}: ${#failures[@]} invariant(s) failed:"
  for f in "${failures[@]}"; do
    print "  - $f"
  done
  print ""
  print "Remediation suggestions:"
  print "  * Ensure tools/perf-capture.zsh ran and wrote perf-current-segments.txt"
  print "  * Verify segment-lib.zsh emits unified SEGMENT lines (check PERF_SEGMENT_LOG)"
  print "  * Confirm required modules (pre/post plugin, prompt readiness) are sourced"
  print "  * Add policy checksum marker via 02-guidelines-checksum.zsh if missing"
  exit 1
fi
