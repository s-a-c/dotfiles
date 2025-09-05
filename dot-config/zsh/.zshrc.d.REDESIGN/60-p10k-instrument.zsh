#!/opt/homebrew/bin/zsh
# 60-p10k-instrument.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Instrument the sourcing of the Powerlevel10k theme (if present) to obtain a
#   granular timing segment (p10k_theme) within the post-plugin phase. This helps
#   isolate large portions of post_plugin_cost_ms and enables future regression
#   gating. Safe to load even when theme absent or already initialized.
#
# FEATURES:
#   - Uses segment-lib.zsh helpers when available for unified SEGMENT emission.
#   - Falls back to a minimal inline timer if segment-lib is not yet loaded.
#   - Emits:
#       SEGMENT name=p10k_theme ms=<delta> phase=post_plugin sample=<cold|warm|unknown>
#       (via segment-lib) plus legacy POST_PLUGIN_SEGMENT line for backward tools.
#   - Idempotent: will not re-source if detected loaded.
#
# DETECTION LOGIC (avoids double load):
#   - _P10K_THEME_LOADED variable
#   - Presence of function prompt_* (heuristic) after sourcing attempt
#
# CONFIG FLAGS:
#   ZSH_P10K_INSTRUMENT=0   Disable instrumentation & sourcing (default enabled)
#   ZSH_P10K_FILE=<path>    Override path to .p10k.zsh (auto-detect if unset)
#
# ORDER:
#   Placed at 60-* after earlier post-plugin segments (20,30,50) and before
#   vcs/gitstatus or prompt-ready markers still useful for isolating cost.
#
# SAFETY:
#   - No compinit invocation.
#   - Silent if theme absent.
#
# FUTURE:
#   - Add separate segment for gitstatus daemon start if measurable.
#
# ------------------------------------------------------------------------------

# Sentinel
[[ -n ${_LOADED_60_P10K_INSTRUMENT:-} ]] && return
_LOADED_60_P10K_INSTRUMENT=1

typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }

# Opt-out
if [[ "${ZSH_P10K_INSTRUMENT:-1}" == "0" ]]; then
  zsh_debug_echo "# [p10k][instrument] disabled via ZSH_P10K_INSTRUMENT=0"
  return 0
fi

# Resolve candidate theme file
if [[ -z ${ZSH_P10K_FILE:-} ]]; then
  if [[ -r "${ZDOTDIR:-$HOME/.config/zsh}/.p10k.zsh" ]]; then
    ZSH_P10K_FILE="${ZDOTDIR:-$HOME/.config/zsh}/.p10k.zsh"
  elif [[ -r "$HOME/.p10k.zsh" ]]; then
    ZSH_P10K_FILE="$HOME/.p10k.zsh"
  fi
fi

# If still empty or unreadable, nothing to do
if [[ -z ${ZSH_P10K_FILE:-} || ! -r ${ZSH_P10K_FILE:-/dev/null} ]]; then
  zsh_debug_echo "# [p10k][instrument] theme file not found (skipping)"
  return 0
fi

# Abort if previously loaded
if [[ -n ${_P10K_THEME_LOADED:-} ]]; then
  zsh_debug_echo "# [p10k][instrument] already marked loaded (skipping)"
  return 0
fi

# Try to load segment-lib for unified helpers (ignore errors)
__p10k_sl_base="${ZDOTDIR:-$HOME/.config/zsh}/tools/segment-lib.zsh"
if [[ -r "$__p10k_sl_base" ]]; then
  # shellcheck disable=SC1090
  source "$__p10k_sl_base" 2>/dev/null || true
fi
unset __p10k_sl_base

# If helper exists use it; else create minimal fallback
if typeset -f _zsh_perf_segment_start >/dev/null 2>&1 && \
   typeset -f _zsh_perf_segment_end >/dev/null 2>&1; then
  __p10k_use_lib=1
else
  __p10k_use_lib=0
  # Minimal ms clock
  _p10k_now_ms() {
    zmodload zsh/datetime 2>/dev/null || true
    local rt=$EPOCHREALTIME
    [[ -z $rt ]] && echo "" && return
    printf '%s' "$rt" | awk -F. '{ms=($1*1000); if(NF>1){ms+=substr($2"000",1,3)+0} printf "%d", ms}'
  }
fi

# Fallback start/end (only if lib absent)
_p10k_fallback_start() {
  [[ -n ${P10K_SEGMENT_START_MS:-} ]] && return
  P10K_SEGMENT_START_MS=$(_p10k_now_ms)
  export P10K_SEGMENT_START_MS
  zsh_debug_echo "# [p10k][instrument][fallback] start=${P10K_SEGMENT_START_MS}"
}
_p10k_fallback_end() {
  [[ -z ${P10K_SEGMENT_START_MS:-} || -n ${P10K_SEGMENT_MS:-} ]] && return
  local end ms
  end=$(_p10k_now_ms)
  [[ -z $end ]] && return
  (( ms = end - P10K_SEGMENT_START_MS ))
  P10K_SEGMENT_MS=$ms
  export P10K_SEGMENT_MS
  local sample="${PERF_SAMPLE_CONTEXT:-unknown}"
  if [[ -n ${PERF_SEGMENT_LOG:-} && -w ${PERF_SEGMENT_LOG:-/dev/null} ]]; then
    print "SEGMENT name=p10k_theme ms=${ms} phase=post_plugin sample=${sample}" >>"${PERF_SEGMENT_LOG}" 2>/dev/null || true
    print "POST_PLUGIN_SEGMENT p10k_theme ${ms}" >>"${PERF_SEGMENT_LOG}" 2>/dev/null || true
  fi
  zsh_debug_echo "# [p10k][instrument][fallback] end=${end} delta=${ms}ms"
}

# Start timing
if (( __p10k_use_lib )); then
  _zsh_perf_segment_start p10k_theme post_plugin
else
  _p10k_fallback_start
fi

# Source theme
# shellcheck disable=SC1090
source "${ZSH_P10K_FILE}" 2>/dev/null || {
  zsh_debug_echo "# [p10k][instrument] ERROR sourcing ${ZSH_P10K_FILE}"
}

# Mark loaded
_P10K_THEME_LOADED=1
export _P10K_THEME_LOADED

# End timing
if (( __p10k_use_lib )); then
  _zsh_perf_segment_end p10k_theme post_plugin
else
  _p10k_fallback_end
fi

zsh_debug_echo "# [p10k][instrument] loaded file=${ZSH_P10K_FILE}"

# Cleanup fallback functions if defined (avoid namespace noise)
if ! (( __p10k_use_lib )); then
  unset -f _p10k_now_ms _p10k_fallback_start _p10k_fallback_end 2>/dev/null || true
fi
unset __p10k_use_lib

# End 60-p10k-instrument.zsh
