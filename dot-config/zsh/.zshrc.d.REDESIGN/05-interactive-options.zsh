#!/opt/homebrew/bin/zsh
# 05-interactive-options.zsh
# Stage 3 – Interactive Shell Options & History Baseline
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Centralizes interactive-oriented Zsh option state (setopt / unsetopt) plus
#   core history configuration and minimal completion style scaffolding.
#   Must be:
#     - Idempotent (re-sourcing = no net option diff)
#     - Low overhead (no compinit invocation here)
#     - Safe on non-interactive shells (skips if $PS1 absent unless forced)
#
# SCOPE (current):
#   - Apply curated option allowlist (SET) & denylist (UNSET)
#   - Configure history variables (if unset) with conservative defaults
#   - Provide lightweight snapshot helper for test harness
#   - Seed minimal completion zstyles (non-destructive) – placeholder only
#
# Deferred (later stages):
#   - Advanced completion style tuning
#   - Dynamic history backend adjustments
#   - Async history compaction / rotation
#
# TEST HOOKS (referenced by option snapshot & idempotency tests):
#   - zf::options_snapshot emits sorted canonical list of managed options (ON/OFF)
#   - Sentinel variable _LOADED_05_INTERACTIVE_OPTIONS ensures single semantic init
#
# Idempotency Contract:
#   Re-sourcing may execute loops but MUST NOT change final effective state or
#   duplicate style entries (guarded via conditional zstyle checks).
#
# NOTE:
#   Keep IMPLEMENTATION.md updated if option set changes (affects golden snapshot).
#
if [[ -n "${_LOADED_05_INTERACTIVE_OPTIONS:-}" ]]; then
  return 0
fi
_LOADED_05_INTERACTIVE_OPTIONS=1

# --------------------------------------------------
# Detect interactive shell (best-effort)
# --------------------------------------------------
_ZF_INTERACTIVE_SHELL=0
if [[ -o interactive ]]; then
  _ZF_INTERACTIVE_SHELL=1
elif [[ -n "${PS1:-}" ]]; then
  _ZF_INTERACTIVE_SHELL=1
fi

# Allow override (force enable)
if [[ -n "${ZF_FORCE_INTERACTIVE_OPTIONS:-}" ]]; then
  _ZF_INTERACTIVE_SHELL=1
fi

# --------------------------------------------------
# History Configuration (only set if unset so caller can override earlier)
# --------------------------------------------------
: ${HISTFILE:=${ZDOTDIR:-$HOME}/.zsh_history}
: ${HISTSIZE:=5000}
: ${SAVEHIST:=5000}

# Ensure directory exists (silent)
mkdir -p -- "${HISTFILE:h}" 2>/dev/null || true

# --------------------------------------------------
# Curated Option Lists
#   These reflect a lean interactive baseline; adjust cautiously.
# --------------------------------------------------
typeset -a _ZF_OPT_SET _ZF_OPT_UNSET

_ZF_OPT_SET=(
  hist_ignore_all_dups     # Collapse duplicates
  share_history            # Share across sessions
  extended_history         # Timestamps in history
  inc_append_history       # Append rather than overwrite
  hist_reduce_blanks       # Strip superfluous blanks
  hist_verify              # Don’t execute recalled line immediately
  auto_cd                  # Bare dir path performs cd
  interactive_comments     # Allow comments in interactive commands
  no_beep                  # Silence bell
  pipefail                 # Propagate pipeline failure
)

_ZF_OPT_UNSET=(
  flow_control             # Disable ^S/^Q interference
  clobber                  # Prevent accidental overwrite (user can enable explicitly)
)

# Normalize naming: accept both with / without "no_" for internal loops.
# Implementation uses `setopt` / `unsetopt` for clarity; handles already-correct states silently.

# --------------------------------------------------
# Apply Options Idempotently
# --------------------------------------------------
for opt in "${_ZF_OPT_SET[@]}"; do
  setopt "$opt" 2>/dev/null || true
done
for opt in "${_ZF_OPT_UNSET[@]}"; do
  unsetopt "$opt" 2>/dev/null || true
done

# Guarantee pipefail (alias for |& semantics on some shells) if available.
# (Already in set list, but re-assert silently if shell supports.)
setopt pipefail 2>/dev/null || true

# --------------------------------------------------
# Minimal Completion Styles (Placeholder)
#   Avoid heavy operations; only insert if not already present to preserve user overrides.
# --------------------------------------------------
if (( _ZF_INTERACTIVE_SHELL )); then
  if command -v zstyle >/dev/null 2>&1; then
    # Helper to conditionally add a style (skip if already defined)
    _zf_add_style() {
      local context=$1 key=$2 value=$3
      if ! zstyle -L "$context" "$key" >/dev/null 2>&1; then
        zstyle "$context" "$key" "$value"
      fi
    }
    _zf_add_style ':completion:*' menu select
    _zf_add_style ':completion:*' matcher-list 'm:{a-z}={A-Z}'
    _zf_add_style ':completion:*' squeeze-slashes true
  fi
fi

# --------------------------------------------------
# Option Snapshot Helper (Used by tests)
#   Emits deterministic sorted list: option=on|off for managed options only.
# --------------------------------------------------
zf::options_snapshot() {
  local name
  local -a all managed
  managed=("${_ZF_OPT_SET[@]}" "${_ZF_OPT_UNSET[@]}")
  # De-duplicate
  typeset -A seen
  for name in "${managed[@]}"; do
    [[ -n "$name" && -z "${seen[$name]:-}" ]] && seen[$name]=1
  done
  for name in "${(@k)seen}"; do
    if [[ -o $name ]]; then
      all+=("${name}=on")
    else
      all+=("${name}=off")
    fi
  done
  printf '%s\n' "${(on)all}"
}

# --------------------------------------------------
# Diagnostics (optional)
# --------------------------------------------------
if [[ -n "${ZF_OPTIONS_DEBUG:-}" ]]; then
  print "[05-interactive-options] interactive=${_ZF_INTERACTIVE_SHELL} managed_opts=$(( ${#_ZF_OPT_SET[@]} + ${#_ZF_OPT_UNSET[@]} ))"
fi
