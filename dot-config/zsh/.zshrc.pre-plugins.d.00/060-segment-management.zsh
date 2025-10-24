#!/usr/bin/env zsh
# 050-segment-management.zsh - Segment Library Loader for ZSH REDESIGN v2
# Phase 1C: Performance Monitoring Infrastructure
# NOTE: Core segment functions (zf::segment, zf::add_segment, etc.) have been
#       moved to .zshenv to ensure availability during zgenom save.
#       This file now only loads the optional advanced segment library.

# -----------------------------------------------------------------------------
# DEFERRED INSTRUMENTATION NOTICE (Breadcrumb)
# -----------------------------------------------------------------------------
# Segment processing / expanded management (wrappers, JSON aggregation, per-module
# emission beyond current passive helpers) is intentionally DEFERRED.
# Do NOT add new wrappers or JSON exporters in active phases (4–7) without
# creating a proposal under docs/fix-zle/segment-instrumentation-proposal.md and
# obtaining explicit approval.
#
# Reserved namespaces (future):
#   plugin/<name>, env/<name>, prod/<name>, neovim/<name>, term/<name>, ux/<name>
# Activation modes (draft – not yet implemented): off|light|full
#   off  : current state (no extra emission unless PERF_SEGMENT_LOG manually set)
#   light: tripod aggregate (pre_plugin_total, post_plugin_total, prompt_ready)
#   full : per-module + themed probes
#
# This breadcrumb documents deferral only; functional behavior unchanged.
# -----------------------------------------------------------------------------

# Core segment functions are now in .zshenv:
#   - zf::debug()
#   - zf::now_ms()
#   - zf::segment_fallback()
#   - zf::segment()
#   - zf::pre_segment()
#   - zf::add_segment()
#   - zf::post_segment()
#
# This ensures they are available during zgenom save (plugin cache regeneration).

# Resolve ZDOTDIR fallback (nounset safe) – default to repo root if absent
_zf_seg_zdotdir="${ZDOTDIR:-${HOME}/.config/zsh}"

# Load advanced segment library if available (optional enhancement)
# The segment library provides _zsh_perf_segment_* functions for enhanced tracking
if [[ -f "${_zf_seg_zdotdir}/tools/segment-lib.zsh" ]]; then
  # shellcheck disable=SC1090
  source "${_zf_seg_zdotdir}/tools/segment-lib.zsh" || true
  zf::debug "# [segment-management] Advanced segment library loaded"
else
  zf::debug "# [segment-management] Advanced segment library not found - using fallback (from .zshenv)"
fi

zf::debug "# [segment-management] Segment management initialized (core functions in .zshenv)"

# Always succeed when sourced (test harness expects non-fatal behavior)
return 0
