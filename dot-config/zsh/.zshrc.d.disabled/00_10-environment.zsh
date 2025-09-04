#!/usr/bin/env zsh
# ==============================================================================
# ZSH Configuration: Core Environment Setup
# ==============================================================================
# Purpose: Interactive shell environment variables that complement .zshenv
#          This file provides ONLY interactive-specific environment settings
#          that are not needed by non-interactive shells.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-26
# Version: 2.0
# Load Order: 2nd in 00-core (after standard helpers, before source detection)
# Dependencies: 00-standard-helpers.zsh, .zshenv
# ==============================================================================

[[ "$ZSH_DEBUG" == "1" ]] && {
        zsh_debug_echo "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
    zsh_debug_echo "# [environment] Loading interactive environment configuration"
}

# REMOVED: All environment variables that are already set in .zshenv
# - XDG_* directories (already in .zshenv)
# - ZDOTDIR, ZSH_CACHE_DIR (already in .zshenv)
# - HISTFILE, HISTSIZE, SAVEHIST (already in .zshenv with correct values)
# - LANG, LC_ALL (already in .zshenv)
# - EDITOR, VISUAL (already in .zshenv with proper detection)

# Interactive-specific terminal settings
export TERM="${TERM:-xterm-256color}"
export COLORTERM="${COLORTERM:-truecolor}"

# Interactive-specific pager configuration (extends .zshenv LESS settings)
export PAGER="${PAGER:-less}"

# Interactive shell prompt settings
export PROMPT_EOL_MARK=''  # Don't show % at end of partial lines

# Interactive completion settings
export COMPLETION_WAITING_DOTS="true"

# npm plugin conflicts with NVM by setting NPM_CONFIG_PREFIX
unset NPM_CONFIG_PREFIX

zsh_debug_echo "# [environment] ✅ Interactive environment configuration loaded"
