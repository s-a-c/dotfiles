#!/usr/bin/env bash
#
# test-live-segment-capture.sh
#
# Phase 7 – Live Segment Capture Prototype Test Harness
#
# Purpose:
#   Validates the prototype live segment capture module (115-live-segment-capture.zsh):
#     * Verifies enablement via ZF_SEGMENT_CAPTURE=1
#     * Confirms NDJSON output file is created
#     * Ensures at least two segment events are logged (one wrap + one manual)
#     * Performs lightweight JSON structural validation (regex + optional Python fallback)
#     * Emits a concise PASS/FAIL summary suitable for aggregation
#
# Output (stdout summary lines):
#   live_segment_capture=PASS|FAIL
#   segments_logged=<int>
#   capture_file=<path or 'none'>
#   layer_set=<value or 'unset'>
#   failures=<comma-separated reasons or 'none'>
#
# Exit Codes:
#   0  Success (all required assertions passed)
#   1  Failure (one or more assertions failed)
#
# Requirements:
#   - bash, zsh, awk, grep, sed, mktemp
#   - python (optional; if present provides stricter JSON validation)
#
# Environment / Overrides:
#   ZDOTDIR                Path to zsh config root (auto-detected if not set)
#   SEG_CAPTURE_MIN_LINES  Minimum events required (default 2)
#   SEG_CAPTURE_SLEEP_MS   Milliseconds to sleep in manual segment (default 50)
#   SEG_CAPTURE_DEBUG=1    Extra internal debug prints
#
# Flags:
#   --require-min-lines N   Override minimum segment events
#   --show-sample           Emit first two raw JSON lines to stderr
#   --help                  Show usage
#
# Safety:
#   - Nounset & strict error handling
#   - Cleans up temporary directory on exit
#
# Notes:
#   The module is already in the active numbered layer set; sourcing happens
#   through the normal .zshrc path. A fallback direct source attempt is made
#   only if the expected functions are missing post-initialization.
#
set -euo pipefail
#
###############################################################################
# Configuration & CLI
###############################################################################
#
SEG_CAPTURE_MIN_LINES="${SEG_CAPTURE_MIN_LINES:-2}"
SEG_CAPTURE_SLEEP_MS="${SEG_CAPTURE_SLEEP_MS:-50}"
SHOW_SAMPLE=0
#
usage() {
  cat <<'EOF'
Usage: test-live-segment-capture.sh [options]
#
Options:
  --require-min-lines N   Require at least N segment events (default 2)
  --show-sample           Show first two logged JSON lines (stderr)
  --help                  This help
#
Environment:
  ZDOTDIR                 Override zsh config root
  SEG_CAPTURE_MIN_LINES   Minimum events required (default 2)
  SEG_CAPTURE_SLEEP_MS    Sleep duration inside manual segment (ms, default 50)
  SEG_CAPTURE_DEBUG=1     Verbose internal debug
#
Exit 0 on success, 1 on failure.
EOF
}
#
while [[ $# -gt 0 ]]; do
  case "$1" in
    --require-min-lines)
      shift
      SEG_CAPTURE_MIN_LINES="${1:-}"
      [[ -n "${SEG_CAPTURE_MIN_LINES}" && "${SEG_CAPTURE_MIN_LINES}" =~ ^[0-9]+$ ]] || {
        echo "Invalid --require-min-lines value" >&2
        exit 1
      }
      ;;
    --show-sample) SHOW_SAMPLE=1 ;;
    --help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
  shift || true
done
#
###############################################################################
# Helpers
###############################################################################
#
dbg() {
  [[ "${SEG_CAPTURE_DEBUG:-0}" == "1" ]] && printf "[live-seg-test] %s\n" "$*" >&2
}
#
fail_reasons=()
#
add_fail() {
  fail_reasons+=("$1")
}
#
tmp_root="$(mktemp -d -t live-seg-cap-XXXXXX)"
cleanup() {
  dbg "Cleaning up ${tmp_root}"
  rm -rf "${tmp_root}"
}
trap cleanup EXIT
#
###############################################################################
# Determine ZDOTDIR (default path matches repository layout)
###############################################################################
#
if [[ -z "${ZDOTDIR:-}" ]]; then
  if [[ -d "${HOME}/dotfiles/dot-config/zsh" ]]; then
    export ZDOTDIR="${HOME}/dotfiles/dot-config/zsh"
  else
    add_fail "ZDOTDIR_not_set_and_default_missing"
    # We'll let the shell fallback to its own default, but likely fail to load module
  fi
fi
#
dbg "Using ZDOTDIR=${ZDOTDIR:-<unset>}"
#
###############################################################################
# Prepare capture directory overrides (prevent clobber of real cache)
###############################################################################
#
capture_dir="${tmp_root}/segments"
mkdir -p "${capture_dir}"
#
export ZF_SEGMENT_CAPTURE=1
export ZF_SEGMENT_CAPTURE_DIR="${capture_dir}"
export ZF_SEGMENT_CAPTURE_MIN_MS=0
export ZF_SEGMENT_CAPTURE_DEBUG=0
#
###############################################################################
# Build shell script to run inside zsh
###############################################################################
#
ms_to_sleep="${SEG_CAPTURE_SLEEP_MS}"
sec_sleep="$(awk -v ms="${ms_to_sleep}" 'BEGIN{printf("%.3f", ms/1000.0)}')"
#
inner_script='
  # Print layer marker early if available (after normal init)
  printf "LAYER_MARKER=%s\n" "${_ZF_LAYER_SET:-unset}"
