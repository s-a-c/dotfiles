#!/usr/bin/env zsh
# =============================================================================
# 10-legacy-compatibility-shims.zsh
#
# Purpose:
#   Provides minimal function stubs and compatibility layer to satisfy test
#   expectations when running in legacy mode (ZSH_ENABLE_*_REDESIGN=0).
#   These are no-op or delegating functions that don't change behavior.
#
# Behavior:
#   - Only active when redesign flags are disabled (legacy mode)
#   - Provides expected function names that tests look for
#   - Delegates to existing legacy functions where possible
#   - Minimal footprint, easily reversible
#
# Activation:
#   Automatically loaded in legacy mode via .zshrc.d/ 
#
# Removal:
#   Simply delete this file to remove all compatibility shims
# =============================================================================

emulate -L zsh

# Exit early if we're in redesign mode - let redesign modules handle functions
if [[ "${ZSH_ENABLE_POSTPLUGIN_REDESIGN:-0}" == "1" ]]; then
    return 0
fi

# =============================================================================
# Core Functions (zf:: namespace) - Tests expect these in redesign mode
# =============================================================================

# Strategy: If redesign module exists and loads properly, delegate to it
# Otherwise provide minimal compatibility functions

# Try to source the redesign module if it exists and we haven't loaded it yet
if [[ -z "${_LOADED_10_CORE_FUNCTIONS:-}" && -f "$ZDOTDIR/.zshrc.d.REDESIGN/10-core-functions.zsh" ]]; then
    source "$ZDOTDIR/.zshrc.d.REDESIGN/10-core-functions.zsh" 2>/dev/null || true
fi

# Provide fallback functions only if not already defined by redesign module
typeset -f zf::path_dedupe >/dev/null 2>&1 || function zf::path_dedupe() {
    emulate -L zsh
    if typeset -f path_dedupe >/dev/null 2>&1; then
        path_dedupe "$@"
    else
        # Fallback: basic dedup
        typeset -U path PATH
    fi
}

# Core redesign functions (provide fallbacks if not loaded from redesign module)
typeset -f zf::log >/dev/null 2>&1 || function zf::log() {
    emulate -L zsh
    [[ -n "$1" ]] || return 0
    print -- "[zf] $*" >&2
}

typeset -f zf::warn >/dev/null 2>&1 || function zf::warn() {
    emulate -L zsh
    [[ -n "$1" ]] || return 0
    print -- "[zf][WARN] $*" >&2
}

typeset -f zf::debug >/dev/null 2>&1 || function zf::debug() {
    emulate -L zsh
    [[ -n "${ZF_DEBUG:-}" ]] || return 0
    print -- "[zf][dbg] $*" >&2
}

typeset -f zf::ensure_cmd >/dev/null 2>&1 || function zf::ensure_cmd() {
    emulate -L zsh
    local missing=0 c
    for c in "$@"; do
        command -v -- "$c" >/dev/null 2>&1 || { print -- "[zf][WARN] missing command: $c" >&2; missing=1; }
    done
    return $missing
}

typeset -f zf::require >/dev/null 2>&1 || function zf::require() {
    emulate -L zsh
    local c=$1
    local msg=${2:-"required command '$c' not found"}
    if ! command -v -- "$c" >/dev/null 2>&1; then
        print -- "[zf][WARN] $msg" >&2
        return 1
    fi
    return 0
}

typeset -f zf::with_timing >/dev/null 2>&1 || function zf::with_timing() {
    emulate -L zsh
    local seg=$1; shift || true
    # Simple fallback - just execute the command
    "$@"
}

typeset -f zf::timed >/dev/null 2>&1 || function zf::timed() {
    emulate -L zsh
    local seg=$1; shift
    zsh -c "$*"
}

typeset -f zf::list_functions >/dev/null 2>&1 || function zf::list_functions() {
    emulate -L zsh
    typeset -f | grep '^zf::[a-zA-Z0-9_]* ()' | sed 's/ ().*//' | sort
}

