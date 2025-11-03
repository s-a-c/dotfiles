#!/usr/bin/env zsh
# 115-live-segment-capture.zsh
# Phase 7 (Optional Enhancements) – Live segment capture prototype
#
# Purpose:
#   Provide a lightweight, opt‑in instrumentation layer that records
#   timing (and basic metadata) for arbitrary “segments” (initialization
#   units, prompt assembly parts, tool setup blocks) as structured NDJSON.
#
# Activation:
#   Export ZF_SEGMENT_CAPTURE=1 before shell startup (or set and then
#   source this file manually) to enable capture. When disabled the
#   functions become inert no‑ops with near‑zero overhead.
#
# Output:
#   NDJSON lines written to: ${XDG_CACHE_HOME:-$HOME/.cache}/zsh/segments/live-segments.ndjson
#   Each line (prototype schema subset):
#     {
#       "type": "segment",
#       "segment": "<name>",
#       "elapsed_ms": <float>,
#       "ts": "<RFC3339>",
#       "pid": <int>,
#       "layer_set": "<_ZF_LAYER_SET or null>",
#       "shell": "zsh",
#       "version": 1
#     }
#
# Environment / Toggles:
#   ZF_SEGMENT_CAPTURE=1                   Enable capture
#   ZF_SEGMENT_CAPTURE_MIN_MS=<float>      Minimum elapsed (ms) to log (default 0)
#   ZF_SEGMENT_CAPTURE_DIR                 Override output directory
#   ZF_SEGMENT_CAPTURE_FILE                Override full output file path
#   ZF_SEGMENT_CAPTURE_DEBUG=1             Emit debug lines (requires zf::debug or silent fallback)
#   ZF_SEGMENT_CAPTURE_DISABLE_RSS=1       Disable RSS sampling entirely (skip ps invocation)
#   ZF_SEGMENT_CAPTURE_DISABLE_TIME_FALLBACK=1  Do not attempt any alternative time fallback if EPOCHREALTIME absent
#
# Exported Markers:
#   _ZF_SEGMENT_CAPTURE=1|0                Effective enablement
#   _ZF_SEGMENT_CAPTURE_FILE=<path>        Resolved log file (when enabled)
#
# Provided Functions (namespaced):
#   zf::segment_capture_start <name>
#   zf::segment_capture_end   <name> [extra_json_kv_pairs...]
#   zf::segment_capture_wrap  <name> <command...>
#   zf::segment_capture_flush            (no‑op placeholder – future batch mode)
#
# Usage Patterns:
#   1) Manual wrapping:
#        zf::segment_capture_start init:atuin
#        # ... code ...
#        zf::segment_capture_end   init:atuin
#
#   2) One‑shot wrapper:
#        zf::segment_capture_wrap init:starship eval "$(starship init zsh)"
#
#   3) Prompt segment (later integration):
#        PROMPT='$(zf::segment_capture_wrap prompt:build build_prompt_fn)'
#
# Performance Notes:
#   - When disabled: start/end macros exit after a single conditional check.
#   - Timing uses EPOCHREALTIME (floating seconds) => microsecond precision.
#   - No external processes spawned except date (RFC3339) – minimized by
#     caching a per-second timestamp where feasible (simple local cache).
#
# Safety:
#   - Nounset-safe guards everywhere.
#   - Idempotent initialization (re-sourcing safe).
#   - Fails closed (if directory cannot be created, capture auto‑disables).
#
# Future Expansion (post-prototype / D14 proposal):
#   - Add sequence / nesting depth
#   - Correlate to parent segment id
#   - Integrate memory deltas (RSS) optionally
#   - Emit separate "shell_start" baseline event
#   - Batch writing + compression / rotation policy
#
# ------------------------------------------------------------------------------

# Idempotency guard
[[ -n ${_ZF_SEGMENT_CAPTURE_LOADED:-} ]] && return 0
_ZF_SEGMENT_CAPTURE_LOADED=1

# Provide silent debug fallback if framework debug function absent
typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

_zf_seg_dbg() {
  [[ "${ZF_SEGMENT_CAPTURE_DEBUG:-0}" == 1 ]] && zf::debug "[segment-capture] $*"
}

