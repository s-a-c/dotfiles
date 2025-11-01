#!/usr/bin/env zsh
# test-preplugin-segment-threshold.zsh
# Compliant with [${HOME}/dotfiles/dot-config/ai/guidelines.md](${HOME}/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Enforce that pre‑plugin segment timing instrumentation is present and that the
#   pre‑plugin cost has not regressed beyond an allowed threshold relative to an
#   optional stored baseline.
#
# SCOPE:
#   Reads metrics emitted by tools/perf-capture.zsh (perf-current.json) in the
#   redesignv2 metrics directory (preferred) or legacy redesign directory fallback.
#
# INVARIANTS:
#   I1: perf-current.json exists.
#   I2: segments_available == true.
#   I3: pre_plugin_cost_ms > 0.
#   I4: pre_plugin_cost_ms <= PREPLUGIN_MAX_MS (default 150ms, override via env).
#   I5: If segment baseline file present and contains baseline_pre_plugin_cost_ms > 0,
#       then pre_plugin_cost_ms <= baseline * (1 + PREPLUGIN_REGRESSION_PCT/100) (default 15%).
#
# BASELINE HANDLING:
#   Optional baseline file: perf-segment-baseline.json (same directory as perf-current.json).
#   Structure (example):
#     {
#       "timestamp":"20250901T010203",
#       "baseline_pre_plugin_cost_ms":30
#     }
#   If absent, regression comparison (I5) is skipped (PASS if other invariants hold).
#
# EXIT CODES:
#   0 PASS
#   1 FAIL
#   2 SKIP (only used if metrics file completely absent — indicates perf not yet captured)
#
# ENVIRONMENT OVERRIDES:
#   PREPLUGIN_MAX_MS              (absolute upper bound, default 150)
#   PREPLUGIN_REGRESSION_PCT      (allowed % over baseline, default 15)
#   PREPLUGIN_REQUIRE_BASELINE=1  (if set, absence of baseline causes FAIL instead of skipping I5)
#
# NOTE:
#   This test intentionally uses only POSIX tools (grep/sed/awk) to avoid jq dependency.
#
set -euo pipefail

# Debug helper (noop if not defined globally)
typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# Resolve metrics directory (mirror logic from perf-capture.zsh)
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
PREF_A="${ZDOTDIR}/docs/redesignv2/artifacts/metrics"
PREF_B="${ZDOTDIR}/docs/redesign/metrics"
if [[ -d "$PREF_A" ]]; then
    METRICS_DIR="$PREF_A"
elif [[ -d "$PREF_B" ]]; then
    METRICS_DIR="$PREF_B"
else
    echo "SKIP: no metrics directory found (run perf-capture first)"
    exit 2
fi

CURRENT="${METRICS_DIR}/perf-current.json"
if [[ ! -f "$CURRENT" ]]; then
    echo "SKIP: perf-current.json not found – run perf-capture.zsh"
    exit 2
fi

BASELINE_FILE="${METRICS_DIR}/perf-segment-baseline.json"

# Config thresholds
: "${PREPLUGIN_MAX_MS:=150}"
: "${PREPLUGIN_REGRESSION_PCT:=15}"
: "${PREPLUGIN_REQUIRE_BASELINE:=0}"

_failures=()

# Extract helper (numeric)
_extract_number() {
    # $1 = key regex (anchored), $2 = file
    local key="$1" file="$2"
    local line
    line=$(grep -E "\"${key}\"" "$file" 2>/dev/null | head -1 || true)
    # Strip everything up to colon, remove trailing comma, keep leading digits
    local val
    val=$(printf "%s" "$line" | sed 's/.*: *//; s/,//; s/[^0-9].*$//')
    [[ -z "$val" ]] && echo "" && return 0
    echo "$val"
}

_extract_bool() {
    local key="$1" file="$2"
    local line
    line=$(grep -E "\"${key}\"" "$file" 2>/dev/null | head -1 || true)
    local val
    val=$(printf "%s" "$line" | sed 's/.*: *//; s/,//; s/[[:space:]]//g')
    # Expect true/false
    echo "$val"
}

pre_ms="$(_extract_number pre_plugin_cost_ms "$CURRENT")"
segments_available="$(_extract_bool segments_available "$CURRENT")"

if [[ "${segments_available}" != "true" ]]; then
    _failures+=("I2 segments_available != true (value='${segments_available:-<empty>}') – instrumentation missing")
fi

if [[ -z "$pre_ms" || "$pre_ms" == "0" ]]; then
    _failures+=("I3 pre_plugin_cost_ms missing or zero (value='${pre_ms:-<empty>}')")
fi

# Absolute max bound (only if we have a numeric value)
if [[ -n "${pre_ms}" && "${pre_ms}" != "0" ]]; then
    if ((pre_ms > PREPLUGIN_MAX_MS)); then
        _failures+=("I4 pre_plugin_cost_ms=${pre_ms}ms exceeds PREPLUGIN_MAX_MS=${PREPLUGIN_MAX_MS}ms")
    fi
fi

baseline_pre=""
if [[ -f "$BASELINE_FILE" ]]; then
    baseline_pre="$(_extract_number baseline_pre_plugin_cost_ms "$BASELINE_FILE")"
    if [[ -n "$baseline_pre" && "$baseline_pre" != "0" && -n "$pre_ms" && "$pre_ms" != "0" ]]; then
        # Allowed max = baseline * (1 + pct/100)
        allowed_max=$(awk -v b="$baseline_pre" -v p="$PREPLUGIN_REGRESSION_PCT" 'BEGIN{printf "%.0f", b * (1 + p/100.0)}')
        if ((pre_ms > allowed_max)); then
            _failures+=("I5 regression: pre_ms=${pre_ms}ms > allowed ${allowed_max}ms (baseline=${baseline_pre}ms, pct=${PREPLUGIN_REGRESSION_PCT}%)")
        fi
    elif [[ -z "$baseline_pre" || "$baseline_pre" == "0" ]]; then
        zf::debug "# [perf-test] baseline file present but baseline_pre_plugin_cost_ms missing/zero – skipping I5 regression check"
    fi
else
    if ((PREPLUGIN_REQUIRE_BASELINE == 1)); then
        _failures+=("I5 baseline required but ${BASELINE_FILE} not found")
    else
        zf::debug "# [perf-test] baseline file not found – skipping regression comparison (I5)"
    fi
fi

# Output decision
if ((${#_failures[@]} == 0)); then
    echo "PASS: pre-plugin segment instrumentation OK (pre_plugin_cost_ms=${pre_ms:-?}ms; baseline=${baseline_pre:-none})"
    exit 0
fi

echo "FAIL: pre-plugin segment threshold violations:"
for f in "${_failures[@]}"; do
    echo "  - $f"
done

# Provide quick diagnostics snippet (first 40 lines of current metrics)
echo ""
echo "---- perf-current.json (head) ----"
head -40 "$CURRENT" | sed 's/^/  /'
echo "----------------------------------"

exit 1
