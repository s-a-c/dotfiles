#!/usr/bin/env zsh
# Filename: 480-user-interface.zsh
# Purpose:  Manages user interface elements including startup splash screen and feature notifications
#           Consolidates all feature welcome messages into a single, unified splash screen
# Phase:    Post-plugin (.zshrc.d/)
# Toggles:  NO_SPLASH=1 or ZF_NO_SPLASH=1 disables the splash screen

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

# ==============================================================================
# Feature Detection
# ==============================================================================

_zf_detect_features() {
  local -a active_features
  local -a help_commands
  
  # Unified Completions (410-completions.zsh)
  if [[ "${ZF_DISABLE_ENHANCED_COMPLETIONS:-0}" != 1 ]] && typeset -f zf::detect_project_type >/dev/null 2>&1; then
    active_features+=("🎯 Enhanced completions")
    help_commands+=("completions-help")
  fi
  
  # Terminal & Multiplexer Integration (420-terminal-integration.zsh)
  if [[ "${ZF_DISABLE_MULTIPLEXER:-0}" != 1 ]] && typeset -f zf::in_multiplexer >/dev/null 2>&1; then
    local available_mux=""
    command -v tmux >/dev/null 2>&1 && available_mux="${available_mux}tmux "
    command -v zellij >/dev/null 2>&1 && available_mux="${available_mux}zellij"
    if [[ -n "$available_mux" ]]; then
      active_features+=("🖥️  Multiplexer (${available_mux% })")
      help_commands+=("terminal-help")
    fi
  fi
  
  # Navigation Tools (430-navigation-tools.zsh)
  if [[ "${ZF_DISABLE_FZF_ENHANCEMENTS:-0}" != 1 ]] && command -v fzf >/dev/null 2>&1; then
    active_features+=("🔍 Advanced FZF + zoxide")
    help_commands+=("fzf-help")
  fi
  
  # macOS Integration (460-macos-integration.zsh)
  if [[ "$(uname -s)" == "Darwin" ]] && [[ "${ZF_DISABLE_MACOS_INTEGRATION:-0}" != 1 ]] && typeset -f spotlight >/dev/null 2>&1; then
    active_features+=("🍎 macOS native features")
    help_commands+=("macos-help")
  fi
  
  # Prompt (470-prompt.zsh)
  if command -v starship >/dev/null 2>&1; then
    active_features+=("✨ Starship prompt")
  fi
  
  echo "${(j:\n:)active_features}"
  echo "---HELP---"
  echo "${(j: | :)help_commands}"
}

# ==============================================================================
# Splash Screen Function
# ==============================================================================

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

  # Detect active features
  local feature_output="$(_zf_detect_features)"
  local features_list="${feature_output%%---HELP---*}"
  local help_list="${feature_output##*---HELP---}"
  help_list="${help_list#$'\n'}"  # Remove leading newline
  
  # Info box
  echo "╭──────────────────────────────────────────────────────────╮"
  printf '│  %s%*s│\n' "Shell: $shell_version" $((60 - 11 - ${#shell_version})) ''
  printf '│  %s%*s│\n' "Time: $timestamp" $((60 - 10 - ${#timestamp})) ''
  echo "│                                                          │"
  echo "│  🚀 Active Features:                                     │"
  
  # Display detected features
  if [[ -n "$features_list" ]]; then
    while IFS= read -r feature; do
      [[ -z "$feature" ]] && continue
      printf '│    %s%*s│\n' "$feature" $((58 - ${#feature})) ''
    done <<< "$features_list"
  else
    echo "│    No enhanced features detected                         │"
  fi
  
  echo "│                                                          │"
  
  # Display help commands if any features are active
  if [[ -n "$help_list" && "$help_list" != "" ]]; then
    echo "│  💡 Help:                                                │"
    printf '│    Type: %s%*s│\n' "$help_list" $((51 - ${#help_list})) ''
  fi
  
  echo "╰──────────────────────────────────────────────────────────╯"
  echo ""
}

# Execute the splash screen
_zqs_show_splash

typeset -f zf::debug >/dev/null 2>&1 && zf::debug "# [ui] Splash screen with feature detection executed"
return 0
