# 25-lazy-integrations.zsh (Pre-Plugin Redesign Skeleton)
[[ -n ${_LOADED_PRE_LAZY_INTEGRATIONS:-} ]] && return
_LOADED_PRE_LAZY_INTEGRATIONS=1

# PURPOSE: Provide lazy wrappers for direnv, git config caching, gh/copilot.
# Real implementation will replace simple echoes with functional deferred loads.

# direnv wrapper
if ! command -v direnv >/dev/null 2>&1; then
    direnv() { echo "# [lazy-direnv] direnv not installed" >&2; return 127; }
else
    if [[ -z ${_DIRENV_LAZY_WRAPPED:-} ]]; then
        _DIRENV_LAZY_WRAPPED=1
        direnv() { unfunction direnv 2>/dev/null || true; command direnv "$@"; }
    fi
fi

# gh/copilot wrapper
if ! command -v gh >/dev/null 2>&1; then
    gh() { echo "# [lazy-gh] gh not installed" >&2; return 127; }
else
    gh() { unfunction gh 2>/dev/null || true; command gh "$@"; }
fi

# git config caching placeholder (actual logic deferred)
safe_git config --global user.name >/dev/null 2>&1 || true

zsh_debug_echo "# [pre-plugin] 25-lazy-integrations skeleton loaded"
