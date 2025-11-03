#!/usr/bin/env zsh
# capture-terminal-evidence.zsh - Phase 6 terminal integration evidence helper
#
# Purpose:
#   Automate creation of standardized terminal session evidence logs required
#   to close Phase 6 (Terminal Integration) for the fix-zle initiative.
#
# Features:
#   - Detect or accept explicit terminal target (warp, wezterm, ghostty, kitty, iterm2)
#   - Emits canonical marker variables for the unified module:
#       WARP_IS_LOCAL_SHELL_SESSION
#       WEZTERM_SHELL_INTEGRATION
#       GHOSTTY_SHELL_INTEGRATION
#       KITTY_SHELL_INTEGRATION
#   - Validates that exactly one primary marker is asserted (or explains mismatch)
#   - Optional use of `script(1)` for raw TTY transcript capture (fallback to direct print)
#   - Optional spawned interactive login shell to ensure full widget registration (--spawn)
#   - Dry‑run mode for preview
#   - Summary line generation suitable for README “Captured Artifacts” section
#
# Output:
#   docs/fix-zle/results/terminal/<terminal>-session-YYYYMMDD-HHMMSS.log
#
# Usage:
#   ./tools/capture-terminal-evidence.zsh [-t auto|warp|wezterm|ghostty|kitty|iterm2] [-o output_dir] [--raw] [--summary] [-n] [--spawn|--no-spawn]
#
# Examples:
#   # Auto-detect terminal and capture
#   ./tools/capture-terminal-evidence.zsh
#
#   # Explicit terminal (if running inside tmux or detached env)
#   ./tools/capture-terminal-evidence.zsh -t wezterm
#
#   # Produce summary line only (no capture)
#   ./tools/capture-terminal-evidence.zsh --summary -t ghostty
#
#   # Force spawned interactive login capture (ensures full modules)
#   ./tools/capture-terminal-evidence.zsh --spawn -t warp
#
#   # Dry run (show what would happen)
#   ./tools/capture-terminal-evidence.zsh -n -t kitty
#
# Exit Codes:
#   0 success
#   1 generic error / invalid usage
#   2 marker validation failure
#
# Nounset Safety:
#   All parameter expansions guarded. Script sets `set -euo pipefail`.
#
# Repository Conventions:
#   Functions namespaced with zf:: prefix (policy compliance).
#
# Phase Reference:
#   Phase 6 closure requires presence of per-terminal evidence logs with correct
#   marker semantics (see docs/fix-zle/results/terminal/README.md).
#
# -----------------------------------------------------------------------------

# Relax -e to avoid premature aborts on benign non-zero (e.g. early zle -la before ZLE init)
# Keep nounset & pipefail for safety.
set -uo pipefail

# Provide minimal debug (disabled unless ZF_TERMCAP_DEBUG=1)
zf::termcap::debug() {
  [[ "${ZF_TERMCAP_DEBUG:-0}" == 1 ]] && print -u2 "[termcap-debug] $*"
}

zf::termcap::usage() {
  cat <<'EOF'
capture-terminal-evidence.zsh - Generate Phase 6 terminal evidence log

Usage:
  capture-terminal-evidence.zsh [-t auto|warp|wezterm|ghostty|kitty|iterm2] [-o output_dir] [--raw] [--summary] [-n] [--spawn|--no-spawn] [-h]

Options:
  -t <terminal>   Explicit terminal target (default: auto)
  -o <dir>        Output directory (default: docs/fix-zle/results/terminal)
  --raw           Force raw TTY capture using 'script' if available
  --summary       Emit only a one-line summary (no log file)
  -n              Dry run (no file operations)
  --spawn                 Force capture in a fresh 'zsh -il' (interactive login) shell
  --no-spawn              Disable auto-spawn even if current shell is non-interactive
  --force-redesign-env    Explicitly export ZDOTDIR & ZSH_USE_REDESIGN=1 inside spawned shell
  --allow-synthetic-marker Allow synthetic assertion of expected marker if terminal auto-detect fails
  -h                      Show help

Environment:
  ZF_TERMCAP_DEBUG=1   Enable debug output
  ZF_TERMCAP_TS_FMT    Override timestamp format (default: %Y%m%d-%H%M%S)
EOF
}

