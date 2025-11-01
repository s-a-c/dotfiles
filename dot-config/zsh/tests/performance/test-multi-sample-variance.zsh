#!/usr/bin/env zsh
# test-multi-sample-variance.zsh
# Compliant with [${HOME}/dotfiles/dot-config/ai/guidelines.md](${HOME}/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Validate stability (variance characteristics) of multi-sample startup performance
#   aggregation produced by tools/perf-capture-multi.zsh (perf-multi-current.json).
#   This test provides an automated readiness signal for advancing from
#   Phase 0 (observe) → Phase 1 (warn) in the Interim Performance Roadmap.
#
# SCOPE:
#   - Confirms presence and shape of perf-multi-current.json (schema perf-multi.v1).
#   - Verifies minimum sample count.
#   - Computes relative standard deviation (stddev/mean) for core lifecycle metrics.
#   - Applies stricter gating to post_plugin_cost_ms (primary optimization target).
#   - Optionally enforces segment aggregation presence (if configured).
#
# INVARIANTS:
#   I1: Aggregate file exists.
#   I2: Schema == perf-multi.v1.
#   I3: samples >= MULTI_VARIANCE_MIN_SAMPLES (default 3).
#   I4: Required metric blocks exist: cold_ms, warm_ms, pre_plugin_cost_ms,
#       post_plugin_cost_ms, prompt_ready_ms.
#   I5: For each required metric block: mean, min, max, stddev, values[] present.
#   I6: values[] length == samples for each metric.
#   I7: post_plugin_cost_ms relative stddev <= MULTI_VARIANCE_POST_PLUGIN_REL_STDDEV_MAX (default 0.25 WARN, 0.15 FAIL).
#   I8: At least MULTI_VARIANCE_MIN_STABLE_METRICS (default 3) metrics have relative stddev <= MULTI_VARIANCE_REL_STDDEV_MAX (default 0.20).
#   I9: If MULTI_VARIANCE_REQUIRE_SEGMENTS=1 then segments array present (non-empty) OR test fails.
#   I10: No metric mean reported as 0 while stddev > 0 (consistency check).
#
# CONFIG (Environment Overrides):
#   MULTI_VARIANCE_FILE=...                         Path to perf-multi-current.json
#   MULTI_VARIANCE_MIN_SAMPLES=3                    Minimum sample count
#   MULTI_VARIANCE_POST_PLUGIN_REL_STDDEV_MAX=0.15  Hard fail threshold (post_plugin)
#   MULTI_VARIANCE_POST_PLUGIN_REL_STDDEV_WARN=0.25 Warn threshold (post_plugin)
#   MULTI_VARIANCE_REL_STDDEV_MAX=0.20              Hard fail threshold (generic metrics)
#   MULTI_VARIANCE_REL_STDDEV_WARN=0.30             Warn threshold (generic metrics)
#   MULTI_VARIANCE_MIN_STABLE_METRICS=3             Minimum metrics under hard threshold
#   MULTI_VARIANCE_REQUIRE_SEGMENTS=0               Set to 1 to require segments array
#
# EXIT CODES:
#   0 PASS (all required invariants satisfied; warnings permitted)
#   1 FAIL (any required invariant violated)
#
# NOTES:
#   - Relative stddev = stddev / mean (rounded to 4 decimal places for reporting).
#   - If mean == 0, relative stddev treated as 0 only if stddev == 0; else failure (I10).
#   - Warnings do not fail the test; they indicate need for more sampling or stability work.
#
# FUTURE:
#   - Add percentile checks (p50/p95) when aggregator supports them.
#   - Integrate adaptive baseline update gating once gate mode active.
#
# -----------------------------------------------------------------------------

set -euo pipefail

# Color helpers
if [[ -t 1 ]]; then
  GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  GREEN=""; RED=""; YELLOW=""; BOLD=""; RESET=""
fi

pass() { print "${GREEN}PASS${RESET}: $*"; }
fail() { print "${RED}FAIL${RESET}: $*"; FAILURES+=("$*"); }
warn() { print "${YELLOW}WARN${RESET}: $*"; WARNINGS+=("$*"); }
info() { print "${YELLOW}INFO${RESET}: $*"; }

FAILURES=()
WARNINGS=()

# Defaults
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
DEFAULT_FILE="${ZDOTDIR}/docs/redesignv2/artifacts/metrics/perf-multi-current.json"

FILE="${MULTI_VARIANCE_FILE:-$DEFAULT_FILE}"
MIN_SAMPLES="${MULTI_VARIANCE_MIN_SAMPLES:-3}"
POST_PLUGIN_REL_STDDEV_MAX="${MULTI_VARIANCE_POST_PLUGIN_REL_STDDEV_MAX:-0.15}"
POST_PLUGIN_REL_STDDEV_WARN="${MULTI_VARIANCE_POST_PLUGIN_REL_STDDEV_WARN:-0.25}"
GENERIC_REL_STDDEV_MAX="${MULTI_VARIANCE_REL_STDDEV_MAX:-0.20}"
GENERIC_REL_STDDEV_WARN="${MULTI_VARIANCE_REL_STDDEV_WARN:-0.30}"
MIN_STABLE_METRICS="${MULTI_VARIANCE_MIN_STABLE_METRICS:-3}"
REQUIRE_SEGMENTS="${MULTI_VARIANCE_REQUIRE_SEGMENTS:-0}"

