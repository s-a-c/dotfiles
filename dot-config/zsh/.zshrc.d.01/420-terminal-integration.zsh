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
    # VSCode/Cursor handles its own shell integration automatically via VSCODE_INJECTION
    # We don't need to source it manually - it's already active by the time we get here
    # We just need to clean up the side effects (PATH corruption, broken functions)

    # CRITICAL: VSCode shell integration corrupts PATH by prepending extension directories
    # (.console-ninja/.bin, .lmstudio/bin, etc.) Re-fix PATH after VSCode integration runs
    export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH}"

    # Ensure vendor env-tracking arrays exist (missing definitions cause math errors)
    if ! typeset -f __zf_vscode_env_guard >/dev/null 2>&1; then
      __zf_vscode_env_guard() {
        if [[ ${__vsc_use_aa:-0} -eq 1 ]]; then
          typeset -gA vsc_aa_env
        fi
        typeset -ga __vsc_env_keys
        typeset -ga __vsc_env_values
      }
    fi

    # Ensure add-zsh-hook is loaded before using it
    autoload -Uz add-zsh-hook 2>/dev/null || true

    # Register guard function if add-zsh-hook is available
    if typeset -f add-zsh-hook >/dev/null 2>&1; then
      add-zsh-hook precmd __zf_vscode_env_guard
      precmd_functions=(__zf_vscode_env_guard ${precmd_functions:#__zf_vscode_env_guard})
    else
      # Fallback: directly add to precmd_functions if add-zsh-hook unavailable
      precmd_functions=(__zf_vscode_env_guard ${precmd_functions:#__zf_vscode_env_guard})
    fi

    zf::debug "# [term] VS Code/Cursor integration active (auto-loaded), PATH fixed"
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