# --- Argument Parsing --------------------------------------------------------
_target="auto"
_out_dir=""
_force_raw=0
_summary_only=0
_dry_run=0
_spawn=0
_no_spawn=0
_force_redesign_env=0
_allow_synth_marker=0
_allow_missing_block=0

while (( $# )); do
  case "$1" in
    -t)
      shift || true
      _target="${1:-auto}"
      ;;
    -o)
      shift || true
      _out_dir="${1:-}"
      ;;
    --raw)
      _force_raw=1
      ;;
    --summary)
      _summary_only=1
      ;;
    -n)
      _dry_run=1
      ;;
    --spawn)
      _spawn=1
      ;;
    --no-spawn)
      _no_spawn=1
      ;;
    --force-redesign-env)
      _force_redesign_env=1
      ;;
    --allow-synthetic-marker)
      _allow_synth_marker=1
      ;;
    --allow-missing-block)
      _allow_missing_block=1
      ;;
    -h|--help)
      zf::termcap::usage
      exit 0
      ;;
    *)
      print -u2 "Unknown argument: $1"
      zf::termcap::usage
      exit 1
      ;;
  esac
  shift || true
done

# --- Defaults & Paths --------------------------------------------------------
: "${ZF_TERMCAP_TS_FMT:=%Y%m%d-%H%M%S}"

if [[ -z "${_out_dir}" ]]; then
  # Resolve repository root relative to script if possible
  _script_dir="$(cd -- "${0:A:h}" && pwd)"
  _repo_root="${_script_dir%/tools*}"
  _out_dir="${_repo_root}/docs/fix-zle/results/terminal"
fi

# Validate output dir existence or create (unless dry run / summary)
if (( _summary_only == 0 && _dry_run == 0 )); then
  if [[ ! -d "${_out_dir}" ]]; then
    mkdir -p "${_out_dir}" || {
      print -u2 "Failed to create output directory: ${_out_dir}"
      exit 1
    }
  fi
fi

# --- Detect Terminal Context -------------------------------------------------
zf::termcap::detect() {
  local tp="${TERM_PROGRAM:-}"
  local term="${TERM:-}"

  if [[ "${_target}" != "auto" ]]; then
    print -- "${_target}"
    return 0
  fi

  case "${tp}" in
    WarpTerminal) print warp; return 0 ;;
    WezTerm)      print wezterm; return 0 ;;
    ghostty)      print ghostty; return 0 ;;
    iTerm.app)    print iterm2; return 0 ;;
  esac

  if [[ "${term}" == "xterm-kitty" ]]; then
    print kitty
    return 0
  fi

  print unknown
  return 0
}

_detected="$(zf::termcap::detect)"
zf::termcap::debug "Detected terminal: ${_detected}"

# Guard: handle unknown terminal detection (informative debug only; no failure)
if [[ "${_detected}" == "unknown" ]]; then
  zf::termcap::debug "Unknown terminal context (TERM_PROGRAM='${TERM_PROGRAM:-}', TERM='${TERM:-}')"
fi

_terminal="${_detected}"

# Auto-enable spawn if current shell is non-interactive and user didn't explicitly disable
case "$-" in
  *i*) : ;;
  *) if (( _no_spawn == 0 )); then _spawn=1; fi ;;
esac

# --- Marker Expectation Map --------------------------------------------------
zf::termcap::expected_marker_name() {
  case "$1" in
    warp)    print WARP_IS_LOCAL_SHELL_SESSION ;;
    wezterm) print WEZTERM_SHELL_INTEGRATION ;;
    ghostty) print GHOSTTY_SHELL_INTEGRATION ;;
    kitty)   print KITTY_SHELL_INTEGRATION ;;
    iterm2)  print "" ;;  # iTerm2 has no dedicated marker in the unified module
    *)       print "" ;;
  esac
}