# Resolve enablement
if [[ "${ZF_SEGMENT_CAPTURE:-0}" != 1 ]]; then
  _ZF_SEGMENT_CAPTURE=0
  export _ZF_SEGMENT_CAPTURE
  _zf_seg_dbg "Disabled (ZF_SEGMENT_CAPTURE!=1)"
  # Define inert stubs (lightweight)
  zf::segment_capture_start() { :; }
  zf::segment_capture_end() { :; }
  zf::segment_capture_wrap() {
    shift
    "$@"
  }
  zf::segment_capture_flush() { :; }
  return 0
fi

# Enabled path
_ZF_SEGMENT_CAPTURE=1
export _ZF_SEGMENT_CAPTURE

# Directory + file resolution
: "${ZF_SEGMENT_CAPTURE_DIR:=${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/segments}"
: "${ZF_SEGMENT_CAPTURE_FILE:=${ZF_SEGMENT_CAPTURE_DIR}/live-segments.ndjson}"

# Create directory (best effort)
if ! command mkdir -p -- "${ZF_SEGMENT_CAPTURE_DIR}" 2>/dev/null; then
  _zf_seg_dbg "Failed to create directory; disabling capture"
  _ZF_SEGMENT_CAPTURE=0
  export _ZF_SEGMENT_CAPTURE
fi

# If disabled due to directory failure supply inert stubs
if [[ "${_ZF_SEGMENT_CAPTURE}" != 1 ]]; then
  zf::segment_capture_start() { :; }
  zf::segment_capture_end() { :; }
  zf::segment_capture_wrap() {
    shift
    "$@"
  }
  zf::segment_capture_flush() { :; }
  return 0
fi

# Export final file path marker
_ZF_SEGMENT_CAPTURE_FILE="${ZF_SEGMENT_CAPTURE_FILE}"
export _ZF_SEGMENT_CAPTURE_FILE

# ---------------------------------------------------------------------------
# Log Rotation Configuration (prototype)
#
# Environment / Toggles:
#   ZF_SEGMENT_CAPTURE_ROTATE_MAX_BYTES   Maximum size before rotation (default 1048576 = 1MB)
#   ZF_SEGMENT_CAPTURE_ROTATE_BACKUPS     Number of rotated backups to retain (default 3)
#   ZF_SEGMENT_CAPTURE_ROTATE_DISABLE=1   Disable rotation logic completely
#
# Rotation Strategy:
#   When file size exceeds MAX_BYTES, shift:
#     live-segments.ndjson -> live-segments.ndjson.1
#     live-segments.ndjson.1 -> live-segments.ndjson.2
#     ...
#   Oldest beyond BACKUPS is removed. New events then append to a fresh file.
#
#   Rotation occurs lazily on each segment end (before append) to avoid
#   extra stat calls during start().
#
: "${ZF_SEGMENT_CAPTURE_ROTATE_MAX_BYTES:=1048576}"
: "${ZF_SEGMENT_CAPTURE_ROTATE_BACKUPS:=3}"

_zf_seg_maybe_rotate() {
  [[ "${_ZF_SEGMENT_CAPTURE}" == "1" ]] || return 0
  [[ "${ZF_SEGMENT_CAPTURE_ROTATE_DISABLE:-0}" == "1" ]] && return 0
  local f="${ZF_SEGMENT_CAPTURE_FILE}"
  [[ -n "$f" && -f "$f" ]] || return 0
  local sz
  # Use wc -c to get size; fallback to disable on error
  sz=$(wc -c <"$f" 2>/dev/null || echo 0)
  [[ -z "$sz" ]] && return 0
  # Numeric compare
  if ((sz < ZF_SEGMENT_CAPTURE_ROTATE_MAX_BYTES)); then
    return 0
  fi
  _zf_seg_dbg "rotate trigger file=${f} size=${sz} threshold=${ZF_SEGMENT_CAPTURE_ROTATE_MAX_BYTES}"
  local i
  # Remove oldest
  if ((ZF_SEGMENT_CAPTURE_ROTATE_BACKUPS > 0)); then
    if [[ -f "${f}.${ZF_SEGMENT_CAPTURE_ROTATE_BACKUPS}" ]]; then
      command rm -f -- "${f}.${ZF_SEGMENT_CAPTURE_ROTATE_BACKUPS}" 2>/dev/null || true
    fi
    # Shift higher indexes
    for ((i = ZF_SEGMENT_CAPTURE_ROTATE_BACKUPS - 1; i >= 1; i--)); do
      if [[ -f "${f}.${i}" ]]; then
        command mv -f -- "${f}.${i}" "${f}.$((i + 1))" 2>/dev/null || true
      fi
    done
    # Shift current live file
    command mv -f -- "${f}" "${f}.1" 2>/dev/null || {
      # If move fails, abort rotation to avoid data loss
      _zf_seg_dbg "rotation move failed; aborting"
      return 0
    }
  else
    # No backups retained; just truncate
    if [[ -n "${f}" ]]; then
      : >"${f}" || return 0
    else
      return 0
    fi
  fi
  # Create/truncate fresh file (owner perms inherited by umask)
  if [[ -n "${f}" ]]; then
    : >"${f}" || true
  fi
}

