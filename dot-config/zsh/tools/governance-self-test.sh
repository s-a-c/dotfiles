#!/usr/bin/env bash
# governance-self-test.sh
#
# Combined governance self-test harness for fix-zle redesign.
#
# Purpose:
#   Execute deterministic, zero‑noise self-tests for governance enforcement tools:
#     1. Stray artifact detector
#     2. Redirection misuse lint
#     3. (Optional) Emergency widget floor probe (authentic + extended summary)
#
#   Produces a single JSON (and optional human summary) suitable for CI gating
#   and promotion preflight validation. Ensures that tool self-tests themselves
#   are stable and fail fast if regressions occur in their internal logic.
#
# Features:
#   - Pure bash (no jq dependency)
#   - Deterministic outputs (uses each tool's --self-test / controlled mode)
#   - Optional emergency widget count integration (with extended mode flag)
#   - Clear exit codes & aggregated status
#
# Exit Codes:
#   0 = All required self-tests passed (and optional emergency check if requested)
#   1 = One or more required self-tests failed / emergency floor breach
#   2 = Usage error
#
# JSON Schema (example):
# {
#   "status": "ok" | "fail",
#   "timestamp": "2025-10-02T12:34:56Z",
#   "tools": {
#     "stray_artifacts": {...},        # Final JSON object line from tool (self_test_pass if OK)
#     "redirection_lint": {...},
#     "emergency": {
#        "status":"ok",
#        "widgets":474,
#        "method":"script",
#        "extended_widgets":474,
#        "extended_core":1,
#        "extended_synthetic":0
#     } | null
#   },
#   "summary": {
#     "stray_pass": true,
#     "redirection_pass": true,
#     "emergency_checked": true,
#     "emergency_widgets": 474,
#     "emergency_extended_widgets": 474,
#     "emergency_core_authentic": 1,
#     "emergency_synthetic": 0,
#     "failures": []
#   }
# }
#
# Notes on Tool Behaviors:
#   - detect-stray-artifacts self-test currently emits TWO JSON objects:
#       (a) scan result with violations
#       (b) self_test_pass summary
#     We intentionally capture the LAST JSON line to standardize behavior.
#   - lint-redirections self-test short-circuits with a single PASS object.
#   - emergency-widget-count does not have a self-test mode; we just call it
#     (optionally with ZF_EMERGENCY_EXTEND=1) and parse extended summary fields if present.
#
# Safety:
#   - set -euo pipefail
#   - All optional variables guarded
#
# Usage:
#   governance-self-test.sh [--json] [--quiet] [--include-emergency] [--emergency-extend]
#                           [--emergency-floor <int>] [--emergency-zshrc <path>]
#
# Options:
#   --json                 Emit JSON (always emitted if requested; human summary suppressed unless --quiet omitted)
#   --quiet                Suppress human-readable summary (still sets exit code)
#   --include-emergency    Include emergency widget check (not a self-test; real measurement)
#   --emergency-extend     Set ZF_EMERGENCY_EXTEND=1 while measuring emergency widgets
#   --emergency-floor <n>  Enforce minimum floor (default: 387) when emergency is included
#   --emergency-zshrc <p>  Override path to emergency rc (default: .zshrc.emergency relative to CWD)
#   --help                 Show help
#
# Environment Overrides:
#   GOV_SELFTEST_JSON=1
#   GOV_SELFTEST_QUIET=1
#   GOV_INCLUDE_EMERGENCY=1
#   GOV_EMERGENCY_EXTEND=1
#   GOV_EMERGENCY_FLOOR (int)
#   GOV_EMERGENCY_ZSHRC (path)
#
# Limitations:
#   - Does not (yet) integrate redirection / stray detector real scans; this harness
#     focuses strictly on tool health. Real scans remain in CI workflow steps.
#
# Author: fix-zle governance automation
# License: MIT (inherit project policy)
#
# -----------------------------------------------------------------------------

set -euo pipefail

# ---------------------------
# Defaults / State
# ---------------------------
JSON=${GOV_SELFTEST_JSON:-0}
QUIET=${GOV_SELFTEST_QUIET:-0}
INCLUDE_EMERGENCY=${GOV_INCLUDE_EMERGENCY:-0}
EMERGENCY_EXTEND=${GOV_EMERGENCY_EXTEND:-0}
EMERGENCY_FLOOR=${GOV_EMERGENCY_FLOOR:-387}
EMERGENCY_ZSHRC=${GOV_EMERGENCY_ZSHRC:-".zshrc.emergency"}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR%/tools}"

FAILURES=()

