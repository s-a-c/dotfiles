#!/usr/bin/env zsh
# perf-module-fire-selftest.zsh
# -----------------------------------------------------------------------------
# Purpose:
#   Self-test whether post-plugin modules emit granular POST_PLUGIN_SEGMENT lines
#   and whether native lifecycle markers (PRE/POST/PROMPT) fire in an interactive
#   harness. Emits a concise JSON summary and optional CI guidance.
#
# Usage:
#   perf-module-fire-selftest.zsh [--timeout-sec N] [--settle-ms N] [--grace-ms N]
#                                 [--json] [--trace] [--ci-guidance] [--strict-exit]
#
# Defaults:
#   --timeout-sec 10
#   --settle-ms 120
#   --grace-ms 60
#
# Outputs:
#   JSON to stdout, diagnostics to stderr when --trace or --ci-guidance is enabled.
#
# Exit codes:
#   0  success (test ran; features may still be missing but no strict gating)
#   2  strict failure (when --strict-exit and critical features missing)
# -----------------------------------------------------------------------------

set -e
set -u
set -o pipefail 2>/dev/null || true

# ------------- Helpers -------------
ts() { date +%Y%m%dT%H%M%S; }
now_ms() { printf '%s' "${EPOCHREALTIME:-$(date +%s).000000}" | awk -F. '{printf "%d", ($1*1000)+substr(($2 "000"),1,3)}'; }
trace() { if (( TRACE )); then printf "[perf-module-fire][trace] %s\n" "$*" >&2; fi }
warn()  { printf "[perf-module-fire][warn] %s\n" "$*" >&2; }
die()   { printf "[perf-module-fire][error] %s\n" "$*" >&2; exit 2; }

json_escape() {
  # Minimal JSON string escape for a safe subset (quotes, backslashes)
  local s="$1"
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  printf '%s' "$s"
}

# ------------- Defaults / args -------------
TIMEOUT_SEC=10
SETTLE_MS=120
GRACE_MS=60
JSON_ONLY=0
TRACE=0
CI_GUIDANCE=0
STRICT_EXIT=0

while (( $# )); do
  case "$1" in
    --timeout-sec) shift; TIMEOUT_SEC="${1:-10}";;
    --settle-ms) shift; SETTLE_MS="${1:-120}";;
    --grace-ms) shift; GRACE_MS="${1:-60}";;
    --json) JSON_ONLY=1;;
    --trace) TRACE=1;;
    --ci-guidance) CI_GUIDANCE=1;;
    --strict-exit) STRICT_EXIT=1;;
    -h|--help)
      cat <<EOF
perf-module-fire-selftest.zsh
  --timeout-sec N   Child interactive harness timeout (default 10)
  --settle-ms N     Post-exit settle/poll window for segment writes (default 120)
  --grace-ms N      Prompt native grace window after POST markers (default 60)
  --json            JSON-only output (suppress non-error logs)
  --trace           Verbose stderr tracing
  --ci-guidance     Print CI guidance warnings when features missing
  --strict-exit     Exit 2 if critical signals are missing (granular segments and/or native prompt)
EOF
      exit 0
      ;;
    *) warn "Unknown arg: $1"; exit 1;;
  esac
  shift || true
done

# ------------- Environment -------------
: ${ZDOTDIR:="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"}
export ZDOTDIR
[[ -d "$ZDOTDIR" ]] || die "ZDOTDIR not found: $ZDOTDIR"

# ------------- Prepare temp log and run harness -------------
SEG_LOG="$(mktemp)"
cleanup() {
  rm -f "$SEG_LOG" 2>/dev/null || true
}
trap cleanup EXIT INT TERM HUP

trace "ZDOTDIR=$ZDOTDIR"
trace "Launching interactive shell with PERF_SEGMENT_LOG capture ($SEG_LOG)"

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
POLL_MS=50
(( POLL_MS < 20 )) && POLL_MS=20

while kill -0 "$CHILD" 2>/dev/null; do
  NOW=$(now_ms)
  if (( NOW >= DEADLINE_MS )); then
    trace "Timeout reached; terminating child"
    kill "$CHILD" 2>/dev/null || true
    sleep 0.05
    kill -9 "$CHILD" 2>/dev/null || true
    break
  fi
  sleep "$(printf '%.3f' "$(awk -v n=$POLL_MS 'BEGIN{printf n/1000.0}')" )"
