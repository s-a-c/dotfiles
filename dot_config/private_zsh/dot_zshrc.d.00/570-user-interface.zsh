#!/usr/bin/env zsh
# 560-user-interface.zsh - Simplified user interface with immediate splash execution
# Runs the splash screen immediately during shell startup instead of via precmd hook
# This prevents cursor positioning issues caused by output appearing after the first prompt

# Only run in interactive shells
[[ -o interactive ]] || return 0

# Check if splash is disabled via environment variable
if [[ -n ${NO_SPLASH:-} ]]; then
  return 0
fi

# Prevent multiple runs
if [[ $SHLVL -eq 1 ]]; then
  unset _STARTUP_SPLASH_PRINTED
fi

if [[ -n ${_STARTUP_SPLASH_PRINTED:-} ]]; then
  return 0
fi

# Simple splash screen without complex settings dependencies
simple_splash_screen() {
  # Show colorful output if colorscript is available
  if command -v colorscript >/dev/null 2>&1; then
    # Use a random, short colorscript with lolcat animation if available
    if command -v lolcat >/dev/null 2>&1; then
      colorscript random 2>/dev/null | lolcat -a || colorscript random 2>/dev/null || true
    else
      colorscript random 2>/dev/null || true
    fi
  fi

  # Show system information with fastfetch if available and not disabled
  if command -v fastfetch >/dev/null 2>&1; then
    # Check if we should suppress fastfetch (simple check)
    if [[ -z ${NO_FASTFETCH:-} ]] && [[ ${COLUMNS:-80} -gt 80 ]]; then
      echo ""
      fastfetch 2>/dev/null || true

      # Show weather information if curl is available and not disabled
      if command -v curl >/dev/null 2>&1; then
        if [[ -z ${NO_WEATHER:-} ]]; then
          # Use a short timeout to prevent hanging if wttr.in is down
          echo ""
          curl -s -m 3 "wttr.in/?0q" 2>/dev/null || true
        fi
      fi
    fi
  fi

  # Figlet welcome message
  local shell_version="ZSH $ZSH_VERSION"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'unknown')

  # Use figlet for main title if available, with optional lolcat coloring
  if command -v figlet >/dev/null 2>&1; then
    local figlet_text="ZSH Enhanced"
    if command -v lolcat >/dev/null 2>&1; then
      figlet -f small "$figlet_text" 2>/dev/null | lolcat -a || figlet -f small "$figlet_text" 2>/dev/null || echo "🚀 $figlet_text"
    else
      figlet -f small "$figlet_text" 2>/dev/null || echo "🚀 $figlet_text"
    fi
  else
    echo "🚀 Enhanced ZSH Configuration"
  fi

  echo "╭──────────────────────────────────────────────────────────╮"
  printf '│  %s%*s│\n' "Shell: $shell_version" $((60 - 11 - ${#shell_version})) ''
  printf '│  %s%*s│\n' "Time: $timestamp" $((60 - 10 - ${#timestamp})) ''
  echo "│                                                          │"
  echo "│  💡 Enhanced features active:                            │"
  echo "│    • Productivity aliases                                │"
  echo "│    • Enhanced keybindings                                │"
  echo "│    • Advanced prompt system                              │"
  echo "│    • Modern tool integrations                            │"
  echo "╰──────────────────────────────────────────────────────────╯"
  echo ""
}

# Run the splash screen immediately
simple_splash_screen

# Mark as printed to prevent re-runs
_STARTUP_SPLASH_PRINTED=1

# Export the marker for child processes
export _STARTUP_SPLASH_PRINTED

# Debug info (only if ZSH_DEBUG is enabled)
if [[ ${ZSH_DEBUG:-0} == 1 ]]; then
  echo "# [560-user-interface] Simple splash screen executed immediately"
fi
