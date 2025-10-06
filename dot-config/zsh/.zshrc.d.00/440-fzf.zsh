#!/usr/bin/env zsh
# 320-fzf.zsh - Phase 4: FZF integration (core bindings + completion hooks)
# Loads fzf keybindings if available; avoids errors if missing.

# Skip if plugin-managed FZF layer already initialized (marker from 160-productivity-fzf.zsh)
if [[ -n ${_ZF_PM_FZF_LOADED:-} ]]; then
  return 0
fi

if [[ "${ZF_DISABLE_FZF:-0}" == 1 ]]; then
  return 0
fi

# FZF default options (user may override in personal layer)
: ${FZF_DEFAULT_OPTS:="--height 40% --border"}
export FZF_DEFAULT_OPTS

# fzf key bindings & completion (standard install locations)
for _fzf_base in "${HOME}/.fzf" "/opt/homebrew/opt/fzf"; do
  if [[ -d "${_fzf_base}" ]]; then
    [[ -r "${_fzf_base}/shell/completion.zsh" ]] && source "${_fzf_base}/shell/completion.zsh"
    [[ -r "${_fzf_base}/shell/key-bindings.zsh" ]] && source "${_fzf_base}/shell/key-bindings.zsh"
  fi
done
unset _fzf_base

# Manual validation:
#   echo test | fzf
#   Press **CTRL-T** (should trigger file selection if fzf installed)
