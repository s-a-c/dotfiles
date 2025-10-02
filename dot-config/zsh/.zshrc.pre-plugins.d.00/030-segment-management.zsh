#!/usr/bin/env zsh
# 030-segment-management.zsh - Unified Segment Management for ZSH REDESIGN v2
# Phase 1C: Performance Monitoring Infrastructure
# Provides segment timing for all plugin phases with consistent naming
# NOTE: Header number corrected from an earlier mislabel (025) to match actual
#       filename and sequence; see plan-of-attack.md (segment instrumentation deferred).

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

# Ensure minimal debug helper exists (avoid non-zero return if undefined)
typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# Resolve ZDOTDIR fallback (nounset safe) – default to repo root if absent
_zf_seg_zdotdir="${ZDOTDIR:-${HOME}/.config/zsh}"

# Load segment library if available (do not fail if unreadable)
if [[ -f "${_zf_seg_zdotdir}/tools/segment-lib.zsh" ]]; then
  # shellcheck disable=SC1090
  source "${_zf_seg_zdotdir}/tools/segment-lib.zsh" || true
  zf::debug "# [segment-mgmt] Segment library loaded"
else
  zf::debug "# [segment-mgmt] Segment library not found - using fallback"
fi

# Unified segment helper for all plugin phases
# Usage: zf::segment <module_name> <action> [phase]
# Example: zf::segment "perf-core" "start" "add_plugin"
zf::segment() {
  local module_name="$1" action="$2" phase="${3:-other}"
  [[ -z "$module_name" || -z "$action" ]] && return 0

  # Normalize module name (consistent with file naming)
  module_name=${module_name// /-}
  local segment_label="plugin/${module_name}"

  if typeset -f _zsh_perf_segment_${action} >/dev/null 2>&1; then
    # Use full segment library
    _zsh_perf_segment_${action} "$segment_label" "$phase"
  else
    # Fallback timing system
    zf::segment_fallback "$module_name" "$action" "$phase"
  fi
}

# Fallback segment timing (when segment-lib not available)
typeset -gA _ZF_SEGMENT_START
zf::segment_fallback() {
  local module_name="$1" action="$2" phase="$3"
  local key="${module_name}_${phase}"

  if [[ "$action" == "start" ]]; then
    _ZF_SEGMENT_START[$key]=$(zf::now_ms)
    zf::debug "# [segment-fallback] Started: plugin/${module_name} phase=${phase}"
  elif [[ "$action" == "end" && -n ${_ZF_SEGMENT_START[$key]:-} ]]; then
    local end_ms=$(zf::now_ms)
    local delta=$((end_ms - _ZF_SEGMENT_START[$key]))
    ((delta < 0)) && delta=0

    # Emit segment data if logging enabled
    if [[ -n "${PERF_SEGMENT_LOG:-}" ]]; then
      print "SEGMENT name=plugin/${module_name} ms=${delta} phase=${phase} sample=${PERF_SAMPLE_CONTEXT:-unknown}" >>"${PERF_SEGMENT_LOG}" 2>/dev/null || true
    fi

    zf::debug "# [segment-fallback] Completed: plugin/${module_name} phase=${phase} delta=${delta}ms"
    unset "_ZF_SEGMENT_START[$key]"
  fi
}

# Millisecond timestamp helper
zf::now_ms() {
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "import time; print(int(time.time() * 1000))"
  elif command -v node >/dev/null 2>&1; then
    node -e "console.log(Date.now())"
  elif command -v perl >/dev/null 2>&1; then
    perl -MTime::HiRes=time -E 'say int(time*1000)'
  else
    # Fallback to seconds * 1000
    echo $(($(date +%s) * 1000))
  fi
}

# Phase-specific segment helpers for consistent usage
zf::pre_segment() { zf::segment "$1" "$2" "pre_plugin"; }
zf::add_segment() { zf::segment "$1" "$2" "add_plugin"; }
zf::post_segment() { zf::segment "$1" "$2" "post_plugin"; }

zf::debug "# [segment-mgmt] Unified segment management initialized"

# Always succeed when sourced (test harness expects non-fatal behavior)
return 0
