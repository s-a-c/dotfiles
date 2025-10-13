#!/usr/bin/env zsh
# ==============================================================================
# 005-load-fragments-no-warn.zsh
# ==============================================================================
# Purpose: Override the load-shell-fragments function from .zshrc to suppress
#          WARN_CREATE_GLOBAL warnings when vendor scripts create globals.
#
# Problem: The original load-shell-fragments function sources files within its
#          function context, causing zsh to report that variables created by
#          vendor scripts (FZF, Atuin, etc.) are "created globally in function".
#
# Solution: Re-define the function with LOCAL_OPTIONS set to suppress warnings
#           during the sourcing phase, while still maintaining the warning for
#           user code after startup.
#
# Load Order: This runs early (005-*) in .zshrc.pre-plugins.d, before plugins
#             are loaded via .zgen-setup, which calls load-shell-fragments to
#             load .zshrc.add-plugins.d/*.zsh files.
#
# Compliant with AI-GUIDELINES.md
# ==============================================================================

# Only redefine if not already done (idempotent)
if [[ -z ${_ZF_LOAD_FRAGMENTS_OVERRIDE_DONE:-} ]]; then

  # Override the load-shell-fragments function from .zshrc
  function load-shell-fragments() {
    # Suppress WARN_CREATE_GLOBAL for vendor scripts sourced via this function
    # This prevents warnings from FZF, zsh-autosuggestions, and other plugins
    # that create global variables during initialization
    setopt LOCAL_OPTIONS no_warn_create_global

    if [[ -z ${1-} ]]; then
      echo "You must give load-shell-fragments a directory path"
    else
      if [[ -d "$1" ]]; then
        if [ -n "$(/bin/ls -A "$1")" ]; then
          local _zqs_fragment # Properly scoped as local
          for _zqs_fragment in $(/bin/ls -A "$1"); do
            if [ -r "$1/$_zqs_fragment" ]; then
              source "$1/$_zqs_fragment"
            fi
          done
        fi
      else
        echo "$1 is not a directory"
      fi
    fi
  }

  # Mark that we've overridden the function
  typeset -g _ZF_LOAD_FRAGMENTS_OVERRIDE_DONE=1

  # Debug output if enabled
  if [[ "${ZSH_DEBUG:-0}" == "1" ]]; then
    echo "# [005-load-fragments-no-warn] Overrode load-shell-fragments function"
  fi
fi
