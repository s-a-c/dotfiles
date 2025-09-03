# 25-lazy-integrations.zsh (Pre-Plugin Redesign Enhanced)
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
[[ -n ${_LOADED_PRE_LAZY_INTEGRATIONS:-} ]] && return
_LOADED_PRE_LAZY_INTEGRATIONS=1
#
# PURPOSE:
#   Provide testable, deterministic lazy integration loaders for direnv and gh (GitHub CLI / Copilot),
#   shifting any future heavier initialization (env exports, caching, auth warmups) off the initial
#   startup path. Uses Stage 2 lazy framework (`lazy_register`) where feasible.
#
#   NOTE: Now that lazy_register supports --force, we directly wrap existing binaries (direnv, gh)
#   with lazy stubs instead of using thin first-call fallback wrappers. This provides consistent
#   loader invocation paths and simplifies test assertions (no skip markers required).
#
# CONFIG FLAGS:
: ${ZSH_LAZY_INTEGRATIONS_DIRENV:=1}
: ${ZSH_LAZY_INTEGRATIONS_GH:=1}
#
typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }

# ---------------- Common Helpers ----------------
# (skip wrapper helper removed – force mode renders it unnecessary)

# ---------------- direnv ----------------
__lazy_loader_direnv_integration() {
  # Loader executed once by lazy_dispatch (if wrapping succeeded)
  # Define final function that calls real binary then returns its status.
  if ! command -v direnv >/dev/null 2>&1; then
    direnv() { echo "# [lazy-direnv] direnv not installed" >&2; return 127; }
    return 0
  fi
  direnv() {
    # Future: attach env cache / logging here
    command direnv "$@"
  }
  zsh_debug_echo "# [lazy-integrations] direnv loader installed"
}

if (( ZSH_LAZY_INTEGRATIONS_DIRENV )); then
  # Force wrap even if binary/function already exists to unify first-call path.
  lazy_register --force direnv __lazy_loader_direnv_integration >/dev/null 2>&1 || true
fi

# ---------------- gh (GitHub CLI / Copilot) ----------------
__lazy_loader_gh_integration() {
  if ! command -v gh >/dev/null 2>&1; then
    gh() { echo "# [lazy-gh] gh not installed" >&2; return 127; }
    return 0
  fi
  gh() {
    # Placeholder: Later we could pre-warm auth status / gh extension list
    command gh "$@"
  }
  zsh_debug_echo "# [lazy-integrations] gh loader installed"
}

if (( ZSH_LAZY_INTEGRATIONS_GH )); then
  # Force wrap gh to ensure loader instrumentation consistency.
  lazy_register --force gh __lazy_loader_gh_integration >/dev/null 2>&1 || true
fi

# ---------------- git config caching placeholder ----------------
# (Retained from skeleton – future: capture and memoize expensive git config reads)
safe_git config --global user.name >/dev/null 2>&1 || true

zsh_debug_echo "# [pre-plugin] 25-lazy-integrations enhanced (forced lazy wrapping active)"
