#!/usr/bin/env zsh
# test-granular-segments.zsh
# Compliant with ${HOME}/dotfiles/dot-config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Validate granular segment probe implementation:
#     1. Essential plugin segments (essential/zsh-syntax-highlighting, etc.)
#     2. Dev environment segments (dev-env/nvm, dev-env/rbenv, etc.)
#     3. Completion segments (completion/history-setup, completion/cache-scan)
#     4. Proper SEGMENT line format with phase=post_plugin
#     5. No duplicate emissions
#
# SCOPE:
#   Tests the expanded real segment probes added in Sprint 2.
#   Validates both segment-lib and fallback timing paths.
#
# OUTPUT:
#   Prints PASS/FAIL lines; exits non-zero on failure.

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

# ---------------------------------------------------------------------------
# Setup temp workspace
# ---------------------------------------------------------------------------
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t grantest)"
LOG_FILE="${TMP_DIR}/perf-segments.log"
export PERF_SEGMENT_LOG="$LOG_FILE"
: > "$LOG_FILE" || fail "Unable to create PERF_SEGMENT_LOG at $LOG_FILE"

ZDOTDIR_ROOT="${PWD}"
PRE_DIR="${ZDOTDIR_ROOT}/.zshrc.pre-plugins.d.REDESIGN"
POST_DIR="${ZDOTDIR_ROOT}/.zshrc.d.REDESIGN"

# Debug output
print "DEBUG: ZDOTDIR_ROOT=$ZDOTDIR_ROOT" >&2
print "DEBUG: POST_DIR=$POST_DIR" >&2
print "DEBUG: PWD=$PWD" >&2

# Define missing functions that modules might need
typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }
autoload -Uz is-at-least 2>/dev/null || true

# Source segment-lib if available
[[ -r "${ZDOTDIR_ROOT}/tools/segment-lib.zsh" ]] && source "${ZDOTDIR_ROOT}/tools/segment-lib.zsh"