done

# ------------- Post-exit settle and prompt grace -------------
if [[ -f "$SEG_LOG" ]]; then
  # Settle for late writes (segment array growth)
  if (( SETTLE_MS > 0 )); then
    trace "Settle begin window=${SETTLE_MS}ms"
    local_prev=$(( $(wc -c <"$SEG_LOG" 2>/dev/null || echo 0) + 0 ))
    S_START=$(now_ms)
    S_END=$(( S_START + SETTLE_MS ))
    loops=0
    while :; do
      NOW=$(now_ms)
      (( NOW >= S_END )) && break
      local_cur=$(( $(wc -c <"$SEG_LOG" 2>/dev/null || echo 0) + 0 ))
      if (( local_cur > local_prev )); then
        trace "Segment log growth ${local_prev}->${local_cur}"
        local_prev=$local_cur
        # break early if granular lines present and prompt native is present
        if grep -q '^POST_PLUGIN_SEGMENT ' "$SEG_LOG" 2>/dev/null; then
          trace "Granular POST_PLUGIN_SEGMENT detected during settle"
          break
        fi
        if grep -q 'PROMPT_READY_COMPLETE' "$SEG_LOG" 2>/dev/null; then
          trace "PROMPT_READY_COMPLETE detected during settle"
          break
        fi
      fi
      sleep 0.01
      loops=$(( loops + 1 ))
    done
    trace "Settle end loops=${loops} final_size=${local_prev}"
  fi

  # Prompt grace: only if POST present but PROMPT missing
  # Compute flags safely under set -e
  post_native_seen=0
  prompt_native_seen=0
  if grep -q 'POST_PLUGIN_COMPLETE' "$SEG_LOG" 2>/dev/null; then post_native_seen=1; fi
  if grep -q 'PROMPT_READY_COMPLETE' "$SEG_LOG" 2>/dev/null; then prompt_native_seen=1; fi
  if (( GRACE_MS > 0 && post_native_seen == 1 && prompt_native_seen == 0 )); then
    trace "Prompt grace begin window=${GRACE_MS}ms (await native prompt)"
    G_START=$(now_ms)
    G_END=$(( G_START + GRACE_MS ))
    g_loops=0
    while :; do
      if grep -q 'PROMPT_READY_COMPLETE' "$SEG_LOG" 2>/dev/null; then trace "Native prompt arrived in grace"; break; fi
      NOW=$(now_ms)
      (( NOW >= G_END )) && break
      sleep 0.01
      (( g_loops++ ))
    done
    trace "Prompt grace end loops=${g_loops}"
  fi
fi

# ------------- Parse results -------------
pre_native=0
post_native=0
prompt_native=0
lifecycle_post_ms=0
lifecycle_prompt_ms=0
post_seg_count=0
post_seg_sum_ms=0
typeset -a post_labels
post_labels=()

if [[ -f "$SEG_LOG" && -s "$SEG_LOG" ]]; then
  if grep -q 'PRE_PLUGIN_COMPLETE' "$SEG_LOG" 2>/dev/null; then pre_native=1; fi
  if grep -q 'POST_PLUGIN_COMPLETE' "$SEG_LOG" 2>/dev/null; then post_native=1; fi
  if grep -q 'PROMPT_READY_COMPLETE' "$SEG_LOG" 2>/dev/null; then prompt_native=1; fi

  lifecycle_post_ms=$(grep 'POST_PLUGIN_COMPLETE' "$SEG_LOG" 2>/dev/null | awk '{print $2}' | tail -1 | sed -E 's/[^0-9].*//' || true)
  [[ -z "$lifecycle_post_ms" ]] && lifecycle_post_ms=0
  lifecycle_prompt_ms=$(grep 'PROMPT_READY_COMPLETE' "$SEG_LOG" 2>/dev/null | awk '{print $2}' | tail -1 | sed -E 's/[^0-9].*//' || true)
  [[ -z "$lifecycle_prompt_ms" ]] && lifecycle_prompt_ms=0

  # POST_PLUGIN_SEGMENT label extraction and sum
  if grep -q '^POST_PLUGIN_SEGMENT ' "$SEG_LOG" 2>/dev/null; then
    post_seg_count=$(grep -c '^POST_PLUGIN_SEGMENT ' "$SEG_LOG" 2>/dev/null || echo 0)
    post_seg_sum_ms=$(grep '^POST_PLUGIN_SEGMENT ' "$SEG_LOG" 2>/dev/null | awk '{s+=$3} END{printf "%d", s+0}')
    # Unique labels
    IFS=$'\n' post_labels=($(grep '^POST_PLUGIN_SEGMENT ' "$SEG_LOG" 2>/dev/null | awk '{print $2}' | sort -u))
  fi
