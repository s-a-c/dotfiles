#!/usr/bin/env zsh
# 93-STARSHIP-GREP-FIX.ZSH - Fix Starship grep bracket errors
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}

# Only run once
[[ ${_ZQS_REDESIGN_STARSHIP_GREP_FIX_DONE:-0} == 1 ]] && return 0
_ZQS_REDESIGN_STARSHIP_GREP_FIX_DONE=1

# Create a safe grep wrapper that handles unbalanced brackets
# This intercepts both 'grep' function calls and 'command grep' calls
_zqs_safe_grep_wrapper() {
  local original_grep="/usr/bin/grep"
  
  # If no arguments, just call original grep
  if (( $# == 0 )); then 
    "$original_grep"
    return $?
  fi
  
  # Parse arguments to find the pattern
  local pat="" found_pat=0
  local -a args=()
  
  for arg in "$@"; do
    if [[ $arg == -- ]]; then 
      args+=("$arg")
      continue
    fi
    if [[ $arg == -* && $found_pat -eq 0 ]]; then 
      args+=("$arg")
      continue
    fi
    if (( found_pat == 0 )); then 
      pat="$arg"
      found_pat=1
      continue
    fi
    args+=("$arg")
  done
  
  # Check for unbalanced brackets and use -F (fixed string) if found
  if [[ -n ${pat:-} && $pat == *'['* && $pat != *']'* ]]; then
    "$original_grep" -F "$pat" "${args[@]}" 2>/dev/null
    return $?
  fi
  
  # Normal grep call
  "$original_grep" "$@"
}

# Override the command builtin to intercept 'command grep' calls
command() {
  if [[ $1 == "grep" ]]; then
    shift
    _zqs_safe_grep_wrapper "$@"
    return $?
  else
    builtin command "$@"
  fi
}

# Also ensure the grep function uses the safe wrapper
grep() {
  _zqs_safe_grep_wrapper "$@"
}

[[ ${ZSH_DEBUG:-0} == 1 && -n ${ZSH_DEBUG_LOG:-} ]] && print -r -- "[STARSHIP-GREP-FIX][93] command grep interceptor active" >>"$ZSH_DEBUG_LOG" 2>/dev/null || true
