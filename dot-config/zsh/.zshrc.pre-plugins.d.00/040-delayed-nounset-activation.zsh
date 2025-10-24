#!/usr/bin/env zsh
# 030-DELAYED-NOUNSET-ACTIVATION.ZSH
# Purpose: Enable nounset safely after early environment, keymap, ZLE, fzf init have stabilized
# and before loading autopair/framework/plugins that benefit from stricter checks.
# Guarded to only activate in interactive shells and only if policy desires.

[[ -n ${_ZQS_DELAYED_NOUNSET_DONE:-} ]] && return 0
[[ -o interactive ]] || return 0

# Honor opt-out knob
if [[ ${ZSH_DISABLE_DELAYED_NOUNSET:-0} == 1 ]]; then
  return 0
fi

# Defer if enabling function missing (should be defined in 010-shell-safety-nounset)
if ! typeset -f zf::enable_nounset_safe >/dev/null 2>&1; then
  return 0
fi

# Check if nounset was disabled for Oh-My-Zsh/zgenom compatibility
if [[ "${_ZQS_NOUNSET_DISABLED_FOR_OMZ:-0}" == "1" ]]; then
  # Do NOT re-enable nounset - Oh-My-Zsh requires it to stay disabled
  _ZQS_DELAYED_NOUNSET_DONE=1
  if [[ ${ZSH_DEBUG:-0} == 1 && -n ${ZSH_DEBUG_LOG:-} ]]; then
    print -r -- "# [delayed-nounset-activation] nounset kept disabled for Oh-My-Zsh compatibility" >>"$ZSH_DEBUG_LOG" 2>/dev/null || true
  fi
  return 0
fi

# Check if nounset was temporarily disabled but Oh-My-Zsh not detected
if [[ "${_ZQS_NOUNSET_WAS_ON:-0}" == "1" ]]; then
  # Re-enable nounset since it was on before and Oh-My-Zsh is not being used
  zf::enable_nounset_safe
  _ZQS_DELAYED_NOUNSET_DONE=1
  unset _ZQS_NOUNSET_WAS_ON
  return 0
fi

# Avoid enabling if user already turned it on manually
if set -o | grep -q '^nounset *on'; then
  _ZQS_DELAYED_NOUNSET_DONE=1
  return 0
fi

# Enable nounset for the first time (normal case)
zf::enable_nounset_safe
_ZQS_DELAYED_NOUNSET_DONE=1

if [[ ${ZSH_DEBUG:-0} == 1 && -n ${ZSH_DEBUG_LOG:-} ]]; then
  print -r -- "# [delayed-nounset-activation] delayed nounset activation complete" >>"$ZSH_DEBUG_LOG" 2>/dev/null || true
fi

return 0
