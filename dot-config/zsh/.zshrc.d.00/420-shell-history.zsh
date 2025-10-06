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

# Validation (manual):
#   command -v atuin && atuin history list | head -n 1
