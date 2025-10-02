#!/usr/bin/env zsh
# 050-ZGEN-RESET.ZSH (migrated from 05-zgen-reset.zsh)
[[ -o interactive ]] || return 0
if [[ "${ZSH_FORCE_ZGEN_RESET:-0}" == "1" ]]; then
  : ${ZGEN_DIR:=${ZDOTDIR:-$HOME}/.zqs-zgenom}
  rm -f -- "$HOME/.zgen/init.zsh" "$HOME/.zgenom/init.zsh" 2>/dev/null || true
  rm -f -- "${ZGEN_DIR}/init.zsh" 2>/dev/null || true
fi
return 0
