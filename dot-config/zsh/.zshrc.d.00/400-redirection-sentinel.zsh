#!/usr/bin/env zsh
# 005-redirection-sentinel.zsh - Early numeric file creation detector
# Phase: 1 (sits very early to catch prior session leftovers)
# Purpose: Detect accidental files named just digits (e.g. '2', '3') often
#          caused by a mistaken redirection pattern like `> 2` instead of `2>`.
# Policy: Non-fatal; logs via zf::debug only when ZSH_DEBUG=1.
# Nounset: safe (use parameter expansions with defaults)

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

if [[ "${ZSH_DEBUG:-0}" == 1 ]]; then
  local _sentinel_root="${ZDOTDIR:-$HOME}"
  local _digit_files=()
  local f
  for f in 0 1 2 3 4 5 6 7 8 9; do
    [[ -f "${_sentinel_root}/${f}" ]] && _digit_files+=("${f}")
  done
  if (( ${#_digit_files[@]} > 0 )); then
    zf::debug "# [redir-sentinel] Detected stray numeric file(s): ${_digit_files[*]} (possible mistaken redirection spacing)"
    zf::debug "# [redir-sentinel] Suggest running: grep -R "'> 2'" -n ${_sentinel_root} | head"
  fi
fi

return 0
