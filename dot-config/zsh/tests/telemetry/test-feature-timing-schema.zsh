#!/usr/bin/env zsh
# test-feature-timing-schema.zsh
#
# T-TEL-03: Feature Timing Telemetry Schema & Privacy Validation
#
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316
#
# PURPOSE:
#   Validate that emitted feature timing telemetry JSON lines conform to the
#   approved schema and that the Privacy Appendix documents the related flag
#   (ZSH_FEATURE_TELEMETRY) without stale "(future)" marker after implementation.
#
# COVERED ASSERTIONS:
#   1. When telemetry + structured logging are enabled, feature_timing lines exist.
#   2. Each feature_timing JSON object contains ONLY the allowed key set:
#        {type,feature,ms,phase,sequence,version,ts_epoch_ms}
#      (ordering not enforced; no extraneous keys).
#   3. Required field constraints:
#        - type == "feature_timing"
#        - phase == "init"
#        - version == 1 (integer)
#        - feature non-empty string
#        - ms integer >= 0
#        - sequence strictly increasing across lines
#        - ts_epoch_ms 13-digit numeric (epoch milliseconds)
#   4. In-memory map ZSH_FEATURE_TIMINGS_SYNC has matching entries for each feature.
#   5. Privacy Appendix row for ZSH_FEATURE_TELEMETRY exists and no longer marked "(future)".
#
# NOT IN SCOPE:
#   - Performance overhead measurement (handled by broader perf harness).
#   - Cross-run persistence validation.
#
# EXIT CODES:
#   0 = success
#   1 = failure
#
# IMPLEMENTATION NOTES:
#   - Uses only POSIX-ish tools available in typical macOS dev environment (grep, sed, awk).
#   - Avoids external JSON parsers to keep test hermetic.
#
# SECURITY / PRIVACY:
#   - Reads only local repository files.
#   - Ensures no unexpected keys leak into telemetry lines (defense-in-depth).
#
# ------------------------------------------------------------------------------
emulate -L zsh
setopt errexit nounset pipefail

_fail() { print -r -- "[FAIL][T-TEL-03] $*" >&2; exit 1; }
_info() { print -r -- "[INFO][T-TEL-03] $*" >&2; }

_assert() {
  local cond="$1" msg="$2"
  if ! eval "$cond"; then
    _fail "$msg"
  fi
}

_assert_file_pattern() {
  local pattern="$1" file="$2" msg="$3"
  if ! grep -E -- "${pattern}" -- "${file}" >/dev/null 2>&1; then
    _fail "${msg}: expected pattern '${pattern}' not found in ${file}"
  fi
}

# --------------------------------------------------------------------
# Locate repository root relative to this file
# Expected path: dot-config/zsh/tests/telemetry/test-feature-timing-schema.zsh
# --------------------------------------------------------------------
SCRIPT_PATH="${(%):-%N}"
SCRIPT_DIR="${SCRIPT_PATH:A:h}"
ZSH_ROOT="${SCRIPT_DIR:A:h:h:h}"
REGISTRY_FILE="${ZSH_ROOT}/feature/registry/feature-registry.zsh"
PRIVACY_FILE="${ZSH_ROOT}/docs/redesignv2/privacy/PRIVACY_APPENDIX.md"

[[ -r "${REGISTRY_FILE}" ]] || _fail "Cannot read feature registry: ${REGISTRY_FILE}"
[[ -r "${PRIVACY_FILE}" ]] || _fail "Cannot read privacy appendix: ${PRIVACY_FILE}"

# --------------------------------------------------------------------
# Environment setup (enable telemetry + structured logging)
# --------------------------------------------------------------------
export ZSH_FEATURE_TELEMETRY=1
export ZSH_LOG_STRUCTURED=1

TMP_DIR="${TMPDIR:-/tmp}"
: "${TMP_DIR:=/tmp}"
JSON_LOG="${TMP_DIR}/test-feature-timing-schema.$$.json"
PLAIN_LOG="${TMP_DIR}/test-feature-timing-schema.$$.log"
: > "${JSON_LOG}"
: > "${PLAIN_LOG}"
export PERF_SEGMENT_JSON_LOG="${JSON_LOG}"
export PERF_SEGMENT_LOG="${PLAIN_LOG}"

# --------------------------------------------------------------------
# Source registry
# --------------------------------------------------------------------
source "${REGISTRY_FILE}"

# --------------------------------------------------------------------
# Register and define sample features (two for sequence check)
# --------------------------------------------------------------------
feature_registry_add "ft_schema_a" "2" "" "no" "telemetry" "Schema test feature A" "guid-schema-a" \
  || _fail "Failed to register ft_schema_a"
feature_registry_add "ft_schema_b" "2" "" "no" "telemetry" "Schema test feature B" "guid-schema-b" \
  || _fail "Failed to register ft_schema_b"

# Lightweight deterministic workloads
feature_ft_schema_a_init() {
  integer s=0
  for i in {1..60000}; do (( s+=i )); done
  return 0
}
feature_ft_schema_b_init() {
  integer s=0
  for i in {1..90000}; do (( s+=i )); done
  return 0
}

# --------------------------------------------------------------------
# Invoke init phase (emits timing)
# --------------------------------------------------------------------
feature_registry_invoke_phase init || _fail "invoke_phase init failed"

# --------------------------------------------------------------------
# Collect feature_timing lines
# --------------------------------------------------------------------
if ! grep -E '"type":"feature_timing"' "${JSON_LOG}" >/dev/null 2>&1; then
  _fail "No feature_timing JSON lines emitted"
fi

typeset -a FT_LINES
while IFS= read -r l; do
  FT_LINES+=("$l")
done < <(grep -E '"type":"feature_timing"' "${JSON_LOG}" || true)

