#!/usr/bin/env zsh
# 300-shell-history.zsh - Phase 4: Shell history enhancements (Atuin optional)
# Provides history enrichment & search if Atuin is installed.
# Guards ensure no errors under nounset or absent binaries.

# Global disable gate
if [[ "${ZF_DISABLE_HISTORY_ENHANCE:-0}" == 1 ]]; then
  return 0
fi

# History option parity & Atuin integration
#
# Provides closer alignment with prior bash history behavior while preserving
# Zsh advantages. All setopts are idempotent and safe under repeated sourcing.
#
# History Policy:
#   - APPEND_HISTORY: append rather than overwrite
#   - SHARE_HISTORY: share across sessions (can disable by exporting ZF_DISABLE_SHARE_HISTORY=1)
#   - HIST_IGNORE_DUPS / HIST_IGNORE_ALL_DUPS: collapse duplicate commands
#   - HIST_IGNORE_SPACE: commands starting with space not stored
#   - HIST_REDUCE_BLANKS: trim superfluous whitespace
#   - EXTENDED_HISTORY: timestamp + duration metadata
#
# Atuin Integration (Defaults Changed):
#   - Keybindings now ENABLED by default (was previously opt-in)
#   - Opt-out variable: export ZF_HISTORY_ATUIN_DISABLE_KEYBINDS=1 to disable Atuin keymaps
#   - Environment markers exported after init:
#       _ZF_ATUIN=1 (atuin detected & initialized)
#       _ZF_ATUIN_KEYBINDS=1|0 (1 if keybindings enabled, else 0)
#
# Users can selectively override by unsetting corresponding options in a later
# personal layer if desired.

setopt APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt EXTENDED_HISTORY
if [[ "${ZF_DISABLE_SHARE_HISTORY:-0}" != 1 ]]; then
  setopt SHARE_HISTORY
fi

# Atuin environment sourcing (optional)
if [[ -f "${HOME}/.atuin/bin/env" ]]; then
  # shellcheck disable=SC1090
  source "${HOME}/.atuin/bin/env" 2>/dev/null || true
fi

# atuin Daemon (robust): interactive-only, deduped, clears stale socket, safe detach, brief readiness wait
if [[ $- == *i* && ${TERM:-dumb} != dumb && -t 1 ]] && command -v atuin >/dev/null 2>&1; then
  _atuin_cache="${XDG_CACHE_HOME:-$HOME/.cache}/atuin"
  _atuin_data="${XDG_DATA_HOME:-$HOME/.local/share}/atuin"
  _atuin_sock="${_atuin_data}/atuin.sock"
  _atuin_log="${_atuin_cache}/daemon.log"
  _atuin_lock="${_atuin_cache}/daemon.lock"

  mkdir -p -- "$_atuin_cache" "$_atuin_data"

  # Is a daemon already running?
  _atuin_running=false
  if command -v pgrep >/dev/null 2>&1; then
    pgrep -u "$UID" -f '^atuin([[:space:]].*)?[[:space:]]+daemon( |$)' >/dev/null 2>&1 && _atuin_running=true
  else
    ps -axo command | grep -E '^[[:space:]]*atuin([[:space:]].*)?[[:space:]]+daemon( |$)' | grep -v grep >/dev/null 2>&1 && _atuin_running=true
  fi

  # If not running, and a stale socket exists, remove it
  if [[ $_atuin_running == false && -S "$_atuin_sock" ]]; then
    if command -v lsof >/dev/null 2>&1; then
      lsof -U "$_atuin_sock" >/dev/null 2>&1 || rm -f -- "$_atuin_sock"
    else
      rm -f -- "$_atuin_sock"
    fi
  fi

  # Start once with a simple lock to avoid races between parallel shells
  if [[ $_atuin_running == false ]]; then
    if mkdir "$_atuin_lock" 2>/dev/null; then
      {
        # Ensure log file exists and is writable (NEW)
        if [[ ! -f "$_atuin_log" ]]; then
          if ! touch "$_atuin_log" 2>/dev/null; then
            # Try creating parent directory if touch fails
            mkdir -p "$(dirname "$_atuin_log")" 2>/dev/null
            touch "$_atuin_log" 2>/dev/null || {
              # Fallback to /tmp if cache directory is not writable
              _atuin_log="/tmp/atuin-daemon-$UID.log"
              touch "$_atuin_log" 2>/dev/null
            }
          fi
        fi

        # Double-check inside the critical section
        if command -v pgrep >/dev/null 2>&1; then
          if ! pgrep -u "$UID" -f '^atuin([[:space:]].*)?[[:space:]]+daemon( |$)' >/dev/null 2>&1; then
            nohup atuin daemon >>"$_atuin_log" 2>&1 &
            disown
          fi
        else
          if ! ps -axo command | grep -E '^[[:space:]]*atuin([[:space:]].*)?[[:space:]]+daemon( |$)' | grep -v grep >/dev/null 2>&1; then
            nohup atuin daemon >>"$_atuin_log" 2>&1 &
            disown
          fi
        fi
      } || true
      rmdir "$_atuin_lock" 2>/dev/null || true

      # Brief readiness wait to avoid the first-command connect race
      for _i in {1..15}; do
        [[ -S "$_atuin_sock" ]] && break
        sleep 0.05
      done
      unset _i
    fi
  fi

  # Clean up temp vars
  unset _atuin_cache _atuin_data _atuin_sock _atuin_log _atuin_lock _atuin_running
fi

# Atuin initialization (if present)
if command -v atuin >/dev/null 2>&1; then
  # Default: enable keybindings unless user explicitly disables via ZF_HISTORY_ATUIN_DISABLE_KEYBINDS=1
  if [[ "${ZF_HISTORY_ATUIN_DISABLE_KEYBINDS:-0}" == 1 ]]; then
    eval "$(atuin init zsh --disable-up-arrow)"
    _ZF_ATUIN_KEYBINDS=0
  else
    eval "$(atuin init zsh)"
    _ZF_ATUIN_KEYBINDS=1
  fi
  _ZF_ATUIN=1
  export _ZF_ATUIN _ZF_ATUIN_KEYBINDS
fi

# (moved) Atuin daemon autostart logic is now placed above the initialization block

# Validation (manual):
#   command -v atuin && atuin history list | head -n 1
