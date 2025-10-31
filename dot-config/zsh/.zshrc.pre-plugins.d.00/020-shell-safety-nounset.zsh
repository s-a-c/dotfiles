#!/usr/bin/env zsh
# 010-SHELL-SAFETY-NOUNSET.ZSH
# Compliant with [${HOME}/dotfiles/dot-config/ai/guidelines.md](${HOME}/dotfiles/dot-config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}
# Purpose: Centralize early safety options & nounset resilience previously scattered
# across legacy guards. Ensures interactive shell viability before plugins load.

[[ -n ${_ZQS_REDESIGN_SHELL_SAFETY_LOADED:-} ]] && return 0
_ZQS_REDESIGN_SHELL_SAFETY_LOADED=1

# Snapshot original option states (only those we might toggle)
typeset -gA _ZQS_OPTION_SNAPSHOT
for __opt in nounset errexit pipefail; do
	set -o | grep -E "^${__opt}[[:space:]]+on" >/dev/null 2>&1 && _ZQS_OPTION_SNAPSHOT[$__opt]=on || _ZQS_OPTION_SNAPSHOT[$__opt]=off
done

# Ensure nounset-safe critical scalars/arrays used later (avoid 'parameter not set')
: ${ZSH_DEBUG:=0}
: ${STARSHIP_CMD_STATUS:=0}
: ${STARSHIP_PIPE_STATUS:=""}
: ${STARSHIP_WRAP_FAILS:=0}
: ${STARSHIP_FALLBACK_ACTIVATED:=0}
: ${STARSHIP_FALLBACK_REASON:=""}

# Oh-My-Zsh and zgenom parameters that cause nounset errors
: ${HYPHEN_INSENSITIVE:=""}
: ${SSH_TTY:=""}
: ${zcompdump_refresh:=""}
# Fix zgenom/oh-my-zsh parameter errors - disable nounset permanently for compatibility
# Oh-My-Zsh and zgenom have fundamental nounset compatibility issues that cause:
# - System hangs during plugin loading
# - ZLE corruption and "function definition file not found" errors
# - Parameter not set errors (e.g., "2: parameter not set")
# Solution: Disable nounset permanently when using Oh-My-Zsh/zgenom
if [[ -o nounset ]]; then
    export _ZQS_NOUNSET_WAS_ON=1
    unsetopt nounset
    export _ZQS_NOUNSET_DISABLED_FOR_OMZ=1
    zf::debug "# [shell-safety-nounset] permanently disabled nounset for Oh-My-Zsh/zgenom compatibility"
else
    export _ZQS_NOUNSET_WAS_ON=0
    export _ZQS_NOUNSET_DISABLED_FOR_OMZ=0
fi

# Guarantee array exists even if later code does `${#STARSHIP_PIPE_STATUS[@]}`
if [[ ${+STARSHIP_PIPE_STATUS[@]} -eq 0 ]]; then
	typeset -ga STARSHIP_PIPE_STATUS
fi

# Provide minimal zf::debug if not yet defined (late .zshenv might have done this)
if ! typeset -f zf::debug >/dev/null 2>&1; then
	zf::debug() { [[ ${ZSH_DEBUG:-0} == 1 ]] && print -u2 -- "$@"; }
fi

zf::debug "# [shell-safety-nounset] applying early guards"

# If nounset already on this early, protect common probes by defining safe indirections
if set -o | grep -q '^nounset *on'; then
	# Wrap ${var:-} expansion pattern for widespread later use
	zf::debug "# [shell-safety-nounset] nounset already active - strengthening guards"
else
	# Defer enabling nounset until after core pre-plugin environment stabilizes
	# (enabling too early risks third-party plugin eval failures on legitimate probes)
	:
fi

# Helper to enable nounset at a controlled later phase (called by later file if desired)
if ! typeset -f zf::enable_nounset_safe >/dev/null 2>&1; then
	zf::enable_nounset_safe() {
		if set -o | grep -q '^nounset *on'; then
			zf::debug "# [shell-safety-nounset] nounset already enabled"
			return 0
		fi
		# Dry-run probe: ensure sentinel scalars resolve
		: ${STARSHIP_CMD_STATUS:=0} ${STARSHIP_PIPE_STATUS:=""}
		set -o nounset
		zf::debug "# [shell-safety-nounset] nounset enabled safely"
	}
fi

# Teardown / restore helper (used by debug policy reset)
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
		zf::debug "# [shell-safety-nounset] restored option snapshot"
	}
fi

return 0
