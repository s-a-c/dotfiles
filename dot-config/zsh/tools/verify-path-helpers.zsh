#!/usr/bin/env zsh
# =============================================================================
# verify-path-helpers.zsh
#
# Purpose:
#   Diagnose availability, correctness, and consistency of the standardized
#   path resolution helpers used in the redesign: zf::script_dir and
#   resolve_script_dir. Designed for both interactive troubleshooting and
#   CI automation (JSON mode).
#
# Rationale:
#   Direct usage of the brittle ${0:A:h} expansion is prohibited. Central
#   helpers abstract nuances (symlinks, compilation contexts, early bootstrap).
#   This tool provides early warning if helpers vanish, regress, or behave
#   inconsistently, preventing subtle path-dependent breakage.
#
# Features:
#   * Detect helper presence (function definitions)
#   * Call helpers (if present) and capture return value
#   * Compare helper output consistency (same dir?)
#   * Fallback derive current script dir using ${(%):-%N}
#   * Optional assertion modes for CI: require "any", "both", "zf", or "resolve"
#   * Optional expected directory (sanity check)
#   * JSON output schema for machine parsing
#   * Quiet mode for exit-code-only usage
#
# Exit Codes:
#   0 Success (assertions satisfied)
#   1 Assertion failure (missing or inconsistent helpers)
#   2 Usage error (bad arguments)
#   3 Internal error (unexpected failure invoking helpers)
#
# JSON Schema (verify-path-helpers.v1):
# {
#   "schema":"verify-path-helpers.v1",
#   "script":"<this-script-abs-path>",
#   "helpers":{
#     "zf::script_dir":{"present":true,"call_status":"ok","value":"/abs/path"},
#     "resolve_script_dir":{"present":true,"call_status":"ok","value":"/abs/path"}
#   },
#   "consistency":{"same_dir":true,"expected_match":true},
#   "assert":{"mode":"both","passed":true},
#   "status":"ok",
#   "recommendation":""
# }
#
# Usage:
#   tools/verify-path-helpers.zsh
#   tools/verify-path-helpers.zsh --json
#   tools/verify-path-helpers.zsh --assert both --json
#   tools/verify-path-helpers.zsh --assert zf --expect-dir "$(pwd)"
#   tools/verify-path-helpers.zsh --quiet --assert both
#
# Options:
#   --json              Emit machine JSON instead of human summary
#   --quiet             Suppress human summary (still errors on stderr)
#   --assert <mode>     any|both|zf|resolve  (default: any)
#   --expect-dir <dir>  Assert helper(s) resolve to this (realpath canonical)
#   --allow-mismatch    Do not fail if helpers differ (report only)
#   --help | -h         Show help
#
# Notes:
#   * This script itself avoids ${0:A:h}. It uses ${(%):-%N}.
#   * If neither helper is present, assertion "any" fails only if --assert any
#     (i.e. any == at least one). Provide --assert both to require both.
#
# Style: 4-space indentation.
# =============================================================================
#
set -euo pipefail
#
SCRIPT_NAME="${0##*/}"
#
# Defaults
JSON_MODE=0
QUIET=0
ASSERT_MODE="any"
EXPECT_DIR=""
ALLOW_MISMATCH=0
#
# Storage
typeset -A HELPERS_PRESENT
typeset -A HELPERS_STATUS
typeset -A HELPERS_VALUE
#
# Internal
STATUS="ok"
ASSERT_PASSED=0
EXPECT_MATCH=1
SAME_DIR=1
#
json_escape() {
    # Escape backslash and double quotes, preserve other chars
    sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}
