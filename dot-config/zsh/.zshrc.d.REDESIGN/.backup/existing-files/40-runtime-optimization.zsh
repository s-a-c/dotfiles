# 40-runtime-optimization.zsh
# Runtime optimization helpers for the redesign
#
# - Idempotent sentinel guard
# - Opt-in via ZSH_USE_REDESIGN (module becomes no-op if not enabled)
# - Small, safe, non-invasive runtime tweaks
# - Exposes a single public function: zred::runtime::optimize
#
# Owner: s-a-c
# Created: 2025-09-07
#
# Usage:
#  - Opt-in locally: `export ZSH_USE_REDESIGN=1`
#  - Source the redesign environment or start an interactive shell:
#      env ZSH_USE_REDESIGN=1 ZDOTDIR=$PWD/dot-config/zsh zsh -i -f
#  - To apply runtime optimizations manually:
#      zred::runtime::optimize
#
emulate -L zsh

# Feature-flag guard: only activate when explicitly opted-in
if [[ "${ZSH_USE_REDESIGN:-0}" != "1" ]]; then
  return 0
fi

# Sentinel guard to avoid double-sourcing
if [[ -n "${_ZRED_40_LOADED:-}" ]]; then
  return 0
fi
_ZRED_40_LOADED=1

# Small namespace for this module to avoid polluting global scope
zred::runtime::is_applied() {
  [[ "${_ZRED_40_APPLIED:-0}" -eq 1 ]]
}

# Internal: apply safe shell options that are known to be low-risk
zred::runtime::_apply_safe_options() {
  # Use setopt with conservative options; avoid surprising behavior for users.
  # These are examples — keep them small and reversible.
  setopt no_beep         # disable audible bell
  setopt PROMPT_SUBST    # enable prompt substitution if required by prompt code
  # Keep other heavy/tunable options off by default to avoid breakage.
}

# Internal: defer heavier initialization until interactive prompt
zred::runtime::_deferred_init() {
  # Example deferred work: lazy-load helpers only when interactive.
  if [[ -n "$PS1" || -n "$ZLE_TERMINAL" || -n "${ZSH_INTERACTIVE:-}" ]]; then
    # autoload expensive helpers only when they will be used
    autoload -Uz compinit 2>/dev/null || true
    # Example: prepare a small cache dir used by runtime optimizations
    : "${ZSH_CACHE_DIR:=$HOME/.cache/zsh}"
    mkdir -p -- "${ZSH_CACHE_DIR}" 2>/dev/null || true
  fi
}

# Public: apply runtime optimizations
# - Idempotent: consecutive calls are safe
# - Lightweight: intended to run at shell startup or on-demand
zred::runtime::optimize() {
  if zred::runtime::is_applied; then
    return 0
  fi

  # Apply only for interactive shells by default; allow invocation in non-interactive when explicitly needed.
  if [[ -z "$PS1" && "${ZRED_FORCE_OPTIMIZE:-0}" != "1" ]]; then
    # schedule deferred initialization if not interactive
    zred::runtime::_deferred_init
    _ZRED_40_APPLIED=1
    return 0
  fi

  # Apply safe options and perform on-demand deferred init
  zred::runtime::_apply_safe_options
  zred::runtime::_deferred_init

  # Mark applied
  _ZRED_40_APPLIED=1
  return 0
}

# Convenience: automatically apply optimizations for interactive shells when sourced
if [[ -n "$PS1" || -n "${ZSH_INTERACTIVE:-}" ]]; then
  # Prefer explicit call, but auto-apply in interactive shells for UX parity.
  zred::runtime::optimize
fi

# Export a small status helper for other modules to query
: ${ZRED_RUNTIME_OPTIMIZED:=0}
if [[ "${_ZRED_40_APPLIED:-0}" -eq 1 ]]; then
  ZRED_RUNTIME_OPTIMIZED=1
fi
export ZRED_RUNTIME_OPTIMIZED

# Provide a minimal cleanup function (no-op unless heavy state is added later)
zred::runtime::cleanup() {
  # Placeholder to undo any temporary runtime changes if needed.
  # Currently non-destructive by design; nothing to clean up.
  return 0
}

# End of module