fi

# ------------- Build JSON summary -------------
schema="perf-module-fire-selftest.v1"
stamp="$(ts)"

# diagnostics and recommendations
emits_granular=$(( post_seg_count > 0 ? 1 : 0 ))
emits_native_prompt=$(( prompt_native == 1 ? 1 : 0 ))

typeset -a recommendations
recommendations=()

if (( emits_granular == 0 )); then
  recommendations+=("No granular POST_PLUGIN_SEGMENT lines were observed. Ensure post-plugin modules are sourced in this harness path and PERF_SEGMENT_LOG is exported before they execute.")
  recommendations+=("Consider a small settle delay (PERF_POST_PLUGIN_SETTLE_MS) to capture late writes.")
  recommendations+=("Verify that you are not running in a fast/minimal mode that bypasses module loading.")
fi
if (( emits_native_prompt == 0 )); then
  recommendations+=("Native PROMPT_READY_COMPLETE was not observed. Increase prompt grace (PERF_PROMPT_NATIVE_GRACE_MS) or verify prompt-ready hook order.")
  recommendations+=("If approximation is used later, annotate provenance to distinguish native vs approx.")
fi

# Output JSON
printf '{\n'
printf '  "schema": "%s",\n' "$schema"
printf '  "timestamp": "%s",\n' "$stamp"
printf '  "pre_native": %d,\n' "$pre_native"
printf '  "post_native": %d,\n' "$post_native"
printf '  "prompt_native": %d,\n' "$prompt_native"
printf '  "lifecycle_post_ms": %d,\n' "$lifecycle_post_ms"
printf '  "lifecycle_prompt_ms": %d,\n' "$lifecycle_prompt_ms"
printf '  "post_segment_count": %d,\n' "$post_seg_count"
printf '  "post_segment_sum_ms": %d,\n' "$post_seg_sum_ms"
printf '  "post_segment_labels": ['

# labels array
if (( ${#post_labels[@]} > 0 )); then
  first=1
  for lb in "${post_labels[@]}"; do
    esc=$(json_escape "$lb")
    if (( first )); then
      printf '"%s"' "$esc"
      first=0
    else
      printf ', "%s"' "$esc"
    fi
  done
fi
printf '],\n'

printf '  "diagnostics": { "emits_granular_segments": %d, "emits_native_prompt": %d },\n' "$emits_granular" "$emits_native_prompt"
printf '  "recommendations": ['

if (( ${#recommendations[@]} > 0 )); then
  first=1
  for rec in "${recommendations[@]}"; do
    esc=$(json_escape "$rec")
    if (( first )); then
      printf '"%s"' "$esc"
      first=0
    else
      printf ', "%s"' "$esc"
    fi
  done
fi
printf ']\n'
printf '}\n'

# ------------- CI guidance (optional) -------------
if (( CI_GUIDANCE )); then
  if (( emits_granular == 0 )); then
    warn "No POST_PLUGIN_SEGMENT lines observed. CI may only rely on lifecycle totals; enable granular emission to improve attribution."
    warn "Suggestions:"
    warn "  - Confirm ZSH post-plugin modules source in this harness."
    warn "  - Export PERF_SEGMENT_LOG before modules run."
    warn "  - Add/keep a small settle delay (e.g., PERF_POST_PLUGIN_SETTLE_MS=120)."
  fi
  if (( emits_native_prompt == 0 )); then
    warn "No native PROMPT_READY_COMPLETE observed. Downstream may approximate prompt readiness."
    warn "Suggestions:"
    warn "  - Increase PERF_PROMPT_NATIVE_GRACE_MS (e.g., 80)."
    warn "  - Ensure prompt-ready hook is registered before harness exit."
  fi
fi

# ------------- Strict exit (optional) -------------
if (( STRICT_EXIT )); then
  # If both granular segments and native prompt are missing, fail hard.
  if (( emits_granular == 0 || emits_native_prompt == 0 )); then
    exit 2
  fi
fi

exit 0
