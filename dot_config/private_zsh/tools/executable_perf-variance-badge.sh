#!/usr/bin/env bash
# perf-variance-badge.sh
# Compliant with [/Users/s-a-c/.config/ai/guidelines.md](/Users/s-a-c/.config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Generate a Shields‑compatible JSON (or plain text) badge summarizing relative
#   variability (RSD = stddev / mean) for a selected performance metric from the
#   multi-sample aggregate file perf-multi-current.json produced by
#   tools/perf-capture-multi.zsh.
#
# OUTPUT (Shields JSON example):
#   {"label":"post_plugin_var","message":"rsd=0.08","color":"green"}
#
# FEATURES:
#   - Zero external hard dependency: uses awk/grep/sed; optional jq if present.
#   - Configurable metric selection & color thresholds.
#   - Graceful fallbacks with explicit error messages & non-zero exit codes.
#
# USAGE:
#   ./tools/perf-variance-badge.sh
#   METRIC=post_plugin_cost_ms ./tools/perf-variance-badge.sh
#   METRIC=prompt_ready_ms FORMAT=text ./tools/perf-variance-badge.sh
#
# ENVIRONMENT:
#   METRICS_DIR          Override directory containing perf-multi-current.json
#   METRIC               Aggregate metric key (default: post_plugin_cost_ms)
#   FORMAT               shields|text (default: shields)
#   LABEL                Badge label override (default: <metric>_var)
#   GREEN_MAX            Upper RSD (inclusive) for green (default 0.10)
#   YELLOW_MAX           Upper RSD (inclusive) for yellow (default 0.20)
#   RED_MAX              Upper RSD for red threshold sanity (default 10.0)
#   PRECISION            Decimal places for rsd display (default 2)
#   FAIL_ON_MISSING=1    Exit non-zero if file/metric missing (default 1)
#
# EXIT CODES:
#   0  Success
#   1  perf-multi-current.json not found
#   2  Metric block or values not found / invalid
#   3  Internal arithmetic or threshold error
#
# NOTES:
#   - RSD (relative standard deviation) gives a dimensionless variance indicator.
#   - High RSD suggests environmental noise or unstable instrumentation.
#
# FUTURE:
#   - Optional percentile extraction once added to perf-multi schema.
#   - Multi-metric composite badges.
#
set -euo pipefail

METRIC="${METRIC:-post_plugin_cost_ms}"
FORMAT="${FORMAT:-shields}"
LABEL="${LABEL:-${METRIC}_var}"
PRECISION="${PRECISION:-2}"

GREEN_MAX="${GREEN_MAX:-0.10}"
YELLOW_MAX="${YELLOW_MAX:-0.20}"
RED_MAX="${RED_MAX:-10.0}"

FAIL_ON_MISSING="${FAIL_ON_MISSING:-1}"

# Resolve metrics directory (prefer redesignv2)
if [[ -z "${METRICS_DIR:-}" ]]; then
  # Attempt common locations relative to ZDOTDIR
  ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
  if [[ -f "$ZDOTDIR/docs/redesignv2/artifacts/metrics/perf-multi-current.json" ]]; then
    METRICS_DIR="$ZDOTDIR/docs/redesignv2/artifacts/metrics"
  elif [[ -f "$ZDOTDIR/docs/redesign/metrics/perf-multi-current.json" ]]; then
    METRICS_DIR="$ZDOTDIR/docs/redesign/metrics"
  else
    METRICS_DIR="."
  fi
fi

MULTI_FILE="${MULTI_FILE:-$METRICS_DIR/perf-multi-current.json}"

err() {
  echo "[perf-variance-badge] ERROR: $*" >&2
}

warn() {
  echo "[perf-variance-badge] WARN: $*" >&2
}

have_jq=0
command -v jq >/dev/null 2>&1 && have_jq=1

