#!/usr/bin/env zsh
# 470-user-interface.zsh
#
# Purpose:
#   Manages the user interface elements of the shell, primarily the startup
#   splash screen. This script is designed to provide a visually appealing
#   welcome message without interfering with shell performance or prompt rendering.
#
# Features:
#   - Displays a splash screen on the first interactive shell launch.
#   - The splash screen is executed immediately during startup to prevent
#     cursor positioning issues with the first prompt.
#   - Integrates `colorscript`, `fastfetch`, and `lolcat` if available for a
#     richer visual experience.
#   - Provides a clean, informative fallback if optional tools are not installed.
#
# Toggles:
#   - `NO_SPLASH=1`: Disables the splash screen entirely.

# Only run in interactive shells
[[ -o interactive ]] || return 0

# Disable if requested
if [[ -n ${NO_SPLASH:-} ]]; then
  return 0
fi

# Prevent multiple runs in the same session
if [[ $SHLVL -eq 1 ]]; then
  unset _STARTUP_SPLASH_PRINTED
fi
if [[ -n ${_STARTUP_SPLASH_PRINTED:-} ]]; then
  return 0
fi
export _STARTUP_SPLASH_PRINTED=1

# --- Splash Screen Function ---
_zqs_show_splash() {
  # Use colorscript and lolcat if available
  if command -v colorscript >/dev/null 2>&1; then
    if command -v lolcat >/dev/null 2>&1; then
      colorscript random 2>/dev/null | lolcat -a || true
    else
      colorscript random 2>/dev/null || true
    fi
  fi

  # Use fastfetch for system info if available
  [[ ${ZSH_DISABLE_FASTFETCH:-1} -ne 1 ]] && {
    if command -v fastfetch >/dev/null 2>&1 && [[ ${COLUMNS:-80} -gt 80 ]]; then
      echo ""
      fastfetch 2>/dev/null || true
    fi
  }

  # Welcome message with figlet if available
  local shell_version="ZSH $ZSH_VERSION"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
  if command -v figlet >/dev/null 2>&1; then
    local figlet_text="ZSH Enhanced"
    if command -v lolcat >/dev/null 2>&1; then
      figlet -f small "$figlet_text" 2>/dev/null | lolcat -a || echo "🚀 $figlet_text"
    else
      figlet -f small "$figlet_text" 2>/dev/null || echo "🚀 $figlet_text"
    fi
  else
    echo "🚀 Enhanced ZSH Configuration"
  fi

  # Info box
  echo "╭──────────────────────────────────────────────────────────╮"
  printf '│  %s%*s│\n' "Shell: $shell_version" $((60 - 11 - ${#shell_version})) ''
  printf '│  %s%*s│\n' "Time: $timestamp" $((60 - 10 - ${#timestamp})) ''
  echo "│                                                          │"
  echo "│  💡 Type 'aliases-help' for a list of commands.          │"
  echo "╰──────────────────────────────────────────────────────────╯"
  echo ""
}

# Execute the splash screen
_zqs_show_splash

zf::debug "# [ui] Splash screen executed"
return 0
