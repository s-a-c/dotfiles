#!/opt/homebrew/bin/zsh
# 10-lazy-framework.zsh (Pre-Plugin Redesign Enhanced)
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
[[ -n ${_LOADED_10_LAZY_FRAMEWORK:-} ]] && return
_LOADED_10_LAZY_FRAMEWORK=1
#
# PURPOSE:
#     Generic, test-driven lazy command registration & dispatch system for pre-plugin phase.
#     Replaces earlier skeleton. Implements registry, dispatch, recursion guard, and error paths.
#
# DESIGN GOALS:
#     - Zero cost until first invocation of a registered command.
#     - Deterministic (idempotent) replacement of stub with real implementation.
#     - Clear error codes & messages for negative path tests (see test-lazy-dispatcher-negative.zsh).
#     - Recursion protection: loader invoking the command it is defining should not loop.
#
# ERROR CODES:
#     0 Success
#     1 Usage error (missing args)
#     2 Already registered (no change)
#     3 Loader function not found
#     4 Loader execution failed (non-zero exit)
#     5 Recursion detected
#     6 Loader did not define target function
#
# REGISTRY STRUCTURE:
#     _LAZY_REGISTRY[cmd]    = loader_function_name
#     _LAZY_STATE[cmd]         = one of: registered | loading | loaded | failed
#
# PUBLIC API:
#   lazy_register [-f|--force] <cmd> <loader-func>
#     lazy_dispatch    (internal, invoked by generated stubs)
#     is_lazy_registered <cmd>
#     is_lazy_loaded <cmd>
#     list_lazy_commands
#
# TEST HOOKS:
#     Negative path test expects:
#         - Recursion guard emits 'RECURSION_GUARD' substring
#         - Missing loader error contains 'no loader'
#         - Failing loader sets state=failed and exits non-zero
#         - Stub not replaced on failure
#
typeset -gA _LAZY_REGISTRY
typeset -gA _LAZY_STATE
typeset -gA _LAZY_ERRORS
typeset -g    _LAZY_LAST # last dispatched command (debug aid)

# Optional debug echo (noop if not defined elsewhere)
typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }

# Register a command for lazy loading.
# Supports optional -f|--force flag to override an existing command/binary.
# When forced, an existing function definition is removed (unfunction) and a stub
# is installed even if a binary exists earlier in PATH. This allows layering a
# lazy wrapper over an already-installed external tool (e.g., direnv, gh).
lazy_register() {
  local force=0
  # Flag parsing
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f|--force) force=1; shift ;;
      --) shift; break ;;
      -*) zsh_debug_echo "# [lazy] unknown flag '$1' (ignored)"; shift ;;
      *) break ;;
    esac
  done
  local cmd="$1" loader="$2"
  if [[ -z $cmd || -z $loader ]]; then
    zsh_debug_echo "# [lazy] usage error: lazy_register [-f|--force] <cmd> <loader>"
    return 1
  fi
  # If command already exists and not forcing, skip.
  if command -v -- "$cmd" >/dev/null 2>&1 && (( ! force )); then
    zsh_debug_echo "# [lazy] skip '$cmd' (already available; use --force to override)"
    return 0
  fi
  # If already registered (and not forcing a re-wrap), idempotent.
  if [[ -n ${_LAZY_REGISTRY[$cmd]:-} && ! $force -eq 1 ]]; then
    zsh_debug_echo "# [lazy] already registered '$cmd'"
    return 2
  fi
  # Verify loader function presence.
  if ! typeset -f -- "$loader" >/dev/null 2>&1; then
    zsh_debug_echo "# [lazy] loader '$loader' not found for '$cmd'"
    return 3
  fi
  # If forcing and an existing function definition is present, remove it so the stub wins.
  if (( force )) && typeset -f -- "$cmd" >/dev/null 2>&1; then
    unfunction "$cmd" 2>/dev/null || true
    zsh_debug_echo "# [lazy] force override applied to '$cmd'"
  fi
  _LAZY_REGISTRY[$cmd]="$loader"
  _LAZY_STATE[$cmd]="registered"

  # Generate stub (always overwrite when forcing)
  eval "
