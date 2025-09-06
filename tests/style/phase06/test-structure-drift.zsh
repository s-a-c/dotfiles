#!/usr/bin/env zsh
# test-structure-drift.zsh
# Purpose: Permissive structure drift check for redesign modules.
# STRICT_DRIFT=1 turns warnings into failures (useful for full enforcement in CI later).
# - Non-strict: Does NOT fail while redesign is in-progress (module count < expected)
# - Strict: Fails on duplicates, missing guard, missing expected prefixes, extra modules at any stage.
# Exit codes:
#   0 PASS / SKIP / WARN (non-blocking in permissive mode)
#   1 FAIL (structure integrity issue)

set -euo pipefail

EXPECTED_COUNT=${EXPECTED_REDESIGN_COUNT:-11}
EXPECTED_PREFIXES=(00 05 10 20 30 40 50 60 70 80 90)
REDESIGN_DIR=".zshrc.d.REDESIGN"
STRICT=${STRICT_DRIFT:-0}

if [[ ! -d $REDESIGN_DIR ]]; then
  echo "SKIP: redesign directory missing ($REDESIGN_DIR)"
  exit 0
fi

modules=(${REDESIGN_DIR}/*.zsh(N))
count=${#modules[@]}

if (( count == 0 )); then
  echo "SKIP: no redesign modules present yet"
  exit 0
fi

# Collect prefixes & guard status
typeset -A seen
missing_guard=0
for f in "${modules[@]}"; do
  bn=${f:t}
  if [[ $bn =~ '^([0-9]{2})' ]]; then
    pfx=${match[1]}
  else
    pfx="NA"
  fi
  (( seen[$pfx]++ ))
  if ! grep -q '_LOADED_' "$f" 2>/dev/null; then
    ((missing_guard++))
  fi
done

dup_prefixes=()
for k in ${(k)seen}; do
  if (( seen[$k] > 1 )) && [[ $k != NA ]]; then
    dup_prefixes+=$k
  fi
done

status=0

# Helper to maybe fail based on strictness
maybe_fail() {
  local msg="$1"
  if (( STRICT )); then
    echo "FAIL: $msg"
    status=1
  else
    echo "WARN: $msg"
  fi
}

if (( count < EXPECTED_COUNT )); then
  echo "PASS: partial redesign skeleton ($count/$EXPECTED_COUNT)"
  (( ${#dup_prefixes[@]} )) && maybe_fail "duplicate prefixes (partial phase): ${dup_prefixes[*]}"
  (( missing_guard > 0 )) && maybe_fail "$missing_guard module(s) missing guard markers (_LOADED_)"
  # Only early exit if not strict or no strict failure accumulated
  if (( STRICT && status == 1 )); then
    exit 1
  fi
  exit 0
fi

# Full enforcement once expected count reached or exceeded.
(( ${#dup_prefixes[@]} )) && { echo "FAIL: duplicate numeric prefixes detected: ${dup_prefixes[*]}"; status=1; }
(( missing_guard > 0 )) && { echo "FAIL: $missing_guard module(s) missing guard markers (_LOADED_)"; status=1; }

actual_prefixes=(${(k)seen})

if (( count > EXPECTED_COUNT )); then
  echo "FAIL: redesign module count ($count) exceeds expected ($EXPECTED_COUNT)"
  status=1
else
  # Only compare sets when counts align
  if (( count == EXPECTED_COUNT )); then
    exp_sorted=(${(o)EXPECTED_PREFIXES})
    act_sorted=(${(o)actual_prefixes})
    if [[ "${exp_sorted[*]}" != "${act_sorted[*]}" ]]; then
      echo "FAIL: prefix set mismatch. Expected: ${exp_sorted[*]} Got: ${act_sorted[*]}"
      status=1
    fi
  fi
fi

if (( status == 0 )); then
  echo "PASS: redesign structure complete & consistent ($count modules)"
fi
exit $status