#
usage() {
    cat <<EOF
$SCRIPT_NAME - Verify standardized path resolution helpers
#
Usage:
  $SCRIPT_NAME [options]
#
Options:
  --json              Emit JSON
  --quiet             Suppress human summary output
  --assert <mode>     any|both|zf|resolve (default: any)
  --expect-dir <dir>  Require helpers (those asserted) to equal this directory
  --allow-mismatch    Do not treat differing helper outputs as assertion failure
  --help | -h         Show this help
#
Assertion Semantics:
  any      -> At least one helper present
  both     -> Both helpers present
  zf       -> zf::script_dir present
  resolve  -> resolve_script_dir present
#
Exit Codes:
  0 success; 1 assertion failure; 2 usage error; 3 internal error
EOF
}
#
die_usage() {
    printf '%s\n' "$1" >&2
    usage >&2
    exit 2
}
#
# -----------------------------------------------------------------------------
# Argument Parsing
# -----------------------------------------------------------------------------
while (( $# > 0 )); do
    case "$1" in
        --json) JSON_MODE=1 ;;
        --quiet) QUIET=1 ;;
        --assert)
            shift || die_usage "Missing value for --assert"
            ASSERT_MODE="$1"
            case "$ASSERT_MODE" in
                any|both|zf|resolve) ;;
                *) die_usage "Unknown --assert mode: $ASSERT_MODE" ;;
            esac
            ;;
        --expect-dir)
            shift || die_usage "Missing value for --expect-dir"
            EXPECT_DIR="$1"
            if [[ -n "$EXPECT_DIR" ]]; then
                if [[ ! -d "$EXPECT_DIR" ]]; then
                    printf '[verify-path-helpers] Warning: --expect-dir path does not exist: %s\n' "$EXPECT_DIR" >&2
                else
                    EXPECT_DIR="$(cd "$EXPECT_DIR" && pwd -P)"
                fi
            fi
            ;;
        --allow-mismatch) ALLOW_MISMATCH=1 ;;
        --help|-h) usage; exit 0 ;;
        *) die_usage "Unknown argument: $1" ;;
    esac
    shift
done
#
# -----------------------------------------------------------------------------
# Helper Detection
# -----------------------------------------------------------------------------
HELPERS_PRESENT["zf::script_dir"]=0
HELPERS_PRESENT["resolve_script_dir"]=0
#
if typeset -f zf::script_dir >/dev/null 2>&1; then
    HELPERS_PRESENT["zf::script_dir"]=1
fi
if typeset -f resolve_script_dir >/dev/null 2>&1; then
    HELPERS_PRESENT["resolve_script_dir"]=1
fi
#
# -----------------------------------------------------------------------------
# Invocation (capture values)
# -----------------------------------------------------------------------------
call_helper() {
    local name="$1"
    local out="" ec=0
    if (( HELPERS_PRESENT["$name"] == 0 )); then
        HELPERS_STATUS["$name"]="absent"
        HELPERS_VALUE["$name"]=""
        return 0
    fi
    # Protected call
    {
        case "$name" in
            zf::script_dir) out="$(zf::script_dir "${(%):-%N}" 2>/dev/null || true)" ;;
            resolve_script_dir) out="$(resolve_script_dir "${(%):-%N}" 2>/dev/null || true)" ;;
        esac
    } || ec=$?
    if (( ec != 0 )); then
        HELPERS_STATUS["$name"]="error:$ec"
        HELPERS_VALUE["$name"]="$out"
        return 0
    fi
    # Normalize if not empty
    if [[ -n "$out" && -d "$out" ]]; then
        local rp
        rp="$(cd "$out" 2>/dev/null && pwd -P 2>/dev/null || true)"
        [[ -n "$rp" ]] && out="$rp"
    fi
    if [[ -z "$out" ]]; then
        HELPERS_STATUS["$name"]="empty"
    else
        HELPERS_STATUS["$name"]="ok"
    fi
    HELPERS_VALUE["$name"]="$out"
}
#
call_helper "zf::script_dir"
call_helper "resolve_script_dir"
#
# -----------------------------------------------------------------------------
# Fallback script path
# -----------------------------------------------------------------------------
RAW_SCRIPT_SPEC="${(%):-%N}"
CANON_SCRIPT_DIR=""
if [[ -n "$RAW_SCRIPT_SPEC" && "$RAW_SCRIPT_SPEC" != "${RAW_SCRIPT_SPEC:t}" ]]; then
    CANON_SCRIPT_DIR="${RAW_SCRIPT_SPEC:A:h}" || true
