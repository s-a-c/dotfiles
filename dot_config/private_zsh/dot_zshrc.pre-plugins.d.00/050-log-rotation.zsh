#!/usr/bin/env zsh
# 040-log-rotation.zsh - Early Log Rotation / Hygiene Module
# Phase: Pre-Plugins (runs before heavy plugin & prompt initialization)
#
# Purpose:
#   Provide a lightweight, nounset-safe, auditable rotation mechanism for
#   common redesign log / trace files so they do not grow unbounded or
#   accumulate stale diagnostic state between sessions.
#
# Design Goals:
#   - Zero external dependencies (pure zsh + coreutils assumptions)
#   - Nounset safe (all parameter expansions guarded)
#   - Idempotent (only runs once per shell startup)
#   - Silent under normal conditions; emits debug lines only if ZF_DEBUG=1
#   - Conservative defaults (rotate only if size threshold exceeded)
#
# Environment Toggles:
#   ZF_LOG_ROTATION_ENABLE=0      Disable the entire module (default: 1)
#   ZF_LOG_ROTATION_FORCE=1       Force rotate even if below size threshold
#   ZF_LOG_ROTATION_LIMIT=<N>     Keep last N rotated files per base (default: 5)
#   ZF_LOG_ROTATION_MAX_BYTES=<B> Rotate if file size > B (default: 200000 ~200KB)
#   ZF_LOG_ROTATION_TARGETS="file1:file2:..."  Override target list (colon-separated)
#
# Exported Marker:
#   _ZF_LOG_ROTATION=1  -> rotation module executed
#
# Rotation Strategy:
#   For each target file F (absolute path) that exists:
#     1. If (force) or (size > threshold) or (file is non-empty and ends with previous session noise):
#        - Move F -> F.<UTC-TIMESTAMP>.log
#     2. Prune older rotations keeping only newest LIMIT for that base.
#
# Timestamp Format:
#   %Y%m%dT%H%M%S (UTC) – predictable & sortable lexicographically.
#
# Safety:
#   - Uses 'mv' only if file exists and is readable.
#   - Ignores permission errors silently (non-fatal).
#
# Future Extensions (Segment Instrumentation Alignment):
#   - Emit rotation events into a structured NDJSON audit stream (optional).
#   - Add checksum over archived logs when integrity requirements rise.
#
# ----------------------------------------------------------------------

# Idempotency guard
[[ -n ${_ZF_LOG_ROTATION_DONE:-} ]] && return 0

# Provide debug shim if not already defined
typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# Enable toggle
: "${ZF_LOG_ROTATION_ENABLE:=1}"
((${ZF_LOG_ROTATION_ENABLE:-1} == 1)) || {
  _ZF_LOG_ROTATION=0
  _ZF_LOG_ROTATION_DONE=1
  return 0
}

# Settings (guarded)
: "${ZF_LOG_ROTATION_FORCE:=0}"
: "${ZF_LOG_ROTATION_LIMIT:=5}"
: "${ZF_LOG_ROTATION_MAX_BYTES:=200000}"

# Default targets (absolute paths)
_default_targets=(
  "${ZDOTDIR:-$HOME}/zsh-debug-output.log"
  "${ZDOTDIR:-$HOME}/.logs/starship.log"
  "${ZDOTDIR:-$HOME}/.logs/performance.log"
  "${ZDOTDIR:-$HOME}/.logs/segment-capture.log"
)

# Allow override via colon-separated list
if [[ -n "${ZF_LOG_ROTATION_TARGETS:-}" ]]; then
  IFS=':' read -rA _rotation_targets <<<"${ZF_LOG_ROTATION_TARGETS}"
else
  _rotation_targets=("${_default_targets[@]}")
fi

# Helper: safe size fetch (returns 0 if unavailable)
_zf_lr_sizeof() {
  local f="$1"
  [[ -f "$f" ]] || {
    echo 0
    return 0
  }
  # Prefer stat -f (BSD/macOS); fallback to wc -c
  local sz
  if sz=$(stat -f %z "$f" 2>/dev/null); then
    echo "${sz}"
  else
    wc -c <"$f" 2>/dev/null || echo 0
  fi
}

# Helper: rotate single file
_zf_lr_rotate_one() {
  local file="$1"
  local limit="${2:-5}"
  [[ -f "$file" ]] || return 0

  local base_dir base_name ts rotated new_name
  base_dir="${file:h}"
  base_name="${file:t}"
  ts="$(TZ=UTC date +%Y%m%dT%H%M%S 2>/dev/null || date +%Y%m%dT%H%M%S)"

  rotated="${file}.${ts}.log"
  mv "$file" "$rotated" 2>/dev/null || return 0
  zf::debug "# [log-rotation] Rotated: ${base_name} -> ${rotated:t}"

  # Prune older rotations
  local pattern older
  pattern="${base_dir}/${base_name}."[0-9]#".log"
  # List sorted newest first (reverse numeric sort by timestamp part)
  older=($(ls -1t ${pattern} 2>/dev/null | tail -n +$((limit + 1))))
  if ((${#older[@]} > 0)); then
    for oldf in "${older[@]}"; do
      rm -f "$oldf" 2>/dev/null || true
      zf::debug "# [log-rotation] Pruned: ${oldf:t}"
    done
  fi
}

# Main routine
_rotated_any=0
for target in "${_rotation_targets[@]}"; do
  [[ -n "$target" ]] || continue
  [[ -f "$target" ]] || continue

  size=$(_zf_lr_sizeof "$target")
  [[ -n "$size" ]] || size=0

  if ((ZF_LOG_ROTATION_FORCE == 1)) || ((size > ZF_LOG_ROTATION_MAX_BYTES)); then
    _zf_lr_rotate_one "$target" "${ZF_LOG_ROTATION_LIMIT}"
    _rotated_any=1
  fi
done

# Marker exports
_ZF_LOG_ROTATION=1
export _ZF_LOG_ROTATION

# Cleanup locals (best effort)
unset _rotation_targets _default_targets _rotated_any size target pattern older oldf ts rotated base_dir base_name

_ZF_LOG_ROTATION_DONE=1
return 0
