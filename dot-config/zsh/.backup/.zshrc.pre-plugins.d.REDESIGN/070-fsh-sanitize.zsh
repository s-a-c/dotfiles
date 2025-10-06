#!/usr/bin/env zsh
# 070-FSH-SANITIZE.ZSH (inlined from legacy 13-fsh-sanitize.zsh)
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}
[[ -o interactive ]] || return 0
[[ ${ZSH_DISABLE_FSH_SANITIZE:-0} == 1 ]] && return 0
local _var
for _var in ${(k)parameters}; do
	if [[ $_var == zsh_highlight__* ]]; then
		unset -m $_var 2>/dev/null || unset $_var 2>/dev/null || true
	fi
done
unset _var
export ZSH_FSH_SANITIZED=1
return 0
