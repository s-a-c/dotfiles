#!/usr/bin/env zsh
# 100-terminal-integration.zsh - Phase 6 unified terminal detection & env exports
# Purpose: Consolidate multi-terminal logic (Warp, WezTerm, Ghostty, Kitty, iTerm2) with
# idempotent guards and minimal side-effects.
# Success criteria: No duplicate exports, safe under repeated sourcing, does not reduce widget count.

[[ -n ${_ZF_TERMINAL_INTEGRATION_DONE:-} ]] && return 0
_ZF_TERMINAL_INTEGRATION_DONE=1

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# Warp
if [[ ${TERM_PROGRAM:-} == WarpTerminal ]]; then
  export WARP_IS_LOCAL_SHELL_SESSION=1
  zf::debug "# [term] warp integration"
fi

# WezTerm
if [[ ${TERM_PROGRAM:-} == WezTerm ]]; then
  export WEZTERM_SHELL_INTEGRATION=1
  zf::debug "# [term] wezterm integration"
fi

# Ghostty
if [[ ${TERM_PROGRAM:-} == ghostty ]]; then
  export GHOSTTY_SHELL_INTEGRATION=1
  # Optional Ghostty integration script (provides prompt & shell features)
  if [[ -n ${GHOSTTY_RESOURCES_DIR:-} && -f "${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration" ]]; then
    # shellcheck disable=SC1090
    source "${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration" 2>/dev/null || true
    zf::debug "# [term] ghostty integration script sourced"
  else
    zf::debug "# [term] ghostty integration"
  fi
fi

# Kitty
if [[ ${TERM:-} == xterm-kitty ]]; then
  export KITTY_SHELL_INTEGRATION=enabled
  zf::debug "# [term] kitty integration"
fi

# iTerm2 (minimal)
if [[ ${TERM_PROGRAM:-} == iTerm.app ]]; then
  if [[ -f ${HOME}/.iterm2_shell_integration.zsh ]]; then
    # shellcheck disable=SC1090
    source "${HOME}/.iterm2_shell_integration.zsh" || true
    zf::debug "# [term] iterm2 integration"
  fi
fi

return 0