if [[ ! -f "$MULTI_FILE" ]]; then
  err "File not found: $MULTI_FILE"
  if [[ $FAIL_ON_MISSING == 1 ]]; then
    exit 1
  else
    [[ $FORMAT == "shields" ]] && echo '{"label":"'"$LABEL"'","message":"missing","color":"lightgrey"}'
    [[ $FORMAT == "text" ]] && echo "$LABEL missing"
    exit 0
  fi
fi

mean=""
stddev=""

if (( have_jq == 1 )); then
  # Use jq if available for exact parsing
  mean=$(jq -r --arg m "$METRIC" '.aggregate[$m].mean // empty' "$MULTI_FILE" 2>/dev/null || true)
  stddev=$(jq -r --arg m "$METRIC" '.aggregate[$m].stddev // empty' "$MULTI_FILE" 2>/dev/null || true)
fi

# Fallback grep/sed parsing if jq absent or returned empty
if [[ -z "$mean" || -z "$stddev" ]]; then
  # Strategy:
  #  1. Find line index where "<metric>": { begins.
  #  2. From there, scan subsequent ~10 lines for "mean": and "stddev":
  block=$(awk -v m="\"${METRIC}\"" '
    $0 ~ m"[[:space:]]*:" {
      # capture next few lines (including this)
      print; c=0
      while (c<12 && getline) {print; c++}
    }
  ' "$MULTI_FILE" 2>/dev/null || true)

  mean=$(printf '%s\n' "$block" | grep -E '"mean"[[:space:]]*:' | head -1 | sed -E 's/.*"mean"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' || true)
  stddev=$(printf '%s\n' "$block" | grep -E '"stddev"[[:space:]]*:' | head -1 | sed -E 's/.*"stddev"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' || true)
fi

if ! [[ "$mean" =~ ^[0-9]+$ ]]; then
  err "Mean not found/invalid for metric '$METRIC' (value='$mean')"
  exit 2
fi
if ! [[ "$stddev" =~ ^[0-9]+$ ]]; then
  err "Stddev not found/invalid for metric '$METRIC' (value='$stddev')"
  exit 2
fi
if (( mean == 0 )); then
  # Avoid divide by zero; treat as zero variance (or unknown)
  rsd="0"
else
  rsd=$(awk -v s="$stddev" -v m="$mean" -v p="$PRECISION" 'BEGIN{
    if (m <= 0) {print "0"; exit}
    r = s / m
    fmt = "%."p"f"
    printf(fmt, r)
  }')
fi

# Determine color
color="red"
# Compare using awk for float safety
lt() { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a<b)}'; }
le() { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a<=b)}'; }

if lt "$rsd" 0; then
  err "Computed negative RSD ($rsd) – invalid"
  exit 3
fi
if le "$rsd" "$GREEN_MAX"; then
  color="green"
elif le "$rsd" "$YELLOW_MAX"; then
  color="yellow"
elif le "$rsd" "$RED_MAX"; then
  color="red"
else
  color="lightgrey"
  warn "RSD $rsd exceeds RED_MAX ($RED_MAX) – marking lightgrey"
fi

# Build message (truncate to precision)
disp_rsd="$rsd"
# Ensure trailing zeros up to precision
if [[ "$PRECISION" =~ ^[0-9]+$ ]]; then
  # Force formatting with awk
  disp_rsd=$(awk -v r="$rsd" -v p="$PRECISION" 'BEGIN{fmt="%."p"f"; printf(fmt,r)}')
fi

case "$FORMAT" in
  shields)
    printf '{"label":"%s","message":"rsd=%s","color":"%s"}\n' "$LABEL" "$disp_rsd" "$color"
    ;;
  text)
    printf '%s rsd=%s mean=%s stddev=%s color=%s\n' "$LABEL" "$disp_rsd" "$mean" "$stddev" "$color"
    ;;
  *)
    err "Unknown FORMAT='$FORMAT' (expected shields|text)"
    exit 3
    ;;
esac

exit 0