print_help() {
  sed -n '1,/^# -----------------------------------------------------------------------------/p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

timestamp_utc() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

json_escape() {
  local s=${1:-}
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  s=${s//$'\r'/\\r}
  s=${s//$'\t'/\\t}
  printf '%s' "$s"
}

extract_last_json_line() {
  # Reads stdin, prints last line starting with {
  grep -E '^\{' | tail -n1 || true
}

# ---------------------------
# Argument Parsing
# ---------------------------
while (($#)); do
  case "$1" in
    --json) JSON=1 ;;
    --quiet) QUIET=1 ;;
    --include-emergency) INCLUDE_EMERGENCY=1 ;;
    --emergency-extend) EMERGENCY_EXTEND=1 ;;
    --emergency-floor)
      shift || { echo "ERROR: --emergency-floor requires value" >&2; exit 2; }
      EMERGENCY_FLOOR="$1"
      ;;
    --emergency-zshrc)
      shift || { echo "ERROR: --emergency-zshrc requires value" >&2; exit 2; }
      EMERGENCY_ZSHRC="$1"
      ;;
    --help|-h) print_help ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      exit 2
      ;;
  esac
  shift
done

# ---------------------------
# Locate Tools
# ---------------------------
STRAY="${SCRIPT_DIR}/detect-stray-artifacts.zsh"
REDIR="${SCRIPT_DIR}/lint-redirections.zsh"
EMERG_COUNT="${SCRIPT_DIR}/emergency-widget-count.sh"

tool_exists() { [[ -x "$1" ]]; }

# ---------------------------
# Run Stray Artifact Self-Test
# ---------------------------
run_stray_self_test() {
  if ! tool_exists "$STRAY"; then
    echo '{"status":"missing","error":"script_not_found"}'
    return 0
  fi
  # Intentionally run with --self-test --json; capture last JSON line (self_test_pass expected)
  local out tmp
  tmp="$(mktemp)"
  if ! zsh "$STRAY" --self-test --json >"$tmp" 2>&1; then
    # Non-zero not necessarily fatal if self_test_pass was printed last; capture anyway
    :
  fi
  out="$(extract_last_json_line <"$tmp")"
  rm -f "$tmp"
  if [[ -z "$out" ]]; then
    echo '{"status":"fail","error":"no_json"}'
  else
    echo "$out"
  fi
}

# ---------------------------
# Run Redirection Lint Self-Test
# ---------------------------
run_redir_self_test() {
  if ! tool_exists "$REDIR"; then
    echo '{"status":"missing","error":"script_not_found"}'
    return 0
  fi
  local out
  if ! out="$(zsh "$REDIR" --self-test --json 2>&1)"; then
    # Script short-circuits with exit 0; any non-zero is abnormal but capture output
    :
  fi
  # Expect single JSON line
  local line
  line="$(printf '%s\n' "$out" | extract_last_json_line)"
  if [[ -z "$line" ]]; then
    echo '{"status":"fail","error":"no_json"}'
  else
    echo "$line"
  fi
}

# ---------------------------
# Run Emergency (Optional)
# ---------------------------
run_emergency_check() {
  if (( INCLUDE_EMERGENCY == 0 )); then
    echo "null"
    return 0
  fi
  if ! tool_exists "$EMERG_COUNT"; then
    echo '{"status":"missing","error":"script_not_found"}'
    FAILURES+=("emergency_missing")
    return 0
  fi

  local raw json tmp env_prefix
  tmp="$(mktemp)"

  # Build environment invocation
  if (( EMERGENCY_EXTEND == 1 )); then
    ZF_EMERGENCY_EXTEND=1 EMERGENCY_ZSHRC_PATH="$EMERGENCY_ZSHRC" bash "$EMERG_COUNT" --json >"$tmp" 2>&1 || true
  else
    EMERGENCY_ZSHRC_PATH="$EMERGENCY_ZSHRC" bash "$EMERG_COUNT" --json >"$tmp" 2>&1 || true
  fi

  json="$(extract_last_json_line <"$tmp")"
  raw="$(cat "$tmp")"
  rm -f "$tmp"

  if [[ -z "$json" ]]; then
    echo '{"status":"fail","error":"no_json"}'
    FAILURES+=("emergency_no_json")
    return 0
  fi
  echo "$json"
}

# ---------------------------
# Execute Tests
# ---------------------------
stray_json="$(run_stray_self_test)"
redir_json="$(run_redir_self_test)"
emerg_json="$(run_emergency_check)"

# ---------------------------
# Parse Key Fields (Minimal Parsing by Regex)
# ---------------------------
# We only need status fields and emergency widget counts for summary logic.

extract_status() {
  # args: json_string
  local s
  s="$(printf '%s' "$1" | sed -n 's/.*"status"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
  [[ -n "$s" ]] || s="unknown"
  printf '%s' "$s"
}

extract_int_field() {
  # args: json name
  local j="$1" f="$2"
  local v
  # More robust (handles ordering/embedded objects) by isolating the key:value pair first
  v="$(printf '%s\n' "$j" | grep -Eo '\"'"$f"'\"[[:space:]]*:[[:space:]]*[0-9]+' | head -n1 | grep -Eo '[0-9]+' || true)"
  [[ -n "$v" ]] || v=0
  printf '%s' "$v"
}