# Source modules with granular probes
for module in 20-essential-plugins 30-development-env 50-completion-history; do
  module_path="${POST_DIR}/${module}.zsh"
  print "DEBUG: Checking module: $module_path" >&2
  [[ -r "$module_path" ]] || fail "Missing $module_path"
  # Clear any existing state
  unset _LOADED_${module//-/_}_PLUGINS POST_SEG_${module//-/_}_MS _LOADED_${module//-/_} 2>/dev/null || true
  source "$module_path"
done

# Flush to ensure log writes are visible
sync 2>/dev/null || true

# Debug: show what was logged
print "DEBUG: Log file contents:" >&2
cat "$LOG_FILE" >&2
print "DEBUG: End of log file" >&2

[[ -s "$LOG_FILE" ]] || fail "PERF_SEGMENT_LOG empty – expected segment lines"

# ---------------------------------------------------------------------------
# Expected granular segments
# ---------------------------------------------------------------------------
typeset -a EXPECTED_SEGMENTS=(
  # Essential plugins
  "essential/zsh-syntax-highlighting"
  "essential/zsh-autosuggestions"
  "essential/zsh-completions"
  # History/safety/navigation placeholders
  "history/baseline"
  "safety/aliases"
  "navigation/cd"
  # Dev environment
  "dev-env/nvm"
  "dev-env/rbenv"
  "dev-env/pyenv"
  "dev-env/go"
  "dev-env/rust"
  # Completion/history
  "completion/history-setup"
  "completion/cache-scan"
  # UI & Security placeholders
  "ui/prompt-setup"
  "security/validation"
)

# ---------------------------------------------------------------------------
# Disable Flag Probe Tests (new)
# ---------------------------------------------------------------------------
# Verifies that setting the disable flags prevents emission of corresponding
# SEGMENT lines after unsetting sentinels and re-sourcing modules.
#
# Flags:
#   ZSH_DISABLE_ALIASES_KEYBINDINGS=1
#   ZSH_DISABLE_UI_PROMPT_SEGMENT=1
#   ZSH_DISABLE_SECURITY_VALIDATION_SEGMENT=1
#
# Strategy:
#   1. Source modules (40,60,80) normally → assert segments present.
#   2. Switch PERF_SEGMENT_LOG to a fresh file, set disable flags, unset sentinels.
#   3. Re‑source modules → assert segments absent.
#
if [[ -r "${POST_DIR}/40-aliases-keybindings.zsh" && -r "${POST_DIR}/60-ui-prompt.zsh" && -r "${POST_DIR}/80-security-validation.zsh" ]]; then
  # Step 1: ensure presence when enabled
  for m in 40-aliases-keybindings 60-ui-prompt 80-security-validation; do
    # Unset sentinels/emission markers (best-effort)
    unset _LOADED_40_ALIASES_KEYBINDINGS _LOADED_60_UI_PROMPT _LOADED_80_SECURITY_VALIDATION \
          _UI_PROMPT_SEGMENT_EMITTED _SEC_VAL_SEGMENT_EMITTED \
          __AK_SEG_EMITTED_ALIASES __AK_SEG_EMITTED_CD 2>/dev/null || true
    source "${POST_DIR}/${m}.zsh"
  done
  sync 2>/dev/null || true
  for seg in "safety/aliases" "navigation/cd" "ui/prompt-setup" "security/validation"; do
    if ! grep -qE "^SEGMENT name=${seg} " "$LOG_FILE"; then
      fail "Expected segment (pre-disable) missing: $seg"
    fi
  done

  # Step 2: disable and re-test absence
  DISABLE_LOG="${TMP_DIR}/perf-segments-disabled.log"
  export PERF_SEGMENT_LOG="$DISABLE_LOG"
  : > "$DISABLE_LOG"

  unset _LOADED_40_ALIASES_KEYBINDINGS _LOADED_60_UI_PROMPT _LOADED_80_SECURITY_VALIDATION \
        _UI_PROMPT_SEGMENT_EMITTED _SEC_VAL_SEGMENT_EMITTED \
        __AK_SEG_EMITTED_ALIASES __AK_SEG_EMITTED_CD 2>/dev/null || true

  export ZSH_DISABLE_ALIASES_KEYBINDINGS=1
  export ZSH_DISABLE_UI_PROMPT_SEGMENT=1
  export ZSH_DISABLE_SECURITY_VALIDATION_SEGMENT=1

  for m in 40-aliases-keybindings 60-ui-prompt 80-security-validation; do
    source "${POST_DIR}/${m}.zsh"
  done
  sync 2>/dev/null || true

  for seg in "safety/aliases" "navigation/cd" "ui/prompt-setup" "security/validation"; do
    if grep -qE "^SEGMENT name=${seg} " "$DISABLE_LOG"; then
      fail "Segment should not be emitted when disabled: $seg"
    fi
  done
  pass "Disable flag segment suppression verified"

  # Restore original log for subsequent parsing helpers/tests
  export PERF_SEGMENT_LOG="$LOG_FILE"
fi

# ---------------------------------------------------------------------------
# Parsing helpers
# ---------------------------------------------------------------------------
check_segment_exists() {
  local seg="$1"
  print "DEBUG: Looking for segment: $seg" >&2
  if ! grep -qE "^SEGMENT name=${seg} " "$LOG_FILE"; then
    print "DEBUG: grep pattern: ^SEGMENT name=${seg} " >&2
    print "DEBUG: Available segments:" >&2
    grep "^SEGMENT " "$LOG_FILE" >&2 || print "  (none found)" >&2
    fail "Missing expected segment: $seg"
  fi
  pass "Found segment: $seg"
}

check_segment_format() {
  local seg="$1"
  local line
  line=$(grep -E "^SEGMENT name=${seg} " "$LOG_FILE" | head -n1)

  # Check required fields
  if [[ ! "$line" =~ "ms=[0-9]+" ]]; then
    fail "Segment $seg missing ms= field"
  fi
  if [[ ! "$line" =~ "phase=post_plugin" ]]; then
    fail "Segment $seg missing or wrong phase (expected post_plugin)"
  fi
  if [[ ! "$line" =~ "sample=" ]]; then
    warn "Segment $seg missing sample= field"
  fi
}

check_no_duplicates() {
  local seg="$1"
  local count
  count=$(grep -cE "^SEGMENT name=${seg} " "$LOG_FILE" || true)
  if (( count > 1 )); then
    fail "Segment $seg emitted $count times (expected 1)"
  fi
}

# ---------------------------------------------------------------------------
# Assertions
# ---------------------------------------------------------------------------

# 1. Check all expected segments exist
for seg in "${EXPECTED_SEGMENTS[@]}"; do
  check_segment_exists "$seg"
  check_segment_format "$seg"
  check_no_duplicates "$seg"
done

# 2. Check aggregate segments still exist (backward compatibility)
for agg_seg in "20-essential" "30-dev-env" "50-completion-history"; do
  if ! grep -qE "^POST_PLUGIN_SEGMENT ${agg_seg} " "$LOG_FILE"; then
    warn "Missing aggregate segment: POST_PLUGIN_SEGMENT $agg_seg"
  fi
done

# 3. Verify timing sanity (non-negative, reasonable values)
while IFS= read -r line; do
  if [[ "$line" =~ "SEGMENT name=([^ ]+) ms=([0-9]+)" ]]; then
    # Extract segment name and ms using sed since ZSH regex capture is different
    seg=$(echo "$line" | sed -n 's/.*name=\([^ ]*\) .*/\1/p')
    ms=$(echo "$line" | sed -n 's/.*ms=\([0-9]*\).*/\1/p')
    if [[ -n "$ms" ]] && (( ms < 0 )); then
      fail "Negative ms value for segment $seg: $ms"
    fi
    if [[ -n "$ms" ]] && (( ms > 1000 )); then
      warn "Suspiciously high ms value for segment $seg: $ms"
    fi
  fi
done < "$LOG_FILE"

# 4. Check segment ordering (granular segments should appear before aggregates)
check_ordering() {
  local module="$1"
  local granular_pattern="$2"
  local aggregate_pattern="POST_PLUGIN_SEGMENT ${module} "

  local last_granular_line=0
  local first_aggregate_line=999999

  # Find last granular segment line
  while IFS= read -r line_info; do
    line_num="${line_info%%:*}"
    (( line_num > last_granular_line )) && last_granular_line=$line_num
  done < <(grep -nE "^SEGMENT name=${granular_pattern}" "$LOG_FILE" 2>/dev/null || true)

  # Find first aggregate line
  if grep -qF "$aggregate_pattern" "$LOG_FILE"; then
    first_aggregate_line=$(grep -nF "$aggregate_pattern" "$LOG_FILE" | head -n1 | cut -d: -f1)
  fi

  if (( last_granular_line > 0 && first_aggregate_line < 999999 && last_granular_line > first_aggregate_line )); then
    fail "Module $module: granular segments appear after aggregate (line $last_granular_line > $first_aggregate_line)"
  fi
}

check_ordering "20-essential" "essential/"
check_ordering "30-dev-env" "dev-env/"
check_ordering "50-completion-history" "completion/"

# ---------------------------------------------------------------------------
# Success
# ---------------------------------------------------------------------------
pass "All granular segment checks passed"
pass "Total segments logged: $(grep -c '^SEGMENT ' "$LOG_FILE" || echo 0)"

# Cleanup
rm -rf "$TMP_DIR"
exit 0
