#!/usr/bin/env zsh
# ==============================================================================
# 526-starship-health.zsh — Weekly Starship health check with on-screen warning
# ==============================================================================
# Purpose:
#   - Run a Starship prompt health check no more than once per week.
#   - Capture warnings/errors to a persistent log file.
#   - Display a concise on-screen warning when issues are detected.
#
# Behavior:
#   - Skips in non-interactive shells or when Starship is not installed.
#   - Respects optional environment knobs:
#       STARSHIP_HEALTH_DISABLE=1       -> disable health checks
#       STARSHIP_HEALTH_INTERVAL_DAYS   -> override interval (default 7)
#   - Files:
#       ${ZDOTDIR:-$HOME}/.cache/starship/health-last-run
#       ${ZDOTDIR:-$HOME}/logs/starship-health.log
#
# Idempotency:
#   - Guarded so it evaluates at most once per shell session.
# ==============================================================================

# Skip in non-interactive shells
if [[ ! -o interactive ]]; then
  return 0
fi

# Prevent multiple sourcing in the same shell session
if [[ -n "${_STARSHIP_HEALTH_FRAGMENT_LOADED:-}" ]]; then
  return 0
fi
typeset -g _STARSHIP_HEALTH_FRAGMENT_LOADED=1

# Respect hard disable knob
if [[ "${STARSHIP_HEALTH_DISABLE:-0}" == "1" ]]; then
  return 0
fi

# Skip if starship is not available
if ! command -v starship >/dev/null 2>&1; then
  return 0
fi

# Derive paths from ZDOTDIR (expected to be .../dot-config/zsh)
local _root="${ZDOTDIR:-$HOME}"
local _cache_dir="${_root}/.cache/starship"
local _log_dir="${_root}/logs"
local _stamp_file="${_cache_dir}/health-last-run"
local _log_file="${_log_dir}/starship-health.log"

# Ensure directories exist (ignore errors)
mkdir -p -- "${_cache_dir}" "${_log_dir}" 2>/dev/null || true

# Interval logic (default 7 days)
local _now _last _interval _days
_now="$(date +%s 2>/dev/null || printf '0')"
_days="${STARSHIP_HEALTH_INTERVAL_DAYS:-7}"
# sanitize interval days (positive integer)
if ! printf '%s' "${_days}" | LC_ALL=C grep -Eq '^[1-9][0-9]*$'; then
  _days=7
fi
_interval="$((_days * 24 * 3600))"

if [[ -r "${_stamp_file}" ]]; then
  read -r _last <"${_stamp_file}" || _last=0
else
  _last=0
fi

# Skip if interval hasn't elapsed
if ((_now - _last < _interval)); then
  return 0
fi

# --- Perform health check ------------------------------------------------------

# Capture warnings/errors emitted by starship prompt invocation
# Use a temporary file to capture STDERR; discard STDOUT
local _tmp rc _warns
_tmp="$(mktemp 2>/dev/null || printf '%s' "/tmp/starship-health.$$.log")"

# Keep the environment minimal but do not break the user's STARSHIP_CONFIG
# Run with WARN level to collect warnings without tracing
STARSHIP_LOG=warn starship prompt >/dev/null 2>"${_tmp}"
rc=$?

# Gather any warning lines (case-insensitive match on 'warn')
_warns="$(grep -i 'warn' "${_tmp}" 2>/dev/null || true)"

# Append results to persistent log
{
  printf '=== %s (PID %s) ===\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$$"
  printf '# starship version: %s\n' "$(starship --version 2>/dev/null || echo unknown)"
  if ((rc != 0)); then
    printf 'ERROR: starship prompt exit code: %s\n' "$rc"
  fi
  if [[ -n "${_warns}" ]]; then
    printf 'WARNINGS:\n%s\n' "${_warns}"
  fi
  if ((rc == 0)) && [[ -z "${_warns}" ]]; then
    printf 'Status: OK (no warnings, rc=0)\n'
  fi
  printf '\n'
} >>"${_log_file}" 2>/dev/null || true

# Update last-run timestamp
printf '%s\n' "${_now}" >|"${_stamp_file}" 2>/dev/null || true

# On-screen warning if issues detected
if ((rc != 0)) || [[ -n "${_warns}" ]]; then
  # Keep the message short and actionable
  print -r -- "⚠️  Starship health check found issues (rc=${rc}). See: ${_log_file}"
  # Inline hint when warnings are present
  if [[ -n "${_warns}" ]]; then
    print -r -- "   Hint: run 'STARSHIP_LOG=trace starship prompt >/dev/null 2> /tmp/starship-trace.log' to capture details"
  fi
fi

# Cleanup
rm -f -- "${_tmp}" 2>/dev/null || true
unset _root _cache_dir _log_dir _stamp_file _log_file _now _last _interval _days _tmp rc _warns

return 0
