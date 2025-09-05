#!/usr/bin/env zsh
# perf-module-tracer.zsh
# ------------------------------------------------------------------------------
# Purpose:
#   Trace which post-plugin modules fired in an interactive Zsh startup and list
#   the granular labels they emitted along with timing stats from POST_PLUGIN_SEGMENT.
#
# Features:
#   - Launches a short-lived interactive shell with PERF_SEGMENT_LOG to capture markers.
#   - Applies a small settle window for late-writing hooks and a prompt grace window.
#   - Parses:
#       * Native lifecycle markers: PRE_PLUGIN_COMPLETE, POST_PLUGIN_COMPLETE, PROMPT_READY_COMPLETE
#       * Granular segments: POST_PLUGIN_SEGMENT <label> <ms>
#       * (Optional) Generic SEGMENT phase=post_plugin for supplemental labels
#   - Outputs:
#       * Human table (default) or JSON (--json or --format json)
#       * Label stats: count, sum_ms, mean_ms, min_ms, max_ms
#       * Lifecycle native marker presence flags
#
# Usage:
#   perf-module-tracer.zsh [options]
#
# Options:
#   --timeout-sec <N>     Child shell timeout in seconds (default: 10)
#   --settle-ms <N>       Post-exit settle window in ms (default: 120)
#   --grace-ms <N>        Prompt native grace window in ms (default: 60)
#   --format <table|json> Output format (default: table)
#   --json                Shortcut for --format json
#   --include-segment     Also parse generic SEGMENT lines (phase=post_plugin)
#   --zdotdir <path>      Override ZDOTDIR (default: env or $XDG_CONFIG_HOME/zsh or ~/.config/zsh)
#   --trace               Verbose tracing to stderr (does not affect output)
#   --strict-exit         Exit 2 when neither granular segments nor native prompt present
#   -h|--help             Show help
#
# Exit codes:
#   0  Success
#   2  Strict gate failure (when --strict-exit and critical signals missing)
# ------------------------------------------------------------------------------

set -euo pipefail

# -------------------------- Helpers --------------------------
ts() { date +%Y%m%dT%H%M%S; }
now_ms() { printf '%s' "${EPOCHREALTIME:-$(date +%s).000000}" | awk -F. '{printf "%d", ($1*1000)+substr(($2 "000"),1,3)}'; }
trace() { (( TRACE )) && printf "[perf-module-tracer][trace] %s\n" "$*" >&2 || true; }

json_escape() {
  local s="$1"
  s=${s//\\/\\\\}; s=${s//\"/\\\"}; s=${s//$'\n'/\\n}; s=${s//$'\r'/\\r}; s=${s//$'\t'/\\t}
  printf '%s' "$s"
}

usage() {
  cat <<'EOF'
perf-module-tracer.zsh
  --timeout-sec <N>     Child shell timeout in seconds (default: 10)
  --settle-ms <N>       Post-exit settle window in ms (default: 120)
  --grace-ms <N>        Prompt native grace window in ms (default: 60)
  --format <table|json> Output format (default: table)
  --json                Shortcut for --format json
  --include-segment     Also parse generic SEGMENT lines (phase=post_plugin)
  --zdotdir <path>      Override ZDOTDIR (default: env or $XDG_CONFIG_HOME/zsh or ~/.config/zsh)
  --trace               Verbose tracing to stderr (does not affect output)
  --strict-exit         Exit 2 when neither granular segments nor native prompt present
  -h|--help             Show help
EOF
}

# -------------------------- Defaults --------------------------
TIMEOUT_SEC=10
SETTLE_MS=120
GRACE_MS=60
FORMAT="table"
INCLUDE_SEGMENT=0
TRACE=0
STRICT_EXIT=0
ZDOT="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"

# -------------------------- Args --------------------------
while (( $# )); do
  case "$1" in
    --timeout-sec) shift; TIMEOUT_SEC="${1:-10}";;
    --settle-ms) shift; SETTLE_MS="${1:-120}";;
    --grace-ms) shift; GRACE_MS="${1:-60}";;
    --format) shift; FORMAT="${1:-table}";;
    --json) FORMAT="json";;
    --include-segment) INCLUDE_SEGMENT=1;;
    --zdotdir) shift; ZDOT="${1:-$ZDOT}";;
    --trace) TRACE=1;;
    --strict-exit) STRICT_EXIT=1;;
    -h|--help) usage; exit 0;;
    *) printf "[perf-module-tracer][error] Unknown option: %s\n" "$1" >&2; usage; exit 1;;
  esac
  shift || true
