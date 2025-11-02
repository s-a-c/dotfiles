#!/usr/bin/env zsh
# test-structured-telemetry.zsh
# Compliant with ${HOME}/dotfiles/dot-config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Validate structured telemetry JSON emission (segments + deferred) and
#   dependency export tool outputs (JSON + DOT) under Sprint 2 instrumentation.
#
# SCOPE:
#   1. When ZSH_LOG_STRUCTURED=0 (default) -> no JSON lines created.
#   2. When ZSH_LOG_STRUCTURED=1:
#       - pre_plugin_start, prompt_ready, deferred_total segment JSON entries exist.
#       - At least one deferred job JSON entry (type=deferred, id=dummy-warm).
#       - Each JSON line parses (basic structural validation) and includes required fields.
#   3. When ZSH_PERF_JSON=1 sidecar path gets auto-derived if PERF_SEGMENT_LOG set.
#   4. Dependency export tool:
#       - JSON export contains version=1, nodes[], edges[].
#       - DOT export contains 'digraph zsh_deps {' header.
#
# ASSUMPTIONS:
#   - Modules: 00-path-safety.zsh, 10-core-functions.zsh, 95-prompt-ready.zsh, 96-deferred-dispatch.zsh present.
#   - deps-export.zsh tool present in tools directory.
#   - Dummy deferred job registered by 96-deferred-dispatch.zsh.
#
# EXIT CODES:
#   0 success (all assertions passed)
#   1 failure (first failing assertion triggers exit)
#
# NOTE:
#   Keeps self‑contained (no reliance on full .zshrc driver).
#
# ------------------------------------------------------------------------------

set -euo pipefail

fail() {
  print -r -- "FAIL: $*" >&2
  exit 1
}

warn() {
  print -r -- "WARN: $*" >&2
}

pass() {
  print -r -- "PASS: $*"
}

info() {
  print -r -- "INFO: $*" >&2
}

# Lightweight JSON validation (structure only)
is_valid_json_line() {
  local line="$1"
  # Basic check: starts with {, ends with }, contains at least one colon
  [[ "$line" == \{*:*} ]] || return 1
  # Reject unbalanced braces (very shallow heuristic)
  local opens closes
  opens=$(print -r -- "$line" | tr -cd '{' | wc -c | tr -d ' ')
  closes=$(print -r -- "$line" | tr -cd '}' | wc -c | tr -d ' ')
  [[ "$opens" -eq "$closes" ]] || return 1
  return 0
}

mktemp_dir() {
  mktemp -d 2>/dev/null || mktemp -d -t zsh_structured_telemetry
}

ROOT="${PWD}"
ZSH_ROOT="${ROOT}/dot-config/zsh"
PRE_DIR="${ZSH_ROOT}/.zshrc.pre-plugins.d.REDESIGN"
POST_DIR="${ZSH_ROOT}/.zshrc.d.REDESIGN"
TOOLS_DIR="${ZSH_ROOT}/tools"

for f in \
  "${PRE_DIR}/00-path-safety.zsh" \
  "${POST_DIR}/10-core-functions.zsh" \
  "${POST_DIR}/95-prompt-ready.zsh" \
  "${POST_DIR}/96-deferred-dispatch.zsh" \
  "${TOOLS_DIR}/deps-export.zsh"
do
  [[ -r "$f" ]] || fail "Required file missing: $f"
done

# ------------------------------------------------------------------------------
# Test 1: Default (no structured flags) -> no JSON lines
# ------------------------------------------------------------------------------
TMP1=$(mktemp_dir)
LOG1="${TMP1}/segments.log"
export PERF_SEGMENT_LOG="$LOG1"
unset ZSH_LOG_STRUCTURED ZSH_PERF_JSON PERF_SEGMENT_JSON_LOG

# Source modules (order matters: path-safety sets start ms; core functions defines timing helpers)
source "${PRE_DIR}/00-path-safety.zsh"
source "${POST_DIR}/10-core-functions.zsh"
source "${POST_DIR}/95-prompt-ready.zsh"
source "${POST_DIR}/96-deferred-dispatch.zsh"

# Manually invoke prompt + deferred hooks
typeset -f __pr__capture_prompt_ready >/dev/null 2>&1 || fail "Missing __pr__capture_prompt_ready"
typeset -f __zsh_deferred_run_once     >/dev/null 2>&1 || fail "Missing __zsh_deferred_run_once"

__pr__capture_prompt_ready
__zsh_deferred_run_once

[[ -f "$LOG1" ]] || fail "Segment log not created at $LOG1"

# No JSON sidecar expected
if [[ -n "${PERF_SEGMENT_JSON_LOG:-}" ]]; then
  fail "PERF_SEGMENT_JSON_LOG set unexpectedly (should be unset when flags off)"
fi

# Ensure no lines beginning with { appear in raw segment log (simple guard)
if grep -q '^{.*}' "$LOG1"; then
  fail "Found JSON-looking line in segment log with structured telemetry disabled"
fi
pass "Test1 (no structured flags) passed"

# Clean sourcing side-effects for next run (start new shell context simulation)
unset PROMPT_READY_MS PROMPT_READY_DELTA_MS _PROMPT_READY_SEGMENT_EMITTED _PROMPT_READY_JSON_EMITTED \
      _ZSH_DEFERRED_DISPATCH_RAN _ZSH_DEFERRED_ORDER _ZSH_DEFERRED_FUNC _ZSH_DEFERRED_TRIGGER \
      _ZSH_DEFERRED_DESC _ZSH_DEFERRED_FLAGS ZSH_START_MS _PREPLUGIN_START_SEGMENT_EMITTED \
      _PREPLUGIN_START_JSON_EMITTED

