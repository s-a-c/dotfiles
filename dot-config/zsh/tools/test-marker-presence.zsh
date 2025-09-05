#!/usr/bin/env zsh
# test-marker-presence.zsh
# Compliant with repository AI guidelines (lightweight test utility).
#
# PURPOSE:
#   CI / local guard that validates lifecycle performance markers in
#   perf-current.json (and optionally a retained segment log) are
#   present and native (not synthesized / fallback) unless explicitly
#   permitted via flags.
#
# VALIDATED FIELDS (perf-current.json):
#   pre_plugin_cost_ms
#   post_plugin_cost_ms
#   prompt_ready_ms
#   lifecycle.pre_plugin_total_ms
#   lifecycle.post_plugin_total_ms
#   lifecycle.prompt_ready_ms
#   lifecycle.approx_prompt_ready   (1 indicates approximation / fallback)
#
# OPTIONAL SEGMENT LOG CHECK:
#   Confirms that (if provided) it contains expected legacy markers:
#     PRE_PLUGIN_COMPLETE
#     POST_PLUGIN_COMPLETE
#     PROMPT_READY_COMPLETE   (unless prompt allowed to be zero or approximation allowed)
#
# EXIT CODES:
#   0  Success (all required markers native & thresholds satisfied)
#   2  perf-current.json missing
#   3  Unable to parse required JSON numeric fields
#   4  Required marker (pre/post/prompt) missing or zero (and not allowed)
#   5  Fallback / approximated prompt detected while native required
#   6  Below minimum ms thresholds (pre / post)
#   7  Adaptive or synthesized lifecycle markers detected (heuristic) and not allowed
#   8  Segment log provided but missing required marker lines
#
# OPTIONS:
#   --metrics <path>                Path to perf-current.json (auto-detect if omitted)
#   --segment-log <path>            Path to retained segment log for native verification
#   --json-report <path>            Write a JSON diagnostic report to this path
#   --allow-zero-prompt             Do not fail if prompt_ready_ms == 0
#   --allow-fallback-post           Permit zero post_plugin_cost_ms when salvage/fallback acceptable
#   --allow-approx-prompt           Allow lifecycle.approx_prompt_ready=1 (otherwise treated as fallback)
#   --allow-adaptive                Allow synthesized/adaptive markers (empty original segment log)
#   --min-pre-ms <N>                Minimum acceptable pre_plugin_cost_ms (default 1 if required)
#   --min-post-ms <N>               Minimum acceptable post_plugin_cost_ms (default 1 if required)
#   --require-native                Fail if any approximation / fallback / adaptive detected
#   --verbose                       Extra diagnostics to stderr
#   -h|--help                       Show help
#
# HEURISTICS FOR ADAPTIVE / SYNTHETIC DETECTION:
#   - Segment log path supplied & file size == 0 -> adaptive synthesis suspected.
#   - No POST_PLUGIN_COMPLETE in segment log but post_plugin_cost_ms > 0 -> possible fallback aggregation (F38).
#   - approx_prompt_ready == 1 and --allow-approx-prompt not specified -> fallback.
#
# DEPENDENCIES:
#   Relies only on POSIX grep/sed/awk (jq not required). If jq is available,
#   set USE_JQ=1 for more robust parsing.
#
# EXAMPLES:
#   tools/test-marker-presence.zsh
#   tools/test-marker-presence.zsh --metrics docs/redesignv2/artifacts/metrics/perf-current.json --segment-log logs/perf/segment-log-<ts>.log
#   tools/test-marker-presence.zsh --require-native --min-pre-ms 50 --min-post-ms 50
#
set -euo pipefail

