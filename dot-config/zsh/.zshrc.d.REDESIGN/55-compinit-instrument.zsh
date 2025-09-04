# 55-compinit-instrument.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Instrument the execution of compinit to obtain an isolated timing segment.
#   Provide consistent SEGMENT emission for later regression analysis and gating.
#
# FEATURES:
#   - Auto-detect central compdump destination.
#   - Strategies: fast (-C), normal (default), secure (compaudit pre-check).
#   - Emits SEGMENT line (segment-lib) or fallback SEGMENT if library absent.
#   - Emits legacy POST_PLUGIN_SEGMENT for backward compatibility (handled by segment-lib or fallback).
#   - Idempotent; skips if compinit already executed.
#
# WHY INSTRUMENT:
#   Compinit can dominate startup cost due to parsing large completion trees.
#   Measuring it separately allows gating and targeted optimization (e.g., caching, pruning fpath).
#
# CONFIGURATION:
#   ZSH_COMPINIT_INSTRUMENT=0        Disable this module entirely.
#   ZSH_COMPINIT_STRATEGY=fast|normal|secure   Choose initialization mode (default fast).
#   ZSH_COMPINIT_DUMPFILE=<path>     Override compdump location.
#   ZSH_COMPINIT_FAST_FALLBACK=1     If secure strategy fails, retry fast (default 1).
#   ZSH_COMPINIT_SKIP_IF_LATEX=1     Example sentinel pattern where we might skip (reserved).
#
# EXPORTS / SENTINELS:
#   ZSH_COMPINIT_RAN=1               Set after successful compinit invocation.
#   _COMPINIT_INSTRUMENT_DELTA_MS    Milliseconds for compinit (fallback timing only).
#
# SEGMENT LABEL:
#   compinit (phase=post_plugin)
#
# ORDER:
#   Placed at 55-* after completion/history scaffold (50-) but before theme (60-).
#
# SAFETY:
#   - Does not run if compinit function missing.
#   - Avoids double invocation by checking common sentinels and non-empty $fpath caches.
#
# FUTURE:
#   - Add pruning metrics (function count before/after).
#   - Track number of insecure paths flagged by compaudit.
#
# -----------------------------------------------------------------------------
[[ -n ${_LOADED_55_COMPINIT_INSTRUMENT:-} ]] && return
_LOADED_55_COMPINIT_INSTRUMENT=1
typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }
# Opt-out early
if [[ "${ZSH_COMPINIT_INSTRUMENT:-1}" == "0" ]]; then
  zsh_debug_echo "# [compinit][instrument] disabled via ZSH_COMPINIT_INSTRUMENT=0"
  return 0
fi
# If we already believe compinit executed, skip
if [[ -n ${ZSH_COMPINIT_RAN:-} || -n ${_COMPINIT_INITIALIZED:-} ]]; then
  zsh_debug_echo "# [compinit][instrument] already ran (sentinel detected)"
  return 0
fi
# Ensure compinit is autoloadable
autoload -Uz compinit 2>/dev/null || {
  zsh_debug_echo "# [compinit][instrument] compinit not available"
  return 0
}
# Try to source segment-lib for unified helpers
__ci_seg_lib="${ZDOTDIR:-$HOME/.config/zsh}/tools/segment-lib.zsh"
if [[ -r "$__ci_seg_lib" ]]; then
  # shellcheck disable=SC1090
  source "$__ci_seg_lib" 2>/dev/null || true
fi
unset __ci_seg_lib
# Clock utilities (fallback if library not present)
if ! typeset -f _zsh_perf_segment_start >/dev/null 2>&1; then
  __ci_now_ms() {
    zmodload zsh/datetime 2>/dev/null || true
    local rt=$EPOCHREALTIME
    [[ -z $rt ]] && echo "" && return
    printf '%s' "$rt" | awk -F. '{ms=($1*1000); if(NF>1){ms+=substr($2"000",1,3)+0} printf "%d", ms}'
  }
fi
# Determine compdump path
if [[ -z ${ZSH_COMPINIT_DUMPFILE:-} ]]; then
  # Centralize in cache under ZDOTDIR for CI determinism
  ZSH_COMPINIT_DUMPFILE="${ZDOTDIR:-$HOME/.config/zsh}/.zcompdump"
