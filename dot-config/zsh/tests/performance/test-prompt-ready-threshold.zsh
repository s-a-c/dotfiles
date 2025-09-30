#!/usr/bin/env zsh
# test-prompt-ready-threshold.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v900f08def0e6f7959ffd283aebb73b625b3473f5e49c57e861c6461b50a62ef2
#
# PURPOSE:
#   Validate that prompt readiness instrumentation is present and that the
#   average prompt_ready_ms (mean of cold/warm or computed aggregate in perf-current.json)
#   does not exceed a configured threshold (default 400ms).
#
# SCOPE:
#   Reads perf-current.json produced by tools/perf-capture.zsh (which should now
#   populate prompt_ready_ms when markers are emitted by 95-prompt-ready.zsh).
#
# INVARIANTS:
#   I1: perf-current.json exists.
#   I2: segments_available == true.
#   I3: prompt_ready_ms present and > 0 (otherwise instrumentation missing → SKIP).
#   I4: prompt_ready_ms <= PROMPT_READY_MAX_MS (default 400).
#
# EXIT CODES:
#   0 PASS
#   1 FAIL
#   2 SKIP (instrumentation or metrics not yet available)
#
# ENV OVERRIDES:
#   PROMPT_READY_MAX_MS   Absolute ceiling (default 400)
#   PROMPT_READY_REQUIRE=1  Force FAIL (not SKIP) if prompt_ready_ms missing
#
# IMPLEMENTATION:
#   - Avoid jq dependency: use grep/sed/awk.
#   - Permissive mode by default: missing metric => SKIP to allow gradual rollout.
#
set -euo pipefail

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

: "${PROMPT_READY_MAX_MS:=400}"
: "${PROMPT_READY_REQUIRE:=0}"

ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"

# Resolve metrics directory (prefer redesignv2)
if [[ -d "${ZDOTDIR}/docs/redesignv2/artifacts/metrics" ]]; then
    METRICS_DIR="${ZDOTDIR}/docs/redesignv2/artifacts/metrics"
elif [[ -d "${ZDOTDIR}/docs/redesign/metrics" ]]; then
    METRICS_DIR="${ZDOTDIR}/docs/redesign/metrics"
else
    echo "SKIP: metrics directory not found (run perf-capture first)"
    exit 2
fi

METRICS_FILE="${METRICS_DIR}/perf-current.json"

if [[ ! -f "$METRICS_FILE" ]]; then
    echo "SKIP: perf-current.json missing (run perf-capture.zsh)"
    exit 2
fi

# Helper: extract numeric field value (integers only) from JSON-ish file without jq
_extract_number() {
    # $1 key, $2 file
    local key="$1" file="$2"
    local line
    line=$(grep -E "\"${key}\"" "$file" 2>/dev/null | head -1 || true)
    [[ -z $line ]] && return 0
    # Remove everything up to colon, strip comma, keep optional digits
    printf "%s" "$line" | sed 's/.*: *//; s/,//; s/[^0-9].*$//' | sed 's/^ *//'
}

_extract_bool() {
    local key="$1" file="$2"
    local line
    line=$(grep -E "\"${key}\"" "$file" 2>/dev/null | head -1 || true)
    [[ -z $line ]] && return 0
    printf "%s" "$line" | sed 's/.*: *//; s/,//; s/[[:space:]]//g'
}

segments_available=$(_extract_bool "segments_available" "$METRICS_FILE")
prompt_ready_ms=$(_extract_number "prompt_ready_ms" "$METRICS_FILE")

failures=()

# I1: file existence already confirmed
# I2: segments_available must be true
if [[ "${segments_available}" != "true" ]]; then
    failures+=("I2 segments_available != true (value='${segments_available:-<empty>}')")
fi

# I3: prompt_ready_ms > 0
if [[ -z "${prompt_ready_ms:-}" || "${prompt_ready_ms}" == "0" ]]; then
    if ((PROMPT_READY_REQUIRE == 1)); then
        failures+=("I3 prompt_ready_ms missing or zero (required mode)")
    else
        # Non-required: treat as SKIP (instrumentation not yet active)
        echo "SKIP: prompt_ready_ms not captured (instrumentation not active yet)"
        exit 2
    fi
fi

# I4: threshold
if [[ -n "${prompt_ready_ms:-}" && "${prompt_ready_ms}" != "0" ]]; then
    if ((prompt_ready_ms > PROMPT_READY_MAX_MS)); then
        failures+=("I4 prompt_ready_ms=${prompt_ready_ms}ms exceeds PROMPT_READY_MAX_MS=${PROMPT_READY_MAX_MS}ms")
    fi
fi

if ((${#failures[@]} == 0)); then
    echo "PASS: prompt readiness OK (prompt_ready_ms=${prompt_ready_ms:-n/a}ms threshold=${PROMPT_READY_MAX_MS}ms)"
    exit 0
fi

echo "FAIL: prompt readiness threshold violations:"
for f in "${failures[@]}"; do
    echo "  - $f"
done

echo ""
echo "---- perf-current.json (excerpt) ----"
head -40 "$METRICS_FILE" | sed 's/^/  /'
echo "-------------------------------------"

exit 1
