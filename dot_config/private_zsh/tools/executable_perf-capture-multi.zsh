#!/usr/bin/env zsh
# .config/zsh/tools/perf-capture-multi.zsh
# Robust multi-sample ZSH startup performance aggregator
# - Adds per-sample polling watchdog and bounded retry attempts (F49)
# - Enforces authentic samples only (no synthetic cloning)
# - Emits per-sample files and aggregate perf-multi-current.json
#
# Usage: perf-capture-multi.zsh [-n N] [-s SLEEP] [--quiet] [--no-segments]
# Example: perf-capture-multi.zsh -n 5 -s 0.5
set -euo pipefail

: ${PERF_CAPTURE_SAMPLE_RETRIES:=2}    # attempts per sample (default 2)
: ${PERF_CAPTURE_ITER_WATCHDOG_MS:=4000}  # max ms allowed for one sample (including retries)
: ${PERF_CAPTURE_PROGRESS_STALL_MS:=5000} # max ms of no progress before we kill sample child
: ${PERF_CAPTURE_PROGRESS_CHECK_MIN_MS:=200} # poll interval ms
: ${PERF_CAPTURE_ENFORCE_AUTH:=1}      # require authentic samples
: ${PERF_CAPTURE_ALLOW_PARTIAL:=1}     # if auth failed, allow partial write (1) or fail (0)
: ${PERF_CAPTURE_DEBUG:=0}

SCRIPT_NAME="${0##*/}"

usage() {
  cat <<EOF
$SCRIPT_NAME - Multi-sample performance capture (robust)

Usage: $SCRIPT_NAME [options]
Options:
  -n, --samples N       Number of capture runs (default: 3)
  -s, --sleep SECS      Sleep between runs (default: 0)
      --quiet           Suppress single-run tool stdout
      --no-segments     Skip post_plugin_segments parsing
      --dry-run, --dry   Do not perform captures; print planned actions and exit (no-op)
      --help            Show this help
EOF
}

# Defaults
MULTI_SAMPLES=3
SLEEP_INTERVAL=0
QUIET=0
DO_SEGMENTS=1
DRY_RUN=0

# Arg parse (simple)
while (( $# > 0 )); do
  case "$1" in
    -n|--samples) shift; MULTI_SAMPLES="$1";;
    -s|--sleep) shift; SLEEP_INTERVAL="$1";;
    --quiet) QUIET=1;;
    --no-segments) DO_SEGMENTS=0;;
    --dry-run|--dry) DRY_RUN=1;;
    --help|-h) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1;;
  esac
  shift
done

if ! [[ "$MULTI_SAMPLES" =~ ^[0-9]+$ ]] || (( MULTI_SAMPLES < 1 )); then
  echo "Invalid samples: $MULTI_SAMPLES" >&2; exit 1
fi

# Resolve ZDOTDIR and metrics directory (prefer redesignv2)
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
if [[ -d "$ZDOTDIR/docs/redesignv2/artifacts/metrics" ]]; then
  METRICS_DIR="$ZDOTDIR/docs/redesignv2/artifacts/metrics"
elif [[ -d "$ZDOTDIR/docs/redesign/artifacts/metrics" ]]; then
  METRICS_DIR="$ZDOTDIR/docs/redesign/artifacts/metrics"
else
  # Fallback create redesignv2 path
  METRICS_DIR="$ZDOTDIR/docs/redesignv2/artifacts/metrics"
  mkdir -p -- "$METRICS_DIR"
fi

PERF_CAPTURE_BIN="${PERF_CAPTURE_BIN:-$ZDOTDIR/tools/perf-capture.zsh}"
# If user requested a dry-run, print planned actions and exit before requiring the
# actual perf-capture binary to exist.
if (( DRY_RUN )); then
  echo "[perf-capture-multi] DRY-RUN: Would perform ${MULTI_SAMPLES} sample(s) with sleep=${SLEEP_INTERVAL}s"
  echo "[perf-capture-multi] DRY-RUN: Metrics directory: $METRICS_DIR"
  echo "[perf-capture-multi] DRY-RUN: Options: QUIET=${QUIET} DO_SEGMENTS=${DO_SEGMENTS}"
  echo "[perf-capture-multi] DRY-RUN: Sample retries=${PERF_CAPTURE_SAMPLE_RETRIES} watchdog=${PERF_CAPTURE_ITER_WATCHDOG_MS}ms"
  # No-op exit
  exit 0
