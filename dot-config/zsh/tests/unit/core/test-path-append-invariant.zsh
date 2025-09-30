#!/usr/bin/env zsh
# =============================================================================
# test-path-append-invariant.zsh
#
# Purpose:
#   Validates that the redesign bootstrap (.zshenv and early modules) *append*
#   to PATH rather than destructively overwriting or reordering critical
#   existing segments. Ensures core tooling (awk, date, mkdir) remains
#   resolvable after environment setup and that later additions appear only
#   at the tail (or in sanctioned insertion points) without removing earlier
#   entries.
#
# Invariants Checked:
#   I1: All original (pre-redesign-load) PATH segments remain present (subset).
#   I2: Relative ordering of original segments is preserved (no permutation).
#   I3: No duplicate collapsing error (duplicates allowed but flagged informationally).
#   I4: Core commands awk, date, mkdir found before/after (must stay resolvable).
#   I5: Redesign-added segments (heuristic) occur only at the end (or after last
#       original segment index).
#
# Heuristic for Redesign-Added Segments:
#   - Any segment containing '/dot-config/zsh' or '/.local/' or ending in '/bin'
#     that did not exist in the original snapshot is tagged as "added".
#
# Exit Codes:
#   0 = PASS
#   1 = FAIL (one or more invariants violated)
#   2 = SKIP (preconditions missing)
#
# Environment Notes:
#   This test assumes it is run *after* the normal redesign bootstrap in CI.
#   For thoroughness it also performs an isolated subshell bootstrap to
#   recapture a "clean" baseline when possible.
#
# Future Enhancements (TODO):
#   - Introduce a canonical whitelist / ordered manifest file to remove
#     heuristic assumptions.
#   - Add duplicate segment normalization test (warn vs fail policy decision).
#
# =============================================================================

set -euo pipefail

PASS=()
FAIL=()
SKIP=0

pass() { PASS+=("$1"); }
fail() { FAIL+=("$1"); }
skip() { print "SKIP: $1"; SKIP=1; }

# Optional debug helper
typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# ---------------------------------------------------------------------------
# Capture "original" PATH via controlled subshell (attempt)
# ---------------------------------------------------------------------------
ORIG_PATH_RAW=""
if command -v zsh >/dev/null 2>&1; then
  # Use a minimal environment attempt; -f skips sourcing of user/system rc files
  # but .zshenv is always sourced by design—this gives us a near-pristine view.
  ORIG_PATH_RAW="$(env -i HOME="$HOME" USER="$USER" PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin" zsh -f -c 'print -r -- $PATH' 2>/dev/null || true)"
fi

if [[ -z "$ORIG_PATH_RAW" ]]; then
  # Fallback to current PATH snapshot (less strict baseline)
  ORIG_PATH_RAW="$PATH"
  pass "Baseline fallback: using current PATH as original (subshell capture unavailable)."
else
  pass "Baseline captured via minimal subshell."
fi

ORIG_SEGMENTS=(${(s/:/)ORIG_PATH_RAW})
CUR_SEGMENTS=(${(s/:/)PATH})

