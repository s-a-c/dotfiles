#!/usr/bin/env zsh
# 090-EARLY-VARS-AND-KEYMAP.ZSH (inlined from legacy 17-early-vars-and-keymap.zsh)
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}

# Purpose: Seed critical prompt status variables and enforce keymap before plugins load.

# Defensive variable seeding for prompt and plugin safety (nounset-safe)
if ! (( ${+STARSHIP_CMD_STATUS}     )); then typeset -gi STARSHIP_CMD_STATUS=0; fi
if ! (( ${+STARSHIP_DURATION_MS}    )); then typeset -gi STARSHIP_DURATION_MS=0; fi
if ! (( ${+STARSHIP_CMD_EXIT_REASON})); then typeset -gi STARSHIP_CMD_EXIT_REASON=0; fi
if ! (( ${+STARSHIP_CMD_START_TIME} )); then typeset -gi STARSHIP_CMD_START_TIME=0; fi
if ! (( ${+STARSHIP_CMD_END_TIME}   )); then typeset -gi STARSHIP_CMD_END_TIME=0; fi
if ! (( ${+STARSHIP_CMD_BG}         )); then typeset -gi STARSHIP_CMD_BG=0; fi
if ! (( ${+STARSHIP_CMD_JOBS}       )); then typeset -gi STARSHIP_CMD_JOBS=0; fi
if ! (( ${+STARSHIP_CMD_PIPESTATUS} )); then typeset -gi STARSHIP_CMD_PIPESTATUS=0; fi
if ! (( ${+STARSHIP_CMD_SIG}        )); then typeset -gi STARSHIP_CMD_SIG=0; fi
if ! (( ${+STARSHIP_CMD_ERR}        )); then typeset -gi STARSHIP_CMD_ERR=0; fi
if ! (( ${+STARSHIP_CMD_ERRNO}      )); then typeset -gi STARSHIP_CMD_ERRNO=0; fi
if ! (( ${+STARSHIP_CMD_ERRCODE}    )); then typeset -gi STARSHIP_CMD_ERRCODE=0; fi
if ! (( ${+STARSHIP_CMD_ERRLINE}    )); then typeset -gi STARSHIP_CMD_ERRLINE=0; fi
if ! (( ${+STARSHIP_CMD_ERRMSG}     )); then typeset -g  STARSHIP_CMD_ERRMSG=""; fi
if ! (( ${+STARSHIP_CMD_ERRCTX}     )); then typeset -g  STARSHIP_CMD_ERRCTX=""; fi
if ! (( ${+STARSHIP_CMD_ERRFUNC}    )); then typeset -g  STARSHIP_CMD_ERRFUNC=""; fi
if ! (( ${+STARSHIP_CMD_ERRFILE}    )); then typeset -g  STARSHIP_CMD_ERRFILE=""; fi

# Defensive ZLE widget and keymap setup
if [[ -o interactive ]]; then
	if zmodload -i zsh/zle 2>/dev/null; then
		if [[ -z "${ZSH_FORCE_VI_MODE:-}" ]]; then
			bindkey -e 2>/dev/null || true
		fi
	fi
fi

return 0
