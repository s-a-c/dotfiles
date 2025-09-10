#!/opt/homebrew/bin/zsh
# 60-ui-prompt.zsh

# Prevent multiple loading
[[ -n "${_LOADED_60_UI_PROMPT:-}" ]] && return 0

: ${_LOADED_60_UI_PROMPT:=1}

# Mark as loaded
readonly _LOADED_60_UI_PROMPT=1
