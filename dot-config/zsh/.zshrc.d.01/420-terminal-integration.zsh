#!/usr/bin/env zsh
# 420-terminal-integration.zsh
#
# Purpose:
#   Unifies terminal emulator integration for Warp, WezTerm, Ghostty, Kitty,
#   and iTerm2. This script sets the necessary environment variables and sources
#   integration scripts to enable features like custom prompts, semantic regions,
#   and proper shell interaction within these modern terminals.
#
# Features:
#   - Idempotent design prevents duplicate exports and sourcing.
#   - Automatically detects the running terminal emulator.
#   - Minimal side-effects and safe to source multiple times.

[[ -n ${_ZF_TERMINAL_INTEGRATION_DONE:-} ]] && return 0
_ZF_TERMINAL_INTEGRATION_DONE=1

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

case "${TERM_PROGRAM:-}" in
  WarpTerminal)
    export WARP_IS_LOCAL_SHELL_SESSION=1
    zf::debug "# [term] Warp integration enabled"
    ;;
  WezTerm)
    export WEZTERM_SHELL_INTEGRATION=1
    zf::debug "# [term] WezTerm integration enabled"
    ;;
  ghostty)
    export GHOSTTY_SHELL_INTEGRATION=1
    if [[ -n ${GHOSTTY_RESOURCES_DIR:-} && -f "${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration" ]]; then
      source "${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration" 2>/dev/null || true
      zf::debug "# [term] Ghostty integration script sourced"
    else
      zf::debug "# [term] Ghostty integration enabled"
    fi
    ;;
  iTerm.app)
    if [[ -f "${HOME}/.iterm2_shell_integration.zsh" ]]; then
      source "${HOME}/.iterm2_shell_integration.zsh" || true
      zf::debug "# [term] iTerm2 integration script sourced"
    fi
    ;;
esac

if [[ "${TERM:-}" == "xterm-kitty" ]]; then
  export KITTY_SHELL_INTEGRATION=enabled
  zf::debug "# [term] Kitty integration enabled"
fi

return 0
