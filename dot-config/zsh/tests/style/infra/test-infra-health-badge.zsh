#!/usr/bin/env zsh
# test-infra-health-badge.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# Purpose:
#   Assert that the synthesized infrastructure health badge (docs/badges/infra-health.json)
#   exists and reports an acceptable color on the main branch.
#
# Policy / Enforcement Logic:
#   - Badge must exist on all branches (missing => WARN off-main, FAIL on main).
#   - On main branch:
#       * color MUST NOT be red
#       * color MUST NOT be lightgrey (interpreted as incomplete / no components)
#       * Allowed colors: brightgreen, green  (yellow/orange now treated as failure)
#       * yellow / orange: now FAIL (below required stability threshold)
#         (yellow/orange tolerated to surface non-critical degradations without blocking PR merge;
#          hard-stop red already enforced by CI workflow and this test provides belt & suspenders)
#   - Off main:
#       * red => FAIL
#       * lightgrey => WARN
#       * others => PASS
#
# Exit Codes:
#   0 = PASS (or non-blocking WARN on non-main)
#   1 = FAIL
#
# Output Conventions:
#   Prints one of: PASS:, FAIL:, WARN: with explanatory text for CI log clarity.
#
# Notes:
#   This test intentionally mirrors (but does not duplicate) the CI step that fails on red for main.
#   Keeping both ensures local test runs surface issues before CI.
#
# Future Enhancements:
#   - Tighten main-branch policy to require green/brightgreen when maturity thresholds reached.
#   - Add interpretation of individual component deltas (perf regressions, structure drift context).
#   - Integrate security (secret scan / vuln) once badge present (security component already stubbed in aggregator script).
#

set -euo pipefail

BADGE_FILE="docs/badges/infra-health.json"

# Derive current branch
branch="${GITHUB_REF##*/}"
if [[ -z "$branch" || "$branch" == "$GITHUB_REF" ]]; then
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
fi
is_main=0
[[ "$branch" == "main" ]] && is_main=1

if [[ ! -f "$BADGE_FILE" ]]; then
    if ((is_main)); then
        echo "FAIL: infra health badge missing on main (expected at $BADGE_FILE)"
        exit 1
    else
        echo "WARN: infra health badge missing on branch '$branch' (non-main tolerated)"
        exit 0
    fi
fi

# Extract fields (prefer jq, fallback to sed)
color=""
message=""
if command -v jq >/dev/null 2>&1; then
    color=$(jq -r '.color // empty' "$BADGE_FILE" 2>/dev/null || true)
    message=$(jq -r '.message // empty' "$BADGE_FILE" 2>/dev/null || true)
else
    line=$(<"$BADGE_FILE")
    color=$(print -- "$line" | sed -n 's/.*"color":"\([^"]*\)".*/\1/p')
    message=$(print -- "$line" | sed -n 's/.*"message":"\([^"]*\)".*/\1/p')
fi

[[ -z "$color" ]] && color="lightgrey"
[[ -z "$message" ]] && message="<no-message>"

# Normalize
color_lc=$(print -- "$color" | tr '[:upper:]' '[:lower:]')

# Policy checks
if ((is_main)); then
    case "$color_lc" in
    red)
        echo "FAIL: infra health badge color 'red' on main (message='$message')"
        exit 1
        ;;
    lightgrey | grey | gray)
        echo "FAIL: infra health badge color '$color_lc' (incomplete state) on main (message='$message')"
        exit 1
        ;;
    brightgreen | green)
        echo "PASS: infra health badge acceptable on main (color=$color_lc message='$message')"
        exit 0
        ;;
    yellow | orange)
        echo "FAIL: infra health badge color '$color_lc' below required green threshold on main (message='$message')"
        exit 1
        ;;
    *)
        echo "WARN: infra health badge unknown color '$color_lc' on main (treat as non-blocking for now) message='$message'"
        exit 0
        ;;
    esac
else
    case "$color_lc" in
    red)
        echo "FAIL: infra health badge color 'red' on branch '$branch' (message='$message')"
        exit 1
        ;;
    lightgrey | grey | gray)
        echo "WARN: infra health badge color '$color_lc' (incomplete) on branch '$branch' (message='$message')"
        exit 0
        ;;
    *)
        echo "PASS: infra health badge acceptable on branch '$branch' (color=$color_lc message='$message')"
        exit 0
        ;;
    esac
fi
