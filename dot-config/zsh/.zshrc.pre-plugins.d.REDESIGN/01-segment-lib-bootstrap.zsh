#!/usr/bin/env zsh
# 01-segment-lib-bootstrap.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Ensure the unified performance instrumentation helper (tools/segment-lib.zsh)
#   is sourced at the earliest safe point in the redesigned pre‑plugin sequence
#   so that subsequent instrumentation modules (compinit, p10k, gitstatus, async,
#   etc.) can emit normalized SEGMENT lines instead of per‑file fallback logic.
#
# RATIONALE:
#   - Some modules include defensive fallbacks if segment-lib was not yet loaded.
#     Early guaranteed sourcing reduces drift and duplication.
#   - Centralizes the environment / feature flag used to opt-out during certain
#     tests or minimal shells (e.g. benchmarking raw zsh startup without helpers).
#
# FEATURES:
#   - Idempotent: no error if already sourced elsewhere.
#   - Silent on failure: absence of the library does NOT abort shell startup.
#   - Optional policy checksum auto-export (segment-lib handles internally).
#
# OPT-OUT / FLAGS:
#   ZSH_SKIP_SEGMENT_LIB=1        Skip sourcing entirely.
#   ZSH_SEGMENT_LIB_SKIP_POLICY=1 Prevent automatic policy checksum export (pass‑through).
#
# DEBUG:
#   If a global debug helper zsh_debug_echo is defined, emits lightweight traces.
#
# SECURITY / SAFETY:
#   - Only reads a repository-local path under $ZDOTDIR/tools.
#   - Does not modify shell options globally.
#
# FUTURE:
#   - Could evolve to perform version / checksum validation of the helper.
#   - Hook in a deferred self-test (SEGMENT sanity) if a debug flag is set.
#
# ------------------------------------------------------------------------------

# Quick return if user explicitly skipped
if [[ "${ZSH_SKIP_SEGMENT_LIB:-0}" == "1" ]]; then
  return 0
fi

typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }

# If already loaded (library exports _ZSH_SEGMENT_LIB_LOADED) we are done
if [[ -n ${_ZSH_SEGMENT_LIB_LOADED:-} ]]; then
    zsh_debug_echo "# [segment-lib-bootstrap] already loaded (early exit)"
    return 0
fi

# Resolve library path (if not already resolved)
if [[ -z ${_ZSH_SEGMENT_LIB_PATH:-} ]]; then
    _ZSH_SEGMENT_LIB_PATH="${ZDOTDIR:-${HOME}/.config/zsh}/tools/segment-lib.zsh"
fi

# Source the library if it exists
if [[ -f "${_ZSH_SEGMENT_LIB_PATH}" ]]; then
    source "${_ZSH_SEGMENT_LIB_PATH}"
else
    zsh_debug_echo "# [segment-lib-bootstrap] library not found at ${_ZSH_SEGMENT_LIB_PATH}"
fi
