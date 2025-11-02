#!/usr/bin/env zsh
# Filename: 050-logging-and-monitoring.zsh
# Purpose:  Sets up logging and performance monitoring infrastructure. This script handles log rotation to prevent unbounded growth of log files and loads the advanced segment library for detailed performance tracking. Features: - Log rotation for key Zsh logs (debug, starship, performance, etc.). - Configurable rotation thresholds, limits, and targets via environment variables. - Pure Zsh implementation with no external dependencies beyond coreutils. Nounset Safety: All parameter expansions are guarded. Idempotency Guard
# Phase:    Pre-plugin (.zshrc.pre-plugins.d/)
# Toggles:  ZF_LOG_ROTATION_ENABLE, ZF_LOG_ROTATION_FORCE, ZF_LOG_ROTATION_LIMIT

[[ -n ${_ZF_LOGGING_MONITORING_DONE:-} ]] && return 0
_ZF_LOGGING_MONITORING_DONE=1

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# --- Log Rotation ---

# Enable toggle
: "${ZF_LOG_ROTATION_ENABLE:=1}"
if (( ${ZF_LOG_ROTATION_ENABLE:-1} == 1 )); then
  : "${ZF_LOG_ROTATION_FORCE:=0}"
  : "${ZF_LOG_ROTATION_LIMIT:=5}"
  : "${ZF_LOG_ROTATION_MAX_BYTES:=200000}" # ~200KB

  _default_targets=(
    "${ZDOTDIR:-$HOME}/zsh-debug-output.log"
    "${ZDOTDIR:-$HOME}/.logs/starship.log"
    "${ZDOTDIR:-$HOME}/.logs/performance.log"
    "${ZDOTDIR:-$HOME}/.logs/segment-capture.log"
  )

  if [[ -n "${ZF_LOG_ROTATION_TARGETS:-}" ]]; then
    IFS=':' read -rA _rotation_targets <<<"${ZF_LOG_ROTATION_TARGETS}"
  else
    _rotation_targets=("${_default_targets[@]}")
  fi

  _zf_lr_sizeof() {
    [[ -f "$1" ]] || { echo 0; return 0; }
    # Use ZSH builtin zstat for portability and performance
    zmodload -F zsh/stat b:zstat 2>/dev/null || true
    if typeset -f zstat >/dev/null 2>&1; then
      local -a fileinfo
      zstat -A fileinfo +size "$1" 2>/dev/null || { echo 0; return 0; }
      echo "${fileinfo[1]}"
    else
      # Fallback to external commands if zstat unavailable
      local sz
      if sz=$(stat -f %z "$1" 2>/dev/null); then
        echo "${sz}"
      else
        wc -c <"$1" 2>/dev/null || echo 0
      fi
    fi
  }

  _zf_lr_rotate_one() {
    local file="$1" limit="${2:-5}"
    [[ -f "$file" ]] || return 0
    local base_dir="${file:h}" base_name="${file:t}"

    # Use ZSH datetime module for timestamp generation (no subprocess overhead)
    zmodload zsh/datetime 2>/dev/null || true
    local ts
    if typeset -p EPOCHSECONDS >/dev/null 2>&1; then
      strftime -s ts "%Y%m%dT%H%M%S" $EPOCHSECONDS 2>/dev/null || \
        ts="$(TZ=UTC date +%Y%m%dT%H%M%S 2>/dev/null || date +%Y%m%dT%H%M%S)"
    else
      # Fallback to date command
      ts="$(TZ=UTC date +%Y%m%dT%H%M%S 2>/dev/null || date +%Y%m%dT%H%M%S)"
    fi

    local rotated="${file}.${ts}.log"
    mv "$file" "$rotated" 2>/dev/null || return 0
    zf::debug "# [log-rotation] Rotated: ${base_name} -> ${rotated:t}"

    # Use ZSH glob qualifiers instead of ls+tail (faster, no subshell)
    local pattern="${base_dir}/${base_name}."[0-9]*.log
    # (Om) = reverse order by mtime, [N,-1] = slice from position N to end
    # This replaces: ls -1t ${pattern} | tail -n +$((limit + 1))
    local older=( ${~pattern}(NOm[$((limit + 1)),-1]) )
    if ((${#older[@]} > 0)); then
      rm -f "${older[@]}" 2>/dev/null || true
      zf::debug "# [log-rotation] Pruned ${#older[@]} old log(s) for ${base_name}"
    fi
  }

  for target in "${_rotation_targets[@]}"; do
    [[ -f "$target" ]] || continue
    size=$(_zf_lr_sizeof "$target")
    if ((ZF_LOG_ROTATION_FORCE == 1)) || ((size > ZF_LOG_ROTATION_MAX_BYTES)); then
      _zf_lr_rotate_one "$target" "${ZF_LOG_ROTATION_LIMIT}"
    fi
  done

  # Age-based cleanup for performance logs (P2 Issue 4.1 Resolution)
  # Remove perf-*.log files older than N days from logs directory
  # Uses ZSH glob qualifiers instead of find (faster, no subprocess)
  : "${ZF_LOG_ROTATION_AGE_DAYS:=7}"
  if [[ -d "${ZDOTDIR:-$HOME}/.logs" ]]; then
    # Load zstat for age-based glob qualifiers
    zmodload -F zsh/stat b:zstat 2>/dev/null || true

    # Use glob qualifiers for age-based selection
    # (N) = NULL_GLOB (no error if no matches)
    # (mw+N) = modified more than N weeks ago
    # Note: Using weeks instead of days for more reliable cross-platform behavior
    local age_weeks=$(( (ZF_LOG_ROTATION_AGE_DAYS + 6) / 7 ))  # Round up to nearest week
    local old_logs=( ${ZDOTDIR:-$HOME}/.logs/perf-*.log(Nmw+${age_weeks}) )

    if ((${#old_logs[@]} > 0)); then
      rm -f "${old_logs[@]}" 2>/dev/null || true
      zf::debug "# [log-rotation] Age-based cleanup: removed ${#old_logs[@]} perf logs older than ${ZF_LOG_ROTATION_AGE_DAYS} days"
    else
      zf::debug "# [log-rotation] Age-based cleanup: no old perf logs found"
    fi
  fi

  unset _default_targets _rotation_targets target size
  unset -f _zf_lr_sizeof _zf_lr_rotate_one
  export _ZF_LOG_ROTATION=1
  zf::debug "# [logging] Log rotation module executed."
fi


# --- Segment Management ---

# Core segment functions (zf::segment, etc.) are now in .zshenv.
# This file now only loads the optional advanced segment library.
_zf_seg_zdotdir="${ZDOTDIR:-${HOME}/.config/zsh}"
if [[ -f "${_zf_seg_zdotdir}/tools/segment-lib.zsh" ]]; then
  source "${_zf_seg_zdotdir}/tools/segment-lib.zsh" || true
  zf::debug "# [monitoring] Advanced segment library loaded"
else
  zf::debug "# [monitoring] Advanced segment library not found, using core fallback"
fi
unset _zf_seg_zdotdir

zf::debug "# [logging-and-monitoring] setup complete"
return 0