if (( ${#CUR_SEGMENTS[@]} == 0 )); then
  skip "Current PATH empty (unexpected environment); cannot validate."
  exit 2
fi

if (( ${#ORIG_SEGMENTS[@]} == 0 )); then
  skip "Original PATH baseline empty; cannot validate append invariant."
  exit 2
fi

# Build index map for original ordering
typeset -A ORIG_INDEX
for i in {1..${#ORIG_SEGMENTS[@]}}; do
  seg="${ORIG_SEGMENTS[i]}"
  ORIG_INDEX["$seg"]=$i
done

# Track ordering preservation
last_index=0
ORDER_VIOLATIONS=0
MISSING_ORIG=()

for seg in "${ORIG_SEGMENTS[@]}"; do
  # Find first occurrence in current PATH
  found_idx=0
  for j in {1..${#CUR_SEGMENTS[@]}}; do
    if [[ "${CUR_SEGMENTS[j]}" == "$seg" ]]; then
      found_idx=$j
      break
    fi
  done
  if (( found_idx == 0 )); then
    MISSING_ORIG+=("$seg")
    continue
  fi
  if (( found_idx < last_index )); then
    (( ORDER_VIOLATIONS++ ))
  fi
  last_index=$found_idx
done

if (( ${#MISSING_ORIG[@]} == 0 )); then
  pass "I1 original-segments-retained"
else
  fail "I1 missing original segments (${#MISSING_ORIG[@]}): ${MISSING_ORIG[*]}"
fi

if (( ORDER_VIOLATIONS == 0 )); then
  pass "I2 original-order-preserved"
else
  fail "I2 ordering violations detected=${ORDER_VIOLATIONS}"
fi

# Duplicate informational scan
typeset -A CUR_COUNT
DUP_COUNT=0
for seg in "${CUR_SEGMENTS[@]}"; do
  (( CUR_COUNT["$seg"]++ )) || CUR_COUNT["$seg"]=1
done
for k v in "${(@kv)CUR_COUNT}"; do
  if (( v > 1 )); then
    (( DUP_COUNT++ ))
  fi
done
# Currently non-fatal; pass with note
pass "I3 duplicate-scan (duplicates=${DUP_COUNT})"

# Core tool resolution invariant
CORE_TOOLS=(awk date mkdir)
CORE_MISSING=()
for tool in "${CORE_TOOLS[@]}"; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    CORE_MISSING+=("$tool")
  fi
done
if (( ${#CORE_MISSING[@]} == 0 )); then
  pass "I4 core-tools-resolvable"
else
  fail "I4 missing core tools: ${CORE_MISSING[*]}"
fi

# Heuristic detection of appended segments
# Determine max index any original segment occupies in current PATH
max_orig_idx=0
for seg in "${ORIG_SEGMENTS[@]}"; do
  for j in {1..${#CUR_SEGMENTS[@]}}; do
    if [[ "${CUR_SEGMENTS[j]}" == "$seg" ]]; then
      (( j > max_orig_idx )) && max_orig_idx=$j
      break
    fi
  done
done

APPEND_VIOLATIONS=0
ADDED_TRACKED=()

for j in {1..${#CUR_SEGMENTS[@]}}; do
  seg="${CUR_SEGMENTS[j]}"
  if [[ -z "${ORIG_INDEX[$seg]:-}" ]]; then
    # Segment is "added"
    case "$seg" in
      *dot-config/zsh*|*\.local/*|*/bin|*/bin/) ADDED_TRACKED+=("$seg")
        if (( j <= max_orig_idx )); then
          (( APPEND_VIOLATIONS++ ))
        fi
        ;;
      *) ;; # ignore non-heuristic additions
    esac
  fi
done

if (( APPEND_VIOLATIONS == 0 )); then
  pass "I5 added-segments-appended"
else
  fail "I5 appended invariant broken (violations=${APPEND_VIOLATIONS})"
fi

# ---------------------------------------------------------------------------
# Result Emission
# ---------------------------------------------------------------------------
for p in "${PASS[@]}"; do
  print "PASS: $p"
done
for f in "${FAIL[@]}"; do
  print "FAIL: $f"
done

print "---"
print "SUMMARY: passes=${#PASS[@]} fails=${#FAIL[@]} orig_count=${#ORIG_SEGMENTS[@]} cur_count=${#CUR_SEGMENTS[@]} duplicates=${DUP_COUNT} added_tracked=${#ADDED_TRACKED[@]}"

if (( ${#FAIL[@]} > 0 )); then
  print -u2 "TEST RESULT: FAIL"
  exit 1
fi

if (( SKIP == 1 )); then
  exit 0
fi

print "TEST RESULT: PASS"
exit 0
