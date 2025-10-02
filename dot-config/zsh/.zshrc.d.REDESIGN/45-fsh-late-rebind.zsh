#!/usr/bin/env zsh
# 45-fsh-late-rebind.zsh - Late fast-syntax-highlighting rebind & noise suppression
# Purpose: Run after completion & environment setup so that most widgets exist,
# reducing 'unhandled ZLE widget' noise. Captures and filters stderr once.
# AI-authored (policy compliant) – does not modify vendored plugin code.

[[ -o interactive ]] || return 0
[[ ${ZSH_DISABLE_FSH_LATE_REBIND:-0} == 1 ]] && return 0

# Only proceed if FSH core function exists
if ! typeset -f -- -fast-highlight-init >/dev/null 2>&1; then
  return 0
fi

# One-time sentinel
if [[ -n ${_ZQS_FSH_LATE_REBIND_DONE:-} ]]; then
  return 0
fi
_ZQS_FSH_LATE_REBIND_DONE=1

typeset -gA ZSH_FSH_UNHANDLED_WIDGETS

_zqs__perform_fsh_late_rebind() {
  local tmp_log="${ZSH_LOG_DIR:-${ZDOTDIR:-$HOME}/logs}/fsh-late-rebind.$EPOCHSECONDS.log"
  mkdir -p -- "${tmp_log:h}" 2>/dev/null || true
  local rc=0
  if typeset -f _zsh_highlight_bind_widgets >/dev/null 2>&1; then
    { _zsh_highlight_bind_widgets } > /dev/null 2>"$tmp_log" || rc=$?
  fi

  # Parse unhandled widget lines (legacy message format reused by FSH)
  if [[ -s $tmp_log ]]; then
    local line widget
    while IFS= read -r line; do
      if [[ $line == *"unhandled ZLE widget"* ]]; then
        widget=${line##*unhandled ZLE widget }
        widget=${widget//\'/}
        ZSH_FSH_UNHANDLED_WIDGETS[$widget]=1
      fi
    done < "$tmp_log"
  fi

  # Log summary once, then suppress further individual lines by clearing log file
  if (( ${#ZSH_FSH_UNHANDLED_WIDGETS[@]} )); then
    if [[ ${ZSH_DEBUG:-0} == 1 && -n ${ZSH_DEBUG_LOG:-} ]]; then
      print -r -- "[FSH-LATE-REBIND] Unhandled widgets: ${(j:, :)${(k)ZSH_FSH_UNHANDLED_WIDGETS}}" >>"$ZSH_DEBUG_LOG" 2>/dev/null || true
    fi
  else
    if [[ ${ZSH_DEBUG:-0} == 1 && -n ${ZSH_DEBUG_LOG:-} ]]; then
      print -r -- "[FSH-LATE-REBIND] All widgets bound successfully" >>"$ZSH_DEBUG_LOG" 2>/dev/null || true
    fi
  fi
  : > "$tmp_log" 2>/dev/null || true
  return 0
}

# Run immediately (post-load) and also add a single precmd safety net if new widgets appear later
_zqs__perform_fsh_late_rebind
if (( ! ${precmd_functions[(I)_zqs__perform_fsh_late_rebind]} )); then
  precmd_functions+=( _zqs__perform_fsh_late_rebind )
fi

export ZSH_FSH_LATE_REBIND=1