REQUIRED_METRICS=(cold_ms warm_ms pre_plugin_cost_ms post_plugin_cost_ms prompt_ready_ms)

# I1: File exists
if [[ ! -f "$FILE" ]]; then
  fail "I1 aggregate file not found: $FILE (run tools/perf-capture-multi.zsh first)"
  print ""
  print "${BOLD}${RED}FAIL${RESET}: Missing required aggregate file."
  exit 1
else
  pass "I1 aggregate file present ($FILE)"
fi

# Load entire file
CONTENT=$(<"$FILE")

# Quick helper to extract numeric field under aggregate.<metric>.<key>
# We rely on predictable formatting from perf-capture-multi.zsh; robust JSON parsing intentionally avoided.
extract_metric_field() {
  local metric="$1" field="$2"
  # Locate block start
  print -- "$CONTENT" | awk -v m="\"${metric}\":" -v f="\"${field}\":" '
    $0 ~ m { in=1 }
    in && $0 ~ f {
      gsub(/[^0-9]/,"",$0); print $0; exit
    }
    in && $0 ~ /^\s*}/ { in=0 }
  '
}

# Extract "samples"
SAMPLES=$(print -- "$CONTENT" | grep -E '"samples"[[:space:]]*:' | head -1 | sed -E 's/.*"samples"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/')
if [[ -z "$SAMPLES" ]]; then
  fail "I2 missing 'samples' field at top level"
else
  info "Detected samples=$SAMPLES"
fi

