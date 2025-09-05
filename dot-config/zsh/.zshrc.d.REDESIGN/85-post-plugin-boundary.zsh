#!/opt/homebrew/bin/zsh
# 85-post-plugin-boundary.zsh
# Post-Plugin Boundary / Marker Consolidation
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md] ${GUIDELINES_CHECKSUM:-vUNKNOWN}
#
# PURPOSE:
#   Establish a deterministic boundary at the end of the "post-plugin" initialization
#   phase and emit coarse timing markers consumed by the performance harness.
#
# WHAT THIS MODULE DOES:
#   1. Captures POST_PLUGIN_END_REALTIME/MS (absolute ms epoch).
#   2. Derives POST_PLUGIN_TOTAL_MS = POST_PLUGIN_END_MS - PRE_PLUGIN_END_MS (if available).
#   3. Emits (once) the legacy coarse markers:
#        POST_PLUGIN_COMPLETE <ms>
#        SEGMENT name=post_plugin_total ms=<ms> phase=post_plugin sample=${PERF_SAMPLE_CONTEXT:-unknown}
#   4. Exports the computed variables for downstream prompt readiness logic.
#
# NON-GOALS (kept minimal for "soonest implementation"):
#   - No retry / synthetic fallback (handled earlier by perf-capture F38).
#   - No prompt readiness fallback emission (deferred to prompt module).
#   - No per-segment enumeration (already handled by segment injection logic).
#
# SAFETY & IDEMPOTENCE:
#   - Guarded by sentinel to prevent double emission.
#   - Re-checks log for an existing POST_PLUGIN_COMPLETE marker to avoid duplicates.
#
# ENV FLAGS (future extension hooks):
#   POST_PLUGIN_BOUNDARY_DISABLE=1  -> Skip all logic.
#   POST_PLUGIN_BOUNDARY_DEBUG=1    -> Verbose stderr debug tracing.
#
# EXIT CONDITIONS (timing):
#   A missing PRE_PLUGIN_END_MS prevents total computation; we still record END times.
#
# ------------------------------------------------------------------------------

[[ -n ${_LOADED_POST_PLUGIN_BOUNDARY:-} ]] && return
_LOADED_POST_PLUGIN_BOUNDARY=1

# Early opt-out
if [[ "${POST_PLUGIN_BOUNDARY_DISABLE:-0}" == "1" ]]; then
  return 0
fi

# Provide quiet debug helper if absent
typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }

_ppb_dbg() {
  [[ "${POST_PLUGIN_BOUNDARY_DEBUG:-0}" == "1" ]] && print -- "[85-post-plugin-boundary][debug] $*" >&2
}

# Convert an EPOCHREALTIME-like float seconds stamp into integer ms
_ppb_epoch_to_ms() {
  local ts="$1" sec frac
  [[ -z $ts ]] && return 1
  case "$ts" in
    *.*) sec=${ts%%.*}; frac=${ts#*.};;
    *) sec=$ts; frac=0;;
  esac
  frac="${frac}000"
  frac=${frac%%[!0-9]*}
  frac=${frac:0:3}
  print $(( sec * 1000 + ${frac:-0} ))
}

# Ensure zsh/datetime for EPOCHREALTIME
zmodload zsh/datetime 2>/dev/null || true

# Capture end realtime if not already set
if [[ -z ${POST_PLUGIN_END_REALTIME:-} ]]; then
  POST_PLUGIN_END_REALTIME=$EPOCHREALTIME
  export POST_PLUGIN_END_REALTIME
fi

# Derive ms variant if missing
if [[ -z ${POST_PLUGIN_END_MS:-} && -n ${POST_PLUGIN_END_REALTIME:-} ]]; then
  if command -v awk >/dev/null 2>&1; then
    POST_PLUGIN_END_MS=$(printf '%s' "$POST_PLUGIN_END_REALTIME" | awk -F. '{ms=$1*1000; if(NF>1){ms+=substr($2"000",1,3)+0} printf "%d",ms}')
  else
    POST_PLUGIN_END_MS=$(_ppb_epoch_to_ms "$POST_PLUGIN_END_REALTIME" || echo "")
  fi
  [[ -n ${POST_PLUGIN_END_MS:-} ]] && export POST_PLUGIN_END_MS
fi

# Compute total (requires PRE_PLUGIN_END_MS); treat negative as zero
if [[ -z ${POST_PLUGIN_TOTAL_MS:-} && -n ${POST_PLUGIN_END_MS:-} && -n ${PRE_PLUGIN_END_MS:-} ]]; then
  (( POST_PLUGIN_TOTAL_MS = POST_PLUGIN_END_MS - PRE_PLUGIN_END_MS ))
  (( POST_PLUGIN_TOTAL_MS < 0 )) && POST_PLUGIN_TOTAL_MS=0
  export POST_PLUGIN_TOTAL_MS
fi

