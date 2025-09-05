#!/opt/homebrew/bin/zsh
# 30-ssh-agent.zsh (Pre-Plugin Redesign Enhanced)
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
[[ -n ${_LOADED_PRE_SSH_AGENT:-} ]] && return
_LOADED_PRE_SSH_AGENT=1
#
# PURPOSE:
#   Deterministic, idempotent SSH agent consolidation before plugin load.
#   Provides single spawn, reuse detection, validation, and debug instrumentation.
#
# TEST INVARIANTS (see feature test test-ssh-agent-duplicate-spawn.zsh):
#   SA1 Single consolidation function (ensure_ssh_agent) is idempotent.
#   SA2 First invocation spawns agent only if no valid socket present.
#   SA3 _SSH_AGENT_SPAWN_COUNT increments exactly once when spawn occurs.
#   SA4 Existing valid socket is reused (debug marker: [ssh-agent] reuse).
#   SA5 Invalid/broken socket triggers exactly one respawn attempt.
#   SA6 _SSH_AGENT_VALIDATED sentinel set after validation to short‑circuit cost.
#
# CONFIG FLAGS (override in .zshenv if needed):
: ${ZSH_SSH_AGENT_ENABLE:=1}
: ${ZSH_SSH_AGENT_VALIDATE:=1}     # 0 to skip validation (always trust existing)
: ${ZSH_SSH_AGENT_MAX_RESPAWNS:=1} # Future use (currently single attempt)
: ${ZSH_SSH_AGENT_DEBUG:=0}
#
# INTERNAL STATE:
#   _SSH_AGENT_SPAWN_COUNT  -> integer count of successful spawns
#   _SSH_AGENT_VALIDATED    -> sentinel once a valid agent (spawned or reused) confirmed
#   _SSH_AGENT_LAST_ACTION  -> last action string (spawn|reuse|failed)
#
# SAFETY:
#   - Does not overwrite a seemingly foreign SSH_AUTH_SOCK if validation passes.
#   - Uses ssh-add -l exit codes: 0 (keys present) / 1 (no keys) treated as VALID.
#
# NOTE:
#   macOS lacks /proc – we avoid /proc checks; rely on ssh-add behavior.
#
typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }

# --- Utility --------------------------------------------------------------

_ssh_agent_debug() {
    ((ZSH_SSH_AGENT_DEBUG)) && zsh_debug_echo "$1"
}

_ssh_agent_valid() {
    # Returns 0 if current SSH_AUTH_SOCK appears to reference a working agent.
    [[ -S ${SSH_AUTH_SOCK:-} ]] || return 1
    if ((ZSH_SSH_AGENT_VALIDATE)); then
        # ssh-add -l: 0 => keys listed, 1 => no identities, both acceptable
        ssh-add -l >/dev/null 2>&1
        case $? in
        0 | 1) return 0 ;;
        *) return 1 ;;
        esac
    fi
    return 0
}

_spawn_ssh_agent() {
    local agent_out
    agent_out="$(ssh-agent -s 2>/dev/null)" || return 1
    # shellcheck disable=SC1090,SC2086
    eval "$agent_out" 2>/dev/null || return 1
    # Basic sanity
    [[ -n ${SSH_AUTH_SOCK:-} && -S ${SSH_AUTH_SOCK} && -n ${SSH_AGENT_PID:-} ]] || return 1
    return 0
}

# --- Public API -----------------------------------------------------------

ensure_ssh_agent() {
    ((ZSH_SSH_AGENT_ENABLE)) || {
        _ssh_agent_debug "# [ssh-agent] disabled via ZSH_SSH_AGENT_ENABLE"
        return 0
    }

    # Idempotent fast path
    if [[ -n ${_SSH_AGENT_VALIDATED:-} ]]; then
        _ssh_agent_debug "# [ssh-agent] already validated (${_SSH_AGENT_LAST_ACTION:-unknown})"
        return 0
    fi

    # Case 1: Existing valid agent → reuse
    if _ssh_agent_valid; then
        : ${_SSH_AGENT_SPAWN_COUNT:=0}
        _SSH_AGENT_LAST_ACTION="reuse"
        _SSH_AGENT_VALIDATED=1
        zsh_debug_echo "# [ssh-agent] reuse existing ($SSH_AUTH_SOCK)"
        return 0
    fi

    # Case 2: Invalid or absent socket → attempt spawn
    if _spawn_ssh_agent; then
        # Validate new agent (optional)
        if _ssh_agent_valid; then
            : ${_SSH_AGENT_SPAWN_COUNT:=0}
            ((_SSH_AGENT_SPAWN_COUNT++))
            _SSH_AGENT_LAST_ACTION="spawn"
            _SSH_AGENT_VALIDATED=1
            zsh_debug_echo "# [ssh-agent] spawn new (pid=$SSH_AGENT_PID sock=$SSH_AUTH_SOCK)"
            return 0
        else
            _SSH_AGENT_LAST_ACTION="failed"
            zsh_debug_echo "# [ssh-agent] spawn validation failed"
            # Cleanup to avoid misleading state
            unset SSH_AUTH_SOCK SSH_AGENT_PID
            return 1
        fi
    else
        _SSH_AGENT_LAST_ACTION="failed"
        zsh_debug_echo "# [ssh-agent] spawn attempt failed"
        return 1
    fi
}

# Backwards-compatible invocation on load
ensure_ssh_agent

# Debug summary (one-time post validation attempt)
if [[ -n ${_SSH_AGENT_VALIDATED:-} ]]; then
    _ssh_agent_debug "# [ssh-agent] summary action=${_SSH_AGENT_LAST_ACTION:-none} spawns=${_SSH_AGENT_SPAWN_COUNT:-0}"
fi
