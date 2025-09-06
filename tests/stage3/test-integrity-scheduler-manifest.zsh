#!/usr/bin/env zsh
# ============================================================================
# test-integrity-scheduler-manifest.zsh
#
# Purpose:
#     Validate that sourcing the Stage 3 security integrity scaffold
#     (00-security-integrity.zsh) produces a single integrity scheduler
#     manifest with correct schema and idempotent re-sourcing behavior.
#
# Assertions:
#   A1: Security integrity module sources successfully (guard + scheduler flags)
#   A2: Manifest path variable (ZSH_SEC_INTEGRITY_MANIFEST) exported and file exists
#   A3: Manifest JSON contains required keys:
#         - schema == "integrity-scheduler.v1"
#         - version == 1
#         - registered_at is non-empty (timestamp-like or "unknown")
#   A4: Re-sourcing module does not modify manifest content (idempotent)
#   A5: Only one registration (flag remains "1"; no duplicate artifacts produced)
#
# Exit Codes:
#   0 = all assertions passed
#   1 = one or more assertions failed / precondition failure
#
# Style:
#   4-space indentation (EditorConfig compliance)
#
# Notes:
#   - Runs in a pristine environment (env -i) to avoid user shell contamination.
#   - Does not rely on jq; parses JSON with grep/sed/awk (best-effort, stable schema).
#   - Uses cksum for content stability (fallback to byte length if cksum missing).
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${(%):-%N}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"
ZSH_DIR="${REPO_ROOT}/dot-config/zsh"
SEC_MODULE_REL=".zshrc.d.REDESIGN/POSTPLUGIN/00-security-integrity.zsh"
SEC_MODULE_PATH="${ZSH_DIR}/${SEC_MODULE_REL}"

# ---------------- Precondition Checks ----------------
if [[ ! -d "${ZSH_DIR}" ]]; then
    print -u2 "FAIL: prerequisite - ZSH_DIR missing at ${ZSH_DIR}"
    exit 1
fi
if [[ ! -f "${ZSH_DIR}/.zshenv" ]]; then
    print -u2 "FAIL: prerequisite - .zshenv missing at ${ZSH_DIR}/.zshenv"
    exit 1
fi
if [[ ! -f "${SEC_MODULE_PATH}" ]]; then
    print -u2 "FAIL: prerequisite - security integrity module missing at ${SEC_MODULE_PATH}"
    exit 1
fi

# ---------------- Test Payload (isolated subshell) ----------------
read -r -d '' ZSH_PAYLOAD <<'__ZSH_EOF__'
set -euo pipefail

_pass=()
_fail=()

pass() { _pass+=("$1"); }
fail() { _fail+=("$1"); }

record_final() {
    for p in "${_pass[@]}"; do
        print "PASS: $p"
    done
    for f in "${_fail[@]}"; do
        print "FAIL: $f"
    done
    print "---"
    print "SUMMARY: passes=${#_pass[@]} fails=${#_fail[@]}"
    (( ${#_fail[@]} == 0 )) || exit 1
}

# Source security integrity module
if ! source "${TEST_SEC_MODULE}"; then
    fail "A1: source-module (sourcing failed)"
else
    if [[ "${ZSH_SEC_INTEGRITY_GUARD:-0}" == "1" && "${ZSH_SEC_INTEGRITY_SCHEDULER_REGISTERED:-0}" == "1" ]]; then
        pass "A1: source-module"
    else
        fail "A1: source-module (guard or scheduler flag missing)"
    fi
fi

# A2: Manifest variable + file existence
if [[ -n "${ZSH_SEC_INTEGRITY_MANIFEST:-}" && -f "${ZSH_SEC_INTEGRITY_MANIFEST}" ]]; then
    MANIFEST="${ZSH_SEC_INTEGRITY_MANIFEST}"
    pass "A2: manifest-present"
else
    fail "A2: manifest-present (variable or file missing)"
    record_final
    exit 1
fi

# Capture initial checksum or size
manifest_cksum_cmd=""
if command -v cksum >/dev/null 2>&1; then
    manifest_cksum_cmd="cksum"
fi

if [[ -n "${manifest_cksum_cmd}" ]]; then
    CK_BEFORE="$($manifest_cksum_cmd < "$MANIFEST" | awk '{print $1":"$2}')"
else
    CK_BEFORE="$(wc -c < "$MANIFEST" | tr -d '[:space:]'):bytes"
fi

# Parse JSON (minimal schema check)
schema="$(grep -E '"schema"' "$MANIFEST" 2>/dev/null | head -1 | sed -E 's/.*"schema"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' || true)"
version_val="$(grep -E '"version"' "$MANIFEST" 2>/dev/null | head -1 | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' || true)"
registered_at="$(grep -E '"registered_at"' "$MANIFEST" 2>/dev/null | head -1 | sed -E 's/.*"registered_at"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' || true)"

# A3: Schema fields validations
if [[ "$schema" == "integrity-scheduler.v1" ]]; then
    pass "A3: schema"
else
    fail "A3: schema (found '$schema')"
fi

if [[ "$version_val" == "1" ]]; then
    pass "A3: version"
else
    fail "A3: version (found '$version_val')"
fi

if [[ -n "$registered_at" ]]; then
    # Accept either timestamp pattern or 'unknown'
    if [[ "$registered_at" == "unknown" || "$registered_at" =~ ^[0-9]{8}T[0-9]{6}$ ]]; then
        pass "A3: registered_at"
    else
        fail "A3: registered_at (format unexpected: $registered_at)"
    fi
else
    fail "A3: registered_at (missing)"
fi

# Re-source module (should be idempotent; content unchanged)
if ! source "${TEST_SEC_MODULE}"; then
    fail "A4: resourcing (second source failed)"
else
    # Confirm flags not redefined incorrectly
    if [[ "${ZSH_SEC_INTEGRITY_SCHEDULER_REGISTERED:-0}" == "1" ]]; then
        pass "A5: single-registration-flag"
    else
        fail "A5: single-registration-flag (flag lost)"
    fi
fi

# Recompute checksum
if [[ -n "${manifest_cksum_cmd}" ]]; then
    CK_AFTER="$($manifest_cksum_cmd < "$MANIFEST" | awk '{print $1":"$2}')"
else
    CK_AFTER="$(wc -c < "$MANIFEST" | tr -d '[:space:]'):bytes"
fi

if [[ "$CK_BEFORE" == "$CK_AFTER" ]]; then
    pass "A4: idempotent-manifest"
else
    fail "A4: idempotent-manifest (checksum changed: $CK_BEFORE -> $CK_AFTER)"
fi

record_final
exit 0
__ZSH_EOF__

set +e
RAW_OUTPUT="$(
    env -i \
        HOME="$HOME" \
        ZDOTDIR="$ZSH_DIR" \
        TEST_SEC_MODULE="$SEC_MODULE_PATH" \
        PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/homebrew/bin" \
        TERM=dumb \
        ZSH_DEBUG=0 \
        zsh -dfc "${ZSH_PAYLOAD}"
)"
rc=$?
set -e

print -- "${RAW_OUTPUT}"

if (( rc != 0 )); then
    print -u2 "TEST RESULT: FAIL (rc=${rc})"
    exit $rc
fi

print "TEST RESULT: PASS"
exit 0
