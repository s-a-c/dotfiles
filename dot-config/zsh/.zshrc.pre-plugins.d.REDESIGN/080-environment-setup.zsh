#!/usr/bin/env zsh
# 080-ENVIRONMENT-SETUP.ZSH (inlined from legacy 15-environment-setup.zsh)
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}
if [[ -n "${_LOADED_ENVIRONMENT_SETUP_REDESIGN:-}" ]]; then return 0; fi
_LOADED_ENVIRONMENT_SETUP_REDESIGN=1
if [[ -n "${ZSH_DEBUG:-}" ]]; then
	zf::debug "[ENV-SETUP] Debug mode active - enhanced logging enabled"
	if [[ -n "${ZSH_LOG_DIR:-}" ]] && [[ ! -d "$ZSH_LOG_DIR" ]]; then
		mkdir -p "$ZSH_LOG_DIR" 2>/dev/null || true
		zf::debug "[ENV-SETUP] Created debug log directory: $ZSH_LOG_DIR"
	fi
fi
export ZSH_DISABLE_OMZ=1 ZSH_DISABLE_OMZ_PLUGINS=1 ZSH_DISABLE_UNIXORN_MISC=1 ZSH_DISABLE_DOCKER_ZSH=1
typeset -gi STARSHIP_CMD_STATUS 2>/dev/null || true; STARSHIP_CMD_STATUS=${STARSHIP_CMD_STATUS:-0}
typeset -ga STARSHIP_PIPE_STATUS 2>/dev/null || true; : ${STARSHIP_PIPE_STATUS:=()}
export SHELL_CONFIG_VERSION="redesign-v2" PRELOAD_PHASE="pre-plugin"
: ${XDG_CONFIG_HOME:="$HOME/.config"}; : ${XDG_CACHE_HOME:="$HOME/.cache"}; : ${XDG_DATA_HOME:="$HOME/.local/share"}
[[ ! -d "$XDG_CACHE_HOME/zsh" ]] && mkdir -p "$XDG_CACHE_HOME/zsh" 2>/dev/null
zf::debug "[ENV-SETUP] XDG directories initialized"
if [[ -n "${PERF_SEGMENT_LOG:-}" ]] || [[ -n "${ZSH_DEBUG:-}" ]]; then
	zmodload zsh/datetime 2>/dev/null || true
	if [[ -z "${ENV_SETUP_START_TIME:-}" ]]; then ENV_SETUP_START_TIME="$EPOCHREALTIME"; export ENV_SETUP_START_TIME; zf::debug "[ENV-SETUP] Performance timing initialized"; fi
fi
if ! command -v can_haz >/dev/null 2>&1; then can_haz() { zf::ensure_cmd "$@"; }; fi
zf::debug "[ENV-SETUP] Compatibility functions verified"
local -a critical_dirs=("${ZDOTDIR:-$HOME}" "${XDG_CACHE_HOME}/zsh")
for dir in "${critical_dirs[@]}"; do [[ -d "$dir" ]] || zf::debug "[ENV-SETUP] Warning: Critical directory missing: $dir"; done
export ENVIRONMENT_SETUP_VERSION="2.0.0" ENVIRONMENT_SETUP_LOADED_AT="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'unknown')" _ENV_SETUP_NAMESPACE_MIGRATED=1
zf::debug "[ENV-SETUP] Environment setup completed successfully"
if [[ -o interactive ]]; then
	_zqs__preprompt_ultra_guard(){ setopt localoptions; unsetopt nounset 2>/dev/null || true; if ! (( ${+STARSHIP_CMD_STATUS} )); then typeset -gi STARSHIP_CMD_STATUS=0; fi; if ! (( ${+STARSHIP_PIPE_STATUS} )); then typeset -ga STARSHIP_PIPE_STATUS; STARSHIP_PIPE_STATUS=(); fi; if [[ ${ZSH_DEBUG:-0} == 1 && -n ${ZSH_DEBUG_LOG:-} ]]; then print -r -- "[ULTRA-GUARD][precmd] status=${STARSHIP_CMD_STATUS}" >>"$ZSH_DEBUG_LOG" 2>/dev/null || true; fi }
	if (( ${+precmd_functions} )); then (( ! ${precmd_functions[(I)_zqs__preprompt_ultra_guard]} )) && precmd_functions=( _zqs__preprompt_ultra_guard ${precmd_functions[@]} ); else precmd_functions=( _zqs__preprompt_ultra_guard ); fi
fi
return 0
