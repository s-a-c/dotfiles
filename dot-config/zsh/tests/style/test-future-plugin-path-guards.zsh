#!/usr/bin/env zsh
# =============================================================================
# test-future-plugin-path-guards.zsh
#
# Purpose:
#   Proactively enforce path resolution standards for any future plugin /
#   external / vendor integration scripts that may be added under:
#       dot-config/zsh/plugins/
#       dot-config/zsh/external/
#       dot-config/zsh/vendor/
#
#   These directories do NOT currently contain active Zsh integration code in
#   this redesign. This test acts as an early warning system: if new scripts are
#   introduced, they must comply with the resilient path helper policy
#   (use `zf::script_dir` or `resolve_script_dir`, never raw `${0:A:h}` or
#   brittle dirname chains).
#
# Guarded Patterns (FAIL if present unless suppressed):
#   1. `${0:A:h}` or `${0:a:h}`
#   2. Manual dirname chains using $0 (e.g. `dirname "$0"` or nested
#      `$(cd "$(dirname "$0")"... )`)
#   3. Overly manual `${(%):-%N:h}` when helpers SHOULD be used (flagged,
#      but can be suppressed if very early bootstrap is justified)
#
# Suppression:
#   Add `# ALLOW_FUTURE_PATH` on the same line to allow a specific occurrence.
#   (Justification must be included in PR description.)
#
# Exit Codes:
#   0 = PASS or SKIP (no candidate dirs or no violations)
#   1 = FAIL (violations found)
#
# Output:
#   PASS/FAIL lines + summary.
#
# Rationale:
#   Ensures future plugin glue scripts conform immediately, preventing drift
#   from the standardized helper approach adopted across redesign modules.
# =============================================================================

set -euo pipefail

PASS=()
FAIL=()
SKIPPED=0
VIOLATION_COUNT=0

pass() { PASS+=("$1"); }
fail() { FAIL+=("$1"); }
skip() { print "SKIP: $1"; SKIPPED=1; }

typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }

SCRIPT_SRC="${(%):-%N}"
if typeset -f zf::script_dir >/dev/null 2>&1; then
  TEST_DIR="$(zf::script_dir "$SCRIPT_SRC")"
elif typeset -f resolve_script_dir >/dev/null 2>&1; then
  TEST_DIR="$(resolve_script_dir "$SCRIPT_SRC")"
else
  TEST_DIR="${SCRIPT_SRC:h}"
fi
REPO_ROOT="$(cd "${TEST_DIR}/../../.." && pwd -P)"

CANDIDATE_DIRS=(
  "dot-config/zsh/plugins"
  "dot-config/zsh/external"
  "dot-config/zsh/vendor"
)

# Collect existing directories
typeset -a PRESENT_DIRS
for d in "${CANDIDATE_DIRS[@]}"; do
  if [[ -d "${REPO_ROOT}/${d}" ]]; then
    PRESENT_DIRS+=("$d")
  fi
done

if (( ${#PRESENT_DIRS[@]} == 0 )); then
  pass "No future plugin/external/vendor directories present (nothing to audit)"
  print "PASS: baseline (no candidate directories)"
  print "---"
  print "SUMMARY: passes=${#PASS[@]} fails=0 scanned_dirs=0 violations=0"
  exit 0
fi

pass "Detected ${#PRESENT_DIRS[@]} candidate directory(ies)"

# Pattern definitions (basic string/ERE forms)
# Using simple grep-like checks instead of heavy parsing for speed & clarity.
is_violation_line() {
  local line="$1"
  # Skip suppression
  if [[ "$line" == *"ALLOW_FUTURE_PATH"* ]]; then
    return 1
  fi
  # Pattern 1: direct ${0:A:h} (case-insensitive A/a)
  if [[ "$line" == *'${0:A:h}'* || "$line" == *'${0:a:h}'* ]]; then
    return 0
  fi
  # Pattern 2: dirname chain referencing $0
  if [[ "$line" == *'dirname "$0"'* || "$line" == *"dirname '$0'"* || "$line" == *'dirname ${0}'* ]]; then
    return 0
  fi
  # Pattern 3: nested cd/dirname $0 constructs (heuristic)
  if print -- "$line" | grep -E '\$\(\s*cd\s+.*dirname\s+"?\$0"?' >/dev/null 2>&1; then
    return 0
  fi
  # Pattern 4: raw ${(%):-%N:h} when helper likely expected (not fatal if suppressed)
  if [[ "$line" == *'${(%):-%N:h}'* ]]; then
    return 0
  fi
  return 1
}

typeset -a FILES
setopt null_glob 2>/dev/null || true
for dir in "${PRESENT_DIRS[@]}"; do
  FILES+=( "${REPO_ROOT}/${dir}"/**/*.zsh(N) )
done
unsetopt null_glob 2>/dev/null || true

if (( ${#FILES[@]} == 0 )); then
  pass "No .zsh files under candidate directories (clean)"
  print "PASS: empty-file-set"
  print "---"
  print "SUMMARY: passes=${#PASS[@]} fails=0 scanned_dirs=${#PRESENT_DIRS[@]} scanned_files=0 violations=0"
  exit 0
fi

pass "Scanning ${#FILES[@]} file(s)"

for f in "${FILES[@]}"; do
  rel="${f#$REPO_ROOT/}"
  line_no=0
  while IFS= read -r line; do
    (( line_no++ )) || true
    [[ -z "$line" ]] && continue
    # Ignore pure comments
    if [[ "${line#"${line%%[![:space:]]*}"}" == \#* ]]; then
      continue
    fi
    if is_violation_line "$line"; then
      (( VIOLATION_COUNT++ ))
      FAIL+=( "VIOLATION: ${rel}:${line_no} -> ${line%%[[:space:]]*}" )
    fi
  done < "$f"
done

if (( VIOLATION_COUNT == 0 )); then
  pass "No path resolution violations in future plugin/external/vendor areas"
else
  fail "Detected ${VIOLATION_COUNT} path resolution violation(s) in future plugin/external/vendor areas"
fi

# Emit results
for p in "${PASS[@]}"; do
  print "PASS: $p"
done
for fmsg in "${FAIL[@]}"; do
  print "FAIL: $fmsg"
done

print "---"
print "SUMMARY: passes=${#PASS[@]} fails=${#FAIL[@]} scanned_dirs=${#PRESENT_DIRS[@]} scanned_files=${#FILES[@]} violations=${VIOLATION_COUNT}"

if (( VIOLATION_COUNT > 0 )); then
  print -u2 "TEST RESULT: FAIL (future plugin path guard)"
  exit 1
fi

print "TEST RESULT: PASS"
exit 0