done

# -------------------------- Env & Sanity --------------------------
if [[ ! -d "$ZDOT" ]]; then
  printf "[perf-module-tracer][error] ZDOTDIR does not exist: %s\n" "$ZDOT" >&2
  exit 1
fi
export ZDOTDIR="$ZDOT"

SEG_LOG="$(mktemp)"
cleanup() { rm -f "$SEG_LOG" 2>/dev/null || true; }
trap cleanup EXIT INT TERM HUP

trace "ZDOTDIR=$ZDOTDIR"
trace "timeout=${TIMEOUT_SEC}s settle=${SETTLE_MS}ms grace=${GRACE_MS}ms format=${FORMAT}"

# -------------------------- Launch child shell --------------------------
(
  ZSH_ENABLE_PREPLUGIN_REDESIGN=1 \
  PERF_SEGMENT_LOG="$SEG_LOG" \
  PERF_PROMPT_HARNESS=1 \
  PERF_FORCE_PRECMD=1 \
  PERF_PROMPT_DEFERRED_CHECK=1 \
  PERF_PROMPT_FORCE_DELAY_MS=30 \
  ZSH_DEBUG=0 \
  ZDOTDIR="$ZDOTDIR" \
  zsh -i -c 'sleep 0.05' </dev/null >/dev/null 2>&1 || true
) &!

CHILD=$!
START_MS=$(now_ms)
DEADLINE_MS=$(( START_MS + TIMEOUT_SEC * 1000 ))
POLL_MS=50; (( POLL_MS < 20 )) && POLL_MS=20

while kill -0 "$CHILD" 2>/dev/null; do
  NOW=$(now_ms)
  if (( NOW >= DEADLINE_MS )); then
    trace "timeout reached; terminating child"
    kill "$CHILD" 2>/dev/null || true
    sleep 0.05
    kill -9 "$CHILD" 2>/dev/null || true
    break
  fi
  sleep "$(printf '%.3f' "$(awk -v n=$POLL_MS 'BEGIN{printf n/1000.0}')" )"
done

# -------------------------- Settle + prompt grace --------------------------
if [[ -f "$SEG_LOG" ]]; then
  if (( SETTLE_MS > 0 )); then
    trace "settle begin window=${SETTLE_MS}ms"
    local_prev=$(wc -c <"$SEG_LOG" 2>/dev/null || echo 0)
    S_START=$(now_ms); S_END=$(( S_START + SETTLE_MS ))
    loops=0
    while :; do
      NOW=$(now_ms)
      (( NOW >= S_END )) && break
      local_cur=$(wc -c <"$SEG_LOG" 2>/dev/null || echo 0)
      if (( local_cur > local_prev )); then
        trace "segment log growth ${local_prev}->${local_cur}"
        local_prev=$local_cur
        if grep -q '^POST_PLUGIN_SEGMENT ' "$SEG_LOG" 2>/dev/null; then
          trace "granular POST_PLUGIN_SEGMENT detected during settle"
          break
        fi
        if grep -q 'PROMPT_READY_COMPLETE' "$SEG_LOG" 2>/dev/null; then
          trace "native PROMPT_READY_COMPLETE detected during settle"
          break
        fi
      fi
      sleep 0.01
      (( loops++ ))
    done
    trace "settle end loops=${loops} final_size=${local_prev}"
  fi

  if (( GRACE_MS > 0 )) && \
     grep -q 'POST_PLUGIN_COMPLETE' "$SEG_LOG" 2>/dev/null && \
     ! grep -q 'PROMPT_READY_COMPLETE' "$SEG_LOG" 2>/dev/null; then
    trace "prompt grace begin window=${GRACE_MS}ms"
    G_START=$(now_ms); G_END=$(( G_START + GRACE_MS ))
    g_loops=0
    while :; do
      grep -q 'PROMPT_READY_COMPLETE' "$SEG_LOG" 2>/dev/null && { trace "native prompt arrived in grace"; break; }
      NOW=$(now_ms)
      (( NOW >= G_END )) && break
      sleep 0.01
      (( g_loops++ ))
    done
    trace "prompt grace end loops=${g_loops}"
  fi