${cmd}() {
  lazy_dispatch '${cmd}' \"\$@\"
}
"
  if (( force )); then
    zsh_debug_echo "# [lazy] registered (forced) '$cmd' -> loader '$loader'"
  else
    zsh_debug_echo "# [lazy] registered '$cmd' -> loader '$loader'"
  fi
  return 0
}

# Internal dispatcher invoked by generated stubs.
lazy_dispatch() {
    local cmd="$1"; shift || true
    _LAZY_LAST="$cmd"

    # Ensure registered
    if [[ -z ${_LAZY_REGISTRY[$cmd]:-} ]]; then
        print -u2 "Error: no loader registered for '$cmd'"
        _LAZY_ERRORS[$cmd]="no loader"
        return 3
    fi

    local state="${_LAZY_STATE[$cmd]:-registered}"
    local loader="${_LAZY_REGISTRY[$cmd]}"

    case "$state" in
        loaded)
            # Directly call real implementation
            if typeset -f -- "$cmd" >/dev/null 2>&1 && ! function_body_contains_lazy_dispatch "$cmd"; then
                "$cmd" "$@"
                return $?
            fi
            # Fallback if for some reason body still stub
            ;;
        loading)
            print -u2 "Error: recursion detected while loading '$cmd' (RECURSION_GUARD)"
            _LAZY_STATE[$cmd]="failed"
            _LAZY_ERRORS[$cmd]="recursion"
            return 5
            ;;
        failed)
            print -u2 "Error: prior load failed for '$cmd'"
            return 4
            ;;
    esac

    # Mark as loading
    _LAZY_STATE[$cmd]="loading"

    # Execute loader
    if ! typeset -f -- "$loader" >/dev/null 2>&1; then
        print -u2 "Error: loader '$loader' missing for '$cmd'"
        _LAZY_STATE[$cmd]="failed"
        _LAZY_ERRORS[$cmd]="loader disappeared"
        return 3
    fi

    # Run loader in current shell so it can define the function.
    "$loader" "$cmd" || {
        _LAZY_STATE[$cmd]="failed"
        _LAZY_ERRORS[$cmd]="loader exit"
        print -u2 "Error: loader failed for '$cmd'"
        return 4
    }

    # Loader success; verify real function now defined & replace stub body if still referencing dispatcher
    if ! typeset -f -- "$cmd" >/dev/null 2>&1; then
        _LAZY_STATE[$cmd]="failed"
        _LAZY_ERRORS[$cmd]="no function defined"
        print -u2 "Error: lazy loader failed to define function '$cmd'"
        return 6
    fi

    # After successful load update state
    _LAZY_STATE[$cmd]="loaded"

    # Call real function
    "$cmd" "$@"
}

# Helper: determine if function body still contains lazy_dispatch (stub not replaced)
function_body_contains_lazy_dispatch() {
    local fname="$1"
    local body
    body="$(functions "$fname" 2>/dev/null || true)"
    [[ $body == *"lazy_dispatch"* ]]
}

is_lazy_registered() {
    local cmd="$1"
    [[ -n ${_LAZY_REGISTRY[$cmd]:-} ]]
}

is_lazy_loaded() {
    local cmd="$1"
    [[ ${_LAZY_STATE[$cmd]:-} == "loaded" ]]
}

list_lazy_commands() {
    local k
    for k in "${(@k)_LAZY_REGISTRY}"; do
        print -- "$k:${_LAZY_STATE[$k]:-unknown}:${_LAZY_REGISTRY[$k]}"
    done
}

# Backwards compatibility alias (original minimal API)
register_lazy() { lazy_register "$@"; }

zsh_debug_echo "# [pre-plugin] 10-lazy-framework enhanced loaded (count=${#_LAZY_REGISTRY[@]})"
