#!/usr/bin/env bash

########################################################################
# run-local-validation.sh - fix-zle local validation convenience runner
#
# Phase Alignment:
#   - Phase 7 (Optional Enhancements) Decision D2: enhanced autopair PTY harness
#   - Future Phase (Deferred) Decision D14: segment instrumentation placeholder
#
# Purpose:
#   Provide a single, ergonomic entrypoint for local developers to:
#     * Run the smoke + autopair (basic + PTY) + aggregator pipeline
#     * Capture artifacts (compact & pretty JSON + summary)
#     * Optionally enforce autopair presence / behavioral success
#     * Optionally embed prototype segment instrumentation JSON
#     * Observe widget baseline / post-run delta and highlight regressions
#
# Policy Conformance:
#   - Minimal, auditable logic (wrapper around existing test harnesses)
#   - Nounset-safe parameter expansion
#   - No silent failure; explicit non-zero exits for actionable errors
#
# Exit Codes:
#   0  Success (all required checks pass)
#   1  Aggregated tests failed (status=fail) or enforced condition unmet
#   2  Script usage / internal error (bad arguments, missing dependencies)
#
# Usage Examples:
#   Fast (presence only if no pexpect):   ./run-local-validation.sh --fast
#   Full PTY + enforce autopair:          ./run-local-validation.sh --full --require-autopair
#   With segment JSON:                    ./run-local-validation.sh --segment metrics/segments.json
#   Custom artifact dir:                  ./run-local-validation.sh -o ./my-artifacts
#
# Implementation Notes:
#   - Automatically detects if pexpect is importable to decide PTY enable (unless overridden)
#   - Delegates core logic to: docs/fix-zle/tests/aggregate-json-tests.sh
#   - Produces a concise console summary plus artifact files for diffing
#
########################################################################

set -euo pipefail

#############################################################################
# Defaults
#############################################################################
RUN_MODE="auto" # auto | fast | full
REQUIRE_AUTOPAIR=0
SEGMENT_FILE=""
OUTPUT_DIR="zsh/artifacts"
ARTIFACT_PREFIX="autopair"
PRETTY=1
FORCE_RUN_PTY="" # empty = auto; 0 = disable; 1 = force
NO_COLOR=${NO_COLOR:-0}

#############################################################################
# Helpers (local namespace: rlv::)
#############################################################################
rlv::usage() {
  cat <<'EOF'
Usage: run-local-validation.sh [options]

  --fast                  Skip PTY harness & post-smoke delta (fast presence check)
  --full                  Force PTY harness (if possible) + post-smoke delta
  --require-autopair      Treat missing / failing autopair as failure
  --segment <file>        Embed segment instrumentation JSON (D14 placeholder)
  --no-pretty             Do not pretty-print JSON copy
  --force-pty             Force PTY harness even if pexpect not detected
  --no-pty                Disable PTY harness even if available
  -o|--output-dir <dir>   Artifact output directory (default: zsh/artifacts)
  --artifact-prefix <p>   Prefix for artifact filenames (default: autopair)
  --help                  Show this help

Environment Overrides:
  RLV_REQUIRE_AUTOPAIR=1      (same as --require-autopair)
  RLV_SEGMENT_FILE=path       (same as --segment)
  RLV_FORCE_PTY=0|1           (override PTY auto detection)
  RLV_OUTPUT_DIR=dir          (same as --output-dir)
  RLV_ARTIFACT_PREFIX=prefix  (same as --artifact-prefix)
  RLV_PRETTY=0                (disable pretty output)

Exit Codes:
  0 success
  1 test failure / enforced requirement failed
  2 usage / internal error
EOF
}

rlv::log() {
  local level="$1"
  shift
  local msg="$*"
  if [[ ${NO_COLOR:-0} -eq 0 ]]; then
    case "$level" in
    INFO) printf "\033[34m[INFO]\033[0m %s\n" "$msg" ;;
    WARN) printf "\033[33m[WARN]\033[0m %s\n" "$msg" ;;
    ERROR) printf "\033[31m[ERROR]\033[0m %s\n" "$msg" ;;
    *) printf "[%s] %s\n" "$level" "$msg" ;;
    esac
  else
    printf "[%s] %s\n" "$level" "$msg"
  fi
}