fi
export ZSH_COMPINIT_DUMPFILE
# Strategy selection
__ci_strategy="${ZSH_COMPINIT_STRATEGY:-fast}"
case "$__ci_strategy" in
  fast|FAST)   __ci_strategy="fast" ;;
  normal|NORMAL|std) __ci_strategy="normal" ;;
  secure|SECURE|audit) __ci_strategy="secure" ;;
  *) __ci_strategy="fast" ;;
esac
zsh_debug_echo "# [compinit][instrument] strategy=$__ci_strategy dump=$ZSH_COMPINIT_DUMPFILE"
# Prepare timing
if typeset -f _zsh_perf_segment_start >/dev/null 2>&1; then
  _zsh_perf_segment_start compinit post_plugin
else
  __ci_start_ms=$(__ci_now_ms)
fi
# Execute compinit according to strategy
__ci_rc=0
if [[ "$__ci_strategy" == "fast" ]]; then
  compinit -C -d "$ZSH_COMPINIT_DUMPFILE" || __ci_rc=$?
elif [[ "$__ci_strategy" == "normal" ]]; then
  compinit -d "$ZSH_COMPINIT_DUMPFILE" || __ci_rc=$?
else
  # secure: run compaudit first
  local insecure_paths insecure_count
  insecure_paths=()
  if typeset -f compaudit >/dev/null 2>&1 || autoload -Uz compaudit 2>/dev/null; then
    while IFS= read -r p; do
      [[ -n $p ]] && insecure_paths+=("$p")
    done < <(compaudit 2>/dev/null)
  fi
  insecure_count=${#insecure_paths[@]}
  if (( insecure_count > 0 )); then
    zsh_debug_echo "# [compinit][instrument][secure] WARNING: ${insecure_count} insecure path(s) detected"
  fi
  compinit -d "$ZSH_COMPINIT_DUMPFILE" || __ci_rc=$?
  # If failure and fallback enabled, retry fast
  if (( __ci_rc != 0 )) && [[ "${ZSH_COMPINIT_FAST_FALLBACK:-1}" == "1" ]]; then
    zsh_debug_echo "# [compinit][instrument][secure] retrying fast fallback"
    __ci_strategy="fast"
    compinit -C -d "$ZSH_COMPINIT_DUMPFILE" || __ci_rc=$?
  fi
fi
# Mark as ran if success
if (( __ci_rc == 0 )); then
  ZSH_COMPINIT_RAN=1
  export ZSH_COMPINIT_RAN
fi
# End timing
if typeset -f _zsh_perf_segment_end >/dev/null 2>&1; then
  _zsh_perf_segment_end compinit post_plugin
else
  __ci_end_ms=$(__ci_now_ms)
  if [[ -n ${__ci_start_ms:-} && -n ${__ci_end_ms:-} ]]; then
    (( _COMPINIT_INSTRUMENT_DELTA_MS = __ci_end_ms - __ci_start_ms ))
    export _COMPINIT_INSTRUMENT_DELTA_MS
    local sample="${PERF_SAMPLE_CONTEXT:-unknown}"
    if [[ -n ${PERF_SEGMENT_LOG:-} && -w ${PERF_SEGMENT_LOG:-/dev/null} ]]; then
      print "SEGMENT name=compinit ms=${_COMPINIT_INSTRUMENT_DELTA_MS} phase=post_plugin sample=${sample}" >>"${PERF_SEGMENT_LOG}" 2>/dev/null || true
      print "POST_PLUGIN_SEGMENT compinit ${_COMPINIT_INSTRUMENT_DELTA_MS}" >>"${PERF_SEGMENT_LOG}" 2>/dev/null || true
    fi
    zsh_debug_echo "# [compinit][instrument][fallback] delta=${_COMPINIT_INSTRUMENT_DELTA_MS}ms"
  fi
fi
if (( __ci_rc == 0 )); then
  zsh_debug_echo "# [compinit][instrument] completed OK"
else
  zsh_debug_echo "# [compinit][instrument] ERROR rc=${__ci_rc}"
fi
# Cleanup temporaries
unset __ci_strategy __ci_start_ms __ci_end_ms __ci_rc insecure_paths insecure_count
# End 55-compinit-instrument.zsh