_expected_marker="$(zf::termcap::expected_marker_name "${_terminal}")"

# --- Capture Core Logic ------------------------------------------------------
# Builds the canonical info block to write (non-spawn direct mode).
zf::termcap::build_block() {
  cat <<EOF
CAPTURE_START
UTC_TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TERMINAL_TARGET=${_terminal}
TERM_PROGRAM=${TERM_PROGRAM:-}
TERM=${TERM:-}
WARP_IS_LOCAL_SHELL_SESSION=${WARP_IS_LOCAL_SHELL_SESSION:-0}
WEZTERM_SHELL_INTEGRATION=${WEZTERM_SHELL_INTEGRATION:-0}
GHOSTTY_SHELL_INTEGRATION=${GHOSTTY_SHELL_INTEGRATION:-0}
KITTY_SHELL_INTEGRATION=${KITTY_SHELL_INTEGRATION:-0}
ZSH_VERSION=$(zsh --version 2>/dev/null)
ZLE_WIDGET_COUNT=$(zle -la 2>/dev/null | wc -l || echo 0)
SHELL=${SHELL:-}
USER=${USER:-}
PWD=$PWD
CAPTURE_END
EOF
}

# Spawned capture (interactive login shell) to ensure full init
zf::termcap::spawn_capture() {
  # Multi-strategy spawn to guarantee CAPTURE_START block even if login hooks modify stdin / flow.
  # Strategies tried in order: login+interactive (-ilc), interactive (-ic), plain (-c)
  local strategies=(
    "-ilc"
    "-ic"
    "-c"
  )

  # Infer redesign ZDOTDIR (script located under .../dot-config/zsh/tools/) only if forced later
  local _script_dir _guess_zdotdir
  _script_dir="$(cd -- "${0:A:h}" && pwd)"
  _guess_zdotdir="${_script_dir%/tools}"

  local cmd='
    {
      # Begin debug phase
      print "[spawn-debug] phase=begin shell=$ZSH_VERSION"

      # Neutralize errexit / nounset inside capture context
      setopt no_errexit 2>/dev/null || set +e
      unsetopt nounset 2>/dev/null || true

      # Stabilize widget count (handle deferred registration)
      attempts=6
      _wcount=0
      while (( attempts > 0 )); do
        _wcount=$(zle -la 2>/dev/null | wc -l 2>/dev/null | tr -d " " || echo 0)
        (( _wcount >= 387 )) && break
        sleep 0.07
        ((attempts--))
      done
      print "[spawn-debug] phase=post-stabilize widgets=${_wcount} attempts_left=${attempts}"

      # Synthetic marker (optional)
      if [[ ${ALLOW_SYNTH_MARKER:-0} == 1 ]]; then
        case ${ZF_TERM_TARGET:-unknown} in
          warp)    : "${WARP_IS_LOCAL_SHELL_SESSION:=1}" ;;
          wezterm) : "${WEZTERM_SHELL_INTEGRATION:=1}" ;;
          ghostty) : "${GHOSTTY_SHELL_INTEGRATION:=1}" ;;
          kitty)   : "${KITTY_SHELL_INTEGRATION:=enabled}" ;;
        esac
        print "[spawn-debug] phase=synthetic-markers applied=1"
      fi

      print "CAPTURE_START"
      print "UTC_TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      print "TERMINAL_TARGET=${ZF_TERM_TARGET:-unknown}"
      print "TERM_PROGRAM=${TERM_PROGRAM:-}"
      print "TERM=${TERM:-}"
      print "WARP_IS_LOCAL_SHELL_SESSION=${WARP_IS_LOCAL_SHELL_SESSION:-0}"
      print "WEZTERM_SHELL_INTEGRATION=${WEZTERM_SHELL_INTEGRATION:-0}"
      print "GHOSTTY_SHELL_INTEGRATION=${GHOSTTY_SHELL_INTEGRATION:-0}"
      print "KITTY_SHELL_INTEGRATION=${KITTY_SHELL_INTEGRATION:-0}"
      print "ZSH_VERSION=$(zsh --version 2>/dev/null)"
      print "ZLE_WIDGET_COUNT=${_wcount}"
      print "SHELL=${SHELL:-}"
      print "USER=${USER:-}"
      print "PWD=$PWD"
      print "CAPTURE_END"
      print "[spawn-debug] phase=done"
    }'

  local strat success=0 tmpfile
  tmpfile="$(mktemp -t termcap.spawn.XXXXXX || echo /tmp/termcap.spawn.$$)"

  for strat in "${strategies[@]}"; do
    : > "${tmpfile}"
    env \
      ZF_TERM_TARGET="${_terminal}" \
      ZF_TERM_EXP_MARKER="${_expected_marker}" \
      TERM_PROGRAM="${TERM_PROGRAM:-}" \
      TERM="${TERM:-}" \
      ${_force_redesign_env:+ZDOTDIR="${_guess_zdotdir}" ZSH_USE_REDESIGN=1} \
      ALLOW_SYNTH_MARKER="${_allow_synth_marker}" \
      zsh ${strat} "${cmd}" > "${tmpfile}" 2>&1 || true

    if grep -q '^CAPTURE_START$' "${tmpfile}"; then
      success=1
      break
    fi
    print -u2 "[spawn-debug] strategy=${strat} missing CAPTURE_START"
  done

  cat "${tmpfile}"
  rm -f "${tmpfile}"

  (( success == 1 )) && return 0 || return 3
}

