#!/opt/homebrew/bin/zsh
# 80-security-validation.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v900f08def0e6f7959ffd283aebb73b625b3473f5e49c57e861c6461b50a62ef2
#
# PURPOSE:
#   Future home for deep integrity / trust validation (deferred hashing, provenance checks).
#   For Sprint 2 we introduce a minimal, low‑overhead performance segment probe so the
#   security validation phase can be tracked independently ahead of real logic.
#
# EMITTED (when PERF_SEGMENT_LOG writable):
#   SEGMENT name=security/validation ms=<delta> phase=post_plugin sample=<context>
#   (Corresponding JSON sidecar entry when ZSH_LOG_STRUCTURED=1)
#
# CHARACTERISTICS:
#   - Idempotent (guarded).
#   - Near‑zero overhead (empty body timing span).
#   - Stable segment name required by granular segment tests.
#
# PRIVACY:
#   Emits only timing metadata (name, ms, phase, sample, ts) — no file paths, hashes, or PII.
#
# OPT OUT:
#   export ZSH_DISABLE_SECURITY_VALIDATION_SEGMENT=1  → suppress emission (used for A/B or debug)
#
# Prevent multiple loading
[[ -n "${_LOADED_80_SECURITY_VALIDATION:-}" ]] && return 0
: ${_LOADED_80_SECURITY_VALIDATION:=1}
readonly _LOADED_80_SECURITY_VALIDATION=1
#
[[ "${ZSH_DISABLE_SECURITY_VALIDATION_SEGMENT:-0}" == "1" ]] && return 0
#
# High‑resolution clock if available
zmodload zsh/datetime 2>/dev/null || true
#
__sv_now_ms() {
  if [[ -n ${EPOCHREALTIME:-} ]]; then
    awk -v t="${EPOCHREALTIME}" 'BEGIN{split(t,a,"."); printf "%s%03d", a[1], substr(a[2]"000",1,3)}'
  else
    (date +%s 2>/dev/null || printf 0) | awk '{printf "%d000",$1}'
  fi
}
__sv_emit_segment() {
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
#
# Emit once
if [[ -z ${_SEC_VAL_SEGMENT_EMITTED:-} ]]; then
  typeset -g _SEC_VAL_SEGMENT_EMITTED=1
  _sv_start="$(__sv_now_ms)"
  # (Future security validation initialization placeholder – intentionally empty)
  _sv_end="$(__sv_now_ms)"
  (( _sv_delta = _sv_end - _sv_start ))
  (( _sv_delta < 0 )) && _sv_delta=0
  __sv_emit_segment "security/validation" "${_sv_delta}"
fi
#
# Cleanup helper symbols (keep sentinel & emission marker)
unset -f __sv_now_ms __sv_emit_segment 2>/dev/null || true
unset _sv_start _sv_end _sv_delta 2>/dev/null || true
