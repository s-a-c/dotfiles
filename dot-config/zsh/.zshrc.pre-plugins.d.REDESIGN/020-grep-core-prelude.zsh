#!/usr/bin/env zsh
# 020-GREP-CORE-PRELUDE.ZSH (renamed from 02-grep-prelude.zsh)
# Original purpose: early neutralization of grep aliases.

if [[ -n ${_ZQS_GREP_PRELUDE_LOADED:-} ]]; then return 0; fi
_ZQS_GREP_PRELUDE_LOADED=1
: ${ZQS_ORIG_GREP:=$(command -v grep 2>/dev/null || echo grep)}
if alias grep >/dev/null 2>&1; then unalias grep 2>/dev/null || true; fi
zf::core_grep() { command grep "$@"; }
export ZQS_GREP_PRELUDE=1