# Internal state: associative array for start times
typeset -gA _ZF_SEGMENT_CAP_START
# RSS start snapshot map (only if sampling succeeds)
typeset -gA _ZF_SEGMENT_CAP_RSS_START
# Optional per-second timestamp cache
typeset -g _ZF_SEGMENT_CAP_TS_CACHE_SEC=""
typeset -g _ZF_SEGMENT_CAP_TS_CACHE_STR=""

# Lightweight RSS sampler (kB). Returns empty string on failure.
_zf_seg_get_rss() {
  # ps is portable enough; rss already in kilobytes on macOS & most *nix when using -o rss
  [[ "${ZF_SEGMENT_CAPTURE_DISABLE_RSS:-0}" == "1" ]] && return 0
  command -v ps >/dev/null 2>&1 || return 0
  command ps -o rss= -p $$ 2>/dev/null | tr -d '[:space:]' || true
}

# Minimum ms threshold
: "${ZF_SEGMENT_CAPTURE_MIN_MS:=0}"

_zf_seg_now() {
  # Return floating seconds from EPOCHREALTIME (already float)
  if [[ "${ZF_SEGMENT_CAPTURE_DISABLE_TIME_FALLBACK:-0}" == "1" && -z "${EPOCHREALTIME:-}" ]]; then
    printf "0"
    return
  fi
  printf "%s" "${EPOCHREALTIME:-0}"
}

_zf_seg_rfc3339() {
  # Cache within the same whole second to avoid repeated date calls
  local now whole
  now="${EPOCHREALTIME:-0}"
  whole="${now%%.*}"
  if [[ "${whole}" != "${_ZF_SEGMENT_CAP_TS_CACHE_SEC}" ]]; then
    # shellcheck disable=SC2016
    _ZF_SEGMENT_CAP_TS_CACHE_STR="$(command date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo 0000-00-00T00:00:00Z)"
    _ZF_SEGMENT_CAP_TS_CACHE_SEC="${whole}"
  fi
  printf "%s" "${_ZF_SEGMENT_CAP_TS_CACHE_STR}"
}

# JSON escape minimal set (quotes + backslashes)
_zf_seg_json_escape() {
  local s="${1:-}"
  # Replace backslash first, then quotes
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf "%s" "${s}"
}

# Public API: start
# zf::segment_capture_start() - moved to .zshenv.00 for global availability

# zf::segment_capture_* functions moved to .zshenv.00 for global availability

# Optional: integrate simple hook examples if user opts in with ZF_SEGMENT_CAPTURE_HOOKS=1
if [[ "${ZF_SEGMENT_CAPTURE_HOOKS:-0}" == 1 ]]; then
  # Wrap starship init if not already loaded (heuristic)
  if [[ -z "${_ZF_STARSHIP_INIT_MS:-}" && -z "${STARSHIP_SHELL:-}" ]]; then
    # Attempt an on-demand capture around starship (non-fatal)
    if command -v starship >/dev/null 2>&1; then
      zf::segment_capture_wrap init:starship eval "$(starship init zsh)" || true
    fi
  fi

  # Hook into precmd for prompt assembly capture (minimal)
  if ! typeset -f zf::segment_capture_precmd >/dev/null 2>&1; then
    zf::segment_capture_precmd() {
      # Acquire prompt build duration (simplistic: measure one cycle)
      zf::segment_capture_start "prompt:build"
    }
    zf::segment_capture_preexec() {
      # Called before executing command; end prompt build window
      zf::segment_capture_end "prompt:build" "phase=preexec"
    }
    # Register hooks only if arrays or add-zsh-hook available
    if typeset -f add-zsh-hook >/dev/null 2>&1; then
      add-zsh-hook precmd zf::segment_capture_precmd
      add-zsh-hook preexec zf::segment_capture_preexec
    fi
  fi
fi

_zf_seg_dbg "Initialized (file=${ZF_SEGMENT_CAPTURE_FILE})"

# End of 115-live-segment-capture.zsh