#
  # Fallback direct source if capture functions missing post init
  if ! typeset -f zf::segment_capture_start >/dev/null 2>&1; then
    if [[ -n "${ZDOTDIR:-}" ]]; then
      if [[ -f "${ZDOTDIR}/.zshrc.d/115-live-segment-capture.zsh" ]]; then
        source "${ZDOTDIR}/.zshrc.d/115-live-segment-capture.zsh"
      else
        # Scan numbered layer directories (e.g. .zshrc.d.00, .zshrc.d.01) if symlink not present or file missing
        for _cand in "${ZDOTDIR}"/.zshrc.d.[0-9][0-9]/115-live-segment-capture.zsh; do
          [[ -f "${_cand}" ]] || continue
          source "${_cand}"
          break
        done
        unset _cand
      fi
    fi
  fi
#
  # Show resolved capture file
  printf "CAP_FILE=%s\n" "${_ZF_SEGMENT_CAPTURE_FILE:-unset}"
  printf "CAP_ENABLED=%s\n" "${_ZF_SEGMENT_CAPTURE:-unset}"
#
  # Emit segments
  if typeset -f zf::segment_capture_wrap >/dev/null 2>&1; then
    zf::segment_capture_wrap test:fast true
    zf::segment_capture_start test:manual
    builtin sleep '"${sec_sleep}"'
    zf::segment_capture_end test:manual note=ok
  else
    echo "NO_CAPTURE_FUNCS=1"
  fi
#
  # Additional quick segment to ensure >2 lines
  if typeset -f zf::segment_capture_start >/dev/null 2>&1; then
    zf::segment_capture_start test:tiny
    zf::segment_capture_end test:tiny
  fi
'
#
###############################################################################
# Execute zsh login+interactive shell
###############################################################################
#
# Capture stdout; stderr not needed here
shell_out_file="${tmp_root}/shell.out"
if ! zsh -lic "${inner_script}" > "${shell_out_file}" 2>"${tmp_root}/shell.err"; then
  add_fail "zsh_execution_failed"
fi
#
dbg "Shell stdout:"
dbg "$(sed 's/^/[shell-out] /' "${shell_out_file}")"
#
###############################################################################
# Extract markers from shell run
###############################################################################
#
layer_set="$(grep '^LAYER_MARKER=' "${shell_out_file}" | head -1 | sed 's/^LAYER_MARKER=//')"
cap_file="$(grep '^CAP_FILE=' "${shell_out_file}" | head -1 | sed 's/^CAP_FILE=//')"
cap_enabled="$(grep '^CAP_ENABLED=' "${shell_out_file}" | head -1 | sed 's/^CAP_ENABLED=//')"
#
[[ -z "${cap_file}" || "${cap_file}" == "unset" ]] && add_fail "capture_file_missing"
[[ "${cap_enabled}" != "1" ]] && add_fail "capture_not_enabled"
#
if [[ -n "${cap_file}" && -f "${cap_file}" ]]; then
  segment_count="$(wc -l < "${cap_file}" | tr -d '[:space:]')"
else
  segment_count=0
fi
#
if [[ "${segment_count}" -lt "${SEG_CAPTURE_MIN_LINES}" ]]; then
  add_fail "insufficient_segments(${segment_count}<${SEG_CAPTURE_MIN_LINES})"
fi
#
###############################################################################
# Basic JSON structural validation
###############################################################################
#
if [[ -f "${cap_file}" ]]; then
  # Regex check for mandatory keys
  if ! grep -q '"type":"segment"' "${cap_file}"; then
    add_fail "missing_type_segment"
  fi
  if ! grep -q '"segment":"' "${cap_file}"; then
    add_fail "missing_segment_field"
  fi
  if ! grep -Eq '"elapsed_ms":[0-9]+' "${cap_file}"; then
    add_fail "missing_elapsed_ms_numeric"
  fi
#
  # Optional: strict parse with python if available
  if command -v python3 >/dev/null 2>&1; then
    if ! python3 - <<'PYEOF'
import sys, json
path = sys.argv[1]
ok = True
with open(path,'r',encoding='utf-8') as fh:
    for i,line in enumerate(fh,1):
        line=line.strip()
        if not line:
            continue
        try:
            obj=json.loads(line)
            if obj.get("type")!="segment":
                ok=False
                print(f"PY_VALIDATE: line {i} missing type=segment", file=sys.stderr)
            if "segment" not in obj:
                ok=False
                print(f"PY_VALIDATE: line {i} missing segment", file=sys.stderr)
            if "elapsed_ms" not in obj:
                ok=False
                print(f"PY_VALIDATE: line {i} missing elapsed_ms", file=sys.stderr)
        except Exception as e:
            ok=False
            print(f"PY_VALIDATE: JSON error line {i}: {e}", file=sys.stderr)
if not ok:
    sys.exit(2)
PYEOF
    then
      add_fail "python_json_validation_failed"
    fi
  fi
fi
#
###############################################################################
# Sample display (optional)
###############################################################################
#
if [[ "${SHOW_SAMPLE}" == "1" && -f "${cap_file}" ]]; then
  {
    echo "--- Segment Capture Sample (first 2 lines) ---"
    head -n 2 "${cap_file}"
    echo "---------------------------------------------"
  } >&2
fi
#
###############################################################################
# Summary + Exit
###############################################################################
#
if [[ ${#fail_reasons[@]} -eq 0 ]]; then
  echo "live_segment_capture=PASS"
  failures="none"
  exit_code=0
else
  echo "live_segment_capture=FAIL"
  failures="$(IFS=,; echo "${fail_reasons[*]}")"
  exit_code=1
fi
#
echo "segments_logged=${segment_count:-0}"
echo "capture_file=${cap_file:-none}"
echo "layer_set=${layer_set:-unset}"
echo "failures=${failures}"
#
exit "${exit_code}"
