#!/usr/bin/env zsh
# 335-completion-styles.zsh - Optional Carapace completion styling
# Phase 4 (Enhancement Add-On) – introduced via Decision D3B (Carapace styling reintroduction)
#
# Purpose:
#   Layer on a lightweight, opt-in styling configuration for carapace-powered
#   completions without increasing baseline complexity when styling is not desired.
#
# Design Principles:
#   - Nounset-safe: every expansion guarded
#   - Idempotent: guarded by sentinel; safe on repeated sourcing
#   - Non-invasive: skips if user already supplies a config file or disables
#   - Fast: zero external process invocation beyond simple condition checks
#
# Toggles / Environment Variables:
#   ZF_DISABLE_CARAPACE_STYLES=1     -> Skip all styling logic
#   ZF_CARAPACE_STYLE_MODE=<mode>    -> Select preset (default|colorful|mono|minimal)
#   ZF_CARAPACE_FORCE=1              -> Apply even if a user config file exists
#   ZF_CARAPACE_DEBUG=1              -> Extra debug lines (in addition to global debug)
#
# Markers (exported):
#   _ZF_CARAPACE_STYLES=1|0          -> Styling applied (1) or skipped (0)
#   _ZF_CARAPACE_STYLE_MODE=<mode>   -> Effective mode chosen (if applied)
#
# Safe Override Points for Users (later layer or ~/.zshrc.local):
#   - Export ZF_DISABLE_CARAPACE_STYLES=1 to opt-out
#   - Provide ${XDG_CONFIG_HOME:-$HOME/.config}/carapace/styles.yaml to use native file
#   - Adjust CARAPACE_COLORS or other future carapace-recognized vars after this file
#
# Validation (Manual):
#   1) echo "$_ZF_CARAPACE_STYLES $_ZF_CARAPACE_STYLE_MODE"
#   2) Invoke a completion that groups different kinds (e.g. `gh issue <TAB>`)
#   3) Toggle: ZF_CARAPACE_STYLE_MODE=colorful; re-source; compare visual difference
#
# Notes:
#   This module intentionally uses environment variable–style theming to avoid
#   writing user config files or presuming format stability of carapace's
#   style YAML. If a config file is present we DO NOT override unless forced.
#
# ------------------------------------------------------------------------------

# Idempotency guard
[[ -n ${_ZF_CARAPACE_STYLES_DONE:-} ]] && return 0
_ZF_CARAPACE_STYLES_DONE=1

# Provide minimal debug helper if not defined
typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

_cstyle_dbg() {
  if [[ ${ZF_CARAPACE_DEBUG:-0} == 1 ]]; then
    zf::debug "$@"
  fi
}

# Early global disable
if [[ "${ZF_DISABLE_CARAPACE_STYLES:-0}" == 1 ]]; then
  _ZF_CARAPACE_STYLES=0
  export _ZF_CARAPACE_STYLES
  _cstyle_dbg "# [carapace-styles] Disabled via ZF_DISABLE_CARAPACE_STYLES"
  return 0
fi

# Preconditions:
#  - carapace command available
#  - shell integration likely initialized earlier (330-completions.zsh)
if ! command -v carapace >/dev/null 2>&1; then
  _ZF_CARAPACE_STYLES=0
  export _ZF_CARAPACE_STYLES
  _cstyle_dbg "# [carapace-styles] carapace not found; skipping"
  return 0
fi

# Respect existing user styles file unless forced
_cfg_root="${XDG_CONFIG_HOME:-${HOME}/.config}"
_user_styles_file="${_cfg_root}/carapace/styles.yaml"
if [[ -f "${_user_styles_file}" && "${ZF_CARAPACE_FORCE:-0}" != 1 ]]; then
  _ZF_CARAPACE_STYLES=0
  export _ZF_CARAPACE_STYLES
  _cstyle_dbg "# [carapace-styles] User styles.yaml present; not overriding"
  unset _cfg_root _user_styles_file
  return 0
fi

# Determine mode (defaults to 'default')
_mode="${ZF_CARAPACE_STYLE_MODE:-default}"

# Construct style environment variables
# (These are illustrative; they won't break if carapace ignores unknown tokens.)
# Format rationale: keep values terse & avoid exotic escape sequences to retain portability.
case "${_mode}" in
colorful)
  # Emphasized grouping & kind differentiation
  CARAPACE_COLORS="group=magenta:bold,border=cyan,flag=blue:bold,option=blue,argument=green:value,command=yellow:bold,file=white,dir=cyan:bold"
  ;;
mono | monochrome)
  CARAPACE_COLORS="group=white,border=white,flag=white,option=white,argument=white,command=white,file=white,dir=white"
  _mode="mono"
  ;;
minimal)
  CARAPACE_COLORS="group=default,border=default,flag=default,option=default,argument=default,command=default,file=default,dir=default"
  ;;
default | *)
  CARAPACE_COLORS="group=blue:bold,border=240,flag=cyan,option=cyan,argument=green,command=yellow,file=default,dir=blue"
  _mode="default"
  ;;
esac

# Export and mark applied
export CARAPACE_COLORS
_ZF_CARAPACE_STYLES=1
_ZF_CARAPACE_STYLE_MODE="${_mode}"
export _ZF_CARAPACE_STYLES _ZF_CARAPACE_STYLE_MODE

_cstyle_dbg "# [carapace-styles] Applied mode=${_mode}"
_cstyle_dbg "# [carapace-styles] CARAPACE_COLORS=${CARAPACE_COLORS}"

# Cleanup local vars
unset _mode _cfg_root _user_styles_file

return 0
