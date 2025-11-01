#!/usr/bin/env zsh
# Filename: 010-shell-safety.zsh
# Purpose:  Centralizes shell safety options, particularly nounset management, to ensure a stable interactive environment before plugins are loaded. This script combines initial setup and delayed activation for better control. Features: - Snapshots original options (nounset, errexit, pipefail) for restoration. - Initializes critical variables to prevent 'parameter not set' errors. - Disables nounset for Oh-My-Zsh/zgenom compatibility to prevent hangs and errors. - Provides helpers (zf::enable_nounset_safe, zf::restore_option_snapshot) for controlled option management. - Delays nounset activation until after critical startup phases, honoring opt-outs. Idempotency Guard
# Phase:    Pre-plugin (.zshrc.pre-plugins.d/)

[[ -n ${_ZQS_SHELL_SAFETY_DONE:-} ]] && return 0
_ZQS_SHELL_SAFETY_DONE=1

# Provide minimal zf::debug if not yet defined
if ! typeset -f zf::debug >/dev/null 2>&1; then
	zf::debug() { [[ ${ZSH_DEBUG:-0} == 1 ]] && print -u2 -- "$@"; }
fi

zf::debug "# [shell-safety] applying early guards"

# Snapshot original option states
typeset -gA _ZQS_OPTION_SNAPSHOT
for __opt in nounset errexit pipefail; do
	set -o | grep -E "^${__opt}[[:space:]]+on" >/dev/null 2>&1 && _ZQS_OPTION_SNAPSHOT[$__opt]=on || _ZQS_OPTION_SNAPSHOT[$__opt]=off
done

# Ensure nounset-safe critical scalars/arrays
: ${ZSH_DEBUG:=0}
: ${STARSHIP_CMD_STATUS:=0}
: ${STARSHIP_PIPE_STATUS:=""}
: ${STARSHIP_WRAP_FAILS:=0}
: ${STARSHIP_FALLBACK_ACTIVATED:=0}
: ${STARSHIP_FALLBACK_REASON:=""}
: ${HYPHEN_INSENSITIVE:=""}
: ${SSH_TTY:=""}
: ${zcompdump_refresh:=""}

# Guarantee array exists
if [[ ${+STARSHIP_PIPE_STATUS[@]} -eq 0 ]]; then
	typeset -ga STARSHIP_PIPE_STATUS
fi

# Oh-My-Zsh/zgenom compatibility: permanently disable nounset
if [[ -o nounset ]]; then
    export _ZQS_NOUNSET_WAS_ON=1
    unsetopt nounset
    export _ZQS_NOUNSET_DISABLED_FOR_OMZ=1
    zf::debug "# [shell-safety] permanently disabled nounset for Oh-My-Zsh/zgenom compatibility"
else
    export _ZQS_NOUNSET_WAS_ON=0
    export _ZQS_NOUNSET_DISABLED_FOR_OMZ=0
fi

# Helper to enable nounset at a controlled later phase
if ! typeset -f zf::enable_nounset_safe >/dev/null 2>&1; then
	zf::enable_nounset_safe() {
		if set -o | grep -q '^nounset *on'; then
			zf::debug "# [shell-safety] nounset already enabled"
			return 0
		fi
		: ${STARSHIP_CMD_STATUS:=0} ${STARSHIP_PIPE_STATUS:=""}
		set -o nounset
		zf::debug "# [shell-safety] nounset enabled safely"
	}
fi

# Teardown / restore helper
if ! typeset -f zf::restore_option_snapshot >/dev/null 2>&1; then
	zf::restore_option_snapshot() {
		local k
		for k in ${(k)_ZQS_OPTION_SNAPSHOT}; do
			if [[ ${_ZQS_OPTION_SNAPSHOT[$k]} == on ]]; then
				set -o $k 2>/dev/null || true
			else
				set +o $k 2>/dev/null || true
			fi
		done
		zf::debug "# [shell-safety] restored option snapshot"
	}
fi

# --- Delayed Nounset Activation Logic ---

# Only run in interactive shells
[[ -o interactive ]] || return 0

# Honor opt-out
if [[ ${ZSH_DISABLE_DELAYED_NOUNSET:-0} == 1 ]]; then
  zf::debug "# [shell-safety] delayed nounset disabled via ZSH_DISABLE_DELAYED_NOUNSET"
  return 0
fi

# If nounset was disabled for OMZ, keep it disabled
if [[ "${_ZQS_NOUNSET_DISABLED_FOR_OMZ:-0}" == "1" ]]; then
  zf::debug "# [shell-safety] nounset kept disabled for Oh-My-Zsh compatibility"
  return 0
fi

# If it was on before, re-enable it
if [[ "${_ZQS_NOUNSET_WAS_ON:-0}" == "1" ]]; then
  zf::enable_nounset_safe
  unset _ZQS_NOUNSET_WAS_ON
  zf::debug "# [shell-safety] delayed nounset re-enabled"
  return 0
fi

# Avoid enabling if user already turned it on
if set -o | grep -q '^nounset *on'; then
  return 0
fi

# Enable nounset for the first time
zf::enable_nounset_safe
zf::debug "# [shell-safety] delayed nounset activation complete"

return 0
