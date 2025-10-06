#!/usr/bin/env zsh
# 030-GREP-SAFE-SHIM.ZSH (from 04-safe-grep.zsh)
[[ ${_ZQS_SAFE_GREP_LOADED:-0} == 1 ]] && return 0
_ZQS_SAFE_GREP_LOADED=1
zf::safe_grep() {
  if (( $# == 0 )); then command grep; return $?; fi
  local pat a found_pat=0
  local -a args
  for a in "$@"; do
    if [[ $a == -- ]]; then args+=("$a"); continue; fi
    if [[ $a == -* && $found_pat -eq 0 ]]; then args+=("$a"); continue; fi
    if (( found_pat == 0 )); then pat="$a"; found_pat=1; continue; fi
    args+=("$a")
  done
  if [[ -n ${pat:-} && $pat == *'['* && $pat != *']'* ]]; then
    command grep -F "$pat" "${args[@]}"
    return $?
  fi
  command grep "$@"
}
zf::grep_v_silence() {
  local phrase="$1"; shift || true
  while IFS= read -r __l; do
    [[ "$__l" == *"$phrase"* ]] || print -r -- "$__l"
  done
}
[[ ${ZSH_DEBUG:-0} == 1 && -n ${ZSH_DEBUG_LOG:-} ]] && print -r -- "[SAFE-GREP][030] shim active" >>"$ZSH_DEBUG_LOG" 2>/dev/null || true
if ! typeset -f zf::core_grep >/dev/null 2>&1; then zf::core_grep() { command grep "$@"; }; fi
