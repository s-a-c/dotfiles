#!/usr/bin/env zsh
# 10-core-functions.zsh
# Stage 3 – Core Function Namespace (zf::*)
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Provides a minimal, consolidated set of foundational helper functions for
#   later redesigned modules. Must remain:
#     - Lightweight (no heavy spawning)
#     - Idempotent (safe re-source)
#     - Side-effect minimal (no unsolicited I/O)
#
# SCOPE (current):
#   - Logging helpers: zf::log / zf::warn
#   - Command presence guard: zf::ensure_cmd
#   - Assertion utility: zf::require
#   - Lightweight timing wrapper: zf::with_timing (optional segment emit)
#
# Deferred (later stages):
#   - Extended logging levels (trace/info/error with routing)
#   - Structured event emission
#   - Integration with async dispatcher
#
# TEST HOOKS (planned):
#   - Namespace uniqueness test enumerates zf::* symbols
#   - Idempotency test ensures second source does not alter PATH, functions, or state
#
# ENV / INTEGRATION:
#   - If PERF_SEGMENT_LOG is set (segment-lib convention) AND ZF_WITH_TIMING_SEGMENTS=1,
#     zf::with_timing will append a SEGMENT line (phase=core, sample=inline).
#
# CHANGE CONTROL:
#   - Any addition/removal of exported functions must update the Stage 3 progress
#     tracking in IMPLEMENTATION.md and adjust CORE_FN_MIN_EXPECT (test harness).
#
if [[ -n "${_LOADED_10_CORE_FUNCTIONS:-}" ]]; then
  return 0
fi
_LOADED_10_CORE_FUNCTIONS=1

# ------------------------------
# Internal State / Constants
# ------------------------------
: ${ZF_LOG_PREFIX:="[zf]"}
: ${ZF_WARN_PREFIX:="[zf][WARN]"}
# Structured telemetry flags (Sprint 2 stubs)
: ${ZSH_LOG_STRUCTURED:=0}
: ${ZSH_PERF_JSON:=0}
# If JSON perf snapshot requested and no explicit path provided, derive sidecar file name
if [[ "${ZSH_PERF_JSON}" == "1" && -z "${PERF_SEGMENT_JSON_LOG:-}" && -n "${PERF_SEGMENT_LOG:-}" ]]; then
  PERF_SEGMENT_JSON_LOG="${PERF_SEGMENT_LOG%.log}.jsonl"
fi

# Allow external toggle for debug verbosity
: ${ZF_DEBUG:=}

# ------------------------------
# Logging
# ------------------------------
zf::log() {
  # Usage: zf::log "message"
  [[ -n "$1" ]] || return 0
  print -- "${ZF_LOG_PREFIX} $*" >&2
}

zf::warn() {
  # Usage: zf::warn "message"
  [[ -n "$1" ]] || return 0
  print -- "${ZF_WARN_PREFIX} $*" >&2
}

# Debug helper (silent unless ZF_DEBUG set)
zf::debug() {
  [[ -n "${ZF_DEBUG:-}" ]] || return 0
  print -- "${ZF_LOG_PREFIX}[dbg] $*" >&2
}

# ------------------------------
# Command Guard
# ------------------------------
zf::ensure_cmd() {
  # Ensures each provided command exists in PATH.
  # Returns 0 if all present, 1 otherwise.
  # Example: zf::ensure_cmd git curl
  local missing=0 c
  for c in "$@"; do
    command -v -- "$c" >/dev/null 2>&1 || { zf::warn "missing command: $c"; missing=1; }
  done
  return $missing
}

# Assert a command (fail hard with message)
zf::require() {
  # Usage: zf::require <command> [message]
  local c=$1
  local msg=${2:-"required command '$c' not found"}
  if ! command -v -- "$c" >/dev/null 2>&1; then
    zf::warn "$msg"
    return 1
  fi
  return 0
}

