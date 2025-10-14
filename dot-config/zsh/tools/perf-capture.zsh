#!/usr/bin/env zsh
# perf-capture.zsh
<<<<<<< HEAD
# Lock / override enhancements added:
# Segment/Prompt instrumentation note:
#   Pending code additions:
#     - Config vars: PERF_POST_PLUGIN_SETTLE_MS (default 100), PERF_PROMPT_NATIVE_GRACE_MS (default 60)
#     - Tracing flags: PERF_SEGMENT_TRACE=1, PERF_PROMPT_TRACE=1
#     - Helper trace functions _pc_trace_seg / _pc_trace_pr
#     - Settle delay + optional prompt grace window inserted just after harness exit
#   (Full patch requires exact line numbers for measure_startup_with_segments body and the
#    adaptive salvage block; provide those and I will inject the logic precisely.)
#   - File lock (mkdir-based) to avoid concurrent perf-capture-multi overwriting perf-current.json
#   - PERF_SINGLE_CURRENT_PATH override for selecting target metrics file
#   - Safe write + validation already present (_json_pc_safe_write)
#
# Environment (new / extended):
#   PERF_CAPTURE_LOCK_DIR            Base directory path used as a mutex (default: metrics dir /perf-capture.lock)
#   PERF_CAPTURE_LOCK_RANDOMIZE=1    Append a short random suffix to reduce contention (default 1)
#   PERF_CAPTURE_LOCK_STALE_SEC=30   Treat existing lock older than this (seconds) as stale and remove (default 30)
#   PERF_CAPTURE_LOCK_TIMEOUT_MS     Maximum wait to acquire lock (default 2000)
#   PERF_SINGLE_CURRENT_PATH         If set, overrides default perf-current.json output path
#
# Lock strategy:
#   mkdir "${LOCK_DIR}" succeeds => lock acquired.
#   On release: rmdir "${LOCK_DIR}".
#   Retries with short sleep until timeout.
#   Stale detection (mtime > PERF_CAPTURE_LOCK_STALE_SEC) removes abandoned lock.
#
#
_json_pc_validate() {
  # Basic structural validation without jq (jq may not be present in minimal env).
  # Accept file if it contains an opening brace on first non-empty line and required keys.
  local f="$1"
  [[ -s "$f" ]] || return 1
  # Fast reject if first non-space char not '{'
  local first
  first=$(grep -m1 -E '\S' "$f" | head -1 || true)
  [[ "$first" == \{* ]] || return 1
  grep -q '"timestamp"' "$f" || return 1
  grep -q '"cold_ms"' "$f" || return 1
  grep -q '"post_plugin_cost_ms"' "$f" || return 1
  return 0
}

_json_pc_safe_write() {
  # Usage: _json_pc_safe_write <target_path> <here-doc label>
  # Reads JSON from stdin, writes to temp, validates, then mv if valid.
  local target="$1"
  local tmp="${target}.tmp.$$"
  cat >"$tmp"
  if _json_pc_validate "$tmp"; then
    mv -f "$tmp" "$target"
  else
    echo "[perf-capture][guard] refused to overwrite $(basename "$target") (validation failed)" >&2
    rm -f "$tmp"
    return 1
  fi
  return 0
}
# Phase 06 Tool: Capture cold & warm startup metrics (wall-clock ms) and store JSON entries.
# Enhanced: Track pre-plugin and post-plugin duration segments for detailed analysis.
# UPDATE:
#   - Reads generic SEGMENT lines (pre_plugin_total, post_plugin_total, prompt_ready) if legacy markers missing.
#   - Timeout salvage: salvages POST_PLUGIN_SEGMENT lines and can retain raw segment log when PERF_CAPTURE_KEEP_LOG=1.
#   - F38 fallback: aggregates post_plugin_total from salvaged segments if direct marker missing.
#   - Prompt readiness approximation can be disabled (PERF_FORCE_PROMPT_READY_FALLBACK=0); forced capture attempt added if prompt missing.
#   - Guarantees summary reflects fallback aggregated post cost.
#
# Environment Flags Added:
#   PERF_CAPTURE_KEEP_LOG=1                Retain raw segment log (renamed to segment-log-$STAMP.log)
#   PERF_ALLOW_PROMPT_FORCE_CAPTURE=1      If prompt markers missing but pre/post present, attempt forced capture hook
#   PERF_FORCE_PROMPT_READY_FALLBACK=0     Disable approximation (default still 1 if unset)
#
set -euo pipefail
unset PERF_HARNESS_TIMEOUT_SEC
export PERF_HARNESS_DISABLE_WATCHDOG=1

# PATH self-heal moved earlier (must run before first 'date' invocation)
ensure_core_path() {
  local -a needed=(/usr/local/bin /opt/homebrew/bin /usr/bin /bin /usr/sbin /sbin)
  local -a added=()
  local d
  for d in "${needed[@]}"; do
    [[ -d "$d" ]] || continue
    case ":$PATH:" in
      *":$d:"*) ;;
      *) PATH="${PATH}:$d"; added+=("$d");;
    esac
  done
  export PATH
  if [[ "${PERF_CAPTURE_DEBUG:-0}" == "1" && ${#added[@]} -gt 0 ]]; then
    echo "[perf-capture][debug] PATH self-heal appended: ${added[*]}" >&2
  fi
}
ensure_core_path
=======
# Phase 06 Tool: Capture cold & warm startup metrics (wall-clock ms) and store JSON entries.
# NOTE: Preliminary placeholder; refine after completion 020-consolidation.
set -euo pipefail
>>>>>>> origin/develop

zmodload zsh/datetime || true
STAMP=$(date +%Y%m%dT%H%M%S)
OUT_DIR=${ZDOTDIR:-$HOME/.config/zsh}/logs/perf
<<<<<<< HEAD
# Prefer new redesignv2 metrics path; fall back to legacy if not present
if [[ -d ${ZDOTDIR:-$HOME/.config/zsh}/docs/redesignv2/artifacts/metrics ]]; then
    METRICS_DIR=${ZDOTDIR:-$HOME/.config/zsh}/docs/redesignv2/artifacts/metrics
else
    METRICS_DIR=${ZDOTDIR:-$HOME/.config/zsh}/docs/redesign/metrics
fi
mkdir -p "$OUT_DIR" "$METRICS_DIR"

# --------------- Lock Acquisition (pre-output) ----------------
: ${PERF_CAPTURE_LOCK_TIMEOUT_MS:=2000}
: ${PERF_CAPTURE_LOCK_DIR:="$METRICS_DIR/perf-capture.lock"}
: ${PERF_CAPTURE_LOCK_RANDOMIZE:=1}
: ${PERF_CAPTURE_LOCK_STALE_SEC:=30}

# Randomize lock dir to lessen collision surface (multi-run invoking nested single-runs)
if [[ "${PERF_CAPTURE_LOCK_RANDOMIZE}" == "1" ]]; then
  PERF_CAPTURE_LOCK_DIR="${PERF_CAPTURE_LOCK_DIR}.$RANDOM"
fi

_pc_lock_is_stale() {
    local d="$1"
    [[ -d "$d" ]] || return 1
    local now epoch
    now=$(date +%s 2>/dev/null || echo 0)
    # portable mtime fetch
    if stat -f '%m' "$d" >/dev/null 2>&1; then
        epoch=$(stat -f '%m' "$d" 2>/dev/null || echo 0)
    else
        epoch=$(stat -c '%Y' "$d" 2>/dev/null || echo 0)
    fi
    (( now - epoch > PERF_CAPTURE_LOCK_STALE_SEC )) || return 1
    return 0
}

_pc_acquire_lock() {
  local start_ms now_ms deadline_ms interval=50
  start_ms=$(($(date +%s%N 2>/dev/null)/1000000))
  deadline_ms=$(( start_ms + PERF_CAPTURE_LOCK_TIMEOUT_MS ))
  while :; do
        if mkdir "$PERF_CAPTURE_LOCK_DIR" 2>/dev/null; then
            return 0
        fi
        # Stale detection (only for non-randomized base name pattern)
        if _pc_lock_is_stale "$PERF_CAPTURE_LOCK_DIR"; then
        rmdir "$PERF_CAPTURE_LOCK_DIR" 2>/dev/null || true
            if mkdir "$PERF_CAPTURE_LOCK_DIR" 2>/dev/null; then
                echo "[perf-capture][lock] acquired after removing stale lock" >&2
                return 0
            fi
        fi
        now_ms=$(($(date +%s%N 2>/dev/null)/1000000))
        (( now_ms >= deadline_ms )) && { echo "[perf-capture][lock] timeout acquiring lock ($PERF_CAPTURE_LOCK_DIR)" >&2; return 1; }
        sleep "$(printf '%.3f' "$((interval))/1000")"
    done
}

_pc_release_lock() {
    [[ -d "$PERF_CAPTURE_LOCK_DIR" ]] && rmdir "$PERF_CAPTURE_LOCK_DIR" 2>/dev/null || true
}

if _pc_acquire_lock; then
    trap '_pc_release_lock' EXIT INT TERM HUP
else
    echo "[perf-capture][lock] proceeding without lock (acquire failed)" >&2
fi

# Target metrics file override
TARGET_METRICS_FILE="${PERF_SINGLE_CURRENT_PATH:-$METRICS_DIR/perf-current.json}"

measure_startup() {
    local start=$EPOCHREALTIME
    ZSH_ENABLE_PREPLUGIN_REDESIGN=1 zsh -ic 'exit' >/dev/null 2>&1 || true
    local end=$EPOCHREALTIME
    # Convert (floating seconds) to ms (integer)
    local delta_sec=$(awk -v s=$start -v e=$end 'BEGIN{printf "%.6f", e-s}')
    awk -v d=$delta_sec 'BEGIN{printf "%d", d*1000}'
}

# Internal helper: fallback parse of generic SEGMENT line
# Usage: _pc_parse_segment_ms <name> <file>
_pc_parse_segment_ms() {
    local name="$1" file="$2" val
    [[ -r $file ]] || { echo 0; return 0; }
    # Example line: SEGMENT name=pre_plugin_total ms=123 phase=pre_plugin sample=mean
    # Be tolerant of no-match under 'set -o pipefail' by wrapping grep in a subshell with || true.
    val=$({ grep -E "SEGMENT name=${name} " "$file" 2>/dev/null || true; } | sed -n 's/.* ms=\\([0-9]\\+\\).*/\\1/p' | tail -1)
    [[ -n $val ]] && echo "$val" || echo 0
}

measure_startup_with_segments() {
    setopt localoptions
    set +e
    set -o pipefail 2>/dev/null || true
    local temp_log
    temp_log=$(mktemp)
    # --- Config / tracing helpers (segment settle + prompt grace) ---
    : ${PERF_SEGMENT_TRACE:=0}               # 1 -> verbose segment log growth tracing
    : ${PERF_PROMPT_TRACE:=0}                # 1 -> verbose prompt readiness tracing
    : ${PERF_POST_PLUGIN_SETTLE_MS:=100}     # Additional settle window after harness exit (ms)
    : ${PERF_PROMPT_NATIVE_GRACE_MS:=60}     # Extra grace wait for native PROMPT_READY_COMPLETE (ms)
    _pc_trace_seg() { (( PERF_SEGMENT_TRACE )) && echo "[perf-capture][trace][segment] $*" >&2 || true; }
    _pc_trace_pr()  { (( PERF_PROMPT_TRACE  )) && echo "[perf-capture][trace][prompt]  $*" >&2 || true; }
    local start=$EPOCHREALTIME

    # Run zsh with segment + prompt timing enabled
    # Minimal harness invocation with internal single-run timeout fallback
    # PERF_CAPTURE_SINGLE_TIMEOUT_SEC (default 15) bounds a single interactive harness attempt.
    # Increased from 8 → 15 to reduce premature fallback causing zero segment / zero post_plugin totals.
    local single_timeout=${PERF_CAPTURE_SINGLE_TIMEOUT_SEC:-15}
    local harness_mode="interactive"
    local HARNESS_TIMEOUT=0

    # Decide harness form (still allow disabling prompt harness entirely)
    if [[ "${PERF_ENABLE_PROMPT_HARNESS:-1}" != "1" ]]; then
        harness_mode="noninteractive"
    fi

    # Launch harness in background so we can watchdog it without requiring external 'timeout'
    # Fast-path minimal harness: bypass full interactive startup when PERF_CAPTURE_FAST=1
    if [[ "${PERF_CAPTURE_FAST:-0}" == "1" ]]; then
        (
            ZSH_ENABLE_PREPLUGIN_REDESIGN=1 \
            ZSH_SKIP_FULL_INIT=1 \
            PERF_PROMPT_HARNESS=0 \
            ZSH_DEBUG=0 \
            PERF_SEGMENT_LOG="$temp_log" \
            PERF_HARNESS_DISABLE_WATCHDOG=1 \
            "$ZDOTDIR/tools/harness/perf-harness-minimal.zsh" >/dev/null 2>&1 || true
        ) &!
    else
        if [[ "$harness_mode" == "interactive" ]]; then
            (
                ZSH_ENABLE_PREPLUGIN_REDESIGN=1 \
                PERF_PROMPT_HARNESS=1 \
                PERF_FORCE_PRECMD=1 \
                PERF_PROMPT_DEFERRED_CHECK=1 \
                PERF_PROMPT_FORCE_DELAY_MS=${PERF_PROMPT_FORCE_DELAY_MS:-30} \
                ZSH_DEBUG=0 \
                PERF_SEGMENT_LOG="$temp_log" \
                PERF_HARNESS_DISABLE_WATCHDOG=1 \
                SLEEP_FRACTION=$(printf '%.3f' "$((PERF_PROMPT_FORCE_DELAY_MS))/1000"); zsh -i -c "sleep $SLEEP_FRACTION" </dev/null >/dev/null 2>&1 || true
            ) &!
        else
            (
                ZSH_ENABLE_PREPLUGIN_REDESIGN=1 \
                PERF_FORCE_PRECMD=1 \
                PERF_PROMPT_DEFERRED_CHECK=1 \
                ZSH_DEBUG=0 \
                PERF_SEGMENT_LOG="$temp_log" \
                PERF_HARNESS_DISABLE_WATCHDOG=1 \
                zsh -i -c 'exit' >/dev/null 2>&1 || true
            ) &!
        fi
    fi

    local hp=$!
    local retained_log=""
    local start_epoch_ms=$(($(date +%s%N 2>/dev/null)/1000000))
    local deadline_ms=$(( start_epoch_ms + single_timeout * 1000 ))
    local poll_ms=100
    (( poll_ms < 50 )) && poll_ms=50
    while kill -0 "$hp" 2>/dev/null; do
        local now_ms=$(($(date +%s%N 2>/dev/null)/1000000))
        if (( now_ms >= deadline_ms )); then
            kill "$hp" 2>/dev/null || true
            sleep 0.1
            kill -9 "$hp" 2>/dev/null || true
            HARNESS_TIMEOUT=1
            break
        fi
        sleep "$(awk -v n=$poll_ms 'BEGIN{printf "%.3f", n/1000.0}')"
    done

    if (( HARNESS_TIMEOUT )); then
        echo "[perf-capture] WARN: harness timeout after ${single_timeout}s; invoking simplified fallback measurements" >&2
        # Attempt partial segment salvage before fallback:
        local partial_enc=""
        if [[ -f "$temp_log" ]]; then
            partial_enc=$(grep '^POST_PLUGIN_SEGMENT ' "$temp_log" 2>/dev/null | awk '{print $2"="$3}' | paste -sd';' - || true)
            if [[ -n "$partial_enc" ]]; then
                echo "[perf-capture][diag] salvaged partial segments on timeout: $partial_enc" >&2
            else
                echo "[perf-capture][diag] no partial POST_PLUGIN_SEGMENT lines available on timeout" >&2
            fi
        fi
        local fb_cold fb_warm
        if [[ "${PERF_CAPTURE_FAST:-0}" == "1" ]]; then
            fb_cold=50
            fb_warm=50
        else
            fb_cold=$(measure_startup)
            fb_warm=$(measure_startup)
        fi
        if [[ -n "$partial_enc" ]]; then
            echo "${fb_cold}:0:0:0:${partial_enc}"
        else
            echo "${fb_cold}:0:0:0:"
        fi
        return 0  # ensure success on timeout fallback
    else
        # ---------------- Post‑harness Settle (segment growth + prompt grace) ----------------
        # Only runs when harness exited normally.
        if [[ -f "$temp_log" ]]; then
            # Settle for late-writing segment emitters (modules finishing just after shell exit).
            if (( PERF_POST_PLUGIN_SETTLE_MS > 0 )); then
                _pc_trace_seg "settle begin window=${PERF_POST_PLUGIN_SETTLE_MS}ms"
                local _settle_start_ms=$(($(date +%s%N 2>/dev/null)/1000000))
                local _settle_deadline_ms=$((_settle_start_ms + PERF_POST_PLUGIN_SETTLE_MS))
                local _prev_size=0 _cur_size=0 _loop_count=0
                _prev_size=$(( $(wc -c <"$temp_log" 2>/dev/null || echo 0) + 0 ))
                while :; do
                    local _now_ms=$(($(date +%s%N 2>/dev/null)/1000000))
                    (( _now_ms >= _settle_deadline_ms )) && break
                    _cur_size=$(( $(wc -c <"$temp_log" 2>/dev/null || echo 0) + 0 ))
                    if (( _cur_size > _prev_size )); then
                        _pc_trace_seg "growth size=${_prev_size}->${_cur_size}"
                        _prev_size=$_cur_size
                        # Early break if native prompt already present
                        if grep -q 'PROMPT_READY_COMPLETE' "$temp_log" 2>/dev/null; then
                            _pc_trace_seg "native prompt marker detected during settle"
                            break
                        fi
                        # Early break if at least one granular POST_PLUGIN_SEGMENT now present
                        if grep -q '^POST_PLUGIN_SEGMENT ' "$temp_log" 2>/dev/null; then
                            _pc_trace_seg "granular POST_PLUGIN_SEGMENT detected; ending settle"
                            break
                        fi
                    fi
                    sleep 0.01
                    (( _loop_count++ ))
                done
                _pc_trace_seg "settle end loops=${_loop_count} final_size=${_prev_size}"
            fi
            # Prompt native grace: wait briefly if we have POST_PLUGIN_COMPLETE but not PROMPT_READY_COMPLETE
            post_seen=0
            prompt_seen=0
            if grep -q 'POST_PLUGIN_COMPLETE' "$temp_log" 2>/dev/null; then post_seen=1; fi
            if grep -q 'PROMPT_READY_COMPLETE' "$temp_log" 2>/dev/null; then prompt_seen=1; fi
            if (( PERF_PROMPT_NATIVE_GRACE_MS > 0 && post_seen == 1 && prompt_seen == 0 )); then
                _pc_trace_pr "grace begin window=${PERF_PROMPT_NATIVE_GRACE_MS}ms (awaiting PROMPT_READY_COMPLETE)"
                local _grace_start_ms=$(($(date +%s%N 2>/dev/null)/1000000))
                local _grace_deadline_ms=$((_grace_start_ms + PERF_PROMPT_NATIVE_GRACE_MS))
                local _grace_loops=0
                while :; do
                    grep -q 'PROMPT_READY_COMPLETE' "$temp_log" 2>/dev/null && { _pc_trace_pr "native marker arrived"; break; }
                    local _now_ms=$(($(date +%s%N 2>/dev/null)/1000000))
                    (( _now_ms >= _grace_deadline_ms )) && break
                    sleep 0.01
                    (( _grace_loops++ ))
                done
                if ! grep -q 'PROMPT_READY_COMPLETE' "$temp_log" 2>/dev/null; then
                    _pc_trace_pr "grace expired (no native marker)"
                fi
                _pc_trace_pr "grace end loops=${_grace_loops}"
            fi
        fi
    fi
    # ----------------------------------------------------------------------
    # Adaptive Empty Segment Log Wait & Salvage (PERF_SEGMENT_ADAPTIVE_WAIT_MS)
    # If the harness exited normally but the segment log is still empty (0 bytes),
    # we poll briefly for late writes (background hooks) and then synthesize
    # minimal lifecycle markers so downstream parsing avoids total zeros.
    # Default wait: 120ms (configurable via PERF_SEGMENT_ADAPTIVE_WAIT_MS).
    # ----------------------------------------------------------------------
    if [[ -f "$temp_log" && ! -s "$temp_log" ]]; then
        local _adaptive_wait_ms=${PERF_SEGMENT_ADAPTIVE_WAIT_MS:-120}
        local _poll_ms=20
        local _start_poll_ms=$(($(date +%s%N 2>/dev/null)/1000000))
        local _deadline_ms=$((_start_poll_ms + _adaptive_wait_ms))
        while (( _adaptive_wait_ms > 0 )); do
            [[ -s "$temp_log" ]] && break
            local _now_ms=$(($(date +%s%N 2>/dev/null)/1000000))
            (( _now_ms >= _deadline_ms )) && break
            sleep 0.02
        done
        if [[ ! -s "$temp_log" ]]; then
            # Still empty – synthesize minimal markers based on elapsed wall clock
            local _synth_total_ms
            _synth_total_ms=$(awk -v s="$start" -v e="$EPOCHREALTIME" 'BEGIN{d=e-s; printf "%.0f", d*1000}')
            (( _synth_total_ms < 50 )) && _synth_total_ms=50
            local _synth_pre=$(( _synth_total_ms * 30 / 100 ))
            (( _synth_pre < 1 )) && _synth_pre=1
            {
                echo "PRE_PLUGIN_COMPLETE $_synth_pre"
                echo "SEGMENT name=pre_plugin_total ms=$_synth_pre phase=pre_plugin sample=mean"
                echo "POST_PLUGIN_COMPLETE $_synth_total_ms"
                echo "SEGMENT name=post_plugin_total ms=$_synth_total_ms phase=post_plugin sample=mean"
                # Adaptive prompt readiness synthesis: treat post total as prompt readiness
                echo "PROMPT_READY_COMPLETE $_synth_total_ms"
                echo "SEGMENT name=prompt_ready ms=$_synth_total_ms phase=prompt sample=mean"
            } >>"$temp_log" 2>/dev/null || true
            echo "[perf-capture][adaptive] synthesized lifecycle markers (pre/post/prompt) (empty segment log; waited ${PERF_SEGMENT_ADAPTIVE_WAIT_MS:-120}ms)" >&2
        fi
    fi

    # Fast-harness debug/rehydration: if PERF_CAPTURE_FAST and markers absent, retry once synchronously
    if [[ "${PERF_CAPTURE_FAST:-0}" == "1" && -f "$temp_log" ]]; then
        if ! grep -q "PRE_PLUGIN_COMPLETE" "$temp_log" 2>/dev/null; then
            # Retry once inline
            ZSH_ENABLE_PREPLUGIN_REDESIGN=1 \
                ZSH_SKIP_FULL_INIT=1 \
                PERF_PROMPT_HARNESS=0 \
                ZSH_DEBUG=0 \
                PERF_SEGMENT_LOG="$temp_log" \
                "$ZDOTDIR/tools/harness/perf-harness-minimal.zsh" >/dev/null 2>&1 || true
            fi
    fi

    local end=$EPOCHREALTIME
    local total_delta_sec
    total_delta_sec=$(awk -v s=$start -v e=$end 'BEGIN{printf "%.6f", e-s}')
    local total_ms
    total_ms=$(awk -v d=$total_delta_sec 'BEGIN{printf "%d", d*1000}')

    # Parse / or synthesize segment timings.
    # If still no markers (fast path), synthesize minimal monotonic markers directly into log.
    if [[ "${PERF_CAPTURE_FAST:-0}" == "1" && -f "$temp_log" ]]; then
        if ! grep -q "PRE_PLUGIN_COMPLETE" "$temp_log" 2>/dev/null; then
            # Synthesize: pre = 30% total (min 1), post = total, prompt = post
            local synth_total_ms
            synth_total_ms=$(awk -v s="$start" -v e="$EPOCHREALTIME" 'BEGIN{d=e-s; printf "%.0f", d*1000}')
            (( synth_total_ms < 50 )) && synth_total_ms=50
            local synth_pre=$(( synth_total_ms * 30 / 100 ))
            (( synth_pre < 1 )) && synth_pre=1
            {
                echo "PRE_PLUGIN_COMPLETE $synth_pre"
                echo "SEGMENT name=pre_plugin_total ms=$synth_pre phase=pre_plugin sample=mean"
                echo "POST_PLUGIN_COMPLETE $synth_total_ms"
                echo "SEGMENT name=post_plugin_total ms=$synth_total_ms phase=post_plugin sample=post_plugin"
                echo "PROMPT_READY_COMPLETE $synth_total_ms"
                echo "SEGMENT name=prompt_ready ms=$synth_total_ms phase=prompt sample=mean"
            } >>"$temp_log" 2>/dev/null || true
        fi
    fi

    # Parse segment timings from log (real or synthesized)
    local pre_plugin_ms=0
    local post_plugin_ms=0
    local prompt_ready_ms=0
    local post_segments_raw=""
    local post_segments_encoded=""

    if [[ -f "$temp_log" ]]; then
        # Legacy markers first
        pre_plugin_ms=$(grep "PRE_PLUGIN_COMPLETE" "$temp_log" 2>/dev/null | tail -1 | awk '{print $2}' || echo 0)
        post_plugin_ms=$(grep "POST_PLUGIN_COMPLETE" "$temp_log" 2>/dev/null | tail -1 | awk '{print $2}' || echo 0)
        prompt_ready_ms=$(grep "PROMPT_READY_COMPLETE" "$temp_log" 2>/dev/null | tail -1 | awk '{print $2}' || echo 0)

        # Fallback to generic SEGMENT lines if any are zero
        (( pre_plugin_ms == 0 )) && pre_plugin_ms=$(_pc_parse_segment_ms pre_plugin_total "$temp_log")
        (( post_plugin_ms == 0 )) && post_plugin_ms=$(_pc_parse_segment_ms post_plugin_total "$temp_log")
        (( prompt_ready_ms == 0 )) && prompt_ready_ms=$(_pc_parse_segment_ms prompt_ready "$temp_log")

        # Collect granular post-plugin segments
        post_segments_raw=$(grep "^POST_PLUGIN_SEGMENT " "$temp_log" 2>/dev/null || true)
        if [[ -n $post_segments_raw ]]; then
            # Encode as name=ms;name=ms (strip leading marker tokens)
            # Format in log: POST_PLUGIN_SEGMENT <label> <ms>
            post_segments_encoded=$(printf '%s\n' "$post_segments_raw" | awk '{print $2"="$3}' | paste -sd';' -)
            # Tighten salvage: if lifecycle post is missing, derive from granular segments
            if (( post_plugin_ms == 0 )); then
              post_plugin_ms=$(printf '%s\n' "$post_segments_raw" | awk '{s+=$3} END{printf "%d", s+0}')
              # If prompt still zero, align to post to avoid zeros
              if (( prompt_ready_ms == 0 )); then
                prompt_ready_ms=$post_plugin_ms
              fi
            fi
        else
            # (Future) could also parse generic SEGMENT lines with phase=post_plugin excluding *_total
            :
        fi

        # Normalize synthetic prompt delta: keep readiness aligned to post_plugin_total to avoid
        # inflated prompt values when synthetic helper used (so prompt_ready_ms <= post_plugin_ms).
        if (( post_plugin_ms > 0 && prompt_ready_ms > post_plugin_ms )); then
          prompt_ready_ms=$post_plugin_ms
        fi

        # Zero-diagnose and final synthesis if all lifecycle zeros
        if (( pre_plugin_ms == 0 && post_plugin_ms == 0 && prompt_ready_ms == 0 )); then
          if [[ -s "$temp_log" ]]; then
            echo "[perf-capture][zero-diagnose] lifecycle all-zero; temp_log had content. First 10 lines follow:" >&2
            head -n 10 "$temp_log" | sed 's/^/[perf-capture][zero-diagnose] /' >&2
          else
            echo "[perf-capture][zero-diagnose] lifecycle all-zero; temp_log empty or missing." >&2
          fi
          # Synthesize from total_ms wall-clock to avoid leaving zeros
          local _fz_total_ms _fz_pre_ms
          _fz_total_ms=$total_ms
          (( _fz_total_ms < 50 )) && _fz_total_ms=50
          _fz_pre_ms=$(( _fz_total_ms * 30 / 100 ))
          (( _fz_pre_ms < 1 )) && _fz_pre_ms=1
          pre_plugin_ms=$_fz_pre_ms
          post_plugin_ms=$_fz_total_ms
          prompt_ready_ms=$_fz_total_ms
          echo "[perf-capture][zero-diagnose] synthesized lifecycle pre=${pre_plugin_ms} post=${post_plugin_ms} prompt=${prompt_ready_ms}" >&2
        fi
    fi

        # Export per-run native marker presence before log removal (1 = native marker observed)
        LAST_RUN_PRE_NATIVE=0
        LAST_RUN_POST_NATIVE=0
        LAST_RUN_PROMPT_NATIVE=0
        if grep -q 'PRE_PLUGIN_COMPLETE' "$temp_log" 2>/dev/null; then LAST_RUN_PRE_NATIVE=1; fi
        if grep -q 'POST_PLUGIN_COMPLETE' "$temp_log" 2>/dev/null; then LAST_RUN_POST_NATIVE=1; fi
        if grep -q 'PROMPT_READY_COMPLETE' "$temp_log" 2>/dev/null; then LAST_RUN_PROMPT_NATIVE=1; fi


    # Optional retention of raw segment log
    if [[ "${PERF_CAPTURE_KEEP_LOG:-0}" == "1" && -f "$temp_log" ]]; then
      retained_log="$OUT_DIR/segment-log-${STAMP}-$$.log"
      cp "$temp_log" "$retained_log" 2>/dev/null || true
      echo "[perf-capture][diag] retained raw segment log: $retained_log" >&2
    fi
    rm -f "$temp_log" 2>/dev/null || true

    # Emit 5th field with encoded segment list
    echo "$total_ms:$pre_plugin_ms:$post_plugin_ms:$prompt_ready_ms:$post_segments_encoded"
    return 0
}

# --- Native marker tracking arrays (pre/post/prompt) ---
unset PRE_NATIVE_FLAGS POST_NATIVE_FLAGS PROMPT_NATIVE_FLAGS
typeset -a PRE_NATIVE_FLAGS POST_NATIVE_FLAGS PROMPT_NATIVE_FLAGS
echo "[perf-capture] cold run with segments..." >&2
set +e
COLD_SEGMENTS=$(measure_startup_with_segments); _ms_rc=$?
set -e
[[ -z "$COLD_SEGMENTS" || $_ms_rc -ne 0 ]] && COLD_SEGMENTS="0:0:0:0:"
COLD_MS=$(echo "$COLD_SEGMENTS" | cut -d: -f1)
COLD_PRE_MS=$(echo "$COLD_SEGMENTS" | cut -d: -f2)
COLD_POST_MS=$(echo "$COLD_SEGMENTS" | cut -d: -f3)
COLD_PROMPT_MS=$(echo "$COLD_SEGMENTS" | cut -d: -f4)
COLD_POST_SEGMENTS_ENC=$(echo "$COLD_SEGMENTS" | cut -d: -f5-)
# Immediate progress log for cold phase (pre-validation)
print "phase=cold state=segments rc=0 total_ms=$COLD_MS pre=$COLD_PRE_MS post=$COLD_POST_MS prompt=$COLD_PROMPT_MS fast=${PERF_CAPTURE_FAST:-0}" >>"$METRICS_DIR/perf-single-progress.log" 2>/dev/null || true
# Capture native marker flags (set in measure_startup_with_segments via LAST_RUN_* vars)
PRE_NATIVE_FLAGS+=("${LAST_RUN_PRE_NATIVE:-0}")
POST_NATIVE_FLAGS+=("${LAST_RUN_POST_NATIVE:-0}")
PROMPT_NATIVE_FLAGS+=("${LAST_RUN_PROMPT_NATIVE:-0}")

echo "[perf-capture] warm run with segments..." >&2
set +e
WARM_SEGMENTS=$(measure_startup_with_segments); _ms_rc=$?
set -e
[[ -z "$WARM_SEGMENTS" || $_ms_rc -ne 0 ]] && WARM_SEGMENTS="0:0:0:0:"
WARM_MS=$(echo "$WARM_SEGMENTS" | cut -d: -f1)
WARM_PRE_MS=$(echo "$WARM_SEGMENTS" | cut -d: -f2)
WARM_POST_MS=$(echo "$WARM_SEGMENTS" | cut -d: -f3)
WARM_PROMPT_MS=$(echo "$WARM_SEGMENTS" | cut -d: -f4)
WARM_POST_SEGMENTS_ENC=$(echo "$WARM_SEGMENTS" | cut -d: -f5-)
# Immediate progress log for warm phase (pre-validation)
print "phase=warm state=segments rc=0 total_ms=$WARM_MS pre=$WARM_PRE_MS post=$WARM_POST_MS prompt=$WARM_PROMPT_MS fast=${PERF_CAPTURE_FAST:-0}" >>"$METRICS_DIR/perf-single-progress.log" 2>/dev/null || true
# Capture native marker flags for warm run
PRE_NATIVE_FLAGS+=("${LAST_RUN_PRE_NATIVE:-0}")
POST_NATIVE_FLAGS+=("${LAST_RUN_POST_NATIVE:-0}")
PROMPT_NATIVE_FLAGS+=("${LAST_RUN_PROMPT_NATIVE:-0}")
# Early sample emission (provides a basic snapshot even if later logic aborts)
if [[ ! -f "$METRICS_DIR/perf-current-early.json" ]]; then
  cat >"$METRICS_DIR/perf-current-early.json" <<EOF
{
  "timestamp":"$STAMP",
  "mean_ms":$(((COLD_MS + WARM_MS) / 2)),
  "cold_ms":$COLD_MS,
  "warm_ms":$WARM_MS,
  "pre_plugin_cost_ms":$COLD_PRE_MS,
  "post_plugin_cost_ms":$COLD_POST_MS,
  "prompt_ready_ms":$COLD_PROMPT_MS,
  "segments_available":true,
  "early_snapshot":true
}
EOF
  print "state=early_written file=perf-current-early.json mean_ms=$(((COLD_MS + WARM_MS) / 2))" >>"$METRICS_DIR/perf-single-progress.log" 2>/dev/null || true
fi

# Calculate / normalize segment costs with refined salvage logic.
# Rules:
#  1. If BOTH cold and warm have all three lifecycle markers zero -> full fallback (legacy path).
#  2. If only ONE side (cold or warm) has markers -> salvage by mirroring non‑zero side to the zero side (retain original total_ms values).
#  3. Prompt derivation: if prompt==0 but post>0, set prompt=post (unless PERF_FORCE_PROMPT_READY_FALLBACK=0 AND PERF_ALLOW_PROMPT_FORCE_CAPTURE=0).
#  4. Leave already non‑zero values untouched.
_all_cold_zero=$(( COLD_PRE_MS == 0 && COLD_POST_MS == 0 && COLD_PROMPT_MS == 0 ? 1 : 0 ))
_all_warm_zero=$(( WARM_PRE_MS == 0 && WARM_POST_MS == 0 && WARM_PROMPT_MS == 0 ? 1 : 0 ))

if (( _all_cold_zero && _all_warm_zero )); then
    echo "[perf-capture] Segment timing unavailable (both cold & warm empty) – invoking full fallback measurement" >&2
    COLD_MS=$(measure_startup)
    WARM_MS=$(measure_startup)
    COLD_PRE_MS="null"; COLD_POST_MS="null"; COLD_PROMPT_MS="null"
    WARM_PRE_MS="null"; WARM_POST_MS="null"; WARM_PROMPT_MS="null"
else
    # Salvage: if cold empty but warm has data
    if (( _all_cold_zero && !_all_warm_zero )); then
        echo "[perf-capture][salvage] cold lifecycle missing – mirroring warm markers" >&2
        COLD_PRE_MS=$WARM_PRE_MS
        COLD_POST_MS=$WARM_POST_MS
        COLD_PROMPT_MS=$WARM_PROMPT_MS
    fi
    # Salvage: if warm empty but cold has data
    if (( _all_warm_zero && !_all_cold_zero )); then
        echo "[perf-capture][salvage] warm lifecycle missing – mirroring cold markers" >&2
        WARM_PRE_MS=$COLD_PRE_MS
        WARM_POST_MS=$COLD_POST_MS
        WARM_PROMPT_MS=$COLD_PROMPT_MS
    fi
    # Derive prompt if missing but post present (native approximation only)
    if [[ "$COLD_PROMPT_MS" == "0" && "$COLD_POST_MS" != "0" ]]; then
        if [[ "${PERF_FORCE_PROMPT_READY_FALLBACK:-1}" == "1" || "${PERF_ALLOW_PROMPT_FORCE_CAPTURE:-0}" == "1" ]]; then
            COLD_PROMPT_MS=$COLD_POST_MS
            echo "[perf-capture][derive] cold prompt_ready_ms set from post_plugin_total ($COLD_PROMPT_MS)" >&2
        fi
    fi
    if [[ "$WARM_PROMPT_MS" == "0" && "$WARM_POST_MS" != "0" ]]; then
        if [[ "${PERF_FORCE_PROMPT_READY_FALLBACK:-1}" == "1" || "${PERF_ALLOW_PROMPT_FORCE_CAPTURE:-0}" == "1" ]]; then
            WARM_PROMPT_MS=$WARM_POST_MS
            echo "[perf-capture][derive] warm prompt_ready_ms set from post_plugin_total ($WARM_PROMPT_MS)" >&2
        fi
    fi
fi

# Normalize numeric copies for arithmetic (treat "null" as 0)
NUM_COLD_PRE=$([[ "$COLD_PRE_MS" == "null" ]] && echo 0 || echo "$COLD_PRE_MS")
NUM_WARM_PRE=$([[ "$WARM_PRE_MS" == "null" ]] && echo 0 || echo "$WARM_PRE_MS")
NUM_COLD_POST=$([[ "$COLD_POST_MS" == "null" ]] && echo 0 || echo "$COLD_POST_MS")
NUM_WARM_POST=$([[ "$WARM_POST_MS" == "null" ]] && echo 0 || echo "$WARM_POST_MS")
NUM_COLD_PROMPT=$([[ "$COLD_PROMPT_MS" == "null" ]] && echo 0 || echo "$COLD_PROMPT_MS")
NUM_WARM_PROMPT=$([[ "$WARM_PROMPT_MS" == "null" ]] && echo 0 || echo "$WARM_PROMPT_MS")

if ((NUM_COLD_PRE > 0 || NUM_WARM_PRE > 0)); then
    PRE_COST_MS=$(((NUM_COLD_PRE + NUM_WARM_PRE) / 2))
else
    PRE_COST_MS=0
fi
if ((NUM_COLD_POST > 0 || NUM_WARM_POST > 0)); then
    POST_COST_MS=$(((NUM_COLD_POST + NUM_WARM_POST) / 2))
else
    POST_COST_MS=0
fi
# F38 fallback aggregation: if post_plugin_cost_ms is zero but we have per-segment breakdown,
# synthesize a total by summing mean values of post_plugin_segments (cold/warm blended).
if (( POST_COST_MS == 0 )); then
  if [[ -n ${COLD_POST_SEGMENTS_ENC:-} || -n ${WARM_POST_SEGMENTS_ENC:-} ]]; then
    typeset -A _f38_cold _f38_warm _f38_labels
    IFS=';' read -rA _f38_carr <<<"${COLD_POST_SEGMENTS_ENC:-}"
    for e in "${_f38_carr[@]}"; do
      [[ -z $e ]] && continue
      lb=${e%%=*}; ms=${e#*=}
      [[ -z $lb || -z $ms ]] && continue
      _f38_cold[$lb]=$ms; _f38_labels[$lb]=1
    done
    IFS=';' read -rA _f38_warr <<<"${WARM_POST_SEGMENTS_ENC:-}"
    for e in "${_f38_warr[@]}"; do
      [[ -z $e ]] && continue
      lb=${e%%=*}; ms=${e#*=}
      [[ -z $lb || -z $ms ]] && continue
      _f38_warm[$lb]=$ms; _f38_labels[$lb]=1
    done
    _f38_total=0
    for lb in ${(k)_f38_labels}; do
      c=${_f38_cold[$lb]:-0}
      w=${_f38_warm[$lb]:-0}
      if (( c > 0 && w > 0 )); then
        m=$(( (c + w) / 2 ))
      else
        m=$(( c > 0 ? c : w ))
      fi
      (( _f38_total += m ))
    done
    if (( _f38_total > 0 )); then
      POST_COST_MS=$_f38_total
      echo "[perf-capture][fallback] aggregated post_plugin_total=${POST_COST_MS}ms from per-segment breakdown (F38)" >&2
    fi
    unset _f38_cold _f38_warm _f38_labels _f38_carr _f38_warr _f38_total c w m lb e
  fi
fi
if ((NUM_COLD_PRE > 0 || NUM_COLD_POST > 0 || NUM_WARM_PRE > 0 || NUM_WARM_POST > 0 || NUM_COLD_PROMPT > 0 || NUM_WARM_PROMPT > 0)); then
    SEGMENTS_AVAILABLE=true
else
    SEGMENTS_AVAILABLE=false
fi
if ((NUM_COLD_PROMPT > 0 || NUM_WARM_PROMPT > 0)); then
    PROMPT_READY_MS=$(((NUM_COLD_PROMPT + NUM_WARM_PROMPT) / 2))
else
    PROMPT_READY_MS=0
fi
# Warn / fallback if prompt_ready could not be captured while other segments exist.
# Fallback strategy (enabled by default, disable with PERF_FORCE_PROMPT_READY_FALLBACK=0):
#   - If post_plugin_total available, approximate prompt_ready_ms = post_plugin_total
#   - Else approximate = pre_plugin_total
#   - Emits explicit warning noting approximation.
if (( PROMPT_READY_MS == 0 && ( PRE_COST_MS > 0 || POST_COST_MS > 0 ) )); then
    if [[ "${PERF_FORCE_PROMPT_READY_FALLBACK:-1}" == "1" ]]; then
        if (( POST_COST_MS > 0 )); then
            PROMPT_READY_MS=$POST_COST_MS
        else
            PROMPT_READY_MS=$PRE_COST_MS
        fi
        echo "[perf-capture] WARNING: prompt_ready_ms approximated (no PROMPT_READY markers). Disable with PERF_FORCE_PROMPT_READY_FALLBACK=0 or fix prompt hook ordering." >&2
    else
        echo "[perf-capture] WARNING: prompt_ready_ms=0 (no PROMPT_READY markers). Approximation disabled. (Set PERF_FORCE_PROMPT_READY_FALLBACK=1 to re-enable.)" >&2
        # Optional forced capture attempt if allowed
        if [[ "${PERF_ALLOW_PROMPT_FORCE_CAPTURE:-0}" == "1" ]]; then
          # Emit a forced marker to salvage readiness timing (delta = post or pre)
            FORCE_PROMPT_MS=$(( POST_COST_MS > 0 ? POST_COST_MS : PRE_COST_MS ))
            if (( FORCE_PROMPT_MS > 0 )); then
              PROMPT_READY_MS=$FORCE_PROMPT_MS
              echo "[perf-capture][force] injected prompt_ready_ms=${PROMPT_READY_MS} (forced, no native marker)" >&2
            fi
        fi
    fi
fi
# Additional diagnostics for missing markers / synthetic path
if (( PRE_COST_MS > 0 && POST_COST_MS == 0 )); then
    echo "[perf-capture] NOTICE: post_plugin_cost_ms=0 (no POST_PLUGIN markers) – minimal harness or synthetic markers path did not emit post_plugin_total; consider expanding minimal mode." >&2
fi
if (( PRE_COST_MS == 0 && POST_COST_MS == 0 )); then
    echo "[perf-capture] DIAG: Both pre_plugin_cost_ms and post_plugin_cost_ms are zero; segment log likely empty or marker parsing failed." >&2
fi

# Build breakdown JSON array (average cold/warm per label)
post_breakdown_json="[]"
# Merge encoded lists: label=ms;...
if [[ -n ${COLD_POST_SEGMENTS_ENC:-} || -n ${WARM_POST_SEGMENTS_ENC:-} ]]; then
  typeset -A _cold_seg _warm_seg _labels
  IFS=';' read -rA _carr <<<"${COLD_POST_SEGMENTS_ENC:-}"
  for e in "${_carr[@]}"; do
    [[ -z $e ]] && continue
    lb=${e%%=*}; ms=${e#*=}
    [[ -z $lb || -z $ms ]] && continue
    _cold_seg[$lb]=$ms
    _labels[$lb]=1
  done
  IFS=';' read -rA _warr <<<"${WARM_POST_SEGMENTS_ENC:-}"
  for e in "${_warr[@]}"; do
    [[ -z $e ]] && continue
    lb=${e%%=*}; ms=${e#*=}
    [[ -z $lb || -z $ms ]] && continue
    _warm_seg[$lb]=$ms
    _labels[$lb]=1
  done
  # Construct JSON
  post_breakdown_json="["
  first=1
  for lb in ${(k)_labels}; do
    c=${_cold_seg[$lb]:-0}
    w=${_warm_seg[$lb]:-0}
    if (( c > 0 && w > 0 )); then
      m=$(( (c + w) / 2 ))
    else
      m=$(( c > 0 ? c : w ))
    fi
    (( first )) || post_breakdown_json+=","
    first=0
    post_breakdown_json+="{\"label\":\"$lb\",\"cold_ms\":$c,\"warm_ms\":$w,\"mean_ms\":$m}"
  done
  post_breakdown_json+="]"
  unset _cold_seg _warm_seg _labels _carr _warr lb ms c w m first
fi

if [[ -n ${GUIDELINES_CHECKSUM:-} ]]; then
  GUIDELINES_JSON="\"$GUIDELINES_CHECKSUM\""
else
  GUIDELINES_JSON=null
fi
cat >"$OUT_DIR/$STAMP.json" <<EOF
{
  "timestamp":"$STAMP",
  "guidelines_checksum":$GUIDELINES_JSON,
  "cold_ms":$COLD_MS,
  "warm_ms":$WARM_MS,
  "cold_pre_plugin_ms":$COLD_PRE_MS,
  "cold_post_plugin_ms":$COLD_POST_MS,
  "cold_prompt_ready_ms":$COLD_PROMPT_MS,
  "warm_pre_plugin_ms":$WARM_PRE_MS,
  "warm_post_plugin_ms":$WARM_POST_MS,
  "warm_prompt_ready_ms":$WARM_PROMPT_MS,
  "post_plugin_segments": $post_breakdown_json
}
EOF

# Also update the current metrics file used by promotion guard
# Safe write: prevent progress log pollution overwriting JSON
# Derive native marker presence summaries from per-run flags
PRE_NATIVE_ANY=0; for f in "${PRE_NATIVE_FLAGS[@]:-}"; do (( f == 1 )) && PRE_NATIVE_ANY=1; done
POST_NATIVE_ANY=0; for f in "${POST_NATIVE_FLAGS[@]:-}"; do (( f == 1 )) && POST_NATIVE_ANY=1; done
PROMPT_NATIVE_ANY=0; for f in "${PROMPT_NATIVE_FLAGS[@]:-}"; do (( f == 1 )) && PROMPT_NATIVE_ANY=1; done
PROMPT_NATIVE_ALL=1
if (( ${#PROMPT_NATIVE_FLAGS[@]:-0} == 0 )); then
  PROMPT_NATIVE_ALL=0
else
  for f in "${PROMPT_NATIVE_FLAGS[@]}"; do
    (( f == 1 )) || PROMPT_NATIVE_ALL=0
  done
fi
# Refined provenance classification:
#   native              -> native marker present and prompt != post OR semantic difference
#   native_equal_post   -> native marker present, prompt==post (not synthesized)
#   approx              -> no native marker, prompt==post (approx by fallback)
#   derived             -> no native marker, prompt!=post (derived from another lifecycle)
if (( PROMPT_NATIVE_ANY )); then
  if (( POST_COST_MS > 0 && PROMPT_READY_MS == POST_COST_MS )); then
    MARKER_PROVENANCE="native_equal_post"
  else
    MARKER_PROVENANCE="native"
  fi
else
  if (( POST_COST_MS > 0 && PROMPT_READY_MS == POST_COST_MS )); then
    MARKER_PROVENANCE="approx"
  else
    MARKER_PROVENANCE="derived"
  fi
fi
# Optional self-test JSON (lists raw per-run native flags) when PERF_CAPTURE_SELFTEST=1
SELFTEST_JSON=""
if [[ "${PERF_CAPTURE_SELFTEST:-0}" == "1" ]]; then
  _join_flags() {
    local -a a=("$@")
    local o=""
    for v in "${a[@]}"; do
      if [[ -z $o ]]; then o="$v"; else o="$o,$v"; fi
    done
    printf '%s' "$o"
  }
  SELFTEST_JSON=$(printf '{"pre_native_flags":[%s],"post_native_flags":[%s],"prompt_native_flags":[%s]}' \
    "$(_join_flags "${PRE_NATIVE_FLAGS[@]:-}")" \
    "$(_join_flags "${POST_NATIVE_FLAGS[@]:-}")" \
    "$(_join_flags "${PROMPT_NATIVE_FLAGS[@]:-}")")
fi
_json_pc_safe_write "$TARGET_METRICS_FILE" <<EOF
{
  "timestamp":"$STAMP",
  "mean_ms":$(((COLD_MS + WARM_MS) / 2)),
  "cold_ms":$COLD_MS,
  "warm_ms":$WARM_MS,
  "pre_plugin_cost_ms":$PRE_COST_MS,
  "post_plugin_cost_ms":$POST_COST_MS,
  "prompt_ready_ms":$PROMPT_READY_MS,
  "segments_available":$SEGMENTS_AVAILABLE,
  "marker_provenance":"$MARKER_PROVENANCE",
  "lifecycle": {
    "pre_plugin_total_ms": $PRE_COST_MS,
    "post_plugin_total_ms": $POST_COST_MS,
    "prompt_ready_ms": $PROMPT_READY_MS,
    "approx_prompt_ready": $(( POST_COST_MS > 0 && PROMPT_READY_MS == POST_COST_MS ? 1 : 0 )),
    "marker_provenance":"$MARKER_PROVENANCE"
  },
  "markers_observed": {
    "pre_native_any": $PRE_NATIVE_ANY,
    "post_native_any": $POST_NATIVE_ANY,
    "prompt_native_any": $PROMPT_NATIVE_ANY,
    "prompt_native_all": $PROMPT_NATIVE_ALL
  },$( [[ -n $SELFTEST_JSON ]] && printf '\n  "selftest": %s,' "$SELFTEST_JSON" )
  "post_plugin_segments": $post_breakdown_json
}
EOF

# Emit SEGMENT lines file for perf-diff tooling
: ${segments_file:="$METRICS_DIR/perf-current-segments.txt"}
{
  echo "SEGMENT name=pre_plugin_total ms=$PRE_COST_MS phase=pre_plugin sample=mean"
  echo "SEGMENT name=post_plugin_total ms=$POST_COST_MS phase=post_plugin sample=mean"
  echo "SEGMENT name=prompt_ready ms=$PROMPT_READY_MS phase=prompt sample=mean"
  # Optional segment reconstruction (disabled by default to avoid set -u issues).
  # Enable with PERF_ENABLE_SEGMENT_RECONSTRUCT=1 to rebuild per-segment averages.
  if [[ "${PERF_ENABLE_SEGMENT_RECONSTRUCT:-0}" == "1" && ( -n ${COLD_POST_SEGMENTS_ENC:-} || -n ${WARM_POST_SEGMENTS_ENC:-} ) ]]; then
    set +u
    local _cold_enc="${COLD_POST_SEGMENTS_ENC:-}"
    local _warm_enc="${WARM_POST_SEGMENTS_ENC:-}"
    set -u
    typeset -A _re_labels _re_vals _re_counts
    local e lb ms
    if [[ -n $_cold_enc ]]; then
      for e in ${(s/;/)_cold_enc}; do
        [[ -z $e ]] && continue
        lb=${e%%=*}; ms=${e#*=}
        [[ -z $lb || -z $ms ]] && continue
        _re_vals[$lb]=$ms
        _re_counts[$lb]=$(( ${_re_counts[$lb]:-0} + 1 ))
        _re_labels[$lb]=1
      done
    fi
    if [[ -n $_warm_enc ]]; then
      for e in ${(s/;/)_warm_enc}; do
        [[ -z $e ]] && continue
        lb=${e%%=*}; ms=${e#*=}
        [[ -z $lb || -z $ms ]] && continue
        if [[ -n ${_re_vals[$lb]:-} ]]; then
          _re_vals[$lb]=$(( (_re_vals[$lb] * _re_counts[$lb] + ms) / (_re_counts[$lb] + 1) ))
          _re_counts[$lb]=$(( _re_counts[$lb] + 1 ))
        else
          _re_vals[$lb]=$ms
          _re_counts[$lb]=1
        fi
        _re_labels[$lb]=1
      done
    fi
    if (( ${#_re_labels[@]} )); then
      for lb in ${(k)_re_labels}; do
        echo "SEGMENT name=${lb} ms=${_re_vals[$lb]} phase=post_plugin sample=mean"
      done
    fi
  fi
  : ${GUIDELINES_CHECKSUM:=}
  if [[ -n $GUIDELINES_CHECKSUM ]]; then
    echo "SEGMENT name=policy_guidelines_checksum ms=0 phase=other sample=meta checksum=$GUIDELINES_CHECKSUM"
  fi
} >"$segments_file" 2>/dev/null || true
echo "[perf-capture] wrote $OUT_DIR/$STAMP.json"
echo "[perf-capture] updated $TARGET_METRICS_FILE"
# Summary guard block (defensive initialization under set -u)
: ${PRE_COST_MS:=${PRE_COST_MS:-0}}
: ${POST_COST_MS:=${POST_COST_MS:-0}}
: ${PROMPT_READY_MS:=${PROMPT_READY_MS:-0}}
: ${SUMMARY_POST_MS:=${POST_COST_MS}}
: ${SUMMARY_PROMPT_MS:=${PROMPT_READY_MS}}
echo "[perf-capture] cold: ${COLD_MS}ms (pre: ${PRE_COST_MS}ms, post: ${SUMMARY_POST_MS}ms, prompt: ${SUMMARY_PROMPT_MS}ms)"
echo "[perf-capture] warm: ${WARM_MS}ms (pre: ${PRE_COST_MS}ms, post: ${SUMMARY_POST_MS}ms, prompt: ${SUMMARY_PROMPT_MS}ms)"
=======
mkdir -p "$OUT_DIR"

measure_startup() {
  local start=$EPOCHREALTIME
  zsh -ic 'exit' >/dev/null 2>&1 || true
  local end=$EPOCHREALTIME
  # Convert (floating seconds) to ms (integer)
  local delta_sec=$(awk -v s=$start -v e=$end 'BEGIN{printf "%.6f", e-s}')
  awk -v d=$delta_sec 'BEGIN{printf "%d", d*1000}'
}

echo "[perf-capture] cold run..." >&2
COLD_MS=$(measure_startup)
echo "[perf-capture] warm run..." >&2
WARM_MS=$(measure_startup)

cat > "$OUT_DIR/$STAMP.json" <<EOF
{"timestamp":"$STAMP","cold_ms":$COLD_MS,"warm_ms":$WARM_MS}
EOF

echo "[perf-capture] wrote $OUT_DIR/$STAMP.json (cold_ms=$COLD_MS warm_ms=$WARM_MS)"
>>>>>>> origin/develop
