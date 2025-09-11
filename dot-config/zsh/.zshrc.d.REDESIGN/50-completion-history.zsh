#!/opt/homebrew/bin/zsh
# 50-completion-history.zsh
: ${_LOADED_POST_PLUGIN_50_COMPLETION_HISTORY:=1}
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

# Helper for granular timing
_zf_ch_now_ms() {
    if [[ -n "${EPOCHREALTIME:-}" ]]; then
        printf '%s' "$EPOCHREALTIME" | awk -F. '{ms=($1*1000); if(NF>1){ ms+=substr($2 "000",1,3)+0 } printf "%d", ms}'
        return 0
    fi
    date +%s 2>/dev/null | awk '{printf "%d",$1*1000}'
}

# Segment helper with fallback
_zf_ch_segment() {
    local name="$1" action="$2"
    if typeset -f _zsh_perf_segment_${action} >/dev/null 2>&1; then
        _zsh_perf_segment_${action} "completion/${name}" post_plugin
    else
        # Fallback timing
        if [[ "$action" == "start" ]]; then
            _ZF_CH_SEG_START[$name]=$(_zf_ch_now_ms)
        elif [[ "$action" == "end" && -n ${_ZF_CH_SEG_START[$name]:-} ]]; then
            local end_ms=$(_zf_ch_now_ms)
            local delta=$(( end_ms - _ZF_CH_SEG_START[$name] ))
            (( delta < 0 )) && delta=0
            if [[ -n "${PERF_SEGMENT_LOG:-}" ]]; then
                print "SEGMENT name=completion/${name} ms=${delta} phase=post_plugin sample=${PERF_SAMPLE_CONTEXT:-unknown}" >> "${PERF_SEGMENT_LOG}" 2>/dev/null || true
            fi
        fi
    fi
}

typeset -gA _ZF_CH_SEG_START

# History configuration
_zf_ch_segment "history-setup" "start"
if [[ -z ${_HISTORY_CONFIGURED:-} ]]; then
    # Set history options
    HISTFILE="${HISTFILE:-${ZDOTDIR:-$HOME}/.zsh_history}"
    HISTSIZE="${HISTSIZE:-10000}"
    SAVEHIST="${SAVEHIST:-10000}"

    # History options for better experience
    setopt HIST_IGNORE_DUPS
    setopt HIST_IGNORE_SPACE
    setopt HIST_VERIFY
    setopt SHARE_HISTORY
    setopt HIST_REDUCE_BLANKS

    _HISTORY_CONFIGURED=1
    export _HISTORY_CONFIGURED
    zsh_debug_echo "# [post-plugin][history] configured with HISTFILE=$HISTFILE"
fi
_zf_ch_segment "history-setup" "end"

# Completion cache scan and initialization
_zf_ch_segment "cache-scan" "start"
if [[ -z ${_COMPINIT_DONE:-} ]]; then
  autoload -Uz compinit 2>/dev/null || true
  if command -v compinit >/dev/null 2>&1; then
    local compdump_file="${ZGEN_CUSTOM_COMPDUMP:-${ZSH_COMPDUMP:-${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zcompdump}}"
    # Check if cache is fresh (less than 24 hours old)
    local dump_mtime=0
    [[ -f "$compdump_file" ]] && dump_mtime=$(stat -f %m "$compdump_file" 2>/dev/null || stat -c %Y "$compdump_file" 2>/dev/null || echo 0)
    local now_time=$(date +%s 2>/dev/null || echo 0)
    local age_hours=$(( (now_time - dump_mtime) / 3600 ))

    if [[ ! -f "$compdump_file" || $age_hours -gt 24 ]]; then
        compinit -d "$compdump_file" 2>/dev/null || true
        zsh_debug_echo "# [post-plugin][completion] rebuilt stale cache (age: ${age_hours}h)"
    else
        compinit -C -d "$compdump_file" 2>/dev/null || true
        zsh_debug_echo "# [post-plugin][completion] using fresh cache (age: ${age_hours}h)"
    fi

    _COMPINIT_DONE=1
    export _COMPINIT_DONE
  fi
fi
_zf_ch_segment "cache-scan" "end"

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
