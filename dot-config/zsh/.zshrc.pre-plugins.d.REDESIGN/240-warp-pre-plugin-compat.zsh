#!/usr/bin/env zsh
# 240-warp-pre-plugin-compat.zsh (INLINE MIGRATION of legacy 90-warp-pre-plugin-compat.zsh)
# AI Authored Consolidation — wrapper sourcing removed; original will be stubbed.
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) ${GUIDELINES_CHECKSUM:-vUNKNOWN}

if [[ -n "${_WARP_PRE_PLUGIN_COMPAT_LOADED:-}" ]]; then
	return 0
fi
export _WARP_PRE_PLUGIN_COMPAT_LOADED=1

_warp_pre_debug() {
	if [[ "${DEBUG_ZSH_REDESIGN:-0}" == "1" || "${ZSH_DEBUG:-0}" == "1" ]]; then
		print "[TERMINAL-PRE-COMPAT] $1" >&2
	fi
}

_warp_pre_debug "Initializing terminal pre-plugin compatibility fixes"

# Skip for Apple Terminal — k plugin fine there
if [[ "$TERM_PROGRAM" == "Apple_Terminal" ]]; then
	return 0
fi

# Prevent k alias/function conflicts that can trip plugin load
if [[ -n ${aliases[k]:-} ]]; then
	unalias k 2>/dev/null || true
	_warp_pre_debug "Removed existing k alias"
fi
if [[ -n ${functions[k]:-} ]]; then
	unfunction k 2>/dev/null || true
	_warp_pre_debug "Removed existing k function"
fi

# Temporary stub function until either plugin or kubectl alias claims it
k() { echo "k function loading..."; }
export WARP_PREFER_KUBECTL_K=1
export WARP_K_STUB_CREATED=1
_warp_pre_debug "K stub established"

# Safety parameter initialization (avoid parameter-not-set)
typeset -gA widgets 2>/dev/null || true
typeset -gA parameters 2>/dev/null || true
typeset -gA functions 2>/dev/null || true

typeset -g PROMPT="${PROMPT:-}" RPROMPT="${RPROMPT:-}" PS1="${PS1:-}" PS2="${PS2:-}"
typeset -g ZSH_THEME_GIT_PROMPT_PREFIX="${ZSH_THEME_GIT_PROMPT_PREFIX:-}" \
		   ZSH_THEME_GIT_PROMPT_SUFFIX="${ZSH_THEME_GIT_PROMPT_SUFFIX:-}" \
		   ZSH_THEME_GIT_PROMPT_DIRTY="${ZSH_THEME_GIT_PROMPT_DIRTY:-}" \
		   ZSH_THEME_GIT_PROMPT_CLEAN="${ZSH_THEME_GIT_PROMPT_CLEAN:-}"
_warp_pre_debug "Plugin safety parameters initialized"

# Disable incompatible / unnecessary integrations for Warp
export DISABLE_ITERM2_SHELL_INTEGRATION=1
export ITERM2_SHELL_INTEGRATION_INSTALLED=""
export DISABLE_AUTO_TITLE=1
_warp_pre_debug "Disabled iTerm2 shell integration and auto title"

# Performance tweaks
export DISABLE_CORRECTION=true
export DISABLE_UNTRACKED_FILES_DIRTY=true
zstyle ':completion:*' menu select=0
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
_warp_pre_debug "Applied Warp performance tweaks"

export WARP_PRE_PLUGIN_COMPAT_APPLIED=1
if command -v kubectl >/dev/null 2>&1; then
	export WARP_KUBECTL_AVAILABLE=1
	_warp_pre_debug "kubectl detected — post-plugin will alias k"
fi

export WARP_PRE_PLUGIN_COMPAT_VERSION="1.0.0"
if command -v date >/dev/null 2>&1; then
	export WARP_PRE_PLUGIN_COMPAT_LOADED_AT="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'unknown')"
else
	export WARP_PRE_PLUGIN_COMPAT_LOADED_AT="unknown"
fi

unset -f _warp_pre_debug
return 0
