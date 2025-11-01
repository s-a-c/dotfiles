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
#   - `NO_SPLASH=1` or `ZF_NO_SPLASH=1`: Disables the splash screen entirely.

# Only run in interactive shells
[[ -o interactive ]] || return 0

# ------------------------------------------------------------------------------
# VSCode/Cursor Splash Screen Control
# ------------------------------------------------------------------------------
# ROOT CAUSE: VSCode shell integration (VSCODE_INJECTION=1) SOURCES .zshrc TWICE
#
# The integration script at:
# /Applications/Cursor.app/Contents/Resources/app/out/vs/workbench/contrib/terminal/
#   common/scripts/shellIntegration-rc.zsh
#
# Line 29-32 shows it re-sources .zshrc during injection phase:
#   if [[ "$VSCODE_INJECTION" == "1" ]]; then
#       . $USER_ZDOTDIR/.zshrc   # ← FIRST .zshrc RUN (during injection)
#   fi
#
# Then normal ZSH startup runs .zshrc again (SECOND run).
#
# The vendored .zshrc is NOT idempotent. Running it twice causes:
# - Duplicate splash screens, plugin loads, update checks
# - Spurious "0" output, "No quickstart marker" errors
#
# SOLUTIONS IMPLEMENTED:
# 1. .zshenv.01: Sets ZF_VSCODE_FIRST_RUN=1 during injection phase
# 2. .zshenv.01: Makes ALL zshenv functions readonly (prevents overwrites)
# 3. .zshenv.01: Disables quickstart update checks (QUICKSTART_KIT_REFRESH_IN_DAYS)
# 4. 420-terminal-integration.zsh: Skips manual VSCode integration (auto-loaded)
# 5. This section: Suppresses splash on first run, re-enables on second run
# ------------------------------------------------------------------------------
if [[ "${TERM_PROGRAM:-}" == "vscode" ]]; then
  if [[ -n "${ZF_VSCODE_FIRST_RUN:-}" ]]; then
    # First .zshrc run (injection phase) - suppress splash and heavy operations
    export ZF_NO_SPLASH=1
    typeset -f zf::debug >/dev/null 2>&1 && zf::debug "# [vscode] First .zshrc run - splash suppressed"
  else
    # Second .zshrc run (normal startup) - re-enable splash
    unset ZF_NO_SPLASH
    typeset -f zf::debug >/dev/null 2>&1 && zf::debug "# [vscode] Second .zshrc run - splash enabled"
  fi
fi

# Disable if requested (check both NO_SPLASH and ZF_NO_SPLASH)
if [[ -n ${NO_SPLASH:-} || -n ${ZF_NO_SPLASH:-} ]]; then
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
  echo "│  🚀 Enhanced features active:                            │"
  echo "│    💡 Productivity aliases                               │"
  echo "│      •  Type 'aliases-help' for a list of commands.      │"
  echo "│    💡 Enhanced keybindings                               │"
  echo "│    💡 Advanced prompt system                             │"
  echo "│    💡 Modern tool integrations                           │"
  echo "╰──────────────────────────────────────────────────────────╯"
  echo ""
}

# Execute the splash screen
_zqs_show_splash

zf::debug "# [ui] Splash screen executed"
return 0