fi

if [[ ! -f "$PERF_CAPTURE_BIN" ]]; then
  echo "perf-capture tool not found at $PERF_CAPTURE_BIN" >&2
  exit 1
fi

timestamp() { date +%Y%m%dT%H%M%S; }

# Simple json presence/field sanity validator (no jq)
_validate_sample_json() {
  local f="$1"
  [[ -s "$f" ]] || return 1
  # lightweight checks
  grep -q '"timestamp"' "$f" || return 1
  grep -q '"post_plugin_cost_ms"' "$f" || return 1
  grep -q '"prompt_ready_ms"' "$f" || return 1
  return 0
}

_extract_num() {
  local file="$1" key="$2" raw val
  raw=$(grep -m1 -E "\"${key}\"[[:space:]]*:" "$file" 2>/dev/null || true)
  [[ -z "$raw" ]] && { echo 0; return 0; }
  val=$(printf '%s\n' "$raw" | sed -E "s/.*\"${key}\"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/")
  [[ "$val" =~ ^[0-9]+$ ]] || val=0
  echo "$val"
}

# Stats helpers (awk)
_stats_mean() { awk 'BEGIN{s=0;n=0}{for(i=1;i<=NF;i++){s+=$i;n++}}END{if(n>0)printf("%.2f",s/n);else print "0.00"}' <<<"$*"; }
_stats_min() { awk '{for(i=1;i<=NF;i++){ if(min=="" || $i<min)min=$i }}END{if(min=="")min=0; printf("%d",min)}' <<<"$*"; }
_stats_max() { awk '{for(i=1;i<=NF;i++){ if(max=="" || $i>max)max=$i }}END{if(max=="")max=0; printf("%d",max)}' <<<"$*"; }
_stats_stddev() { awk '{for(i=1;i<=NF;i++){n++;sum+=$i;sq+=($i*$i)}}END{ if(n<2){printf("0.00");exit} mean=sum/n; var=(sq/n)-(mean*mean); if(var<0)var=0; printf("%.2f",sqrt(var)) }' <<<"$*"; }

# Segment extraction (very small)
_segment_iterate() {
  local file="$1"
  [[ $DO_SEGMENTS -eq 1 ]] || return 0
  awk '
    /"post_plugin_segments"[[:space:]]*:/ {inarr=1; next}
    inarr && /\]/ {inarr=0; next}
    inarr {
      if ($0 ~ /"label"/) {
        lab=$0; gsub(/.*"label":"/,"",lab); gsub(/".*/,"",lab)
        mm=$0; gsub(/.*"mean_ms":/,"",mm); gsub(/[^0-9].*/,"",mm)
        if (lab != "" && mm ~ /^[0-9]+$/) printf("%s %s\n", lab, mm)
      }
    }' "$file" 2>/dev/null
}

# Arrays to collect valid values
typeset -a cold_values warm_values pre_values post_values prompt_values prompt_prov
typeset -A sample_flags
typeset -A seg_count seg_sum seg_sum_sq seg_min seg_max seg_values

# Debug helper
_dbg() { (( PERF_CAPTURE_DEBUG )) && printf "[%s][%s] %s\n" "$(timestamp)" "$SCRIPT_NAME" "$*" >&2; }

