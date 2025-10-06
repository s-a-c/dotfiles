#!/usr/bin/env zsh
# 060-ENSURE-ZGENOM-SYMLINK.ZSH (migrated from 11-ensure-zgenom-symlink.zsh)
[[ -o interactive ]] || return 0
[[ ${ZSH_DISABLE_ZGENOM_SYMLINK_ENSURE:-0} == 1 ]] && return 0
local target_dir="${ZDOTDIR:-$HOME}/.zqs-zgenom"
local legacy_dir="${ZDOTDIR:-$HOME}/.zgenom"
if [[ -d "$target_dir" ]]; then
  if [[ -d "$legacy_dir" && ! -L "$legacy_dir" ]]; then
    if [[ "$legacy_dir" -ef "$target_dir" ]]; then return 0; fi
    return 0
  fi
  if [[ ! -L "$legacy_dir" ]] || [[ "$(readlink "$legacy_dir" 2>/dev/null)" != ".zqs-zgenom" && "$(readlink "$legacy_dir" 2>/dev/null)" != "$target_dir" ]]; then
    ln -snf "$target_dir" "$legacy_dir" 2>/dev/null || true
    [[ ${ZSH_DEBUG:-0} == 1 ]] && print -r -- "[ZGENOM-SYMLINK][060] Ensured $legacy_dir -> $target_dir" >&2
  fi
fi
export ZSH_ZGENOM_SYMLINK_ENSURED=1
return 0
