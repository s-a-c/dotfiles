#!/usr/bin/env zsh
# Filename: 400-options.zsh
# Purpose:  Consolidates all Zsh shell options (`setopt`/`unsetopt`) into a single, authoritative file. This script provides a comprehensive baseline for shell behavior, covering history, completion, navigation, and more. Customization: To override these settings, create a file with a higher number in this commands there. Key Sections: - History: Configuration for command history behavior. - Completion: Settings for tab-completion. - Navigation: Options for directory navigation (`cd`, `pushd`). - Globbing: Enhanced file matching patterns. - Safety: Features to prevent accidental data loss (e.g., `NO_CLOBBER`). - Job Control: Management of background processes.
# Phase:    Post-plugin (.zshrc.d/)

# --- History Options ---
setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FCNTL_LOCK
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_NO_STORE
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
unsetopt HIST_BEEP
# unsetopt BANG_HIST # Disabled by default for safety

# --- Completion Options ---
setopt AUTO_LIST
setopt AUTO_MENU
setopt ALWAYS_TO_END
setopt COMPLETE_IN_WORD
unsetopt MENU_COMPLETE

# --- Input & Editing Options ---
setopt IGNORE_EOF

# --- Directory & Navigation Options ---
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_MINUS
setopt PUSHD_SILENT
setopt CDABLE_VARS

# --- Globbing & Expansion Options ---
setopt EXTENDED_GLOB
setopt GLOB_DOTS
setopt NULL_GLOB
setopt NO_CASE_GLOB
setopt NUMERIC_GLOB_SORT
setopt PROMPT_SUBST

# --- Input/Output & Redirection Options ---
unsetopt CLOBBER # Safety: prevent overwriting files with >
setopt MULTIOS
setopt PIPE_FAIL
setopt PRINT_EXIT_VALUE

# --- Prompt & Display Options ---
setopt TRANSIENT_RPROMPT
unsetopt PROMPT_CR # Fixes cursor positioning with complex prompts
setopt PROMPT_SP

# --- Scripting & Expansion Behavior ---
setopt RC_EXPAND_PARAM
unsetopt SH_WORD_SPLIT # Zsh default is safer

# --- Job Control Options ---
setopt LONG_LIST_JOBS
setopt MONITOR
setopt NOTIFY
setopt BG_NICE

# --- Spelling & Correction Options ---
setopt CORRECT
unsetopt CORRECT_ALL

# --- Miscellaneous Options ---
setopt COMBINING_CHARS
setopt INTERACTIVE_COMMENTS
setopt NO_FLOW_CONTROL
setopt RC_QUOTES

# --- Redirection Sentinel ---
# Detect accidental numeric file creation (e.g., `> 2` instead of `2>`)
if [[ "${ZSH_DEBUG:-0}" == 1 ]]; then
  local _sentinel_root="${ZDOTDIR:-$HOME}"
  local _digit_files=()
  for f in {0..9}; do
    [[ -f "${_sentinel_root}/${f}" ]] && _digit_files+=("${f}")
  done
  if ((${#_digit_files[@]} > 0)); then
    zf::debug "# [options] Detected stray numeric file(s): ${_digit_files[*]}"
  fi
  unset _sentinel_root _digit_files f
fi

return 0
