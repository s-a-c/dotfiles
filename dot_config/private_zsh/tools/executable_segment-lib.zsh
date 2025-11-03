#!/usr/bin/env zsh
# segment-lib.zsh
# Compliant with [${HOME}/.config/ai/guidelines.md](${HOME}/.config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Unified lightweight timing + emission helper used by redesigned pre/post plugin
#   instrumentation and deeper hotspot probes (compinit, p10k, gitstatus, etc.).
#
# DESIGN GOALS:
#   - Zero external processes for steady‑state (only awk used when converting realtime).
#   - Idempotent start/end (multiple end calls are ignored).
#   - Generic SEGMENT line emission for future perf-diff tooling:
#       SEGMENT name=<label> ms=<duration_ms> phase=<phase> sample=<context>
#     Where:
#       phase   = pre_plugin | post_plugin | prompt | other (caller provided / default other)
#       sample  = cold | warm | unknown (auto from $PERF_SAMPLE_CONTEXT if set)
#
# RELATION TO EXISTING MARKERS:
#   Existing coarse markers (PRE_PLUGIN_COMPLETE, POST_PLUGIN_COMPLETE, POST_PLUGIN_SEGMENT, PROMPT_READY_COMPLETE)
#   will remain for backward compatibility; this library enables finer granularity and a unified schema.
#
# USAGE (basic):
#   _zsh_perf_segment_start compinit post_plugin
#   # ... run compinit ...
#   _zsh_perf_segment_end compinit   # phase inferred from start map
#
# WRAP HELPER:
#   _zsh_perf_segment_wrap compinit post_plugin -- compinit -C
#
# OPTIONAL GUIDELINES CHECKSUM EXPORT:
#   If GUIDELINES_CHECKSUM not already set, callers may invoke:
#       _zsh_perf_export_guidelines_checksum
#   which shells out once to tools/guidelines-checksum.sh (if present) or inline hashes
#   (inline path fallback kept intentionally simple; prefer script for canonical value).
#
# ENVIRONMENT VARIABLES:
#   PERF_SEGMENT_LOG          Path to append markers (if unset, emission is skipped silently).
#   PERF_SAMPLE_CONTEXT       User / harness sets to 'cold' or 'warm' (else 'unknown').
#
# OUTPUT LINES (examples):
#   SEGMENT name=compinit ms=1234 phase=post_plugin sample=cold
#   SEGMENT name=p10k_theme ms=842 phase=post_plugin sample=warm
#
# STABILITY / SAFETY:
#   - No mutation of positional parameters.
#   - Does not modify options (setopt) globally.
#
# FUTURE EXTENSIONS:
#   - Aggregated stdev/count accumulation
#   - JSON sidecar emission
#   - Nested segment hierarchical IDs
#
# ------------------------------------------------------------------------------

# Guard against double sourcing
[[ -n ${_ZSH_SEGMENT_LIB_LOADED:-} ]] && return
_ZSH_SEGMENT_LIB_LOADED=1

typeset -gA _ZSH_SEGMENT_START_MS   # label -> start_ms
typeset -gA _ZSH_SEGMENT_PHASE      # label -> phase
typeset -gA _ZSH_SEGMENT_DONE       # label -> 1 (ended)

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# Internal: now (ms) using EPOCHREALTIME
_zsh_perf_now_ms() {
  # Use awk only (fast, already used elsewhere)
  # EPOCHREALTIME example: 1725234567.123456789
  [[ -z ${EPOCHREALTIME:-} ]] && { zmodload zsh/datetime 2>/dev/null || true; }
  local rt=$EPOCHREALTIME
  [[ -z $rt ]] && echo "" && return 0
  printf '%s' "$rt" | awk -F. '{ms=($1*1000); if(NF>1){ms+=substr($2"000",1,3)+0} printf "%d", ms}'
}