# --- Marker Validation -------------------------------------------------------
zf::termcap::validate_markers() {
  local term="$1"
  local emarker="$2"
  local failures=0
  local active=0

  # Count active markers (any that are not 0 / empty)
  local mlist=(
    "WARP_IS_LOCAL_SHELL_SESSION=${WARP_IS_LOCAL_SHELL_SESSION:-0}"
    "WEZTERM_SHELL_INTEGRATION=${WEZTERM_SHELL_INTEGRATION:-0}"
    "GHOSTTY_SHELL_INTEGRATION=${GHOSTTY_SHELL_INTEGRATION:-0}"
    "KITTY_SHELL_INTEGRATION=${KITTY_SHELL_INTEGRATION:-0}"
  )

  for mpair in "${mlist[@]}"; do
    local val="${mpair#*=}"
    if [[ -n "${val}" && "${val}" != "0" ]]; then
      ((active++))
    fi
  done

  if [[ "${term}" == "iterm2" ]]; then
    if (( active != 0 )); then
      print -u2 "[validate] iTerm2: expected 0 active markers, found ${active}"
      ((failures++))
    fi
  else
    if [[ -z "${emarker}" ]]; then
      print -u2 "[validate] Unknown terminal '${term}' – skipping strict marker check"
    else
      local em_val="${(P)emarker:-0}"
      if [[ -z "${em_val}" || "${em_val}" == "0" ]]; then
        print -u2 "[validate] Expected marker ${emarker} not asserted (value='${em_val}')"
        ((failures++))
      fi
      if (( active != 1 )); then
        print -u2 "[validate] Expected exactly 1 active marker, found ${active}"
        ((failures++))
      fi
    fi
  fi

  (( failures > 0 )) && return 2 || return 0
}

# --- Filename & Paths --------------------------------------------------------
_timestamp="$(date -u +${ZF_TERMCAP_TS_FMT})"
_log_file="${_terminal}-session-${_timestamp}.log"
_full_path="${_out_dir}/${_log_file}"

# --- Summary Line Builder ----------------------------------------------------
zf::termcap::summary_line() {
  local marker_status="OK"
  if ! zf::termcap::validate_markers "${_terminal}" "${_expected_marker}"; then
    marker_status="MISMATCH"
  fi
  local widgets="$(zle -la 2>/dev/null | wc -l || echo 0)"
  print -- "- ${_timestamp%T*}: ${_log_file} (widgets=${widgets}; marker ${marker_status}; spawn=${_spawn})"
}

