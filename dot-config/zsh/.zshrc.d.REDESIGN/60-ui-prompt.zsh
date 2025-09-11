#!/opt/homebrew/bin/zsh
# 60-ui-prompt.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v900f08def0e6f7959ffd283aebb73b625b3473f5e49c57e861c6461b50a62ef2
#
# PURPOSE:
#   Placeholder for future unified prompt/theme orchestration (Stage 5+).
#   Adds a minimal instrumentation stub so that incremental prompt work
#   can be performance-attributed early without adding noise.
#
# EMITTED (when PERF_SEGMENT_LOG is writable):
#   SEGMENT name=ui/prompt-setup ms=<delta> phase=post_plugin sample=<context>
#   (JSON sidecar line when ZSH_LOG_STRUCTURED=1)
#
# GUARANTEES:
#   - Zero side effects on user prompt today (does NOT change $PROMPT or p10k).
#   - Idempotent (guarded).
#   - Near‑zero overhead (a few arithmetic ops).
#
# DISABLE (optional):
#   export ZSH_DISABLE_UI_PROMPT_SEGMENT=1  → suppress timing emission (for A/B)
#
# PRIVACY:
#   Only timing metadata (whitelisted fields). No shell state or directory paths.

# Prevent multiple loading
[[ -n "${_LOADED_60_UI_PROMPT:-}" ]] && return 0

: ${_LOADED_60_UI_PROMPT:=1}
readonly _LOADED_60_UI_PROMPT=1

# Fast exit if disabled
if [[ "${ZSH_DISABLE_UI_PROMPT_SEGMENT:-0}" == "1" ]]; then
  return 0
fi

# High‑resolution clock if available
zmodload zsh/datetime 2>/dev/null || true

__ui_now_ms() {
  if [[ -n ${EPOCHREALTIME:-} ]]; then
    awk -v t="${EPOCHREALTIME}" 'BEGIN{split(t,a,"."); printf "%s%03d", a[1], substr(a[2]"000",1,3)}'
  else
    (date +%s 2>/dev/null || printf 0) | awk '{printf "%d000",$1}'
  fi
}

__ui_emit_segment() {
  local _name="$1" _ms="$2" _sample="${PERF_SAMPLE_CONTEXT:-unknown}"
  [[ -n "${PERF_SEGMENT_LOG:-}" && -w "${PERF_SEGMENT_LOG:-/dev/null}" ]] || return 0
  print "SEGMENT name=${_name} ms=${_ms} phase=post_plugin sample=${_sample}" >> "${PERF_SEGMENT_LOG}" 2>/dev/null || true
  if [[ "${ZSH_LOG_STRUCTURED:-0}" == "1" ]]; then
    local _ts
    if [[ -n ${EPOCHREALTIME:-} ]]; then
      _ts=$(awk -v t="${EPOCHREALTIME}" 'BEGIN{split(t,a,"."); printf "%s%03d", a[1], substr(a[2]"000",1,3)}')
    else
      _ts="$(date +%s 2>/dev/null || printf 0)000"
    fi
    local _json_target="${PERF_SEGMENT_JSON_LOG:-${PERF_SEGMENT_LOG}}"
    [[ -w "${_json_target}" ]] && print -- "{\"type\":\"segment\",\"name\":\"${_name}\",\"ms\":${_ms},\"phase\":\"post_plugin\",\"sample\":\"${_sample}\",\"ts\":${_ts}}" >> "${_json_target}" 2>/dev/null || true
  fi
}

# Guard to avoid double emission if sourced twice unintentionally
if [[ -z ${_UI_PROMPT_SEGMENT_EMITTED:-} ]]; then
  typeset -g _UI_PROMPT_SEGMENT_EMITTED=1
  _ui_start="$(__ui_now_ms)"
  # (Future placeholder: minimal hook registration or prompt introspection)
  # Keep body intentionally empty today.
  _ui_end="$(__ui_now_ms)"
  (( _ui_delta = _ui_end - _ui_start ))
  (( _ui_delta < 0 )) && _ui_delta=0
  __ui_emit_segment "ui/prompt-setup" "${_ui_delta}"
fi

unset -f __ui_now_ms __ui_emit_segment 2>/dev/null || true
unset _ui_start _ui_end _ui_delta 2>/dev/null || true