print_usage() {
  cat <<'EOF'
Usage: test-marker-presence.zsh [options]

Validate lifecycle performance markers in perf-current.json.

Options:
  --metrics <path>           Path to perf-current.json
  --segment-log <path>       Retained segment log for native marker verification
  --json-report <path>       Write machine-readable JSON result
  --allow-zero-prompt        Permit prompt_ready_ms == 0
  --allow-fallback-post      Permit zero post when fallback acceptable
  --allow-approx-prompt      Permit approximated prompt readiness (approx_prompt_ready=1)
  --allow-adaptive           Permit synthesized/adaptive lifecycle markers
  --min-pre-ms <N>           Minimum pre_plugin_cost_ms if required (default 1)
  --min-post-ms <N>          Minimum post_plugin_cost_ms if required (default 1)
  --require-native           Fail if any fallback/approx/adaptive path detected
  --verbose                  Verbose diagnostics
  -h, --help                 Show this help
EOF
}

# Defaults
METRICS_PATH=""
SEGMENT_LOG=""
JSON_REPORT=""
ALLOW_ZERO_PROMPT=0
ALLOW_FALLBACK_POST=0
ALLOW_APPROX_PROMPT=0
ALLOW_ADAPTIVE=0
MIN_PRE_MS=1
MIN_POST_MS=1
REQUIRE_NATIVE=0
VERBOSE=0
USE_JQ=${USE_JQ:-0}

while (( $# > 0 )); do
  case "$1" in
    --metrics) shift; METRICS_PATH="${1:-}";;
    --segment-log) shift; SEGMENT_LOG="${1:-}";;
    --json-report) shift; JSON_REPORT="${1:-}";;
    --allow-zero-prompt) ALLOW_ZERO_PROMPT=1;;
    --allow-fallback-post) ALLOW_FALLBACK_POST=1;;
    --allow-approx-prompt) ALLOW_APPROX_PROMPT=1;;
    --allow-adaptive) ALLOW_ADAPTIVE=1;;
    --min-pre-ms) shift; MIN_PRE_MS="${1:-1}";;
    --min-post-ms) shift; MIN_POST_MS="${1:-1}";;
    --require-native) REQUIRE_NATIVE=1;;
    --verbose) VERBOSE=1;;
    -h|--help) print_usage; exit 0;;
    *) echo "Unknown option: $1" >&2; print_usage; exit 1;;
  esac
  shift || true
done

# Auto-detect metrics path if not provided
if [[ -z $METRICS_PATH ]]; then
  for c in \
    "docs/redesignv2/artifacts/metrics/perf-current.json" \
    "dot-config/zsh/docs/redesignv2/artifacts/metrics/perf-current.json" \
    "perf-current.json"; do
    [[ -f $c ]] && METRICS_PATH="$c" && break
  done
fi

log() { (( VERBOSE )) && print -- "[marker-test] $*" >&2 || true; }

fail() {
  local code="$1"; shift
  print -- "[marker-test] FAIL($code): $*" >&2
  emit_json "$code" "$*" || true
  exit "$code"
}

emit_json() {
  local code="$1" msg="$2"
  [[ -z $JSON_REPORT ]] && return 0
  {
    printf '{'
    printf '"status":%d,' "$code"
    printf '"message":%q,' "$msg"
    printf '"metrics_path":%q,' "$METRICS_PATH"
    printf '"pre_plugin_cost_ms":%s,' "${PRE_COST_MS:-null}"
    printf '"post_plugin_cost_ms":%s,' "${POST_COST_MS:-null}"
    printf '"prompt_ready_ms":%s,' "${PROMPT_MS:-null}"
    printf '"approx_prompt_ready":%s,' "${APPROX_PROMPT_FLAG:-null}"
    printf '"fallback_post_detected":%s,' "${FALLBACK_POST_DETECTED:-false}"
    printf '"adaptive_synth_detected":%s,' "${ADAPTIVE_SYNTH:-false}"
    printf '"segment_log":%q,' "$SEGMENT_LOG"
    printf '"require_native":%s,' "$REQUIRE_NATIVE"
    printf '"allow_zero_prompt":%s,' "$ALLOW_ZERO_PROMPT"
    printf '"allow_fallback_post":%s,' "$ALLOW_FALLBACK_POST"
    printf '"allow_approx_prompt":%s,' "$ALLOW_APPROX_PROMPT"
    printf '"allow_adaptive":%s' "$ALLOW_ADAPTIVE"
    printf '}\n'
  } >| "$JSON_REPORT" 2>/dev/null || true
}

