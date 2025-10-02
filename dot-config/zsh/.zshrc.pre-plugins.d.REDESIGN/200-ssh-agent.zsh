#!/usr/bin/env zsh
# 200-SSH-AGENT.ZSH - Inlined (was sourcing 70-ssh-agent.zsh)
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}
[[ -n ${_LOADED_PRE_SSH_AGENT:-} ]] && return
_LOADED_PRE_SSH_AGENT=1
if [[ -z ${_CORE_INFRASTRUCTURE_REDESIGN:-} && -f ${ZDOTDIR:-$HOME}/.zshrc.d.REDESIGN/00-core-infrastructure.zsh ]]; then source ${ZDOTDIR:-$HOME}/.zshrc.d.REDESIGN/00-core-infrastructure.zsh; fi
: ${ZSH_SSH_AGENT_ENABLE:=1} : ${ZSH_SSH_AGENT_VALIDATE:=1} : ${ZSH_SSH_AGENT_MAX_RESPAWNS:=1} : ${ZSH_SSH_AGENT_DEBUG:=0}
_ssh_agent_debug(){ ((ZSH_SSH_AGENT_DEBUG)) && zf::debug "[SSH] $1"; }
_ssh_agent_valid(){ [[ -S ${SSH_AUTH_SOCK:-} ]] || return 1; if ((ZSH_SSH_AGENT_VALIDATE)); then ssh-add -l >/dev/null 2>&1; case $? in 0|1) return 0;; *) return 1;; esac; fi; return 0; }
_spawn_ssh_agent(){ local agent_out; agent_out="$(ssh-agent -s 2>/dev/null)" || return 1; eval "$agent_out" 2>/dev/null || return 1; [[ -n ${SSH_AUTH_SOCK:-} && -S ${SSH_AUTH_SOCK} && -n ${SSH_AGENT_PID:-} ]] || return 1; }
ensure_ssh_agent(){ ((ZSH_SSH_AGENT_ENABLE)) || { _ssh_agent_debug "# [ssh-agent] disabled"; return 0; }; if [[ -n ${_SSH_AGENT_VALIDATED:-} ]]; then _ssh_agent_debug "# [ssh-agent] already validated (${_SSH_AGENT_LAST_ACTION:-unknown})"; return 0; fi; if _ssh_agent_valid; then : ${_SSH_AGENT_SPAWN_COUNT:=0}; _SSH_AGENT_LAST_ACTION=reuse; _SSH_AGENT_VALIDATED=1; zf::debug "# [ssh-agent] reuse existing ($SSH_AUTH_SOCK)"; return 0; fi; if _spawn_ssh_agent; then if _ssh_agent_valid; then : ${_SSH_AGENT_SPAWN_COUNT:=0}; ((_SSH_AGENT_SPAWN_COUNT++)); _SSH_AGENT_LAST_ACTION=spawn; _SSH_AGENT_VALIDATED=1; zf::debug "# [ssh-agent] spawn new (pid=$SSH_AGENT_PID sock=$SSH_AUTH_SOCK)"; return 0; else _SSH_AGENT_LAST_ACTION=failed; zf::debug "# [ssh-agent] spawn validation failed"; unset SSH_AUTH_SOCK SSH_AGENT_PID; return 1; fi; else _SSH_AGENT_LAST_ACTION=failed; zf::debug "# [ssh-agent] spawn attempt failed"; return 1; fi }
ensure_ssh_agent
# Backward compatibility wrapper
zf::ssh_ensure_agent() { ensure_ssh_agent "$@"; }
export _SSH_AGENT_NAMESPACE_MIGRATED=1
if [[ -n ${_SSH_AGENT_VALIDATED:-} ]]; then _ssh_agent_debug "# [ssh-agent] summary action=${_SSH_AGENT_LAST_ACTION:-none} spawns=${_SSH_AGENT_SPAWN_COUNT:-0}"; fi
return 0
