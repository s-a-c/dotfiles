#!/usr/bin/env zsh
# Late grep sanitize (REDESIGN) - override any plugin-added grep alias that reintroduces bracket errors.
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}

# Only run once
[[ ${_ZQS_REDESIGN_GREP_SANITIZE_DONE:-0} == 1 ]] && return 0
_ZQS_REDESIGN_GREP_SANITIZE_DONE=1

# If an alias exists now, remove it first (avoid 'defining function based on alias' parse issues)
if alias grep >/dev/null 2>&1; then
  unalias grep 2>/dev/null || true
fi

# Install a function wrapper only if not already a function (idempotent)
if ! typeset -f grep >/dev/null 2>&1; then
  grep() {
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
fi

# Ensure helper exists
if ! typeset -f zf::core_grep >/dev/null 2>&1; then
  zf::core_grep() { command grep "$@"; }
fi

[[ ${ZSH_DEBUG:-0} == 1 && -n ${ZSH_DEBUG_LOG:-} ]] && print -r -- "[GREP-SANITIZE][late][REDESIGN] enforced command grep" >>"$ZSH_DEBUG_LOG" 2>/dev/null || true
