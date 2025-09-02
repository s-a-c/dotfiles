# 50-completion-history.zsh
: ${_LOADED_50_COMPLETION_HISTORY:=1}
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v900f08def0e6f7959ffd283aebb73b625b3473f5e49c57e861c6461b50a62ef2
#
# PURPOSE:
#   Timing instrumentation for the completion + history post‑plugin phase.
#   Provides a granular marker so large post_plugin_cost_ms can be decomposed.
#
# MARKER FORMAT:
#   POST_PLUGIN_SEGMENT 50-completion-history <delta_ms>
#
# DESIGN:
#   - Emits only if PERF_SEGMENT_LOG is set (perf-capture context).
#   - Idempotent; will not re-emit if POST_SEG_50_COMPLETION_HISTORY_MS already set.
#   - Placeholder area for future completion/history initialization logic.
#
zmodload zsh/datetime 2>/dev/null || true
typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }

# Capture start time (ms) once if logging is active
if [[ -n ${PERF_SEGMENT_LOG:-} && -z ${POST_SEG_50_COMPLETION_HISTORY_START_MS:-} ]]; then
  POST_SEG_50_COMPLETION_HISTORY_START_MS=$(printf '%s' "$EPOCHREALTIME" | awk -F. '{ms=$1*1000;if(NF>1){ms+=substr($2"000",1,3)+0}printf "%d",ms}')
  export POST_SEG_50_COMPLETION_HISTORY_START_MS
fi

# === Completion & history initialization placeholder START ===
# (Future: compinit guarded invocation, history extended settings, cache warming, etc.)
# === Completion & history initialization placeholder END ===

# Emit end marker & delta once
if [[ -n ${PERF_SEGMENT_LOG:-} && -n ${POST_SEG_50_COMPLETION_HISTORY_START_MS:-} && -z ${POST_SEG_50_COMPLETION_HISTORY_MS:-} ]]; then
  __post_seg_50_end_ms=$(printf '%s' "$EPOCHREALTIME" | awk -F. '{ms=$1*1000;if(NF>1){ms+=substr($2"000",1,3)+0}printf "%d",ms}')
  if [[ -n $__post_seg_50_end_ms ]]; then
    (( __post_seg_50_delta = __post_seg_50_end_ms - POST_SEG_50_COMPLETION_HISTORY_START_MS ))
    POST_SEG_50_COMPLETION_HISTORY_MS=$__post_seg_50_delta
    export POST_SEG_50_COMPLETION_HISTORY_MS
    if (( __post_seg_50_delta >= 0 )); then
      print "POST_PLUGIN_SEGMENT 50-completion-history $__post_seg_50_delta" >>"${PERF_SEGMENT_LOG}" 2>/dev/null || true
    fi
    zsh_debug_echo "# [post-plugin][perf] segment=50-completion-history delta=${POST_SEG_50_COMPLETION_HISTORY_MS}ms"
  fi
  unset __post_seg_50_end_ms __post_seg_50_delta
fi