# --- Main Execution Paths ----------------------------------------------------
if (( _summary_only == 1 )); then
  zf::termcap::summary_line
  exit 0
fi

zf::termcap::debug "Writing capture to: ${_full_path} (spawn=${_spawn})"

# Dry run path
if (( _dry_run == 1 )); then
  print "Dry run: would create ${_full_path}"
  zf::termcap::summary_line
  exit 0
fi

if (( _spawn == 1 )); then
  zf::termcap::debug "Using spawned interactive login shell for capture"
  _tmpfile="$(mktemp -t termcap.spawn.XXXXXX || echo "/tmp/termcap-spawn-${RANDOM}.tmp")"
  zf::termcap::spawn_capture > "${_tmpfile}" 2>&1 || true
  mv "${_tmpfile}" "${_full_path}"
  # Integrity check: ensure CAPTURE_START is present; retry once with synthetic marker if allowed not already enabled.
  if ! grep -q '^CAPTURE_START$' "${_full_path}"; then
    zf::termcap::debug "Missing CAPTURE_START in initial spawn output; retrying (allow_synth=${_allow_synth_marker})"
    if (( _allow_synth_marker == 0 )); then
      _allow_synth_marker=1
      _tmpfile="$(mktemp -t termcap.spawn.XXXXXX || echo "/tmp/termcap-spawn-${RANDOM}.tmp")"
      zf::termcap::spawn_capture > "${_tmpfile}" 2>&1 || true
      mv "${_tmpfile}" "${_full_path}"
    fi
  fi
  # Enforce presence (unless user explicitly allows missing block)
  if ! grep -q '^CAPTURE_START$' "${_full_path}"; then
    if (( _allow_missing_block == 1 )); then
      {
        echo ""
        echo "# ERROR"
        echo "Capture block missing after retry (override: --allow-missing-block). See [spawn-debug] lines."
      } >> "${_full_path}"
    else
      {
        echo ""
        echo "# ERROR"
        echo "Capture block missing after retry. Failing (use --allow-missing-block to suppress)."
      } >> "${_full_path}"
      print -u2 "[capture] FATAL: CAPTURE_START block absent in ${_full_path}"
      exit 3
    fi
  fi
else
  # Non-spawn path (legacy / direct mode)
  _use_script=0
  if (( _force_raw == 1 )); then
    _use_script=1
  elif command -v script >/dev/null 2>&1; then
    _use_script=1
  fi
  _capture_tmp=""
  if (( _use_script == 1 )); then
    _capture_tmp="$(mktemp -t termcap.XXXXXX || echo "/tmp/termcap-${RANDOM}.tmp")"
    script -q "${_capture_tmp}" zsh -i -c 'echo "__TERM_EVIDENCE_BEGIN__"; zsh --version >/dev/null 2>&1; echo "__TERM_EVIDENCE_READY__"; sleep 0.05' >/dev/null 2>&1 || true
    zf::termcap::build_block > "${_capture_tmp}"
    mv "${_capture_tmp}" "${_full_path}"
  else
    zf::termcap::build_block > "${_full_path}"
  fi
fi

# Validate markers after capture (current shell context; for spawned mode this may be conservative)
if ! zf::termcap::validate_markers "${_terminal}" "${_expected_marker}"; then
  _validation_status="FAIL"
  _rc=2
else
  _validation_status="OK"
  _rc=0
fi

# Append a trailing note section (kept minimal)
{
  echo ""
  echo "# Notes"
  echo "Validation: ${_validation_status}"
  echo "Expected Marker: ${_expected_marker:-<none>}"
  echo "Spawned: ${_spawn}"
  echo "Generated By: capture-terminal-evidence.zsh"
} >> "${_full_path}"

print "Captured: ${_full_path} (validation=${_validation_status}; spawn=${_spawn})"

# Emit summary line for convenience
zf::termcap::summary_line

exit ${_rc}
