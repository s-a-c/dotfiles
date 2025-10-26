#!/usr/bin/env zsh
# 060-zqs-enhancements.zsh
#
# Purpose:
#   Extends the functionality of the Zsh Quickstart Kit (ZQS) by adding
#   new commands and overriding the default help function to include them.
#
# Features:
#   - `zqs enable-always-show-splash`: Configures the startup splash to show on every reload.
#   - `zqs disable-always-show-splash`: Restores the default behavior of showing the splash only once.
#   - `zqs set-starship-offset VALUE`: Sets the UTC offset for the Starship time module.
#   - The `zqs-help` function is extended to display these new commands.
#
# Implementation:
#   - Uses a layered approach to wrap the original `zqs` and `zqs-help` functions,
#     ensuring that original functionality is preserved.

# Store original zqs implementation if it exists
if typeset -f zqs >/dev/null 2>&1; then
  builtin functions -c zqs _zqs_original_impl 2>/dev/null || true
fi

# Store original zqs-help implementation
if typeset -f zqs-help >/dev/null 2>&1; then
  builtin functions -c zqs-help _original_zqs_help 2>/dev/null || true
fi

# Extended help function
function zqs-help-extension() {
  # Call original help function if it exists
  if typeset -f _original_zqs_help >/dev/null 2>&1; then
    _original_zqs_help
  fi

  # Add additional help text
  echo ""
  echo "Additional zqs commands:"
  echo "  zqs enable-always-show-splash   - Always show the startup splash (also on reloads)"
  echo "  zqs disable-always-show-splash  - Show splash only once per interactive session (default)"
  echo "  zqs set-starship-offset VALUE - Set the Starship UTC offset for time module (e.g., +2, -5.5, +0)"
}

# Override the original help function
function zqs-help() {
  zqs-help-extension
}

# Extended zqs function handler
function zqs-extension() {
  case "$1" in
    'enable-always-show-splash')
      _zqs-set-setting always-show-splash true
      return 0
      ;;
    'disable-always-show-splash')
      _zqs-set-setting always-show-splash false
      return 0
      ;;
    'set-starship-offset')
      _zqs-set-setting starship-utc-offset "$2"
      return 0
      ;;
    *)
      # Command not handled by extension
      return 1
      ;;
  esac
}

# Main zqs function wrapper
function zqs() {
  # Try our extension first
  zqs-extension "$@"
  local ret=$?

  # If our extension handled it, return
  [[ $ret -eq 0 ]] && return 0

  # If not, and an original implementation exists, call it
  if typeset -f _zqs_original_impl >/dev/null 2>&1; then
    _zqs_original_impl "$@"
  elif [[ $ret -ne 0 ]]; then
    # If no original and not our command, show an error
    echo "zqs: unknown command: $1" >&2
    return 127
  fi
}

typeset -f zf::debug >/dev/null 2>&1 && zf::debug "# [zqs-enhancements] ZQS functions extended."

return 0
