#!/usr/bin/env zsh
# =============================================================================
# test-option-snapshot-golden.zsh
#
# Purpose:
#   Enforces that the current interactive option state emitted by
#     zf::options_snapshot
#   exactly matches the Stage 3 golden baseline file:
#     docs/redesignv2/artifacts/golden/options-snapshot-stage3-initial.txt
#
# Why:
#   - Protects against accidental drift in foundational interactive / history /
#     completion‑related options governed by module 05-interactive-options.zsh.
#   - Complements stability test (test-option-snapshot-stability.zsh) which
#     checks re-source idempotency rather than canonical alignment.
#
# Invariants:
#   G1: Golden snapshot file exists (else SKIP – infrastructure issue).
#   G2: zf::options_snapshot function exists (else SKIP – module not loaded yet).
#   G3: Current snapshot lines exactly equal golden lines (order & content).
#
# Skip Conditions:
#   - TDD_SKIP_OPTION_GOLDEN=1
#
# Exit Codes:
#   0 = PASS or SKIP
#   1 = FAIL (drift detected)
#
# Environment Variables (optional):
#   ZF_OPTION_GOLDEN_PATH  Override path to golden file (for experimentation)
#
# Update Workflow on Intentional Change:
#   1. Modify module 05-interactive-options.zsh intentionally.
#   2. Run zf::options_snapshot locally and verify new output.
#   3. Update the golden file with the new snapshot (sorted lines, option=on|off).
#   4. Document rationale in IMPLEMENTATION.md change log.
#
# Safety:
#   - Does not attempt auto-fix; explicit golden update required.
#
# =============================================================================

set -euo pipefail

# ---------------------------
# Skip Handling
# ---------------------------
if [[ "${TDD_SKIP_OPTION_GOLDEN:-0}" == "1" ]]; then
  print "SKIP: option golden test skipped (TDD_SKIP_OPTION_GOLDEN=1)"
  exit 0
fi

PASS=()
FAIL=()
SKIP=()
pass() { PASS+=("$1"); }
fail() { FAIL+=("$1"); }
skip() { SKIP+=("$1"); }

# Quiet debug shim (optional)
typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }

# ---------------------------
# Repo Root Resolution
# ---------------------------
SCRIPT_SRC="${(%):-%N}"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [[ -z "$REPO_ROOT" ]]; then
  REPO_ROOT="$ZDOTDIR"
fi
zsh_debug_echo "DEBUG: PWD=$PWD"
zsh_debug_echo "DEBUG: ZDOTDIR=$ZDOTDIR"
zsh_debug_echo "DEBUG: SCRIPT_SRC=$SCRIPT_SRC"
zsh_debug_echo "DEBUG: REPO_ROOT=$REPO_ROOT"

# ---------------------------
# Golden File Path
# ---------------------------
: ${ZF_OPTION_GOLDEN_PATH:="${REPO_ROOT}/dot-config/zsh/docs/redesignv2/artifacts/golden/options-snapshot-stage3-initial.txt"}

if [[ ! -f "$ZF_OPTION_GOLDEN_PATH" ]]; then
  skip "G1 golden-file-missing (${ZF_OPTION_GOLDEN_PATH})"
  for s in "${SKIP[@]}"; do print "SKIP: $s"; done
  exit 0
fi
pass "G1 golden-file-present"

# ---------------------------
# Availability of snapshot function
# (Module 05 should have been sourced by the test harness; if not, we attempt a best-effort source)
# ---------------------------
if ! typeset -f zf::options_snapshot >/dev/null 2>&1; then
  # Attempt to source module directly (non-fatal if absent)
  MOD05="${REPO_ROOT}/dot-config/zsh/.zshrc.d.REDESIGN/05-interactive-options.zsh"
  if [[ -f "$MOD05" ]]; then
    # shellcheck disable=SC1090
    . "$MOD05" 2>/dev/null || true
  fi
fi

if ! typeset -f zf::options_snapshot >/dev/null 2>&1; then
  skip "G2 snapshot-function-missing (zf::options_snapshot)"
  for s in "${SKIP[@]}"; do print "SKIP: $s"; done
  exit 0
fi
pass "G2 snapshot-function-available"

# ---------------------------
# Capture Current Snapshot
# ---------------------------
CURRENT_RAW="$(zf::options_snapshot 2>/dev/null || true)"
if [[ -z "$CURRENT_RAW" ]]; then
  fail "G3 empty-current-snapshot"
  # Report and exit early
  for p in "${PASS[@]}"; do print "PASS: $p"; done
  for f in "${FAIL[@]}"; do print "FAIL: $f"; done
  print "TEST RESULT: FAIL"
  exit 1
fi

# Normalize (strip trailing spaces, remove blank lines) & sort
normalize_and_sort() {
  print -- "$1" | sed -e 's/[[:space:]]*$//' -e '/^$/d' | sort
}

CUR_SORTED="$(normalize_and_sort "$CURRENT_RAW")"
GOLDEN_SORTED="$(normalize_and_sort "$(cat "$ZF_OPTION_GOLDEN_PATH")")"

# Quick hash (informational)
cur_hash=$(print -- "$CUR_SORTED" | sha1sum 2>/dev/null | awk '{print $1}')
gold_hash=$(print -- "$GOLDEN_SORTED" | sha1sum 2>/dev/null | awk '{print $1}')

if [[ "$CUR_SORTED" == "$GOLDEN_SORTED" ]]; then
  pass "G3 snapshot-matches-golden hash_current=$cur_hash"
else
  fail "G3 snapshot-drift hash_current=$cur_hash hash_golden=$gold_hash"
  # Produce unified diff (if diff present)
  if command -v diff >/dev/null 2>&1; then
    print "---- DIFF (current vs golden) ----"
    diff -u <(print -- "$GOLDEN_SORTED") <(print -- "$CUR_SORTED") || true
  else
    print "---- GOLDEN ----"
    print -- "$GOLDEN_SORTED"
    print "---- CURRENT ----"
    print -- "$CUR_SORTED"
  fi
fi

# ---------------------------
# Reporting
# ---------------------------
for s in "${SKIP[@]}"; do print "SKIP: $s"; done
for p in "${PASS[@]}"; do print "PASS: $p"; done
for f in "${FAIL[@]}"; do print "FAIL: $f"; done

print "---"
print "SUMMARY: passes=${#PASS[@]} fails=${#FAIL[@]} skips=${#SKIP[@]} golden_path=${ZF_OPTION_GOLDEN_PATH}"
print "Hashes: current=${cur_hash:-na} golden=${gold_hash:-na}"

if (( ${#FAIL[@]} > 0 )); then
  print -u2 "TEST RESULT: FAIL"
  exit 1
fi

print "TEST RESULT: PASS"
exit 0
