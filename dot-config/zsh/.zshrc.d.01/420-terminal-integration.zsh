#!/usr/bin/env zsh
# Compliant with AI-GUIDELINES.md vbc9deb6c637b1c541e1a04ab4578ac5e1dbf786b6aa902097a66f841d6914c34
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
  vscode)
    local _vscode_cmd="" _vscode_path=""
    if command -v code >/dev/null 2>&1; then
      _vscode_cmd="code"
    elif command -v code-insiders >/dev/null 2>&1; then
      _vscode_cmd="code-insiders"
    fi

    if [[ -n ${_vscode_cmd} ]]; then
      _vscode_path="$("${_vscode_cmd}" --locate-shell-integration-path zsh 2>/dev/null)"
      if [[ -n ${_vscode_path} && -f "${_vscode_path}" ]]; then
        source "${_vscode_path}" 2>/dev/null || true
        # Ensure vendor env-tracking arrays exist; missing definitions cause math errors in __vsc_update_env.
        if ! typeset -f __zf_vscode_env_guard >/dev/null 2>&1; then
          __zf_vscode_env_guard() {
            if [[ ${__vsc_use_aa:-0} -eq 1 ]]; then
              typeset -gA vsc_aa_env
            fi
            typeset -ga __vsc_env_keys
            typeset -ga __vsc_env_values
          }
        fi
        add-zsh-hook precmd __zf_vscode_env_guard
        precmd_functions=(__zf_vscode_env_guard ${precmd_functions:#__zf_vscode_env_guard})
        zf::debug "# [term] VS Code integration guard registered before precmd"
        zf::debug "# [term] VS Code integration script sourced (${_vscode_cmd})"
      else
        zf::debug "# [term] VS Code integration path missing (${_vscode_cmd})"
      fi
    else
      zf::debug "# [term] VS Code integration command unavailable"
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
