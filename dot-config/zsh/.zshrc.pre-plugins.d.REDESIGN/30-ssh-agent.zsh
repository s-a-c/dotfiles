# 30-ssh-agent.zsh (Pre-Plugin Redesign Skeleton)
[[ -n ${_LOADED_PRE_SSH_AGENT:-} ]] && return
_LOADED_PRE_SSH_AGENT=1

# PURPOSE: Consolidated SSH agent startup + key permission sanity (skeleton)
# NOTE: Skeleton avoids spawning new agent; implementation phase will add logic.

if [[ -S ${SSH_AUTH_SOCK:-/nonexistent} ]]; then
  zsh_debug_echo "# [pre-plugin] Existing SSH agent detected ($SSH_AUTH_SOCK)"
else
  zsh_debug_echo "# [pre-plugin] SSH agent startup deferred (skeleton)"
fi