rlv::fail() {
  rlv::log ERROR "$*"
  exit 2
}

#############################################################################
# Parse Environment Overrides
#############################################################################
REQUIRE_AUTOPAIR=${RLV_REQUIRE_AUTOPAIR:-$REQUIRE_AUTOPAIR}
SEGMENT_FILE=${RLV_SEGMENT_FILE:-$SEGMENT_FILE}
FORCE_RUN_PTY=${RLV_FORCE_PTY:-$FORCE_RUN_PTY}
OUTPUT_DIR=${RLV_OUTPUT_DIR:-$OUTPUT_DIR}
ARTIFACT_PREFIX=${RLV_ARTIFACT_PREFIX:-$ARTIFACT_PREFIX}
PRETTY=${RLV_PRETTY:-$PRETTY}

#############################################################################
# Parse CLI Arguments
#############################################################################
while (($#)); do
  case "$1" in
  --fast) RUN_MODE="fast" ;;
  --full) RUN_MODE="full" ;;
  --require-autopair) REQUIRE_AUTOPAIR=1 ;;
  --segment)
    shift || rlv::fail "--segment requires path"
    SEGMENT_FILE="$1"
    ;;
  --no-pretty) PRETTY=0 ;;
  --force-pty) FORCE_RUN_PTY=1 ;;
  --no-pty) FORCE_RUN_PTY=0 ;;
  -o | --output-dir)
    shift || rlv::fail "--output-dir requires path"
    OUTPUT_DIR="$1"
    ;;
  --artifact-prefix)
    shift || rlv::fail "--artifact-prefix requires value"
    ARTIFACT_PREFIX="$1"
    ;;
  --help | -h)
    rlv::usage
    exit 0
    ;;
  *) rlv::fail "Unknown argument: $1" ;;
  esac
  shift
done

#############################################################################
# Resolve Repository Root (assume script lives in docs/fix-zle/tests)
#############################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$SCRIPT_DIR"
DOCS_FIX_ZLE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ZSH_ROOT="$(cd "$DOCS_FIX_ZLE_DIR/../../.." && pwd)"

AGGREGATOR="$TESTS_DIR/aggregate-json-tests.sh"
SMOKE="$DOCS_FIX_ZLE_DIR/test-smoke.sh"

[[ -f "$AGGREGATOR" ]] || rlv::fail "Aggregator script not found: $AGGREGATOR"
[[ -f "$SMOKE" ]] || rlv::fail "Smoke script not found: $SMOKE"

#############################################################################
# Determine PTY Capability
#############################################################################
have_pexpect=0
if command -v python3 >/dev/null 2>&1; then
  python3 - <<'PY' >/dev/null 2>&1 || true
import importlib, sys
importlib.import_module("pexpect")
PY
  if [[ $? -eq 0 ]]; then have_pexpect=1; fi
elif command -v python >/dev/null 2>&1; then
  python - <<'PY' >/dev/null 2>&1 || true
import importlib, sys
importlib.import_module("pexpect")
PY
  if [[ $? -eq 0 ]]; then have_pexpect=1; fi
fi

# Decide PTY usage
RUN_PTY=0
case "$RUN_MODE" in
fast) RUN_PTY=0 ;;
full) RUN_PTY=1 ;;
auto)
  if [[ $have_pexpect -eq 1 ]]; then RUN_PTY=1; else RUN_PTY=0; fi
  ;;
esac
if [[ -n "${FORCE_RUN_PTY:-}" ]]; then
  if [[ $FORCE_RUN_PTY == 1 ]]; then RUN_PTY=1; fi
  if [[ $FORCE_RUN_PTY == 0 ]]; then RUN_PTY=0; fi
fi

if [[ $RUN_PTY -eq 1 && $have_pexpect -eq 0 ]]; then
  rlv::log WARN "Requested PTY run but pexpect not available; downgrading to basic mode."
  RUN_PTY=0
fi

#############################################################################
# Prepare Output Directory
#############################################################################
mkdir -p "$OUTPUT_DIR"

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
compact_json="$OUTPUT_DIR/${ARTIFACT_PREFIX}-report-${timestamp}.json"
pretty_json="$OUTPUT_DIR/${ARTIFACT_PREFIX}-report-${timestamp}.pretty.json"
summary_txt="$OUTPUT_DIR/${ARTIFACT_PREFIX}-summary-${timestamp}.txt"