fi

# -------------------------- Parse markers --------------------------
pre_native=0; post_native=0; prompt_native=0
lifecycle_post_ms=0; lifecycle_prompt_ms=0

if [[ -s "$SEG_LOG" ]]; then
  grep -q 'PRE_PLUGIN_COMPLETE' "$SEG_LOG" 2>/dev/null && pre_native=1
  grep -q 'POST_PLUGIN_COMPLETE' "$SEG_LOG" 2>/dev/null && post_native=1
  grep -q 'PROMPT_READY_COMPLETE' "$SEG_LOG" 2>/dev/null && prompt_native=1
  lifecycle_post_ms=$(grep 'POST_PLUGIN_COMPLETE' "$SEG_LOG" 2>/dev/null | awk '{print $2}' | tail -1 | sed -E 's/[^0-9].*//')
  [[ -z "$lifecycle_post_ms" ]] && lifecycle_post_ms=0
  lifecycle_prompt_ms=$(grep 'PROMPT_READY_COMPLETE' "$SEG_LOG" 2>/dev/null | awk '{print $2}' | tail -1 | sed -E 's/[^0-9].*//')
  [[ -z "$lifecycle_prompt_ms" ]] && lifecycle_prompt_ms=0
fi

# Aggregate POST_PLUGIN_SEGMENT label stats
# Output format: label|sum|count|min|max|mean
label_stats="$(awk '
  BEGIN { FS=" "; OFS="|" }
  /^POST_PLUGIN_SEGMENT[[:space:]]+/ {
    lab=$2; ms=$3+0
    sum[lab]+=ms; cnt[lab]++
    if (!(lab in min) || ms<min[lab]) min[lab]=ms
    if (!(lab in max) || ms>max[lab]) max[lab]=ms
  }
  END {
    for (l in cnt) {
      mean=sum[l]/cnt[l]
      printf "%s|%d|%d|%d|%d|%.2f\n", l, sum[l]+0, cnt[l]+0, min[l]+0, max[l]+0, mean+0.0
    }
  }
' "$SEG_LOG" 2>/dev/null || true)"

# Optionally mine generic SEGMENT lines (phase=post_plugin) for supplemental labels
segment_supp=""
if (( INCLUDE_SEGMENT )); then
  segment_supp="$(awk '
    BEGIN { FS="[ =]+"; }
    /^SEGMENT[[:space:]]+/ && $0 ~ /phase=post_plugin/ {
      # Extract name=<label> ms=<num>
      name=""; ms=""
      for (i=1; i<=NF; i++) {
        if ($i=="name") { name=$(i+1) }
        if ($i=="ms") { ms=$(i+1)+0 }
      }
      if (name!="") { print name"|"ms }
    }
  ' "$SEG_LOG" 2>/dev/null || true)"
fi

# -------------------------- Output --------------------------
schema="perf-module-tracer.v1"
stamp="$(ts)"