# I2: Schema
SCHEMA=$(print -- "$CONTENT" | grep -E '"schema"[[:space:]]*:' | head -1 | sed -E 's/.*"schema"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
if [[ "$SCHEMA" == "perf-multi.v1" ]]; then
  pass "I2 schema perf-multi.v1"
else
  fail "I2 unexpected schema '$SCHEMA' (expected perf-multi.v1)"
fi

# I3: samples >= MIN_SAMPLES
if [[ -n "$SAMPLES" && "$SAMPLES" =~ ^[0-9]+$ && $SAMPLES -ge $MIN_SAMPLES ]]; then
  pass "I3 samples >= $MIN_SAMPLES (actual $SAMPLES)"
else
  fail "I3 insufficient samples ($SAMPLES < $MIN_SAMPLES)"
fi

# I4 & I5 & I6 & I10
STABLE_COUNT=0
declare -A REL_STDDEV_MAP
declare -A MEAN_MAP

for metric in "${REQUIRED_METRICS[@]}"; do
  mean=$(extract_metric_field "$metric" mean)
  min=$(extract_metric_field "$metric" min)
  max=$(extract_metric_field "$metric" max)
  stddev=$(extract_metric_field "$metric" stddev)

  block_present=1
  if [[ -z "$mean" || -z "$min" || -z "$max" || -z "$stddev" ]]; then
    fail "I4/I5 missing one or more fields for metric=$metric (mean=$mean min=$min max=$max stddev=$stddev)"
    block_present=0
  fi

  # Count value occurrences (rough; rely on values array delim)
  values_line=$(print -- "$CONTENT" | awk -v m="\"${metric}\":" '
    $0 ~ m {in=1}
    in && /"values"[[:space:]]*:/ {print; exit}
    in && /^\s*}/ {in=0}
  ')
  # Extract CSV numbers
  values_csv=$(print -- "$values_line" | sed -E 's/.*"values":[[:space:]]*\[([^]]*)\].*/\1/')
  value_count=0
  if [[ -n "$values_csv" ]]; then
    # Remove spaces, split by comma
    for v in ${(s:,:)values_csv}; do
      [[ -z "$v" ]] && continue
      (( value_count++ ))
    done
  fi

  if [[ $block_present -eq 1 ]]; then
    # I6: value count matches samples
    if [[ "$value_count" -eq "$SAMPLES" ]]; then
      pass "I6 metric=$metric values count matches samples ($value_count)"
    else
      fail "I6 metric=$metric values count ($value_count) != samples ($SAMPLES)"
    fi

    # I10: mean/stddev consistency
    if [[ "$mean" == "0" && "$stddev" != "0" ]]; then
      fail "I10 metric=$metric mean=0 but stddev=$stddev (inconsistent)"
    fi

    # Compute relative stddev
    rel="0"
    if [[ "$mean" != "0" ]]; then
      # scale to 6 decimals: (stddev / mean)
      rel=$(awk -v s="$stddev" -v m="$mean" 'BEGIN{ if(m==0) r=0; else r=s/m; printf "%.6f", r }')
    fi
    REL_STDDEV_MAP[$metric]=$rel
    MEAN_MAP[$metric]=$mean

    # Determine stability (generic threshold)
    rel_num=${rel}
    # Hard stable if <= GENERIC_REL_STDDEV_MAX
    awk_check=$(awk -v r="$rel_num" -v thr="$GENERIC_REL_STDDEV_MAX" 'BEGIN{ if(r <= thr) print "1"; else print "0"; }')
    if [[ "$awk_check" == "1" ]]; then
      (( STABLE_COUNT++ ))
    fi
  fi
done

# I7: post_plugin_cost_ms specific thresholds
pp_rel=${REL_STDDEV_MAP[post_plugin_cost_ms]:-}
pp_mean=${MEAN_MAP[post_plugin_cost_ms]:-}
if [[ -z "$pp_rel" ]]; then
  fail "I7 unable to compute relative stddev for post_plugin_cost_ms"
else
  # Compare thresholds
  # Hard fail if > POST_PLUGIN_REL_STDDEV_MAX
  hard_fail=$(awk -v r="$pp_rel" -v thr="$POST_PLUGIN_REL_STDDEV_MAX" 'BEGIN{ if(r>thr) print 1; else print 0 }')
  warn_only=$(awk -v r="$pp_rel" -v thr="$POST_PLUGIN_REL_STDDEV_WARN" 'BEGIN{ if(r>thr) print 1; else print 0 }')
  if [[ "$hard_fail" == "1" ]]; then
    fail "I7 post_plugin_cost_ms relative stddev=${pp_rel} exceeds hard max (${POST_PLUGIN_REL_STDDEV_MAX}); mean=${pp_mean}"
  elif [[ "$warn_only" == "1" ]]; then
    warn "post_plugin_cost_ms relative stddev=${pp_rel} exceeds warn threshold (${POST_PLUGIN_REL_STDDEV_WARN}); mean=${pp_mean}"
    pass "I7 post_plugin_cost_ms relative stddev within hard bound (${POST_PLUGIN_REL_STDDEV_MAX})"
  else
    pass "I7 post_plugin_cost_ms relative stddev=${pp_rel} within thresholds"
  fi
fi

# I8: Minimum stable metrics count
if [[ -n "$SAMPLES" && "$SAMPLES" =~ ^[0-9]+$ ]]; then
  if (( STABLE_COUNT >= MIN_STABLE_METRICS )); then
    pass "I8 stable metrics count (${STABLE_COUNT}) >= required (${MIN_STABLE_METRICS})"
  else
    fail "I8 only ${STABLE_COUNT} stable metrics (< ${MIN_STABLE_METRICS}); investigate variance sources"
  fi
fi

# I9: Segments presence (conditional)
if [[ "$REQUIRE_SEGMENTS" == "1" ]]; then
  seg_array_line=$(print -- "$CONTENT" | grep -E '"segments"[[:space:]]*:' | head -1 || true)
  if [[ -z "$seg_array_line" ]]; then
    fail "I9 segments array missing while MULTI_VARIANCE_REQUIRE_SEGMENTS=1"
  else
    # Quick non-empty check (could span multiple lines; simple heuristic)
    seg_count=$(print -- "$CONTENT" | awk '/"segments"[[:space:]]*:/ {in=1; next} in && /\]/ {exit} in {print}' | grep -Ec '"label"' || true)
    if (( seg_count > 0 )); then
      pass "I9 segments array present with ${seg_count} entries"
    else
      fail "I9 segments array present but appears empty of label entries"
    fi
  fi
else
  info "Segments presence not required (MULTI_VARIANCE_REQUIRE_SEGMENTS=0)"
fi

# Report relative stddev table (informational)
print ""
info "Relative StdDev Summary (metric => rel_stddev)"
for metric in "${REQUIRED_METRICS[@]}"; do
  rel=${REL_STDDEV_MAP[$metric]:-n/a}
  print "  - ${metric} => ${rel}"
done

# Summary / Exit
print ""
if (( ${#FAILURES[@]} == 0 )); then
  pass "All required variance invariants satisfied."
  if (( ${#WARNINGS[@]} > 0 )); then
    print "${YELLOW}Warnings:${RESET}"
    for w in "${WARNINGS[@]}"; do
      print "  - $w"
    done
  fi
  exit 0
else
  print "${BOLD}${RED}FAIL${RESET}: ${#FAILURES[@]} invariant(s) failed:"
  for f in "${FAILURES[@]}"; do
    print "  - $f"
  done
  print ""
  print "Remediation Suggestions:"
  print "  * Increase sample count (e.g., rerun tools/perf-capture-multi.zsh with --samples 5+)."
  print "  * Investigate largest contributing segments (run single-run perf capture & segment diff)."
  print "  * Defer heavy plugin/theme or VCS initialization asynchronously to reduce variance."
  print "  * Ensure system load is stable (avoid parallel heavy processes during sampling)."
  print "  * If post_plugin_cost_ms variance is persistently high, profile individual segments."
  exit 1
fi