#############################################################################
# Build Aggregator Command
#############################################################################
agg_cmd=(bash "$AGGREGATOR")
if [[ $RUN_PTY -eq 1 ]]; then
  agg_cmd+=(--run-pty)
fi
if [[ $REQUIRE_AUTOPAIR -eq 1 ]]; then
  agg_cmd+=(--require-autopair)
fi
if [[ -n "$SEGMENT_FILE" ]]; then
  agg_cmd+=(--segment-file "$SEGMENT_FILE")
fi
# Always capture post-smoke delta unless --fast chosen
if [[ $RUN_MODE == "fast" ]]; then
  agg_cmd+=(--no-post-smoke)
fi
agg_cmd+=(--output "$compact_json")

#############################################################################
# Execute Aggregator (compact JSON)
#############################################################################
rlv::log INFO "Running aggregator: ${agg_cmd[*]}"
if ! "${agg_cmd[@]}"; then
  rlv::log ERROR "Aggregator returned failure status (see JSON)."
  AGG_FAILURE=1
else
  AGG_FAILURE=0
fi

#############################################################################
# Pretty Print (optional)
#############################################################################
if [[ $PRETTY -eq 1 ]]; then
  if command -v python3 >/dev/null 2>&1; then
    python3 - <<PY 2>/dev/null >"$pretty_json" || cp "$compact_json" "$pretty_json"
import json,sys
with open("$compact_json","r",encoding="utf-8") as f:
    obj=json.load(f)
json.dump(obj, open("$pretty_json","w",encoding="utf-8"), indent=2, sort_keys=True)
PY
  elif command -v python >/dev/null 2>&1; then
    python - <<PY 2>/dev/null >"$pretty_json" || cp "$compact_json" "$pretty_json"
import json,sys
with open("$compact_json","r") as f:
    obj=json.load(f)
json.dump(obj, open("$pretty_json","w"), indent=2, sort_keys=True)
PY
  else
    cp "$compact_json" "$pretty_json"
  fi
else
  rlv::log INFO "Pretty-print disabled (--no-pretty)"
fi

#############################################################################
# Derive Summary Fields
#############################################################################
status=$(grep -Eo '"status":"(ok|fail)"' "$compact_json" | head -n1 | sed 's/.*"status":"//;s/"//')
widgets=$(grep -Eo '"widget_count":[0-9]+' "$compact_json" | head -n1 | cut -d: -f2 || echo 0)
widget_delta=$(grep -Eo '"widget_delta":(-?[0-9]+|null)' "$compact_json" | head -n1 | cut -d: -f2 || echo null)
autopair_present=$(grep -Eo '"autopair_present":(true|false)' "$compact_json" | head -n1 | cut -d: -f2 || echo false)
autopair_pty=$(grep -Eo '"autopair_pty_passed":(true|false|null)' "$compact_json" | head -n1 | cut -d: -f2 || echo null)
failures=$(grep -Eo '"failures":\[[^]]*]' "$compact_json" | sed 's/.*"failures"://' || echo "[]")

{
  echo "Validation Timestamp (UTC): $timestamp"
  echo "Status: $status"
  echo "Widget Count: $widgets"
  echo "Widget Delta: $widget_delta"
  echo "Autopair Present: $autopair_present"
  echo "Autopair PTY Passed: $autopair_pty"
  echo "Failures: $failures"
  echo "Compact JSON: $compact_json"
  if [[ $PRETTY -eq 1 ]]; then
    echo "Pretty JSON:  $pretty_json"
  fi
  if [[ -n "$SEGMENT_FILE" ]]; then
    echo "Segment File: $SEGMENT_FILE"
  fi
} | tee "$summary_txt"

#############################################################################
# Enforce Failure Semantics
#############################################################################
if [[ $AGG_FAILURE -eq 1 || "$status" == "fail" ]]; then
  rlv::log ERROR "Validation failed (aggregator status=fail). See artifacts."
  exit 1
fi

if [[ $REQUIRE_AUTOPAIR -eq 1 && "$autopair_present" != "true" ]]; then
  rlv::log ERROR "Autopair required but not present."
  exit 1
fi

rlv::log INFO "Validation succeeded."
exit 0
