#!/usr/bin/env zsh
# 040-GREP-DEBUG-TRACER.ZSH (migrated from legacy 07-grep-debug-tracer.zsh)
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}
# Activated only when ZSH_DEBUG=1 to trace risky grep pattern usage.

[[ ${ZSH_DEBUG:-0} == 1 ]] || return 0
[[ -n ${_ZQS_GREP_DEBUG_TRACER_LOADED:-} ]] && return 0
_ZQS_GREP_DEBUG_TRACER_LOADED=1

if alias grep >/dev/null 2>&1; then
  if ! typeset -f _zqs__orig_cmd_grep >/dev/null 2>&1; then
    _zqs__orig_cmd_grep() { command grep "$@"; }
  fi
  grep() {
    local pat found=0 arg
    for arg in "$@"; do
      if [[ $arg == -- ]]; then break; fi
      if [[ $arg == -* ]]; then continue; fi
      if (( found == 0 )); then pat=$arg; found=1; fi
    done
    if [[ -n ${ZSH_DEBUG_LOG:-} ]]; then
      if [[ $pat == *'['* && $pat != *']'* ]]; then
        print -r -- "[GREP-TRACE][040] unbalanced_bracket pattern=${pat}" >>"$ZSH_DEBUG_LOG" 2>/dev/null || true
      fi
    fi
    command grep "$@"
  }
  [[ -n ${ZSH_DEBUG_LOG:-} ]] && print -r -- "[GREP-TRACE][040] wrapper active (alias detected)" >>"$ZSH_DEBUG_LOG" 2>/dev/null || true
fi
