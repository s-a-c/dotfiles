#!/usr/bin/env zsh
# =============================================================================
# test-option-snapshot-stability.zsh
#
# Purpose:
#   Ensures re-sourcing the Stage 3 core module
#     05-interactive-options.zsh
#   does NOT mutate the interactive / history / completion‑related shell
#   options after their initial canonical setup. This enforces idempotency
#   and prevents subtle behavioral drift across multiple loads (e.g. in
#   subshells, test harness re-entry, or guarded reload flows).
#
# Scope:
#   Focuses on a curated set of "governed" options that the redesign intends
#   to centralize in module 05. If these toggle on a second source (without
#   intentional change), that indicates a missing sentinel or unintended
#   side-effect.
#
# Monitored Options (adjust if module scope evolves):
#   - extendedglob
#   - hist_ignore_all_dups
#   - hist_ignore_space
#   - hist_reduce_blanks
#   - share_history
#   - append_history
#   - interactive_comments
#   - autocd
#   - promptsubst
#
# Invariants:
#   I1: Module file is present (else SKIP).
#   I2: On re-source, the monitored option states match the pre-source snapshot.
#   I3: No new unexpected monitored option flips occur.
#
# Exit Codes:
#   0 = PASS (or SKIP)
#   1 = FAIL
#
# Skip Conditions:
#   - TDD_SKIP_OPTION_SNAPSHOT=1
#
# Notes:
#   - Uses `set -o` output parsing (portable within Zsh).
#   - If helpers (zf::script_dir / resolve_script_dir) are available they
#     are used to locate the repo root robustly.
#   - Designed to be fast and side‑effect free.
#
# Future Enhancements (non-blocking):
#   - Generate a golden snapshot file & diff structurally.
#   - Expand monitored list based on final Stage 3 module content.
#   - Integrate with an option classification manifest (core vs feature).
# =============================================================================

set -euo pipefail

# ------------------------------------------------------
# Skip Handling
# ------------------------------------------------------
if [[ "${TDD_SKIP_OPTION_SNAPSHOT:-0}" == "1" ]]; then
  print "SKIP: option snapshot stability test skipped (TDD_SKIP_OPTION_SNAPSHOT=1)"
  exit 0
fi

# ------------------------------------------------------
# Helper: quiet debug shim
# ------------------------------------------------------
typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }

# ------------------------------------------------------
# Repo Root / Module Path Resolution
# ------------------------------------------------------
SCRIPT_SRC="${(%):-%N}"
if typeset -f zf::script_dir >/dev/null 2>&1; then
  THIS_DIR="$(zf::script_dir "$SCRIPT_SRC")"
elif typeset -f resolve_script_dir >/dev/null 2>&1; then
  THIS_DIR="$(resolve_script_dir "$SCRIPT_SRC")"
else
  THIS_DIR="${SCRIPT_SRC:h}"
fi
# Expect test resides under: dot-config/zsh/tests/...
REPO_ROOT="$(cd "$THIS_DIR/../../../.." && pwd -P 2>/dev/null)"

MODULE_REL=".zshrc.d.REDESIGN/05-interactive-options.zsh"
MODULE_PATH="${REPO_ROOT}/dot-config/zsh/${MODULE_REL}"

if [[ ! -f "$MODULE_PATH" ]]; then
  print "SKIP: module not present (${MODULE_REL})"
  exit 0
fi

# ------------------------------------------------------
# Monitored Options List
# (Keep alphabetical for stable output)
# ------------------------------------------------------
MONITORED_OPTS=(
  append_history
  autocd
  extendedglob
  hist_ignore_all_dups
  hist_ignore_space
  hist_reduce_blanks
  interactive_comments
  promptsubst
  share_history
)

# ------------------------------------------------------
# Capture Option State
# ------------------------------------------------------
capture_snapshot() {
  # Produces lines: option_name=on/off
  local raw line name state
  raw="$(set -o)"  # Format: "optionname <spaces> on|off"
  local -A snap
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    # Split tokens (last field is on/off, first token is name)
    name="${line%%[[:space:]]*}"
    state="${line##*[[:space:]]}"
    snap["$name"]="$state"
  done <<< "$raw"

  # Emit only monitored set
  for opt in "${MONITORED_OPTS[@]}"; do
    print "${opt}=${snap[$opt]:-<unset>}"
  done
}

# Parse snapshot lines into associative array
declare -A BEFORE AFTER
read_snapshot_into_map() {
  local snapshot_line key val
  while IFS= read -r snapshot_line; do
    key="${snapshot_line%%=*}"
    val="${snapshot_line#*=}"
    [[ -z "$key" ]] && continue
    eval "$1[\$key]=\"\$val\""
  done
}

# ------------------------------------------------------
# Take BEFORE snapshot
# ------------------------------------------------------
BEFORE_RAW="$(capture_snapshot)"
read_snapshot_into_map BEFORE <<< "$BEFORE_RAW"

# ------------------------------------------------------
# Re-source module (SECOND LOAD) - should be idempotent
# ------------------------------------------------------
# shellcheck disable=SC1090
if ! . "$MODULE_PATH" 2>/dev/null; then
  print "FAIL: module re-source failed (${MODULE_REL})"
  exit 1
fi

# ------------------------------------------------------
# Take AFTER snapshot
# ------------------------------------------------------
AFTER_RAW="$(capture_snapshot)"
read_snapshot_into_map AFTER <<< "$AFTER_RAW"

# ------------------------------------------------------
# Compare
# ------------------------------------------------------
PASS_COUNT=0
FAIL_COUNT=0
DIFFS=()

for opt in "${MONITORED_OPTS[@]}"; do
  b="${BEFORE[$opt]:-<unset>}"
  a="${AFTER[$opt]:-<unset>}"
  if [[ "$b" == "$a" ]]; then
    (( PASS_COUNT++ ))
  else
    (( FAIL_COUNT++ ))
    DIFFS+=( "$opt:$b->$a" )
  fi
done

# ------------------------------------------------------
# Reporting
# ------------------------------------------------------
if (( FAIL_COUNT > 0 )); then
  print "FAIL: option snapshot drift detected (${FAIL_COUNT})"
  print "CHANGES:"
  for d in "${DIFFS[@]}"; do
    print "  - $d"
  done
  print "--- BEFORE ---"
  print "$BEFORE_RAW"
  print "--- AFTER ----"
  print "$AFTER_RAW"
  exit 1
fi

print "PASS: option snapshot stable (monitored=${#MONITORED_OPTS[@]})"
print "DETAIL (before==after):"
print "$AFTER_RAW"
exit 0
