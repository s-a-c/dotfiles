#!/usr/bin/env zsh
# test-hooks-badge.zsh
# Compliant with [${HOME}/.config/ai/guidelines.md](${HOME}/.config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# Purpose:
#   Enforce that the generated hooks status badge (docs/badges/hooks.json) reflects a
#   successful hooks environment on the main branch (belt & suspenders with CI logic).
#
# Enforcement Rules:
#   - On main branch:
#       Accepted hook states: ok, fixed
#       Any other state (missing badge, mismatch, enforced-fail, fail-missing, unknown) => FAIL
#   - On non-main branches:
#       mismatch / unknown => WARN (exit 0)
#       enforced-fail / fail-missing => FAIL
#
# Outputs:
#   PASS / WARN / FAIL lines for CI log clarity.
#
# Exit Codes:
#   0 = success (or non-blocking warn on non-main)
#   1 = failure (violates policy)
#
# Policy rationale:
#   Ensures contributors do not silently bypass local hook protections once merged.
#
# Dependencies:
#   - Optional: jq (used if available; fallback grep/sed JSON extraction if absent).
#
# Safe operation:
#   - Does not modify repository state.
#
# Usage:
#   Invoked via existing test runner discovery (matches test-*.zsh pattern).
#
# Future enhancements:
#   - Add color validation (ensure brightgreen/green only on main).
#   - Integrate with a consolidated infra health badge if introduced.

set -euo pipefail

badge_file="docs/badges/hooks.json"

# Determine branch (prefer CI env; fallback to git)
branch="${GITHUB_REF##*/}"
if [[ -z "${branch}" || "${branch}" == "refs/heads/"* || "${branch}" == "${GITHUB_REF}" ]]; then
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
fi

is_main=0
[[ "$branch" == "main" ]] && is_main=1

status=""
color=""

extract_with_jq() {
  status=$(jq -r '.message // empty' "$badge_file" 2>/dev/null || true)
  color=$(jq -r '.color // empty' "$badge_file" 2>/dev/null || true)
}

extract_with_sed() {
  local line
  line=$(cat "$badge_file" 2>/dev/null || echo "")
  status=$(echo "$line" | sed -n 's/.*"message":"\([^"]*\)".*/\1/p')
  color=$(echo "$line" | sed -n 's/.*"color":"\([^"]*\)".*/\1/p')
}

if [[ ! -f "$badge_file" ]]; then
  if (( is_main )); then
    echo "FAIL: hooks badge missing on main (expected at $badge_file)"
    exit 1
  else
    echo "WARN: hooks badge missing on branch '$branch' (non-main tolerated)"
    exit 0
  fi
fi

if command -v jq >/dev/null 2>&1; then
  extract_with_jq
else
  extract_with_sed
fi

[[ -z "$status" ]] && status="unknown"

normalize() {
  # Lowercase normalization (defensive)
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

status_norm=$(normalize "$status")

pass_main_states=("ok" "fixed")
fail_any_states=("enforced-fail" "fail-missing")
warn_non_main_states=("mismatch" "unknown")

contains() {
  local needle="$1"; shift
  local x
  for x in "$@"; do
    [[ "$x" == "$needle" ]] && return 0
  done
  return 1
}

if (( is_main )); then
  if contains "$status_norm" "${pass_main_states[@]}"; then
    # Color policy on main: only brightgreen or green are acceptable when status is ok/fixed.
    case "$color" in
      brightgreen|green)
        echo "PASS: hooks badge status '$status_norm' acceptable on main (color=$color)"
        exit 0
        ;;
      *)
        echo "FAIL: hooks badge color '$color' not permitted on main for status '$status_norm' (expected brightgreen or green)"
        exit 1
        ;;
    esac
  else
    echo "FAIL: hooks badge status '$status_norm' not permitted on main (expected one of: ${(j:, :)pass_main_states})"
    exit 1
  fi
else
  # Non-main branch logic
  if contains "$status_norm" "${fail_any_states[@]}"; then
    echo "FAIL: hooks badge status '$status_norm' indicates hard failure state on branch '$branch'"
    exit 1
  elif contains "$status_norm" "${warn_non_main_states[@]}"; then
    echo "WARN: hooks badge status '$status_norm' on branch '$branch' (non-blocking)"
    exit 0
  else
    # ok / fixed or any other benign state
    echo "PASS: hooks badge status '$status_norm' acceptable on branch '$branch' (color=$color)"
    exit 0
  fi
fi