# Public: start a segment
# Args:
#   $1 label   (required, normalized to lowercase with dashes preserved)
#   $2 phase   (optional: pre_plugin|post_plugin|prompt|other) default other
_zsh_perf_segment_start() {
  local label="$1"
  local phase="${2:-other}"
  [[ -z $label ]] && return 0
  # Normalize label (avoid spaces)
  label=${label// /_}

  # Ignore if already started
  if [[ -n ${_ZSH_SEGMENT_START_MS[$label]:-} ]]; then
    return 0
  fi

  local now
  now=$(_zsh_perf_now_ms)
  [[ -z $now ]] && return 0

  _ZSH_SEGMENT_START_MS[$label]=$now
  _ZSH_SEGMENT_PHASE[$label]=$phase
  unset "_ZSH_SEGMENT_DONE[$label]"
  zf::debug "# [segment-lib][start] label=$label phase=$phase ms=$now"
}

# Public: end a segment and emit
# Args:
#   $1 label (required)
#   $2 (optional) override phase (if provided)
_zsh_perf_segment_end() {
  local label="$1"
  local phase_override="${2:-}"
  [[ -z $label ]] && return 0
  label=${label// /_}

  # If not started or already ended, ignore
  [[ -z ${_ZSH_SEGMENT_START_MS[$label]:-} ]] && return 0
  [[ -n ${_ZSH_SEGMENT_DONE[$label]:-} ]] && return 0

  local end_ms start_ms delta phase
  end_ms=$(_zsh_perf_now_ms)
  start_ms=${_ZSH_SEGMENT_START_MS[$label]}
  [[ -z $end_ms || -z $start_ms ]] && return 0
  (( delta = end_ms - start_ms ))
  [[ -n $phase_override ]] && _ZSH_SEGMENT_PHASE[$label]=$phase_override
  phase=${_ZSH_SEGMENT_PHASE[$label]:-other}

  _ZSH_SEGMENT_DONE[$label]=1

  local sample="${PERF_SAMPLE_CONTEXT:-unknown}"

  # Emit generic SEGMENT line (for perf-diff future)
  if [[ -n ${PERF_SEGMENT_LOG:-} && -w ${PERF_SEGMENT_LOG:-/dev/null} ]]; then
    # Format: SEGMENT name=<label> ms=<delta> phase=<phase> sample=<sample>
    print "SEGMENT name=${label} ms=${delta} phase=${phase} sample=${sample}" >>"${PERF_SEGMENT_LOG}" 2>/dev/null || true
  fi

  # For backward compatibility: If phase == post_plugin and we are in redesign context,
  # also emit legacy POST_PLUGIN_SEGMENT line (only if not already emitted externally)
  if [[ $phase == post_plugin && -n ${PERF_SEGMENT_LOG:-} ]]; then
    # Avoid collision with existing module labels by checking pattern
    if [[ $label != POST_PLUGIN_SEGMENT* ]]; then
      print "POST_PLUGIN_SEGMENT ${label} ${delta}" >>"${PERF_SEGMENT_LOG}" 2>/dev/null || true
    fi
  fi

  zf::debug "# [segment-lib][end] label=$label phase=$phase delta=${delta}ms sample=$sample"
}

# Public: wrap helper
# Usage: _zsh_perf_segment_wrap <label> [phase] -- <command> [args...]
_zsh_perf_segment_wrap() {
  local label phase cmd
  label="$1"; shift || return 1
  phase="$1"
  if [[ "$phase" == "--" ]]; then
    phase="other"
  else
    shift || return 1
  fi
  [[ "$1" == "--" ]] && shift
  [[ -z "$label" || -z "$1" ]] && return 1

  _zsh_perf_segment_start "$label" "$phase"
  "$@"
  local rc=$?
  _zsh_perf_segment_end "$label" "$phase"
  return $rc
}

# ------------------------------------------------------------------------------
# GUIDELINES CHECKSUM SUPPORT
# ------------------------------------------------------------------------------

# Compute (or retrieve) the policy guidelines checksum and export GUIDELINES_CHECKSUM.
# Strategy:
#   1. If already exported, no-op.
#   2. If tools/guidelines-checksum.sh exists and executable: call it directly.
#   3. Fallback inline (best-effort) hashing using available tool.
_zsh_perf_export_guidelines_checksum() {
  [[ -n ${GUIDELINES_CHECKSUM:-} ]] && return 0

  local base_root
  # Try to infer dot-config/ai root:
  # Current file path environment: ${(%):-%x} provides source path for current script if called via source.
  # If not available, fallback to $ZDOTDIR heuristics.
  local this="${(%):-%x}"
  if [[ -n $this && -f $this ]]; then
    base_root=$(dirname "$this")/../ai
    base_root=$(builtin cd -q "$base_root" 2>/dev/null && pwd || echo "")
  fi
  if [[ -z $base_root || ! -d $base_root ]]; then
    base_root="${ZDOTDIR:-$HOME/.config/zsh}/../ai"
  fi

  local checksum_script
  checksum_script="${ZDOTDIR:-$HOME/.config/zsh}/tools/guidelines-checksum.sh"
  if [[ ! -x $checksum_script ]]; then
    # Also try relative to this script if sourced directly from repo
    checksum_script="$(dirname "${(%):-%x}")/guidelines-checksum.sh"
  fi

  local cs=""
  if [[ -x $checksum_script ]]; then
    cs=$("$checksum_script" 2>/dev/null | head -1 | tr -d '[:space:]')
  else
    # Inline fallback: rough equivalence (master + sorted modules)
    local master="${base_root%/}/guidelines.md"
    local modules_dir="${base_root%/}/guidelines"
    if [[ -f $master && -d $modules_dir ]]; then
      local hasher=""
      if command -v shasum >/dev/null 2>&1; then
        hasher="shasum -a 256"
      elif command -v sha256sum >/dev/null 2>&1; then
        hasher="sha256sum"
      elif command -v openssl >/dev/null 2>&1; then
        hasher="openssl dgst -sha256"
      fi
      if [[ -n $hasher ]]; then
        if [[ $hasher == "openssl dgst -sha256" ]]; then
          cs=$( (cat "$master"; find "$modules_dir" -type f -print | LC_ALL=C sort | xargs cat) | openssl dgst -sha256 | awk '{print $2}')
        else
          cs=$( (cat "$master"; find "$modules_dir" -type f -print | LC_ALL=C sort | xargs cat) | $hasher | awk '{print $1}')
        fi
      fi
    fi
  fi

  [[ -n $cs ]] && GUIDELINES_CHECKSUM="$cs" && export GUIDELINES_CHECKSUM

  if [[ -n ${PERF_SEGMENT_LOG:-} && -n ${GUIDELINES_CHECKSUM:-} && ! -f ${_GUIDELINES_MARK_EMITTED:-} ]]; then
    print "POLICY checksum=${GUIDELINES_CHECKSUM}" >>"${PERF_SEGMENT_LOG}" 2>/dev/null || true
  fi

  zf::debug "# [segment-lib][policy] GUIDELINES_CHECKSUM=${GUIDELINES_CHECKSUM:-unset}"
}

# Convenience one-shot public alias
zsh_export_guidelines_checksum() { _zsh_perf_export_guidelines_checksum "$@"; }

# ------------------------------------------------------------------------------
# HIGH-LEVEL INSTRUMENTATION HELPERS (OPTIONAL ADAPTERS)
# ------------------------------------------------------------------------------

# Instrument compinit (caller supplies flags). Emits segment 'compinit'.
# Usage:
#   _zsh_perf_instrument_compinit -C   # example flag
_zsh_perf_instrument_compinit() {
  # Only run if compinit available and not already executed (heuristics)
  autoload -Uz compinit 2>/dev/null || return 0
  if [[ -n ${ZSH_COMPINIT_RAN:-} || -n ${_COMPINIT_INITIALIZED:-} ]]; then
    zf::debug "# [segment-lib][compinit] already ran (skipping instrumentation)"
    return 0
  fi
  local label="compinit"
  _zsh_perf_segment_start "$label" post_plugin
  compinit "$@"
  local rc=$?
  ZSH_COMPINIT_RAN=1
  export ZSH_COMPINIT_RAN
  _zsh_perf_segment_end "$label" post_plugin
  return $rc
}

# Instrument Powerlevel10k theme sourcing (~p10k).
# Usage:
#   _zsh_perf_instrument_p10k "$HOME/.p10k.zsh"
_zsh_perf_instrument_p10k() {
  local p10k_file="$1"
  [[ -z $p10k_file || ! -r $p10k_file ]] && return 0
  # Avoid double load if PROMPT already defined in expected way
  if [[ -n ${_P10K_THEME_LOADED:-} ]]; then
    return 0
  fi
  local label="p10k_theme"
  _zsh_perf_segment_start "$label" post_plugin
  source "$p10k_file"
  local rc=$?
  _P10K_THEME_LOADED=1
  export _P10K_THEME_LOADED
  _zsh_perf_segment_end "$label" post_plugin
  return $rc
}

# Generic probe for arbitrary file sourcing:
#   _zsh_perf_source_probe label path [phase]
# Example:
#   _zsh_perf_source_probe gitstatus "$HOME/.cache/gitstatus/gitstatus.plugin.zsh" post_plugin
_zsh_perf_source_probe() {
  local label="$1"
  local path="$2"
  local phase="${3:-post_plugin}"
  [[ -z $label || -z $path || ! -r $path ]] && return 0
  _zsh_perf_segment_start "$label" "$phase"
  source "$path"
  local rc=$?
  _zsh_perf_segment_end "$label" "$phase"
  return $rc
}

# ------------------------------------------------------------------------------
# OPTIONAL: Auto-export guidelines checksum early (can be disabled by setting
#           ZSH_SEGMENT_LIB_SKIP_POLICY=1 before sourcing).
# ------------------------------------------------------------------------------
if [[ "${ZSH_SEGMENT_LIB_SKIP_POLICY:-0}" != "1" ]]; then
  _zsh_perf_export_guidelines_checksum
fi

zf::debug "# [segment-lib] loaded (policy=${GUIDELINES_CHECKSUM:-unset})"

# End of segment-lib.zsh
