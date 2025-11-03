#!/usr/bin/env zsh
# test-feature-timing-enabled.zsh
#
# T-TEL-02: Feature Timing Telemetry Enabled Path
#
# Compliant with ${HOME}/.config/ai/guidelines.md v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316
#
# PURPOSE:
#   Validate that when feature timing telemetry and structured logging are enabled:
#     1. feature_timing JSON lines are emitted for init-phase features.
#     2. Sequence numbers are monotonically increasing.
#     3. Each JSON line contains required keys:
#          type=feature_timing, feature, ms (integer), phase=init, sequence (int),
#          version (int), ts_epoch_ms (13-digit epoch ms)
#     4. ZSH_FEATURE_TIMINGS_SYNC contains ms entries for registered features.
#     5. At least one ms value is > 0 (non-zero timing captured).
#
# SCOPE:
#   - Covers enabled path (complements T-TEL-01 disabled test).
#   - Schema validation performed with POSIX-ish tooling (grep/sed/awk) — no jq dependency.
#
# SUCCESS CRITERIA:
#   - >=2 feature_timing lines (we register two features).
#   - Both registered features appear.
#   - All required keys present in every line.
#   - Monotonic strictly increasing sequence field.
#   - At least one ms > 0 (timing resolution observable).
#
# PERFORMANCE NOTE:
#   Loops inside feature init functions are calibrated to produce small but
#   measurable durations without exceeding ~5–10ms total (implementation detail).
#
# EXIT CODES:
#   0 = success
#   1 = failure (any assertion fails)
#
# ------------------------------------------------------------------------------
emulate -L zsh
setopt errexit nounset pipefail

