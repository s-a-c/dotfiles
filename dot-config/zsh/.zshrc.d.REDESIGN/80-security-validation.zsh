#!/opt/homebrew/bin/zsh
# 80-security-validation.zsh

# Prevent multiple loading
[[ -n "${_LOADED_80_SECURITY_VALIDATION:-}" ]] && return 0

: ${_LOADED_80_SECURITY_VALIDATION:=1}

# Mark as loaded
readonly _LOADED_80_SECURITY_VALIDATION=1