# Launch a single attempt with watchdog and progress polling.
# Args: sample_index attempt_index out_tmpfile
_single_attempt() {
  local idx="$1" attempt="$2" out="$3"
  local start_ms now_ms elapsed_ms last_mtime last_size cur_mtime cur_size pid rc child_env
  start_ms=$(($(date +%s%N)/1000000))
  last_mtime=0; last_size=0
  # Ensure output path doesn't exist
  rm -f -- "$out" 2>/dev/null || true

  # Start child perf-capture in background, ensure it writes to PERF_SINGLE_CURRENT_PATH
  PERF_SINGLE_CURRENT_PATH="$out" \
    zsh "$PERF_CAPTURE_BIN" ${QUIET:+>/dev/null 2>&1} &
  pid=$!
  _dbg "started child pid=$pid for sample=$idx attempt=$attempt"

  # Poll loop
  while :; do
    sleep_ms=$PERF_CAPTURE_PROGRESS_CHECK_MIN_MS
    if command -v usleep >/dev/null 2>&1; then
      usleep $(( sleep_ms * 1000 ))
    else
      sleep $(awk -v ms="$sleep_ms" 'BEGIN{printf "%.3f", ms/1000}')
    fi

    now_ms=$(($(date +%s%N)/1000000))
    elapsed_ms=$(( now_ms - start_ms ))

    # check file progress
    if [[ -f "$out" ]]; then
      if stat -f '%m' "$out" >/dev/null 2>&1; then
        cur_mtime=$(stat -f '%m' "$out" 2>/dev/null || echo 0)
      else
        cur_mtime=$(stat -c '%Y' "$out" 2>/dev/null || echo 0)
      fi
      cur_size=$(wc -c <"$out" 2>/dev/null || echo 0)
      if (( cur_mtime > last_mtime || cur_size > last_size )); then
        last_mtime=$cur_mtime; last_size=$cur_size
      fi
    fi

    # If child finished, capture rc and break
    if ! kill -0 "$pid" 2>/dev/null; then
      wait $pid 2>/dev/null || true
      rc=$?
      _dbg "child pid=$pid exited rc=$rc sample=$idx attempt=$attempt elapsed=${elapsed_ms}ms"
      return $rc
    fi

    # Check for progress stall
    if (( last_mtime > 0 )); then
      # compute time since last progress
      now_ms=$(($(date +%s%N)/1000000))
      time_since_progress=$(( now_ms - last_mtime * 1000 / 1000 )) # last_mtime is epoch seconds; convert to ms
      # last_mtime from stat -f '%m' returns seconds; convert to ms for comparison
      time_since_progress=$(( now_ms - (last_mtime * 1000) ))
      if (( time_since_progress >= PERF_CAPTURE_PROGRESS_STALL_MS )); then
        _dbg "progress stall detected: since_progress_ms=$time_since_progress killing pid=$pid"
        kill -TERM "$pid" 2>/dev/null || kill -KILL "$pid" 2>/dev/null || true
        wait $pid 2>/dev/null || true
        return 124  # indicate timed-out/stalled
      fi
    else
      # No file yet; if total elapsed exceeds watchdog, kill
      if (( elapsed_ms >= PERF_CAPTURE_ITER_WATCHDOG_MS )); then
        _dbg "no output produced within watchdog (${elapsed_ms}ms) killing pid=$pid"
        kill -TERM "$pid" 2>/dev/null || kill -KILL "$pid" 2>/dev/null || true
        wait $pid 2>/dev/null || true
        return 124
      fi
    fi
  done
}

# Capture loop
valid_samples=0
skipped_samples=0

_dbg "starting multi-capture requested=$MULTI_SAMPLES sleep=${SLEEP_INTERVAL}s retries=${PERF_CAPTURE_SAMPLE_RETRIES} watchdog=${PERF_CAPTURE_ITER_WATCHDOG_MS}ms"

