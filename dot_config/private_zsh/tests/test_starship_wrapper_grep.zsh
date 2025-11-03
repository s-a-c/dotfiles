#!/usr/bin/env zsh
# test_starship_wrapper_grep.zsh
# Verifies the starship wrapper uses 'command grep' (to avoid user grep aliases)
# and does not contain a raw ' 2> >(grep -v ' fragment.

set -euo pipefail

wrapper_file="${ZDOTDIR:-$PWD}/.zshrc.d.REDESIGN/40-starship-and-fsh-post.zsh"

if [[ ! -r $wrapper_file ]]; then
  print -r -- "FAIL: wrapper file not found: $wrapper_file" >&2
  exit 1
fi

content=$(<"$wrapper_file")

if ! print -r -- "$content" | grep -q "2> >(command grep -v \"parameter not set\""; then
  print -r -- "FAIL: wrapper does not use 'command grep -v' filter" >&2
  exit 1
fi

if print -r -- "$content" | grep -q "2> >(grep -v \"parameter not set\""; then
  print -r -- "FAIL: legacy plain 'grep -v' filter still present" >&2
  exit 1
fi

print -r -- "PASS: starship wrapper uses 'command grep' filter correctly" >&2
exit 0