(( ${#FT_LINES[@]} >= 2 )) || _fail "Expected >=2 feature_timing lines, got ${#FT_LINES[@]}"

# --------------------------------------------------------------------
# Allowed keys & validation
# --------------------------------------------------------------------
# Allowed / expected keys set (no extras permitted)
typeset -a ALLOWED_KEYS=(type feature ms phase sequence version ts_epoch_ms)

_is_allowed_key() {
  local k="$1"
  local a
  for a in "${ALLOWED_KEYS[@]}"; do
    [[ "$k" == "$a" ]] && return 0
  done
  return 1
}

typeset -a SEQS
integer saw_ms_gt_zero=0

for line in "${FT_LINES[@]}"; do
  # Basic required keys presence
  _assert "print -r -- \"$line\" | grep -q '\"type\":\"feature_timing\"'" "Missing type=feature_timing in line: $line"
  _assert "print -r -- \"$line\" | grep -q '\"phase\":\"init\"'" "Missing phase=init in line: $line"
  _assert "print -r -- \"$line\" | grep -q '\"version\":1'" "Missing version=1 in line: $line"
  _assert "print -r -- \"$line\" | grep -q '\"feature\":\"ft_schema_'" "Feature name not matching ft_schema_*: $line"

  # Extract ms
  ms_val="$(print -r -- "$line" | sed -n 's/.*\"ms\":\([0-9]\+\).*/\1/p')"
  [[ -n "${ms_val}" ]] || _fail "Missing ms numeric field: $line"
  [[ "${ms_val}" == <-> ]] || _fail "ms not integer: ${ms_val}"
  (( ms_val >= 0 )) || _fail "ms negative: ${ms_val}"
  (( ms_val > 0 )) && (( saw_ms_gt_zero++ ))

  # Extract sequence
  seq_val="$(print -r -- "$line" | sed -n 's/.*\"sequence\":\([0-9]\+\).*/\1/p')"
  [[ -n "${seq_val}" ]] || _fail "Missing sequence field: $line"
  [[ "${seq_val}" == <-> ]] || _fail "sequence not integer: ${seq_val}"
  SEQS+=("${seq_val}")

  # Extract ts_epoch_ms
  ts_val="$(print -r -- "$line" | sed -n 's/.*\"ts_epoch_ms\":\([0-9]\{13\}\).*/\1/p')"
  [[ -n "${ts_val}" ]] || _fail "Missing ts_epoch_ms 13-digit field: $line"
  [[ "${ts_val}" == <-> ]] || _fail "ts_epoch_ms not numeric: ${ts_val}"
  (( ${#ts_val} == 13 )) || _fail "ts_epoch_ms not 13 digits: ${ts_val}"

  # Detect extraneous keys by enumerating all "key": occurrences.
  # This is a heuristic appropriate for controlled emission format.
  keys_found=()
  while IFS= read -r k; do
    keys_found+=("$k")
  done < <(print -r -- "$line" | sed -E 's/[{}]/ /g' | tr ',' '\n' | sed -n 's/.*"([^"]+)":.*/\1/p')

  for k in "${keys_found[@]}"; do
    _is_allowed_key "$k" || _fail "Extraneous key '$k' in line: $line"
  done

  # Ensure all allowed keys appear (strict completeness)
  for want in "${ALLOWED_KEYS[@]}"; do
    _assert "print -r -- \"$line\" | grep -q '\"$want\"'" "Missing required key '$want' in line: $line"
  done
done

# Monotonic sequence strictly increasing
# (Sort numerically and compare to original order)
integer idx
for (( idx=2; idx <= ${#SEQS[@]}; idx++ )); do
  prev="${SEQS[idx-1]}"
  curr="${SEQS[idx]}"
  (( curr > prev )) || _fail "Sequence not strictly increasing: prev=${prev} curr=${curr}"
done

(( saw_ms_gt_zero > 0 )) || _fail "All ms values zero (insufficient timing resolution)"

# --------------------------------------------------------------------
# In-memory map cross-check
# --------------------------------------------------------------------
typeset -p ZSH_FEATURE_TIMINGS_SYNC >/dev/null 2>&1 \
  || _fail "ZSH_FEATURE_TIMINGS_SYNC not defined"

for f in ft_schema_a ft_schema_b; do
  val="${ZSH_FEATURE_TIMINGS_SYNC[$f]:-}"
  [[ -n "${val}" ]] || _fail "Missing timing map entry for ${f}"
  [[ "${val}" == <-> ]] || _fail "Non-integer timing for ${f}: ${val}"
done

# --------------------------------------------------------------------
# Privacy Appendix Validation
# --------------------------------------------------------------------
if ! grep -q 'ZSH_FEATURE_TELEMETRY' "${PRIVACY_FILE}"; then
  _fail "Privacy appendix missing ZSH_FEATURE_TELEMETRY row"
fi

# Ensure row is not stale (should not contain '(future)' anymore)
if grep -E 'ZSH_FEATURE_TELEMETRY.*future' "${PRIVACY_FILE}" >/dev/null 2>&1; then
  _fail "Privacy appendix still marks ZSH_FEATURE_TELEMETRY as future"
fi

# Optionally assert mention of per-feature timing description
grep -E 'ZSH_FEATURE_TELEMETRY.*per-feature init timing' "${PRIVACY_FILE}" >/dev/null 2>&1 \
  || _fail "Privacy appendix row for ZSH_FEATURE_TELEMETRY does not describe per-feature init timing"

_info "All T-TEL-03 schema & privacy assertions passed."

# Cleanup
rm -f -- "${JSON_LOG}" "${PLAIN_LOG}" 2>/dev/null || true

exit 0