stray_status="$(extract_status "$stray_json")"
redir_status="$(extract_status "$redir_json")"
emerg_status="skipped"
emerg_widgets=0
emerg_ext_widgets=0
emerg_core=0
emerg_synth=0

if (( INCLUDE_EMERGENCY == 1 )); then
  if [[ "$emerg_json" != "null" ]]; then
    emerg_status="$(extract_status "$emerg_json")"
    emerg_widgets="$(extract_int_field "$emerg_json" widgets)"
    emerg_ext_widgets="$(extract_int_field "$emerg_json" extended_widgets)"
    emerg_core="$(extract_int_field "$emerg_json" extended_core)"
    emerg_synth="$(extract_int_field "$emerg_json" extended_synthetic)"
    # Prefer extended widget count when present (>0) for all subsequent logic & reporting
    if (( emerg_ext_widgets > 0 )); then
      emerg_widgets="$emerg_ext_widgets"
    fi
  else
    emerg_status="null"
  fi
fi

# Determine pass/fail conditions
overall_status="ok"

if [[ "$stray_status" != "self_test_pass" && "$stray_status" != "ok" ]]; then
  overall_status="fail"
  FAILURES+=("stray_self_test_failed:$stray_status")
fi
if [[ "$redir_status" != "self_test_pass" && "$redir_status" != "ok" ]]; then
  overall_status="fail"
  FAILURES+=("redirection_self_test_failed:$redir_status")
fi
if (( INCLUDE_EMERGENCY == 1 )); then
  if [[ "$emerg_status" != "ok" ]]; then
    # emergency script returning "error" should fail harness
    overall_status="fail"
    FAILURES+=("emergency_status:$emerg_status")
  else
    # Floor evaluation uses effective (possibly extended) widget count
    if (( emerg_widgets < EMERGENCY_FLOOR )); then
      overall_status="fail"
      FAILURES+=("emergency_floor_breach:${emerg_widgets}<${EMERGENCY_FLOOR}")
    fi
  fi
fi

# ---------------------------
# Human Summary (if not quiet)
# ---------------------------
if (( QUIET == 0 )); then
  echo "[governance] Stray artifacts self-test: $stray_status"
  echo "[governance] Redirection lint self-test: $redir_status"
  if (( INCLUDE_EMERGENCY == 1 )); then
    echo "[governance] Emergency: status=$emerg_status widgets=$emerg_widgets extended_widgets=$emerg_ext_widgets core=$emerg_core synthetic=$emerg_synth floor=$EMERGENCY_FLOOR"
  else
    echo "[governance] Emergency: (skipped)"
  fi
  if [[ "${#FAILURES[@]}" -gt 0 ]]; then
    echo "[governance] FAILURES: ${FAILURES[*]}"
  else
    echo "[governance] All governance self-tests passed"
  fi
fi

# ---------------------------
# JSON Assembly
# ---------------------------
if (( JSON == 1 )); then
  # Escape raw tool JSON fragments (already JSON objects) by embedding directly (assumed valid)
  printf '{'
  printf '"status":"%s",' "$(json_escape "$overall_status")"
  printf '"timestamp":"%s",' "$(timestamp_utc)"
  printf '"tools":{'
  printf '"stray_artifacts":%s,' "${stray_json:-null}"
  printf '"redirection_lint":%s,' "${redir_json:-null}"
  if (( INCLUDE_EMERGENCY == 1 )); then
    printf '"emergency":%s' "${emerg_json:-null}"
  else
    printf '"emergency":null'
  fi
  printf '},'
  printf '"summary":{'
  printf '"stray_pass":%s,' "$([[ "$stray_status" == "self_test_pass" || "$stray_status" == "ok" ]] && echo true || echo false)"
  printf '"redirection_pass":%s,' "$([[ "$redir_status" == "self_test_pass" || "$redir_status" == "ok" ]] && echo true || echo false)"
  printf '"emergency_checked":%s,' "$(( INCLUDE_EMERGENCY ))"
  printf '"emergency_widgets":%d,' "$emerg_widgets"
  printf '"emergency_extended_widgets":%d,' "$emerg_ext_widgets"
  printf '"emergency_core_authentic":%d,' "$emerg_core"
  printf '"emergency_synthetic":%d,' "$emerg_synth"
  printf '"emergency_floor":%d,' "$EMERGENCY_FLOOR"
  printf '"failures":['
  if [[ "${#FAILURES[@]}" -gt 0 ]]; then
    for i in "${!FAILURES[@]}"; do
      [[ $i -gt 0 ]] && printf ','
      printf '"%s"' "$(json_escape "${FAILURES[$i]}")"
    done
  fi
  printf ']}' # end summary
  printf '}\n'
fi

# ---------------------------
# Exit
# ---------------------------
if [[ "$overall_status" == "fail" ]]; then
  exit 1
fi
exit 0