# ------------------------------
# Timing / Segment Wrapper
# ------------------------------
# Lightweight timing using EPOCHREALTIME (zsh builtin)
# Usage:
#   zf::with_timing segment_name some_command arg1 arg2
# Captures elapsed ms; if PERF_SEGMENT_LOG + ZF_WITH_TIMING_SEGMENTS=1 are set,
# emits a SEGMENT line (compatible with existing perf tooling).
zf::with_timing() {
  local seg=$1; shift || true
  [[ -n "$seg" ]] || seg="anon"
  local start end elapsed_ms
  if [[ -n ${EPOCHREALTIME:-} ]]; then
    start=$EPOCHREALTIME
  else
    # Fallback: date +%s%3N (Linux) or perl for macOS if needed; keep minimal
    start=$(date +%s.%N 2>/dev/null || date +%s 2>/dev/null)
  fi

  # Execute payload
  "$@" 2>&1
  local rc=$?

  if [[ -n ${EPOCHREALTIME:-} ]]; then
    end=$EPOCHREALTIME
    # Compute (floating) ms
    elapsed_ms=$(awk -v s="$start" -v e="$end" 'BEGIN{printf "%.0f", (e - s)*1000}')
  else
    end=$(date +%s.%N 2>/dev/null || date +%s 2>/dev/null)
    elapsed_ms=$(awk -v s="$start" -v e="$end" 'BEGIN{printf "%.0f", (e - s)*1000}')
  fi

  if [[ -n "${PERF_SEGMENT_LOG:-}" && "${ZF_WITH_TIMING_SEGMENTS:-0}" == "1" ]]; then
    {
      print -- "SEGMENT name=${seg} ms=${elapsed_ms} phase=core sample=inline"
    } >> "${PERF_SEGMENT_LOG}" 2>/dev/null || true
    # Structured telemetry (opt-in, zero overhead when disabled)
    if [[ "${ZSH_LOG_STRUCTURED:-0}" == "1" && -w ${PERF_SEGMENT_JSON_LOG:-${PERF_SEGMENT_LOG:-/dev/null}} ]]; then
      # Minimal JSON payload (privacy appendix governs future field expansion)
      # Fields: type, name, ms, phase, sample, ts (epoch ms)
      local __ts
      if [[ -n ${EPOCHREALTIME:-} ]]; then
        __ts=$(awk -v t="${EPOCHREALTIME}" 'BEGIN{split(t,a,"."); printf "%s%03d", a[1], substr(a[2]"000",1,3)}')
      else
        __ts="$(date +%s 2>/dev/null || printf 0)000"
      fi
      print -- "{\"type\":\"segment\",\"name\":\"${seg}\",\"ms\":${elapsed_ms},\"phase\":\"core\",\"sample\":\"inline\",\"ts\":${__ts}}" >> "${PERF_SEGMENT_JSON_LOG:-${PERF_SEGMENT_LOG}}" 2>/dev/null || true
    fi
  fi

  zf::debug "with_timing seg=${seg} ms=${elapsed_ms} rc=${rc}"
  return $rc
}

# Convenience: measure a shell block:
# Example:
#   zf::timed pre_plugin_total 'sleep 0.1'
zf::timed() {
  local seg=$1; shift
  zf::with_timing "$seg" zsh -c "$*"
}

# ------------------------------
# Function Registry Introspection (for tests)
# ------------------------------
# Emits a sorted list of exported zf:: function names
zf::list_functions() {
  typeset -f | grep '^zf::[a-zA-Z0-9_]* ()' | sed 's/ ().*//' | sort
}

# ------------------------------
# Path Utilities
# ------------------------------
zf::script_dir() {
  # Emit absolute directory path of the calling script (best-effort).
  # Usage: local dir=$(zf::script_dir)
  # Resolves the current sourced file via ${(%)...} expansion; falls back to $PWD.
  local src="${(%):-%N}"
  if [[ -n "$src" && -f "$src" ]]; then
    print -r -- "${src:h}"
  else
    print -r -- "$PWD"
  fi
}

# PATH management utilities (legacy compatibility)
_path_prepend() {
  # Prepend directory to PATH if not already present
  local dir="$1"
  [[ -z "$dir" || ! -d "$dir" ]] && return 1
  case ":$PATH:" in
    *:"$dir":*) return 0 ;; # already present
    *) PATH="$dir:$PATH" ;;
  esac
  export PATH
}

_path_append() {
  # Append directory to PATH if not already present
  local dir="$1"
  [[ -z "$dir" || ! -d "$dir" ]] && return 1
  case ":$PATH:" in
    *:"$dir":*) return 0 ;; # already present
    *) PATH="$PATH:$dir" ;;
  esac
  export PATH
}

# ------------------------------
# Export Metadata / Introspection
# ------------------------------
# Static export list (fallback for environments where `typeset -f` filtering
# is restricted or altered by shell options). Bench / tooling can source this
# variable or call zf::exports to obtain the canonical set without parsing.
: ${ZF_CORE_EXPORTS:="zf::log zf::warn zf::debug zf::ensure_cmd zf::require zf::with_timing zf::timed zf::list_functions zf::script_dir _path_prepend _path_append"}

zf::exports() {
  print -r -- $ZF_CORE_EXPORTS
}

# ------------------------------
# Diagnostics (optional)
# ------------------------------
if [[ -n "${ZF_DEBUG:-}" ]]; then
  local _count
  _count=$(zf::list_functions | wc -l | tr -d ' ')
  zf::debug "core functions loaded (idempotent) exported=${_count} list=($ZF_CORE_EXPORTS)"
fi