fi
if [[ -z "$CANON_SCRIPT_DIR" ]]; then
    CANON_SCRIPT_DIR="$(pwd -P)"
fi
#
# -----------------------------------------------------------------------------
# Consistency Checks
# -----------------------------------------------------------------------------
zf_val="${HELPERS_VALUE["zf::script_dir"]}"
res_val="${HELPERS_VALUE["resolve_script_dir"]}"
#
if (( HELPERS_PRESENT["zf::script_dir"] == 1 && HELPERS_PRESENT["resolve_script_dir"] == 1 )); then
    if [[ -n "$zf_val" && -n "$res_val" && "$zf_val" != "$res_val" ]]; then
        SAME_DIR=0
    fi
fi
#
# EXPECT_DIR check
if [[ -n "$EXPECT_DIR" ]]; then
    # Only check helpers that are present & returned ok
    if [[ -n "$zf_val" && "$zf_val" != "$EXPECT_DIR" ]]; then
        EXPECT_MATCH=0
    fi
    if [[ -n "$res_val" && "$res_val" != "$EXPECT_DIR" ]]; then
        EXPECT_MATCH=0
    fi
fi
#
# -----------------------------------------------------------------------------
# Assertion Logic
# -----------------------------------------------------------------------------
case "$ASSERT_MODE" in
    any)
        if (( HELPERS_PRESENT["zf::script_dir"] == 1 || HELPERS_PRESENT["resolve_script_dir"] == 1 )); then
            ASSERT_PASSED=1
        fi
        ;;
    both)
        if (( HELPERS_PRESENT["zf::script_dir"] == 1 && HELPERS_PRESENT["resolve_script_dir"] == 1 )); then
            ASSERT_PASSED=1
        fi
        ;;
    zf)
        if (( HELPERS_PRESENT["zf::script_dir"] == 1 )); then
            ASSERT_PASSED=1
        fi
        ;;
    resolve)
        if (( HELPERS_PRESENT["resolve_script_dir"] == 1 )); then
            ASSERT_PASSED=1
        fi
        ;;
esac
#
# Additional failure conditions
if (( ASSERT_PASSED == 1 )); then
    # Fail if helper present but status not ok/empty (error)
    if [[ "${HELPERS_STATUS["zf::script_dir"]}" == error:* || "${HELPERS_STATUS["resolve_script_dir"]}" == error:* ]]; then
        ASSERT_PASSED=0
        STATUS="error"
    fi
    if (( SAME_DIR == 0 && ALLOW_MISMATCH == 0 && HELPERS_PRESENT["zf::script_dir"] == 1 && HELPERS_PRESENT["resolve_script_dir"] == 1 )); then
        ASSERT_PASSED=0
        STATUS="mismatch"
    fi
    if (( EXPECT_MATCH == 0 )); then
        ASSERT_PASSED=0
        STATUS="expected-mismatch"
    fi
else
    STATUS="missing"
fi
#
# Recommendation assembly
RECOMMENDATION=""
if (( ASSERT_PASSED == 0 )); then
    if [[ "$STATUS" == missing ]]; then
        RECOMMENDATION="Ensure .zshenv defines helpers early; verify no conditional guard prevents loading."
    elif [[ "$STATUS" == mismatch ]]; then
        RECOMMENDATION="Normalize implementation: both helpers should resolve identical canonical directory."
    elif [[ "$STATUS" == expected-mismatch ]]; then
        RECOMMENDATION="Adjust helper logic or fix --expect-dir value; mismatch indicates staging inconsistency."
    elif [[ "$STATUS" == error ]]; then
        RECOMMENDATION="Investigate helper runtime error (wrap logic in minimal reproducible snippet)."
    fi
