#!/usr/bin/env zsh
# test-structured-telemetry-schema.zsh (test)
# Compliant with ${HOME}/.config/ai/guidelines.md v900f08def0e6f7959ffd283aebb73b625b3473f5e49c57e861c6461b50a62ef2
#
# PURPOSE:
#   Validates the structured telemetry schema validator script:
#     tools/test-structured-telemetry-schema.zsh
#   Ensures:
#     1. Valid segment JSON lines pass in strict mode (exit 0).
#     2. Unknown key causes failure in strict mode (exit != 0).
#     3. Unknown key is tolerated (non-fatal) in non-strict mode (exit 0).
#   This enforces privacy & schema drift guardrails (future task A/B dependencies).
#
# TEST CASES:
#   - CASE 1: Strict validation of valid lines   -> PASS expected
#   - CASE 2: Strict validation with extra key   -> FAIL expected
#   - CASE 3: Non-strict validation with extra key -> PASS expected
#
# EXIT CODES:
#   0 success (all assertions passed)
#   1 internal test failure or missing validator
#
# NOTES:
#   - Test is self-contained; does not depend on external jq (validator handles absence).
#   - Uses mktemp for isolated fixtures.
#   - Avoids leaving artifacts on disk.
#
# FUTURE EXTENSION:
#   - Add schema evolution test (adding allowed key via env override then validating).
#   - Add DEFERRED type objects once implemented.
#
# AUTHOR: AI Orchestration – Telemetry Governance Tests

set -euo pipefail

SCRIPT_UNDER_TEST="${0:A:h:h:h}/tools/test-structured-telemetry-schema.zsh"  # ascend from tests/performance/telemetry
[[ -x "$SCRIPT_UNDER_TEST" ]] || {
  print -r -- "FAIL: Missing or non-executable validator script at $SCRIPT_UNDER_TEST" >&2
  exit 1
}

_fail() {
  print -r -- "FAIL: $*" >&2
  exit 1
}

_warn() {
  print -r -- "WARN: $*" >&2
}

_pass() {
  print -r -- "PASS: $*"
}

# Create temp workspace
WORKDIR="$(mktemp -d 2>/dev/null || mktemp -d -t telem-schema-test)"
trap 'rm -rf "$WORKDIR"' EXIT INT TERM

VALID_FILE="${WORKDIR}/valid.jsonl"
INVALID_FILE="${WORKDIR}/invalid.jsonl"
NON_STRICT_FILE="${WORKDIR}/non_strict.jsonl"

# ---------------------------------------------------------------------------
# Fixture: Valid lines
# ---------------------------------------------------------------------------
cat > "$VALID_FILE" <<'JSON'
{"type":"segment","name":"pre_plugin_start","ms":0,"phase":"pre_plugin","sample":"cold","ts":1690000000000}
{"type":"segment","name":"post_plugin_total","ms":185,"phase":"post_plugin","sample":"cold","ts":1690000000200}
{"type":"segment","name":"prompt_ready","ms":334,"phase":"prompt","sample":"cold","ts":1690000000334}
JSON

# ---------------------------------------------------------------------------
# Fixture: Invalid (adds disallowed key "secret")
# ---------------------------------------------------------------------------
cat > "$INVALID_FILE" <<'JSON'
{"type":"segment","name":"pre_plugin_start","ms":0,"phase":"pre_plugin","sample":"cold","ts":1690000000000}
{"type":"segment","name":"security/validation","ms":2,"phase":"post_plugin","sample":"cold","ts":1690000000100,"secret":"leak"}
JSON

# ---------------------------------------------------------------------------
# Fixture: Non-strict (same invalid line should pass)
# ---------------------------------------------------------------------------
cp "$INVALID_FILE" "$NON_STRICT_FILE"

# ---------------------------------------------------------------------------
# CASE 1: Strict validation should pass on valid file
# ---------------------------------------------------------------------------
if ! "$SCRIPT_UNDER_TEST" --file "$VALID_FILE" --strict --quiet >/dev/null 2>&1; then
  _fail "Strict validation failed on valid segment lines"
else
  _pass "Strict validation passed on valid segment lines"
fi

# ---------------------------------------------------------------------------
# CASE 2: Strict validation must fail on invalid file (unknown key)
# ---------------------------------------------------------------------------
if "$SCRIPT_UNDER_TEST" --file "$INVALID_FILE" --strict --quiet >/dev/null 2>&1; then
  _fail "Strict validation unexpectedly passed with unknown key"
else
  _pass "Strict validation correctly failed with unknown key"
fi

# ---------------------------------------------------------------------------
# CASE 3: Non-strict validation should pass (warning expected) on same invalid file
# ---------------------------------------------------------------------------
if ! "$SCRIPT_UNDER_TEST" --file "$NON_STRICT_FILE" --quiet >/dev/null 2>&1; then
  _fail "Non-strict validation failed unexpectedly on file with unknown key"
else
  _pass "Non-strict validation tolerated unknown key as expected"
fi

# ---------------------------------------------------------------------------
# CASE 4: Max-lines sampling (ensure option does not break parsing)
# ---------------------------------------------------------------------------
if ! "$SCRIPT_UNDER_TEST" --file "$VALID_FILE" --max-lines 1 --strict --quiet >/dev/null 2>&1; then
  _fail "Strict validation with --max-lines failed unexpectedly"
else
  _pass "Strict validation with --max-lines succeeded"
fi

# ---------------------------------------------------------------------------
# (Optional) CASE 5: stdin path (sample one line)
# ---------------------------------------------------------------------------
head -n1 "$VALID_FILE" | if ! "$SCRIPT_UNDER_TEST" --stdin --strict --quiet >/dev/null 2>&1; then
  _fail "Strict validation via stdin failed"
else
  _pass "Strict validation via stdin succeeded"
fi

# All assertions passed
exit 0