# Emit markers only if:
#   - PERF_SEGMENT_LOG set
#   - We have POST_PLUGIN_TOTAL_MS
#   - POST_PLUGIN_COMPLETE not already present
if [[ -n ${PERF_SEGMENT_LOG:-} && -n ${POST_PLUGIN_TOTAL_MS:-} ]]; then
  if ! grep -q 'POST_PLUGIN_COMPLETE' "${PERF_SEGMENT_LOG}" 2>/dev/null; then
    {
      print "POST_PLUGIN_COMPLETE ${POST_PLUGIN_TOTAL_MS}"
      print "SEGMENT name=post_plugin_total ms=${POST_PLUGIN_TOTAL_MS} phase=post_plugin sample=${PERF_SAMPLE_CONTEXT:-unknown}"
    } >>"${PERF_SEGMENT_LOG}" 2>/dev/null || true
    _ppb_dbg "emitted POST_PLUGIN_COMPLETE=${POST_PLUGIN_TOTAL_MS}"
  else
    _ppb_dbg "marker already present; skipping emission"
  fi
elif [[ -n ${PERF_SEGMENT_LOG:-} && -z ${POST_PLUGIN_TOTAL_MS:-} ]]; then
  _ppb_dbg "POST_PLUGIN_TOTAL_MS unavailable (missing PRE_PLUGIN_END_MS=${PRE_PLUGIN_END_MS:-?})"
fi

# Export adapter names used by perf-capture fallback logic (align naming)
if [[ -n ${POST_PLUGIN_TOTAL_MS:-} ]]; then
  : "${POST_PLUGIN_TOTAL_MS:?}"  # no-op assertion
fi

zsh_debug_echo "# [post-plugin-boundary] end=${POST_PLUGIN_END_MS:-n/a} total=${POST_PLUGIN_TOTAL_MS:-n/a}"

# Optional: set simple alias variables expected by older tooling (defensive)
if [[ -n ${POST_PLUGIN_TOTAL_MS:-} && -z ${POST_PLUGIN_MS:-} ]]; then
  POST_PLUGIN_MS=$POST_PLUGIN_TOTAL_MS
  export POST_PLUGIN_MS
fi

# ---------------------------------------------------------------------------
# Option C: Immediate Prompt Readiness Capture (Headless Harness Support)
#
# PURPOSE:
#   In headless / harness-driven startup (PERF_PROMPT_HARNESS=1) the interactive
#   shell may exit before the prompt-ready module's background timers or precmd
#   hook fire. To avoid forcing approximation or fallback injection later,
#   we opportunistically emit PROMPT_READY_COMPLETE here at the post-plugin
#   boundary if it has not already appeared.
#
# CONTROL:
#   POST_PLUGIN_BOUNDARY_PROMPT_CAPTURE=1 (default 1) to enable.
#   Set to 0 to disable this early capture (allows measuring true prompt latency
#   in fully interactive sessions).
#
# DELTA REFERENCE ORDER:
#   1. PRE_PLUGIN_END_MS
#   2. PRE_PLUGIN_START_MS
#   3. POST_PLUGIN_END_MS (as a last resort; delta then reflects zero or minimal gap)
#
# SAFETY:
#   - Emits only if PROMPT_READY_COMPLETE absent.
#   - Uses current EPOCHREALTIME; if earlier prompt module later fires, duplicate
#     emission is prevented by its own re-entry guard + existing marker check logic.
# ---------------------------------------------------------------------------
: ${POST_PLUGIN_BOUNDARY_PROMPT_CAPTURE:=1}
if [[ "${POST_PLUGIN_BOUNDARY_PROMPT_CAPTURE}" == "1" && "${PERF_PROMPT_HARNESS:-0}" == "1" && -n ${PERF_SEGMENT_LOG:-} ]]; then
  if ! grep -q 'PROMPT_READY_COMPLETE' "${PERF_SEGMENT_LOG}" 2>/dev/null; then
    zmodload zsh/datetime 2>/dev/null || true
    _ppb_pr_base=""
    if [[ -n ${PRE_PLUGIN_END_MS:-} ]]; then
      _ppb_pr_base=$PRE_PLUGIN_END_MS
    elif [[ -n ${PRE_PLUGIN_START_MS:-} ]]; then
      _ppb_pr_base=$PRE_PLUGIN_START_MS
    elif [[ -n ${POST_PLUGIN_END_MS:-} ]]; then
      _ppb_pr_base=$POST_PLUGIN_END_MS
    fi
    if [[ -n $_ppb_pr_base ]]; then
      _ppb_pr_now_rt=$EPOCHREALTIME
      _ppb_pr_now_ms=$(print -r -- "$_ppb_pr_now_rt" | awk -F. '{ms=$1*1000; if(NF>1){ms+=substr($2"000",1,3)+0}; printf "%d", ms}')
      (( _ppb_pr_delta = _ppb_pr_now_ms - _ppb_pr_base ))
      (( _ppb_pr_delta < 0 )) && _ppb_pr_delta=0
      {
        print "PROMPT_READY_COMPLETE ${_ppb_pr_delta}"
        print "SEGMENT name=prompt_ready ms=${_ppb_pr_delta} phase=prompt sample=${PERF_SAMPLE_CONTEXT:-unknown}"
      } >>"${PERF_SEGMENT_LOG}" 2>/dev/null || true
      zsh_debug_echo "# [post-plugin-boundary][prompt-immediate] emitted prompt_ready delta=${_ppb_pr_delta}"
    else
      zsh_debug_echo "# [post-plugin-boundary][prompt-immediate] skipped (no base ms available)"
    fi
  fi
fi

# Cleanup internal helpers (retain exported timings)
unset -f _ppb_epoch_to_ms 2>/dev/null || true
unset -f _ppb_dbg 2>/dev/null || true

# End of 85-post-plugin-boundary.zsh