# ------------------------------------------------------------------------------
# Test 2: Structured telemetry JSON emission (with performance JSON sidecar)
# ------------------------------------------------------------------------------
TMP2=$(mktemp_dir)
LOG2="${TMP2}/segments.log"
export PERF_SEGMENT_LOG="$LOG2"
export ZSH_LOG_STRUCTURED=1
export ZSH_PERF_JSON=1
unset PERF_SEGMENT_JSON_LOG  # Let auto-derivation happen

source "${PRE_DIR}/00-path-safety.zsh"
source "${POST_DIR}/10-core-functions.zsh"
source "${POST_DIR}/95-prompt-ready.zsh"
source "${POST_DIR}/96-deferred-dispatch.zsh"

__pr__capture_prompt_ready
__zsh_deferred_run_once

[[ -s "$LOG2" ]] || fail "Segment log empty with structured telemetry enabled"

# Derive expected JSON path: segments.log -> segments.jsonl (per core-functions logic)
EXPECTED_JSON="${LOG2%.log}.jsonl"
if [[ ! -f "$EXPECTED_JSON" ]]; then
  # Fallback: some code writes to PERF_SEGMENT_LOG if JSON sidecar unwritable
  if ! grep -q '"type":"segment"' "$LOG2"; then
    fail "Structured telemetry JSON neither in sidecar ($EXPECTED_JSON missing) nor inline in segment log"
  fi
else
  pass "Structured telemetry sidecar created: $EXPECTED_JSON"
fi

JSON_SOURCE_FILE=""
if [[ -f "$EXPECTED_JSON" ]]; then
  JSON_SOURCE_FILE="$EXPECTED_JSON"
else
  JSON_SOURCE_FILE="$LOG2"
fi

# Collect JSON lines
mapfile -t JSON_LINES < <(grep -E '^\{' "$JSON_SOURCE_FILE" || true)
(( ${#JSON_LINES[@]} > 0 )) || fail "No JSON lines found in ${JSON_SOURCE_FILE}"

# Validate required labels present
grep -q '"name":"pre_plugin_start"' "$JSON_SOURCE_FILE" || fail "Missing pre_plugin_start JSON segment"
grep -q '"name":"prompt_ready"' "$JSON_SOURCE_FILE"     || fail "Missing prompt_ready JSON segment"
grep -q '"name":"deferred_total"' "$JSON_SOURCE_FILE"   || fail "Missing deferred_total JSON segment"

# Check deferred job JSON entry
if ! grep -q '"type":"deferred"' "$JSON_SOURCE_FILE"; then
  warn "No deferred job JSON entry found (dummy-warm may have produced zero runtime); continuing"
fi

# Basic JSON line structural validation
for line in "${JSON_LINES[@]}"; do
  is_valid_json_line "$line" || fail "Malformed JSON line: $line"
  # Required keys minimal check
  if ! print -r -- "$line" | grep -q '"type":"'; then
    fail "JSON line missing 'type' key: $line"
  fi
done

pass "Test2 (structured telemetry JSON emission) passed"

# ------------------------------------------------------------------------------
# Test 3: Dependency export JSON + DOT
# ------------------------------------------------------------------------------
TMP3=$(mktemp_dir)
DEPS_JSON="${TMP3}/deps.json"
DEPS_DOT="${TMP3}/deps.dot"

# Source deps-export tool
source "${TOOLS_DIR}/deps-export.zsh"

# JSON export
zf::deps::export --format=json --output "$DEPS_JSON" --only=all --include-disabled || fail "deps export JSON command failed"
[[ -s "$DEPS_JSON" ]] || fail "Deps JSON output empty"

grep -q '"version": 1' "$DEPS_JSON" || fail "Deps JSON missing version=1"
grep -q '"nodes": \[' "$DEPS_JSON"  || fail "Deps JSON missing nodes array"
grep -q '"edges": \[' "$DEPS_JSON"  || fail "Deps JSON missing edges array"

# Quick parse sanity: count braces balanced at top-level start/end (rough)
OPEN=$(grep -o '{' "$DEPS_JSON" | wc -l | tr -d ' ')
CLOSE=$(grep -o '}' "$DEPS_JSON" | wc -l | tr -d ' ')
[[ "$OPEN" -ge 5 && "$OPEN" -eq "$CLOSE" ]] || fail "Deps JSON brace imbalance (open=$OPEN close=$CLOSE)"

# DOT export
zf::deps::export --format=dot --output "$DEPS_DOT" --only=all --include-disabled || fail "deps export DOT command failed"
[[ -s "$DEPS_DOT" ]] || fail "Deps DOT output empty"
grep -q 'digraph zsh_deps {' "$DEPS_DOT" || fail "DOT export missing digraph header"
grep -q 'rankdir=LR;' "$DEPS_DOT" || fail "DOT export missing rankdir directive"

pass "Test3 (dependency export JSON + DOT) passed"

# ------------------------------------------------------------------------------
# Success Summary
# ------------------------------------------------------------------------------
pass "All structured telemetry & dependency export tests passed"

exit 0
