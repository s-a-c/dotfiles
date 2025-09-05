#!/opt/homebrew/bin/zsh
# 20-macos-defaults-deferred.zsh (Pre-Plugin Redesign Enhanced)
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
[[ -n ${_LOADED_PRE_MACOS_DEFAULTS_DEFERRED:-} ]] && return
_LOADED_PRE_MACOS_DEFAULTS_DEFERRED=1

# PURPOSE:
#   Provide a lightweight, non-blocking scheduling hook for macOS defaults / preference
#   audits or adjustments. Actual work is deferred until after the first prompt to
#   avoid impacting interactive startup timing. This file intentionally ships a
#   "shadow" implementation that proves scheduling semantics; the real audit logic
#   will be attached in Stage 5 when the async engine promotion occurs.
#
# DESIGN:
#   - Zero synchronous I/O beyond environment checks.
#   - One-time post-first-prompt execution via a precmd hook.
#   - Optional async dispatch if async enqueue helper present.
#   - Safe no-op on non-macOS platforms.
#
# CONFIG FLAGS (override in .zshenv if needed):
: ${ZSH_MACOS_DEFAULTS_DEFERRED_ENABLE:=1}     # Master enable switch
: ${ZSH_MACOS_DEFAULTS_AUDIT_MODE:=shadow}     # shadow | enforce (future)
: ${ZSH_MACOS_DEFAULTS_ASYNC:=1}               # Attempt async queue when helper present
#
# INTERNAL SENTINELS:
#   _MACOS_DEFAULTS_AUDIT_RAN  -> ensures single execution
#
typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }

# One-time runner (executed after first prompt)
_macos_defaults_audit_run() {
  [[ -n ${_MACOS_DEFAULTS_AUDIT_RAN:-} ]] && return 0
  _MACOS_DEFAULTS_AUDIT_RAN=1
  zsh_debug_echo "# [macos-defaults] run (mode=${ZSH_MACOS_DEFAULTS_AUDIT_MODE})"
  # Placeholder: real audit / adjustments inserted in later stage
  if (( ZSH_MACOS_DEFAULTS_ASYNC )) && typeset -f _zsh_async_enqueue >/dev/null 2>&1; then
    _zsh_async_enqueue macos_defaults_audit "echo '# [macos-defaults] async shadow task'; true"
  fi
  # Remove hook after first run
  if typeset -f add-zsh-hook >/dev/null 2>&1; then
    add-zsh-hook -d precmd _macos_defaults_audit_run 2>/dev/null || true
  fi
}

# Queue mechanism sets up post-prompt hook
_macos_defaults_audit_queue() {
  (( ZSH_MACOS_DEFAULTS_DEFERRED_ENABLE )) || {
    zsh_debug_echo "# [macos-defaults] disabled via ZSH_MACOS_DEFAULTS_DEFERRED_ENABLE"
    return 0
  }
  # Avoid duplicate hook registration
  if [[ -z ${_MACOS_DEFAULTS_AUDIT_HOOKED:-} ]]; then
    _MACOS_DEFAULTS_AUDIT_HOOKED=1
    if typeset -f add-zsh-hook >/dev/null 2>&1; then
      add-zsh-hook precmd _macos_defaults_audit_run
    else
      # Fallback for environments without add-zsh-hook
      typeset -ga precmd_functions
      precmd_functions+=(_macos_defaults_audit_run)
    fi
    zsh_debug_echo "# [macos-defaults] deferred audit hook registered"
  fi
}

if [[ "${OSTYPE}" == darwin* ]]; then
  _macos_defaults_audit_queue
  zsh_debug_echo "# [pre-plugin] macOS defaults audit queued (deferred post-prompt)"
else
  zsh_debug_echo "# [pre-plugin] macOS defaults skipped (non-macos)"
fi
