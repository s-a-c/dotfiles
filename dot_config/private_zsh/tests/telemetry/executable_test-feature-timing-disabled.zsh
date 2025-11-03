#!/usr/bin/env zsh
# test-feature-timing-disabled.zsh
#
# T-TEL-01: Feature Timing Telemetry Disabled Path
#
# Compliant with ${HOME}/.config/ai/guidelines.md v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316
#
# PURPOSE:
#   Validate that when both ZSH_FEATURE_TELEMETRY and structured JSON logging flags
#   are disabled (unset / zero):
#     1. No feature_timing JSON lines are emitted.
#     2. ZSH_FEATURE_TIMINGS_SYNC does not record timing entries for invoked features.
#
# SCOPE:
#   Covers disabled path only (T-TEL-01). Enabled path and schema validation
#   are implemented in complementary tests (T-TEL-02 / T-TEL-03).
#
# SUCCESS CRITERIA:
#   - feature-timing log sidecar contains zero lines matching '"type":"feature_timing"'.
#   - Associative array ZSH_FEATURE_TIMINGS_SYNC is either undefined or has no key
#     for the sample feature.
#   - Exit code 0 on pass, 1 on failure.
#
# IMPLEMENTATION DETAILS:
#   - Creates a temporary JSON target file and points PERF_SEGMENT_JSON_LOG to it.
#     Even though structured logging is disabled, this ensures we would capture lines
#     if they were (incorrectly) emitted.
#   - Defines a synthetic feature 'ft_disabled_sample' with a trivial init function.
#   - Invokes only the 'init' phase (timing emission scope) via registry.
#
# PERFORMANCE GUARD:
#   Disabled path should add effectively zero overhead (single flag check) — this
#   test keeps workload minimal (single feature) to avoid masking regressions.
#
# EXIT CODES:
#   0 success
#   1 failure
#
# ------------------------------------------------------------------------------

emulate -L zsh
setopt errexit nounset pipefail

# ------------- Helpers --------------------------------------------------------
_fail() { print -r -- "[FAIL][T-TEL-01] $*" >&2; exit 1; }
_info() { print -r -- "[INFO][T-TEL-01] $*" >&2; }
_assert_file_absent_pattern() {
  local pattern="$1" file="$2" msg="$3"
  if grep -E -- "${pattern}" -- "${file}" >/dev/null 2>&1; then
    _fail "${msg}: pattern '${pattern}' found in ${file}"
  fi
}

# ------------- Locate & Source Registry ---------------------------------------
# Expect repository layout where this test sits under:
#   dot-config/zsh/tests/telemetry/
SCRIPT_PATH="${(%):-%N}"
SCRIPT_DIR="${SCRIPT_PATH:A:h}"
ZSH_ROOT="${SCRIPT_DIR:A:h:h:h}"   # ascend back to dot-config/zsh
REGISTRY_FILE="${ZSH_ROOT}/feature/registry/feature-registry.zsh"

[[ -r "${REGISTRY_FILE}" ]] || _fail "Feature registry file not readable: ${REGISTRY_FILE}"

# Source the registry (no flags set prior)
source "${REGISTRY_FILE}"

# Sanity: ensure guard / core arrays exist
typeset -p ZSH_FEATURE_REGISTRY_NAMES >/dev/null 2>&1 || _fail "Registry arrays not initialized"

# ------------- Environment (Disabled Telemetry) -------------------------------
# Explicitly ensure telemetry-related flags are *unset / disabled*
unset ZSH_FEATURE_TELEMETRY 2>/dev/null || true
unset ZSH_LOG_STRUCTURED 2>/dev/null || true
unset ZSH_PERF_JSON 2>/dev/null || true

# Create temp files (simulate harness targets)
TMP_DIR="${TMPDIR:-/tmp}"
: "${TMP_DIR:=/tmp}"

FEATURE_TIMING_JSON_LOG="${TMP_DIR}/test-feature-timing-disabled.$$.json"
SEGMENT_PLAIN_LOG="${TMP_DIR}/test-feature-timing-disabled.$$.log"

: > "${FEATURE_TIMING_JSON_LOG}"
: > "${SEGMENT_PLAIN_LOG}"

# Point logging variables (should remain silent under disabled flags)
export PERF_SEGMENT_JSON_LOG="${FEATURE_TIMING_JSON_LOG}"
export PERF_SEGMENT_LOG="${SEGMENT_PLAIN_LOG}"

# ------------- Define Sample Feature -----------------------------------------
# Registration: name phase depends deferred category description guid
feature_registry_add "ft_disabled_sample" "2" "" "no" "telemetry" "Disabled path timing sample" "guid-ft-disabled-sample" \
  || _fail "Failed to register sample feature"

# Provide init implementation (would be timed if telemetry active)
feature_ft_disabled_sample_init() {
  # Minimal work; avoid sleeps to keep test fast
  integer x=0
  for i in {1..50}; do (( x+=i )); done
  return 0
}

# ------------- Invoke init Phase ---------------------------------------------
feature_registry_invoke_phase init || _fail "invoke_phase init returned non-zero"

# ------------- Assertions -----------------------------------------------------
# 1) No feature_timing JSON lines
_assert_file_absent_pattern '"type":"feature_timing"' "${FEATURE_TIMING_JSON_LOG}" \
  "feature_timing JSON unexpectedly emitted while telemetry disabled"

# 2) No timing stored in ZSH_FEATURE_TIMINGS_SYNC for our feature
if typeset -p ZSH_FEATURE_TIMINGS_SYNC >/dev/null 2>&1; then
  if [[ -n "${ZSH_FEATURE_TIMINGS_SYNC[ft_disabled_sample]:-}" ]]; then
    _fail "Timing entry found in ZSH_FEATURE_TIMINGS_SYNC for ft_disabled_sample with telemetry disabled"
  fi
fi

# 3) Plain segment log should NOT contain feature_timing either
_assert_file_absent_pattern 'feature_timing' "${SEGMENT_PLAIN_LOG}" \
  "Plain segment log contained unexpected feature_timing artifact"

_info "All assertions passed: disabled feature timing path produced no timing artifacts."

# Cleanup (best-effort, ignore errors)
rm -f -- "${FEATURE_TIMING_JSON_LOG}" "${SEGMENT_PLAIN_LOG}" 2>/dev/null || true

exit 0