for (( i=1; i<=MULTI_SAMPLES; i++ )); do
  _dbg "sample loop i=$i"
  attempt=0
  sample_ok=0
  while (( attempt < PERF_CAPTURE_SAMPLE_RETRIES )); do
    (( attempt++ ))
    tmp_out="$METRICS_DIR/perf-current-run-${i}-${attempt}.json"
    _dbg "attempt $attempt for sample $i -> $tmp_out"
    rc=0
    # Run one attempt with watchdog; _single_attempt returns rc
    _single_attempt "$i" "$attempt" "$tmp_out"
    rc=$?
    _dbg "attempt finished rc=$rc for sample $i attempt $attempt"

    if (( rc == 0 )) && _validate_sample_json "$tmp_out"; then
      # Validate non-zero required fields
      cold=$( _extract_num "$tmp_out" cold_ms )
      warm=$( _extract_num "$tmp_out" warm_ms )
      pre=$( _extract_num "$tmp_out" pre_plugin_cost_ms )
      post=$( _extract_num "$tmp_out" post_plugin_cost_ms )
      prompt=$( _extract_num "$tmp_out" prompt_ready_ms )
      # if prompt is zero but post present, use post as best-effort
      if (( prompt == 0 )) && (( post > 0 )); then prompt=$post; fi

      if (( pre > 0 && post > 0 && prompt > 0 && (cold > 0 || warm > 0) )); then
        # Accept sample, copy to canonical sample file
        sample_file="$METRICS_DIR/perf-sample-${i}.json"
        cp -f "$tmp_out" "$sample_file"
        # collect segment info
        if [[ $DO_SEGMENTS -eq 1 ]]; then
          while read -r lab mm; do
            if [[ -z "${seg_count[$lab]:-}" ]]; then
              seg_count[$lab]=0; seg_sum[$lab]=0; seg_sum_sq[$lab]=0; seg_min[$lab]="$mm"; seg_max[$lab]="$mm"; seg_values[$lab]=""
            fi
            (( seg_count[$lab]++ ))
            (( seg_sum[$lab] += mm ))
            (( seg_sum_sq[$lab] += mm * mm ))
            (( mm < seg_min[$lab] )) && seg_min[$lab]=$mm
            (( mm > seg_max[$lab] )) && seg_max[$lab]=$mm
            seg_values[$lab]="${seg_values[$lab]} $mm"
          done < <(_segment_iterate "$sample_file")
        fi

        # prompt provenance
        if grep -q '"approx_prompt_ready"[[:space:]]*:[[:space:]]*1' "$sample_file" 2>/dev/null; then
          prompt_prov+=("approx"); sample_flags[approx_prompt]=1
        else
          prompt_prov+=("native"); sample_flags[native_prompt]=1
        fi

        cold_values+=("$cold"); warm_values+=("$warm"); pre_values+=("$pre"); post_values+=("$post"); prompt_values+=("$prompt")
        (( valid_samples++ )); sample_ok=1
        _dbg "accepted sample $i (attempt $attempt) valid_samples=$valid_samples"
        break
      else
        _dbg "rejected sample $i attempt $attempt due to zero-fields pre=$pre post=$post prompt=$prompt cold=$cold warm=$warm"
      fi
    else
      _dbg "attempt produced invalid json or rc!=0 rc=$rc file_exists=$([[ -f "$tmp_out" ]] && echo 1 || echo 0)"
    fi

    # If not last attempt, sleep a bit before next try
    if (( attempt < PERF_CAPTURE_SAMPLE_RETRIES )); then
      if command -v usleep >/dev/null 2>&1; then
        usleep $(( PERf_CAPTURE_RETRY_SLEEP_MS:-200 * 1000 )) 2>/dev/null || true
      else
        sleep 0.2
      fi
    fi
  done

  if (( ! sample_ok )); then
    (( skipped_samples++ ))
    _dbg "sample $i failed after $attempt attempts"
  fi

  # inter-sample sleep
  if (( i < MULTI_SAMPLES )) && [[ "$SLEEP_INTERVAL" != "0" ]]; then
    sleep "$SLEEP_INTERVAL"
  fi
done

_dbg "collection finished valid=$valid_samples skipped=$skipped_samples requested=$MULTI_SAMPLES"

# Enforce authenticity: ensure we have requested number of samples unless partial allowed
auth_shortfall=$(( MULTI_SAMPLES - valid_samples ))
if (( PERF_CAPTURE_ENFORCE_AUTH )) && (( auth_shortfall > 0 )); then
  if (( PERF_CAPTURE_ALLOW_PARTIAL )); then
    _dbg "auth shortfall detected but partials allowed: collected=$valid_samples requested=$MULTI_SAMPLES"
    partial_flag=1
  else
    echo "[perf-capture-multi] ERROR: insufficient authentic samples: requested=$MULTI_SAMPLES got=$valid_samples" >&2
    exit 2
  fi
else
  partial_flag=0
fi

# If we have zero valid samples -> fail
if (( valid_samples == 0 )); then
  echo "[perf-capture-multi] ERROR: no valid samples collected" >&2
  exit 2
fi