emit_table() {
  printf "Schema: %s\n" "$schema"
  printf "Timestamp: %s\n" "$stamp"
  printf "Lifecycle: pre_native=%d post_native=%d prompt_native=%d post_ms=%d prompt_ms=%d\n" "$pre_native" "$post_native" "$prompt_native" "$lifecycle_post_ms" "$lifecycle_prompt_ms"
  echo
  if [[ -n "$label_stats" ]]; then
    printf "POST_PLUGIN_SEGMENT labels:\n"
    printf "  %-32s %8s %8s %8s %8s %8s\n" "label" "count" "sum_ms" "mean" "min" "max"
    printf "  %s\n" "-------------------------------------------------------------------------------------"
    # Sort by sum descending
    printf "%s\n" "$label_stats" | awk -F'|' '{printf "%s|%8d|%8d|%8d|%8d|%8.2f\n",$1,$3,$2,$6,$4,$5}' | sort -t'|' -k3,3nr | awk -F'|' '{printf "  %-32s %8s %8s %8s %8s %8s\n",$1,$2,$3,$4,$5,$6}'
  else
    printf "No POST_PLUGIN_SEGMENT labels observed.\n"
  fi
  if (( INCLUDE_SEGMENT )); then
    echo
    printf "Supplemental SEGMENT (phase=post_plugin) labels (raw):\n"
    if [[ -n "$segment_supp" ]]; then
      printf "  %-40s %8s\n" "label" "ms"
      printf "  %s\n" "--------------------------------------------------------------"
      printf "%s\n" "$segment_supp" | awk -F'|' '{printf "  %-40s %8d\n",$1,$2}'
    else
      printf "  (none)\n"
    fi
  fi
}

emit_json() {
  # Build labels JSON array
  labels_json="[]"
  if [[ -n "$label_stats" ]]; then
    labels_json="["
    first=1
    while IFS='|' read -r lab sum cnt min max mean; do
      [[ -z "$lab" ]] && continue
      esc=$(json_escape "$lab")
      if (( first )); then
        first=0
      else
        labels_json+=","
      fi
      labels_json+=$(printf '{"label":"%s","count":%d,"sum_ms":%d,"mean_ms":%.2f,"min_ms":%d,"max_ms":%d}' "$esc" "$cnt" "$sum" "$mean" "$min" "$max")
    done <<<"$label_stats"
    labels_json+="]"
  fi

  # Supplemental segment labels (raw)
  supp_json="[]"
  if (( INCLUDE_SEGMENT )) && [[ -n "$segment_supp" ]]; then
    supp_json="["
    sfirst=1
    while IFS='|' read -r n ms; do
      [[ -z "$n" ]] && continue
      esc=$(json_escape "$n")
      if (( sfirst )); then sfirst=0; else supp_json+=","; fi
      supp_json+=$(printf '{"label":"%s","ms":%d}' "$esc" "$ms")
    done <<<"$segment_supp"
    supp_json+="]"
  fi

  printf '{\n'
  printf '  "schema": "%s",\n' "$schema"
  printf '  "timestamp": "%s",\n' "$stamp"
  printf '  "lifecycle": { "pre_native": %d, "post_native": %d, "prompt_native": %d, "post_ms": %d, "prompt_ms": %d },\n' "$pre_native" "$post_native" "$prompt_native" "$lifecycle_post_ms" "$lifecycle_prompt_ms"
  printf '  "labels": %s' "$labels_json"
  if (( INCLUDE_SEGMENT )); then
    printf ',\n  "segment_phase_post_plugin_raw": %s\n' "$supp_json"
  else
    printf '\n'
  fi
  printf '}\n'
}

if [[ "$FORMAT" == "json" ]]; then
  emit_json
else
  emit_table
fi

# -------------------------- Strict exit (optional) --------------------------
# Fail if both: no granular labels & no native prompt
if (( STRICT_EXIT )); then
  emits_granular=0
  [[ -n "$label_stats" ]] && emits_granular=1
  if (( emits_granular == 0 && prompt_native == 0 )); then
    exit 2
  fi
fi

exit 0
