#!/usr/bin/env zsh
# ==============================================================================
# Performance Test: Feature Synchronous Init Timing Gating
# File: tests/performance/test-feature-sync-timings.zsh
#
# Compliant with [${HOME}/dotfiles/dot-config/ai/guidelines.md](${HOME}/dotfiles/dot-config/ai/guidelines.md) v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316
#
# Purpose:
#   Enforce early Stage 4 per‑feature synchronous initialization performance
#   expectations using the feature invocation wrapper’s telemetry output.
#
#   This test:
#     1. Executes the feature timing extraction tool in a clean (-f) shell.
#     2. Captures per-feature synchronous init timings (ms).
#     3. Validates presence & sanity of the noop feature timing.
#     4. Applies per-feature thresholds (current focus: noop exemplar).
#     5. Provides extensible gating for additional features as they are added.
#
# Threshold Policy (initial):
#   - noop: MUST be present; MUST be <= ${PERF_FEATURE_NOOP_MAX_MS:-50} ms (default).
#   - Any feature timing < 0 or > hard ceiling -> failure.
#
# Environment Overrides:
#   PERF_FEATURE_NOOP_MAX_MS   (default 50)
#   PERF_FEATURE_GENERIC_MAX_MS (fallback for unspecified features, default 120)
#
# Exit Codes:
#   0 = success
#   1 = failure (one or more violations)
#
# Notes:
#   - Does not measure aggregate cold start; that remains covered by existing perf harness.
#   - Extensible: add per-feature custom thresholds to FEATURE_LIMITS associative array.
#   - Runs under `zsh -f`; independent of user configuration.
#
# Sensitive Actions:
#   - None (local script execution only).
# ==============================================================================

emulate -L zsh
setopt pipe_fail
setopt nounset

# ------------------------------------------------------------------------------
# Assertion / Logging Helpers
# ------------------------------------------------------------------------------
typeset -gA _PT_TIMINGS
typeset -gA _PT_STATUS
typeset -gA _PT_ERRORS
typeset -gA FEATURE_LIMITS

_FAIL_COUNT=0
_SECTION="(unset)"

section() {
  _SECTION="$1"
  print -- "[SECTION] $1"
}

log_info()  { print -- "[INFO]  $*"; }
log_warn()  { print -- "[WARN]  $*"; }
log_error() { print -u2 -- "[ERROR] $*"; }

fail() {
  (( _FAIL_COUNT++ ))
  log_error "$_SECTION: $*"
}

# ------------------------------------------------------------------------------
# Threshold Configuration
# ------------------------------------------------------------------------------
: "${PERF_FEATURE_NOOP_MAX_MS:=50}"
: "${PERF_FEATURE_GENERIC_MAX_MS:=120}"

# Per-feature explicit limits (feature -> max_ms)
FEATURE_LIMITS[noop]="$PERF_FEATURE_NOOP_MAX_MS"

# ------------------------------------------------------------------------------
# Resolve Repository Root
# ------------------------------------------------------------------------------
# This file: .../tests/performance/test-feature-sync-timings.zsh
__test_dir="${0:A:h}"
__repo_root="${__test_dir%/tests/performance}"

if [[ ! -d "${__repo_root}/feature/registry" ]]; then
  fail "Could not locate feature registry in ${__repo_root}/feature/registry"
  print -u2 -- "[RESULT] FAIL (early abort)"
  exit 1
fi

# ------------------------------------------------------------------------------
# Execute Timing Extraction Tool
# ------------------------------------------------------------------------------
_TIMING_TOOL="${__repo_root}/tools/perf-extract-feature-sync.zsh"
if [[ ! -x "$_TIMING_TOOL" ]]; then
  if [[ -f "$_TIMING_TOOL" ]]; then
    # fallback: ensure executable bit not strictly required
    :
  else
    fail "Timing extraction tool not found: $_TIMING_TOOL"
    print -u2 -- "[RESULT] FAIL (early abort)"
    exit 1
  fi
fi

section "collect-timings"

RAW_OUTPUT="$(cd "${__repo_root}" && zsh -f "./tools/perf-extract-feature-sync.zsh" --raw 2>&1)" || {
  fail "Failed running timing extraction tool"
  print -u2 -- "[DEBUG] Raw tool output:\n${RAW_OUTPUT}"
  print -u2 -- "[RESULT] FAIL"
  exit 1
}

# ------------------------------------------------------------------------------
# Parse Output
# Lines: timing.<name>=<ms> OR status.<name>=<value>
# ------------------------------------------------------------------------------
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  case "$line" in
    timing.*=*)
      key="${line#timing.}"; key="${key%%=*}"
      val="${line#*=}"
      if [[ "$val" == <-> ]]; then
        _PT_TIMINGS["$key"]="$val"
      else
        fail "Non-integer timing for feature '$key': $val"
      fi
      ;;
    status.*=*)
      key="${line#status.}"; key="${key%%=*}"
      val="${line#*=}"
      _PT_STATUS["$key"]="$val"
      ;;
  esac
done <<<"$RAW_OUTPUT"

if (( ${#_PT_TIMINGS[@]} == 0 )); then
  fail "No timings captured (ensure telemetry is active in invocation wrapper)"
fi

# ------------------------------------------------------------------------------
# Sanity & Threshold Checks
# ------------------------------------------------------------------------------
section "validate-timings"

for feature timing in "${(@kv)_PT_TIMINGS}"; do
  # baseline constraints
  if (( timing < 0 )); then
    fail "Feature '$feature' reported negative timing: $timing ms"
    continue
  fi
  # Derive allowed limit
  limit="${FEATURE_LIMITS[$feature]:-$PERF_FEATURE_GENERIC_MAX_MS}"
  if (( timing > limit )); then
    fail "Feature '$feature' timing ${timing}ms exceeds limit ${limit}ms"
  else
    print -- "[OK] ${feature}: ${timing}ms (limit ${limit}ms)"
  fi
done

# Specific required feature presence
section "required-features"
if [[ -z "${_PT_TIMINGS[noop]:-}" ]]; then
  fail "Required exemplar feature 'noop' missing from timing set"
fi

# ------------------------------------------------------------------------------
# Status Checks
# ------------------------------------------------------------------------------
section "status-checks"
for feature status in "${(@kv)_PT_STATUS}"; do
  if [[ "$status" == "error" ]]; then
    fail "Feature '$feature' invocation status=error"
  fi
done

# Ensure every timed feature has a status (non-fatal if missing, but warn)
for feature in "${(@k)_PT_TIMINGS}"; do
  if [[ -z "${_PT_STATUS[$feature]:-}" ]]; then
    log_warn "Feature '$feature' has timing but no status entry (acceptable, but instrumentation should record status)"
  fi
done

# ------------------------------------------------------------------------------
# Reporting & Exit
# ------------------------------------------------------------------------------
section "report"
print -- "Collected features: ${#_PT_TIMINGS[@]}"
print -- "Failures: ${_FAIL_COUNT}"

if (( _FAIL_COUNT > 0 )); then
  print -u2 -- "[RESULT] FAIL (${_FAIL_COUNT} violations)"
  exit 1
fi

print -- "[RESULT] OK"
exit 0
