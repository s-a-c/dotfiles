#!/usr/bin/env zsh
# ==============================================================================
# 006-zqs-get-setting-no-warn.zsh
# ==============================================================================
# Purpose: Override the _zqs-get-setting function from .zshrc to properly
#          declare the 'svalue' variable as local, preventing WARN_CREATE_GLOBAL
#          warnings.
#
# Problem: The original _zqs-get-setting function in .zshrc creates the 'svalue'
#          variable without declaring it as local, causing warnings when
#          WARN_CREATE_GLOBAL is enabled.
#
# Solution: Re-define the function with proper local variable declaration.
#
# Load Order: This runs early (006-*) in .zshrc.pre-plugins.d, before the
#             function is called by plugin initialization code.
#
# Compliant with AI-GUIDELINES.md
# ==============================================================================

# Only redefine if not already done (idempotent)
if [[ -z ${_ZF_ZQS_GET_SETTING_OVERRIDE_DONE:-} ]]; then

  # Override the _zqs-get-setting function from .zshrc
  # Settings names have to be valid file names, and we're not doing any parsing here.
  _zqs-get-setting() {
    # Suppress WARN_CREATE_GLOBAL within this function
    setopt LOCAL_OPTIONS no_warn_create_global

    # If there is a $2, we return that as the default value if there's
    # no settings file.
    local sfile="${_ZQS_SETTINGS_DIR}/${1}"
    local svalue

    if [[ -f "$sfile" ]]; then
      svalue=$(cat "$sfile")
    else
      if [[ $# -eq 2 ]]; then
        svalue=$2
      else
        svalue=''
      fi
    fi

    echo "$svalue"
  }

  # Mark that we've overridden the function
  typeset -g _ZF_ZQS_GET_SETTING_OVERRIDE_DONE=1

  # Debug output if enabled
  if [[ "${ZSH_DEBUG:-0}" == "1" ]]; then
    echo "# [006-zqs-get-setting-no-warn] Overrode _zqs-get-setting function"
  fi
fi