# PATH manipulation helpers (fallbacks)
typeset -f zf::path_prepend >/dev/null 2>&1 || function zf::path_prepend() {
    emulate -L zsh
    local p="$1"
    [[ -z "$p" || ! -d "$p" ]] && return 0
    
    # Remove if already present, then prepend
    path=(${path:#$p})
    path=("$p" $path)
    typeset -U path PATH
}

typeset -f zf::path_append >/dev/null 2>&1 || function zf::path_append() {
    emulate -L zsh
    local p="$1"
    [[ -z "$p" || ! -d "$p" ]] && return 0
    
    # Remove if already present, then append
    path=(${path:#$p})
    path=($path "$p")
    typeset -U path PATH
}

typeset -f zf::path_contains >/dev/null 2>&1 || function zf::path_contains() {
    emulate -L zsh
    local needle="$1"
    [[ -z "$needle" ]] && return 1
    
    local d
    for d in $path; do
        [[ "$d" == "$needle" ]] && return 0
    done
    return 1
}

# Script directory helper is already defined in redesign module

# =============================================================================
# SSH Agent Helpers - Tests expect these functions
# =============================================================================

typeset -f ssh_agent_detect >/dev/null 2>&1 || function ssh_agent_detect() {
    emulate -L zsh
    [[ -S "${SSH_AUTH_SOCK:-}" ]] && ssh-add -l >/dev/null 2>&1
}

typeset -f ssh_agent_start >/dev/null 2>&1 || function ssh_agent_start() {
    emulate -L zsh
    # Only actually start if explicitly enabled
    [[ "${ZSH_ENABLE_SSH_AGENT:-0}" == "1" ]] || return 0
    
    command -v ssh-agent >/dev/null || return 1
    eval "$(ssh-agent -s)" >/dev/null 2>&1 || return 1
}

typeset -f ssh_agent_ensure >/dev/null 2>&1 || function ssh_agent_ensure() {
    emulate -L zsh
    ssh_agent_detect || ssh_agent_start
}

typeset -f ssh_add_keys_safe >/dev/null 2>&1 || function ssh_add_keys_safe() {
    emulate -L zsh
    [[ "${ZSH_ENABLE_SSH_AGENT:-0}" == "1" ]] || return 0
    
    command -v ssh-add >/dev/null || return 0
    # Avoid interactive prompts in test environments
    SSH_ASKPASS_REQUIRE=force SSH_ASKPASS=/usr/bin/false ssh-add -l >/dev/null 2>&1 || true
}

# =============================================================================
# Test Environment Helpers
# =============================================================================

# Ensure zsh_debug_echo is available (should already be defined in .zshenv)
typeset -f zsh_debug_echo >/dev/null 2>&1 || function zsh_debug_echo() {
    emulate -L zsh
    echo "$@"
    if [[ "${ZSH_DEBUG:-0}" == "1" && -n "${ZSH_DEBUG_LOG:-}" ]]; then
        print -r -- "$@" >> "$ZSH_DEBUG_LOG"
    fi
}

# =============================================================================
# Legacy Mode Marker
# =============================================================================

# Set a marker that we've loaded legacy compatibility
export _ZSH_LEGACY_COMPATIBILITY_LOADED=1

# Debug output (only if debug enabled)
if [[ "${ZSH_DEBUG:-0}" == "1" ]]; then
    local -a zf_funcs
    zf_funcs=(${(k)functions:#zf::*})
    zsh_debug_echo "# [legacy-compat] Legacy compatibility loaded (${#zf_funcs[@]} zf:: functions)"
    zsh_debug_echo "# [legacy-compat] Core functions: zf::log, zf::warn, zf::debug, zf::ensure_cmd, zf::require, zf::with_timing, zf::timed, zf::list_functions"
    zsh_debug_echo "# [legacy-compat] PATH functions: zf::path_prepend, zf::path_append, zf::path_contains"
    zsh_debug_echo "# [legacy-compat] SSH helpers: ssh_agent_detect, ssh_agent_start, ssh_agent_ensure, ssh_add_keys_safe"
    if [[ -n "${_LOADED_10_CORE_FUNCTIONS:-}" ]]; then
        zsh_debug_echo "# [legacy-compat] Redesign module was loaded successfully"
    else
        zsh_debug_echo "# [legacy-compat] Using fallback compatibility functions"
    fi
fi
