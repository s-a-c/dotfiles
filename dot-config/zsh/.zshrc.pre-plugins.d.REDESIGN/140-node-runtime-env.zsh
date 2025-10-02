#!/usr/bin/env zsh
# 140-NODE-RUNTIME-ENV.ZSH (inlined from legacy 40-node-runtime-env.zsh)
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}
[[ -n ${_LOADED_PRE_NODE_RUNTIME_ENV:-} ]] && return 0
_LOADED_PRE_NODE_RUNTIME_ENV=1
: ${ZSH_ENABLE_NVM_PLUGINS:=1}
: ${ZSH_NODE_LAZY:=1}
if [[ -z ${NVM_DIR:-} ]]; then
	if [[ -d "${HOME}/Library/Application Support/Herd/config/nvm" ]]; then
		NVM_DIR="${HOME}/Library/Application Support/Herd/config/nvm"
	elif [[ -n ${HOMEBREW_PREFIX:-} && -d "${HOMEBREW_PREFIX}/opt/nvm" ]]; then
		NVM_DIR="${HOMEBREW_PREFIX}/opt/nvm"
	elif [[ -d "${HOME}/.nvm" ]]; then
		NVM_DIR="${HOME}/.nvm"
	fi
	export NVM_DIR
fi
export NVM_AUTO_USE=true NVM_LAZY_LOAD=true NVM_COMPLETION=true
zstyle ':omz:plugins:nvm' lazy yes
zstyle ':omz:plugins:nvm' lazy-cmd eslint prettier typescript
zstyle ':omz:plugins:nvm' autoload yes
if [[ ${ZSH_NODE_LAZY} == 1 && -d ${NVM_DIR:-/nonexistent} ]]; then
	nvm() { unfunction nvm 2>/dev/null || true; [[ -s "${NVM_DIR}/nvm.sh" ]] && builtin source "${NVM_DIR}/nvm.sh"; [[ -s "${NVM_DIR}/bash_completion" ]] && builtin source "${NVM_DIR}/bash_completion"; typeset -f node_first_use_init >/dev/null 2>&1 && node_first_use_init || true; nvm "$@"; }
fi
node_first_use_init() { :; }
zf::debug "# [pre-plugin] node-runtime-env skeleton loaded (lazy=${ZSH_NODE_LAZY})"
return 0