else
    if (( HELPERS_PRESENT["zf::script_dir"] == 0 )); then
        RECOMMENDATION="Consider loading zf::script_dir earlier for uniformity."
    fi
fi
#
# -----------------------------------------------------------------------------
# Output
# -----------------------------------------------------------------------------
emit_json() {
    printf '{\n'
    printf '  "schema":"verify-path-helpers.v1",\n'
    printf '  "script":"%s",\n' "$(printf '%s' "${RAW_SCRIPT_SPEC}" | json_escape)"
    printf '  "helpers":{\n'
    printf '    "zf::script_dir":{"present":%s,"status":"%s","value":"%s"},\n' \
       "$(( HELPERS_PRESENT["zf::script_dir"] ))" "$(printf '%s' "${HELPERS_STATUS["zf::script_dir"]}" | json_escape)" "$(printf '%s' "${HELPERS_VALUE["zf::script_dir"]}" | json_escape)"
    printf '    "resolve_script_dir":{"present":%s,"status":"%s","value":"%s"}\n' \
       "$(( HELPERS_PRESENT["resolve_script_dir"] ))" "$(printf '%s' "${HELPERS_STATUS["resolve_script_dir"]}" | json_escape)" "$(printf '%s' "${HELPERS_VALUE["resolve_script_dir"]}" | json_escape)"
    printf '  },\n'
    printf '  "consistency":{"same_dir":%s,"expected_match":%s},\n' "$SAME_DIR" "$EXPECT_MATCH"
    printf '  "assert":{"mode":"%s","passed":%s},\n' "$(printf '%s' "$ASSERT_MODE" | json_escape)" "$ASSERT_PASSED"
    printf '  "status":"%s",\n' "$(printf '%s' "$STATUS" | json_escape)"
    printf '  "recommendation":"%s"\n' "$(printf '%s' "$RECOMMENDATION" | json_escape)"
    printf '}\n'
}
#
emit_human() {
    local pad="  "
    printf '%sVerification: Path Helpers\n' "$pad"
    printf '%sScript Spec: %s\n' "$pad" "${RAW_SCRIPT_SPEC}"
    printf '%sHelper Presence:\n' "$pad"
    printf '%s  zf::script_dir:        present=%s status=%s value=%s\n' "$pad" "${HELPERS_PRESENT["zf::script_dir"]}" "${HELPERS_STATUS["zf::script_dir"]}" "${HELPERS_VALUE["zf::script_dir"]:-<none>}"
    printf '%s  resolve_script_dir:    present=%s status=%s value=%s\n' "$pad" "${HELPERS_PRESENT["resolve_script_dir"]}" "${HELPERS_STATUS["resolve_script_dir"]}" "${HELPERS_VALUE["resolve_script_dir"]:-<none>}"
    printf '%sConsistency: same_dir=%s allow_mismatch=%s\n' "$pad" "$SAME_DIR" "$ALLOW_MISMATCH"
    if [[ -n "$EXPECT_DIR" ]]; then
        printf '%sExpect Dir: %s (match=%s)\n' "$pad" "$EXPECT_DIR" "$EXPECT_MATCH"
    fi
    printf '%sAssertion: mode=%s passed=%s status=%s\n' "$pad" "$ASSERT_MODE" "$ASSERT_PASSED" "$STATUS"
    if [[ -n "$RECOMMENDATION" ]]; then
        printf '%sRecommendation: %s\n' "$pad" "$RECOMMENDATION"
    fi
}
#
if (( JSON_MODE )); then
    emit_json
else
    (( QUIET )) || emit_human
fi
#
if (( ASSERT_PASSED == 1 )); then
    exit 0
else
    exit 1
fi
#
# End of file