# -----------------------------
# Helpers
# -----------------------------
_fail() { print -r -- "[FAIL][T-TEL-02] $*" >&2; exit 1; }
_info() { print -r -- "[INFO][T-TEL-02] $*" >&2; }
_assert_file_pattern() {
  local pattern="$1" file="$2" msg="$3"
  if ! grep -E -- "${pattern}" -- "${file}" >/dev/null 2>&1; then
    _fail "${msg}: expected pattern '${pattern}' not found in ${file}"
  fi
}
_assert_non_empty() {
  local value="$1" msg="$2"
  [[ -n "$value" ]] || _fail "$msg (was empty)"
}
_assert_int_ge() {
  local val="$1" min="$2" msg="$3"
  [[ "$val" == <-> ]] || _fail "${msg}: '$val' not an integer"
  (( val >= min )) || _fail "${msg}: $val < $min"
}
_assert_strictly_increasing() {
  local -a arr
  arr=("$@")
  local i
  for (( i=2; i <= ${#arr[@]}; i++ )); do
    local prev="${arr[i-1]}"
    local curr="${arr[i]}"
    (( curr > prev )) || _fail "Sequence not strictly increasing at index $i (prev=${prev} curr=${curr})"
  done
}

# -----------------------------
# Locate & Source Registry
# -----------------------------
SCRIPT_PATH="${(%):-%N}"
SCRIPT_DIR="${SCRIPT_PATH:A:h}"
ZSH_ROOT="${SCRIPT_DIR:A:h:h:h}"   # ascend to dot-config/zsh
REGISTRY_FILE="${ZSH_ROOT}/feature/registry/feature-registry.zsh"
[[ -r "${REGISTRY_FILE}" ]] || _fail "Feature registry not readable: ${REGISTRY_FILE}"
source "${REGISTRY_FILE}"

# -----------------------------
# Environment (Enabled Telemetry)
# -----------------------------
export ZSH_FEATURE_TELEMETRY=1
export ZSH_LOG_STRUCTURED=1
# PERF_SEGMENT_JSON_LOG preferred; provide both for completeness
TMP_DIR="${TMPDIR:-/tmp}"
: "${TMP_DIR:=/tmp}"
FEATURE_TIMING_JSON_LOG="${TMP_DIR}/test-feature-timing-enabled.$$.json"
SEGMENT_PLAIN_LOG="${TMP_DIR}/test-feature-timing-enabled.$$.log"
: > "${FEATURE_TIMING_JSON_LOG}"
: > "${SEGMENT_PLAIN_LOG}"
export PERF_SEGMENT_JSON_LOG="${FEATURE_TIMING_JSON_LOG}"
export PERF_SEGMENT_LOG="${SEGMENT_PLAIN_LOG}"

# -----------------------------
# Define Sample Features
# -----------------------------
# Registration: name phase depends deferred category description guid
feature_registry_add "ft_enabled_sample_a" "2" "" "no" "telemetry" "Enabled path timing sample A" "guid-ft-enabled-sample-a" \
  || _fail "Registration failed for feature A"
feature_registry_add "ft_enabled_sample_b" "2" "" "no" "telemetry" "Enabled path timing sample B" "guid-ft-enabled-sample-b" \
  || _fail "Registration failed for feature B"

# Provide init impls with deterministic light CPU loops to yield measurable ms.
feature_ft_enabled_sample_a_init() {
  integer x=0
  # Calibrated loop count: modest workload
  for i in {1..80000}; do (( x+=i )); done
  return 0
}
feature_ft_enabled_sample_b_init() {
  integer x=0
  # Slightly larger loop to differentiate timing
  for i in {1..120000}; do (( x+=i )); done
  return 0
}

# -----------------------------
# Invoke init Phase
# -----------------------------
feature_registry_invoke_phase init || _fail "invoke_phase init returned non-zero"

# -----------------------------
# Assertions: JSON Lines
# -----------------------------
# Must contain feature_timing lines for both features.
grep -E '"type":"feature_timing"' "${FEATURE_TIMING_JSON_LOG}" >/dev/null 2>&1 \
  || _fail "No feature_timing lines emitted"

# Collect lines (preserve order)
typeset -a FT_LINES
while IFS= read -r line; do
  FT_LINES+=("$line")
done < <(grep -E '"type":"feature_timing"' "${FEATURE_TIMING_JSON_LOG}" || true)

(( ${#FT_LINES[@]} >= 2 )) || _fail "Expected >=2 feature_timing lines (got ${#FT_LINES[@]})"

# Validate presence of each feature
print -r -- "${FT_LINES[@]}" | grep -q '"feature":"ft_enabled_sample_a"' \
  || _fail "Missing timing line for ft_enabled_sample_a"
print -r -- "${FT_LINES[@]}" | grep -q '"feature":"ft_enabled_sample_b"' \
  || _fail "Missing timing line for ft_enabled_sample_b"

# Extract & validate fields
typeset -a SEQS
typeset -a MS_VALUES
integer ms_gt_zero_count=0
for l in "${FT_LINES[@]}"; do
  # Required keys
  print -r -- "$l" | grep -q '"type":"feature_timing"' || _fail "Line missing type key: $l"
  print -r -- "$l" | grep -q '"phase":"init"' || _fail "Line missing/incorrect phase=init: $l"
  print -r -- "$l" | grep -q '"version":1' || _fail "Line missing version=1: $l"
  # ts_epoch_ms 13-digit numeric
  ts_field="$(print -r -- "$l" | sed -n 's/.*"ts_epoch_ms":\([0-9]\{13\}\).*/\1/p')"
  _assert_non_empty "$ts_field" "ts_epoch_ms missing"
  [[ "$ts_field" == <-> ]] || _fail "ts_epoch_ms not numeric: $ts_field"
  (( ${#ts_field} == 13 )) || _fail "ts_epoch_ms not 13 digits: $ts_field"

  seq_field="$(print -r -- "$l" | sed -n 's/.*"sequence":\([0-9]\+\).*/\1/p')"
  _assert_non_empty "$seq_field" "sequence missing"
  SEQS+=("$seq_field")

  ms_field="$(print -r -- "$l" | sed -n 's/.*"ms":\([0-9]\+\).*/\1/p')"
  _assert_non_empty "$ms_field" "ms missing"
  MS_VALUES+=("$ms_field")
  (( ms_field > 0 )) && (( ms_gt_zero_count++ ))
done

# Sequence monotonic
_assert_strictly_increasing "${SEQS[@]}"

# At least one ms > 0
(( ms_gt_zero_count >= 1 )) || _fail "No feature_timing line had ms > 0 (collected: ${MS_VALUES[*]})"

# -----------------------------
# Assertions: In-Memory Timing Map
# -----------------------------
typeset -p ZSH_FEATURE_TIMINGS_SYNC >/dev/null 2>&1 \
  || _fail "ZSH_FEATURE_TIMINGS_SYNC not defined"

for f in ft_enabled_sample_a ft_enabled_sample_b; do
  val="${ZSH_FEATURE_TIMINGS_SYNC[$f]:-}"
  _assert_non_empty "$val" "Timing map entry missing for $f"
  _assert_int_ge "$val" 0 "Timing ms for $f invalid"
done

# Confirm at least one in-memory timing > 0
integer in_memory_nonzero=0
for f in ft_enabled_sample_a ft_enabled_sample_b; do
  (( ZSH_FEATURE_TIMINGS_SYNC[$f] > 0 )) && (( in_memory_nonzero++ ))
done
(( in_memory_nonzero >= 1 )) || _fail "In-memory timings all zero (values: ${ZSH_FEATURE_TIMINGS_SYNC[ft_enabled_sample_a]}, ${ZSH_FEATURE_TIMINGS_SYNC[ft_enabled_sample_b]})"

# -----------------------------
# Optional: Cross-check JSON vs Map
# -----------------------------
# (Non-fatal sanity: if a feature appears in JSON its in-memory entry should match)
for f in ft_enabled_sample_a ft_enabled_sample_b; do
  json_ms="$(print -r -- "${FT_LINES[@]}" | sed -n "/\"feature\":\"$f\"/s/.*\"ms\":\\([0-9]\\+\\).*/\\1/p" | head -n1)"
  [[ -n "$json_ms" ]] || _fail "Could not extract JSON ms for $f"
  map_ms="${ZSH_FEATURE_TIMINGS_SYNC[$f]}"
  # Allow equality; no further tolerance needed since both integers
  if [[ "$json_ms" != "$map_ms" ]]; then
    _info "Note: JSON ms ($json_ms) != map ms ($map_ms) for $f (acceptable if timing updated later, but should normally match)"
  fi
done

_info "All T-TEL-02 assertions passed (feature timing telemetry enabled path)."

# Cleanup temp artifacts
rm -f -- "${FEATURE_TIMING_JSON_LOG}" "${SEGMENT_PLAIN_LOG}" 2>/dev/null || true

exit 0
