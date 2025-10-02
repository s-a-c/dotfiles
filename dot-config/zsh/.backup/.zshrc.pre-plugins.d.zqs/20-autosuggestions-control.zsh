#!/usr/bin/env zsh
# 20-autosuggestions-control.zsh - Control autosuggestions loading timing
# Part of the ZDOTDIR-aware ZQS setup

# =============================================================================
# AUTOSUGGESTIONS TIMING CONTROL (PRE-PLUGIN PHASE)
# =============================================================================
# Problem: zsh-autosuggestions tries to bind ZLE widgets before ZLE is ready
# Solution: Disable during plugin loading, re-enable after ZLE is initialized

if [[ -o interactive ]]; then
    # Disable autosuggestions during plugin loading to prevent ZLE widget errors
    export ZSH_AUTOSUGGEST_DISABLE=1
    export DISABLE_AUTO_SUGGESTIONS=1

    zf::debug "# [pre-plugin-ext] Autosuggestions disabled during plugin loading phase"

    # Mark that we've disabled it so post-plugin can re-enable
    export _AUTOSUGGESTIONS_DISABLED_BY_TIMING=1
else
    zf::debug "# [pre-plugin-ext] Non-interactive shell, autosuggestions control not needed"
fi