# compute aggregate and produce perf-multi-current.json
AGG_FILE="$METRICS_DIR/perf-multi-current.json"
{
  echo "{"
  echo "  \"schema\": \"perf-multi.v1\","
  echo "  \"timestamp\": \"$(timestamp)\","
  echo "  \"requested_samples\": $MULTI_SAMPLES,"
  echo "  \"authentic_samples\": $valid_samples,"
  echo "  \"partial\": $partial_flag,"
  echo "  \"per_run\": ["
  # emit per-run using collected arrays
  idx=1
  emitted=0
  for (( j=1; j<=${#cold_values[@]}; j++ )); do
    c=${cold_values[$((j-1))]:-0}
    w=${warm_values[$((j-1))]:-0}
    ppre=${pre_values[$((j-1))]:-0}
    ppost=${post_values[$((j-1))]:-0}
    pront=${prompt_values[$((j-1))]:-0}
    prov=${prompt_prov[$((j-1))]:-unknown}
    (( emitted++ ))
    comma=","
    if (( emitted == valid_samples )); then comma=""; fi
    printf "    {\"index\": %d, \"cold_ms\": %d, \"warm_ms\": %d, \"pre_plugin_cost_ms\": %d, \"post_plugin_cost_ms\": %d, \"prompt_ready_ms\": %d, \"prompt_provenance\": \"%s\"}%s\n" "$emitted" "$c" "$w" "$ppre" "$ppost" "$pront" "$prov" "$comma"
  done
  echo "  ],"
  # aggregates
  echo "  \"aggregate\": {"
  # helper to emit metric block
  emit_metric() {
    local name="$1"; shift; local vals=("$@")
    if (( ${#vals[@]} == 0 )); then
      printf '    "%s": {"mean": 0, "min": 0, "max": 0, "stddev": 0, "values": []},\n' "$name"
      return
    fi
    local csv=$(printf "%s " "${vals[@]}" | sed -e 's/ $//')
    local mean=$(_stats_mean $csv)
    local min=$(_stats_min $csv)
    local max=$(_stats_max $csv)
    local sd=$(_stats_stddev $csv)
    printf '    "%s": {"mean": %s, "min": %s, "max": %s, "stddev": %s, "values": [' "$name" "$mean" "$min" "$max" "$sd"
    # values as plain integers
    local first=1
    for v in "${vals[@]}"; do
      if (( first )); then printf "%s" "$v"; first=0; else printf ",%s" "$v"; fi
    done
    printf "]},\n"
  }
  emit_metric "cold_ms" "${cold_values[@]}"
  emit_metric "warm_ms" "${warm_values[@]}"
  emit_metric "pre_plugin_cost_ms" "${pre_values[@]}"
  emit_metric "post_plugin_cost_ms" "${post_values[@]}"
  emit_metric "prompt_ready_ms" "${prompt_values[@]}"
  # remove trailing comma - simple approach: close aggregate and continue
  echo "  },"
  # segments
  if [[ $DO_SEGMENTS -eq 1 ]]; then
    if (( ${#seg_count[@]} == 0 )); then
      echo "  \"segments\": []"
    else
      echo "  \"segments\": ["
      keys=("${(@k)seg_count}")
      keys=("${(on)keys}")
      for (( si=1; si<=${#keys[@]}; si++ )); do
        lab=${keys[$((si-1))]}
        cnt=${seg_count[$lab]}
        sum=${seg_sum[$lab]}
        minv=${seg_min[$lab]}
        maxv=${seg_max[$lab]}
        mean=$(( sum / cnt ))
        csvv=$(printf "%s" "${seg_values[$lab]}" | sed -e 's/^ *//' -e 's/  */ /g' | tr ' ' ',')
        comma=","
        (( si == ${#keys[@]} )) && comma=""
        printf '    {"label":"%s","samples":%d,"mean_ms":%d,"min_ms":%d,"max_ms":%d,"values":[%s]}%s\n' "$lab" "$cnt" "$mean" "$minv" "$maxv" "$csvv" "$comma"
      done
      echo "  ]"
    fi
  else
    echo "  \"segments\": []"
  fi
  echo "}"
} >| "$AGG_FILE"

echo "[perf-capture-multi] Wrote aggregate $AGG_FILE (samples=$valid_samples skipped=$skipped_samples requested=$MULTI_SAMPLES)"
# Exit successfully (if partial allowed, we still exit 0)
exit 0
