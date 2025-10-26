#!/usr/bin/env zsh
# 510-developer-tools.zsh
#
# Purpose:
#   Configures environment and PATH for various developer tools, including
#   Laravel Herd, LM Studio, and Console Ninja.
#
# Features:
#   - Detects Laravel Herd and sources its specific shell configuration.
#   - Adds Herd's binary directory to the PATH.
#   - Adds LM Studio's binary directory to the PATH if it exists.
#   - Adds Console Ninja's binary directory to the PATH if it exists.

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# --- Laravel Herd ---
if [[ -d "/Applications/Herd.app" ]]; then
  # Source Herd's shell configuration
  local herd_rc="/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh"
  if [[ -f "$herd_rc" ]]; then
    source "$herd_rc"
  fi
  # Add Herd's bin directory to the PATH
  zf::path_prepend "${HOME}/Library/Application Support/Herd/bin/"
  zf::debug "# [dev-tools] Laravel Herd environment configured"
fi

# --- LM Studio ---
if [[ -d "${HOME}/.lmstudio/bin" ]]; then
  zf::path_prepend "${HOME}/.lmstudio/bin"
  zf::debug "# [dev-tools] LM Studio CLI added to PATH"
fi

# --- Console Ninja ---
if [[ -d "${HOME}/.console-ninja/.bin" ]]; then
  zf::path_prepend "${HOME}/.console-ninja/.bin"
  zf::debug "# [dev-tools] Console Ninja added to PATH"
fi

return 0