[[ -n $METRICS_PATH && -f $METRICS_PATH ]] || fail 2 "perf-current.json not found (searched path: $METRICS_PATH)"

raw_json=$(<"$METRICS_PATH") || fail 3 "cannot read metrics file"

extract_numeric_grep() {
  # Greedy but safe enough for simple integer extraction.
  # Usage: extract_numeric_grep key
  local key="$1"
  local line
  line=$(grep -E "\"$key\"[[:space:]]*:" "$METRICS_PATH" 2>/dev/null | head -1 || true)
  [[ -z $line ]] && { echo ""; return 0; }
  line=${line#*:$IFS}
  line=${line%%,*}
  line=${line//[^0-9]/}
  echo "$line"
}

if (( USE_JQ )) && command -v jq >/dev/null 2>&1; then
  PRE_COST_MS=$(jq -r '.pre_plugin_cost_ms // .lifecycle.pre_plugin_total_ms // empty' "$METRICS_PATH" 2>/dev/null || echo "")
  POST_COST_MS=$(jq -r '.post_plugin_cost_ms // .lifecycle.post_plugin_total_ms // empty' "$METRICS_PATH" 2>/dev/null || echo "")
  PROMPT_MS=$(jq -r '.prompt_ready_ms // .lifecycle.prompt_ready_ms // empty' "$METRICS_PATH" 2>/dev/null || echo "")
  APP_PROX=$(jq -r '.lifecycle.approx_prompt_ready // .approx_prompt_ready // empty' "$METRICS_PATH" 2>/dev/null || echo "")
else
  PRE_COST_MS=$(extract_numeric_grep pre_plugin_cost_ms)
  POST_COST_MS=$(extract_numeric_grep post_plugin_cost_ms)
  PROMPT_MS=$(extract_numeric_grep prompt_ready_ms)
  APP_PROX=$(extract_numeric_grep approx_prompt_ready)  # under lifecycle; fallback if top-level
  if [[ -z $PRE_COST_MS || $PRE_COST_MS == 0 ]]; then
    # Fallback to lifecycle.pre_plugin_total_ms
    PRE_COST_MS=$(grep -E '"pre_plugin_total_ms"[[:space:]]*:' "$METRICS_PATH" 2>/dev/null | head -1 | sed -E 's/.*"pre_plugin_total_ms"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' || true)
  fi
  if [[ -z $POST_COST_MS || $POST_COST_MS == 0 ]]; then
    POST_COST_MS=$(grep -E '"post_plugin_total_ms"[[:space:]]*:' "$METRICS_PATH" 2>/dev/null | head -1 | sed -E 's/.*"post_plugin_total_ms"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' || true)
  fi
  if [[ -z $PROMPT_MS || $PROMPT_MS == 0 ]]; then
    PROMPT_MS=$(grep -E '"prompt_ready_ms"[[:space:]]*:' "$METRICS_PATH" 2>/dev/null | head -1 | sed -E 's/.*"prompt_ready_ms"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' || true)
    # If still zero try lifecycle.prompt_ready_ms explicitly (in case top-level absent)
    if [[ -z $PROMPT_MS || $PROMPT_MS == 0 ]]; then
      PROMPT_MS=$(grep -E '"prompt_ready_ms"[[:space:]]*:' "$METRICS_PATH" | grep '"lifecycle"' -n 2>/dev/null | head -1 | sed -E 's/.*"prompt_ready_ms"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' || true)
    fi
  fi
  if [[ -z $APP_PROX ]]; then
    APP_PROX=$(grep -E '"approx_prompt_ready"[[:space:]]*:' "$METRICS_PATH" 2>/dev/null | head -1 | sed -E 's/.*"approx_prompt_ready"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' || true)
  fi
fi

APPROX_PROMPT_FLAG=${APP_PROX:-0}
[[ -z $PRE_COST_MS || -z $POST_COST_MS || -z $PROMPT_MS ]] && fail 3 "one or more lifecycle cost fields missing"

log "Parsed: pre=$PRE_COST_MS post=$POST_COST_MS prompt=$PROMPT_MS approx_prompt_ready=$APPROX_PROMPT_FLAG"

# Determine fallback post detection (heuristic)
FALLBACK_POST_DETECTED=false
if (( POST_COST_MS == 0 )); then
  FALLBACK_POST_DETECTED=true
fi

# Adaptive synthesis (empty segment log AND all three zero OR segment log explicitly zero bytes)
ADAPTIVE_SYNTH=false
if [[ -n $SEGMENT_LOG ]]; then
  if [[ -f $SEGMENT_LOG && ! -s $SEGMENT_LOG && ( $PRE_COST_MS == 0 && $POST_COST_MS == 0 ) ]]; then
    ADAPTIVE_SYNTH=true
  fi
fi

# Require native?
if (( REQUIRE_NATIVE )); then
  if (( APPROX_PROMPT_FLAG == 1 )) && (( ! ALLOW_APPROX_PROMPT )); then
    fail 5 "approx prompt readiness not allowed (approx_prompt_ready=1)"
  fi
  if $FALLBACK_POST_DETECTED && (( POST_COST_MS == 0 )) && (( ! ALLOW_FALLBACK_POST )); then
    fail 4 "post_plugin_cost_ms=0 (native post marker missing)"
  fi
  if $ADAPTIVE_SYNTH && (( ! ALLOW_ADAPTIVE )); then
    fail 7 "adaptive synthesized markers detected (empty segment log)"
  fi
fi

# Zero / threshold checks
if (( PRE_COST_MS == 0 && MIN_PRE_MS > 0 )); then
  fail 4 "pre_plugin_cost_ms=0 (required)"
fi
if (( POST_COST_MS == 0 && MIN_POST_MS > 0 && ! ALLOW_FALLBACK_POST )); then
  fail 4 "post_plugin_cost_ms=0 (required)"
fi
if (( PROMPT_MS == 0 )) && (( ! ALLOW_ZERO_PROMPT )) && (( APPROX_PROMPT_FLAG == 0 )); then
  fail 4 "prompt_ready_ms=0 (required non-zero)"
fi

if (( PRE_COST_MS < MIN_PRE_MS )); then
  fail 6 "pre_plugin_cost_ms=$PRE_COST_MS < min=$MIN_PRE_MS"
fi
if (( POST_COST_MS < MIN_POST_MS )) && (( POST_COST_MS > 0 )); then
  fail 6 "post_plugin_cost_ms=$POST_COST_MS < min=$MIN_POST_MS"
fi

# Segment log validation if provided
if [[ -n $SEGMENT_LOG && -f $SEGMENT_LOG ]]; then
  if [[ -s $SEGMENT_LOG ]]; then
    if ! grep -q 'PRE_PLUGIN_COMPLETE' "$SEGMENT_LOG" 2>/dev/null; then
      fail 8 "segment log missing PRE_PLUGIN_COMPLETE"
    fi
    if (( POST_COST_MS > 0 )) && ! grep -q 'POST_PLUGIN_COMPLETE' "$SEGMENT_LOG" 2>/dev/null; then
      # Allow if fallback post accepted
      if (( ! ALLOW_FALLBACK_POST )); then
        fail 8 "segment log missing POST_PLUGIN_COMPLETE (post required)"
      fi
    fi
    if (( PROMPT_MS > 0 )) && (( ! ALLOW_APPROX_PROMPT )) && (( ! ALLOW_ZERO_PROMPT )); then
      if ! grep -q 'PROMPT_READY_COMPLETE' "$SEGMENT_LOG" 2>/dev/null; then
        fail 8 "segment log missing PROMPT_READY_COMPLETE (prompt required native)"
      fi
    fi
  else
    # Empty file already handled as adaptive above
    log "segment log empty (size=0) – treated as adaptive"
  fi
fi

emit_json 0 "markers ok"
log "All checks passed"
exit 0
