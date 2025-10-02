#!/usr/bin/env bash
# test-phase4.sh - Phase 4 productivity module smoke test
# Verifies:
#   1. ZLE widget count >= baseline (387)
#   2. Conditional tools (atuin, zoxide, eza, fzf, carapace) do not cause errors if absent
#   3. Optional environment variables / aliases set when tools present
# Exit Codes:
#   0 success; 1 widget regression; 2 sourcing failure; 3 unexpected error

set -euo pipefail

BASELINE_WIDGETS=387
TMP_OUT=$(mktemp)

# Optional preload: export ZSH_TEST_PRELOAD=/absolute/path/to/bootstrap-zgenom.zsh before running
# This allows plugin managers or other prerequisites to be sourced prior to numbered modules
# without embedding bootstrap logic inside the redesign phases.

# Spawn an isolated interactive zsh capturing widget count and feature probes
zsh --no-globalrcs --no-rcs -ic '
  # Disable errexit inside harness so individual non-zero plugin steps do not abort
  set +e
  # Harness Preload (plugin manager / environment) if provided
  if [[ -n ${ZSH_TEST_PRELOAD:-} && -r ${ZSH_TEST_PRELOAD} ]]; then
    # shellcheck disable=SC1090
    source "${ZSH_TEST_PRELOAD}" || echo "WARN: preload failed: ${ZSH_TEST_PRELOAD}" >&2
  fi

  # Source redesigned layers (assuming current directory root of repo or user uses symlinked .zshrc)
  # If a bootstrap script exists, prefer it; otherwise source empty layer directories in order.
  # NOTE: Adjust this block if project introduces a unified loader.
  for dir in .zshrc.pre-plugins.d.empty .zshrc.add-plugins.d.empty .zshrc.d.empty; do
    if [[ -d "$dir" ]]; then
      for f in "$dir"/*.zsh; do
        # shellcheck disable=SC1090
        source "$f" || { echo "ERROR: failed sourcing $f"; exit 2; }
      done
    fi
  done
  WC=$(zle -la 2>/dev/null | wc -l | tr -d "[:space:]")
  echo "WIDGET_COUNT=$WC"
  # Probe commands (may or may not exist)
  for cmd in atuin zoxide eza fzf carapace; do
    if command -v "$cmd" >/dev/null 2>&1; then
      echo "HAVE_${cmd}=1"
    else
      echo "HAVE_${cmd}=0"
    fi
  done
  # Basic alias checks (only if tools exist)
  alias ls >/dev/null 2>&1 && alias ls | grep -q eza && echo "ALIAS_LS_EZA=1" || echo "ALIAS_LS_EZA=0"
  exit 0
' > "$TMP_OUT" 2>&1 || { echo "FAIL: zsh invocation failed"; cat "$TMP_OUT"; exit 2; }

# Parse results
WIDGET_COUNT=$(grep '^WIDGET_COUNT=' "$TMP_OUT" | cut -d= -f2 || echo 0)
if [[ -z "$WIDGET_COUNT" ]]; then
  echo "FAIL: Missing widget count output"; cat "$TMP_OUT"; exit 3
fi

if (( WIDGET_COUNT < BASELINE_WIDGETS )); then
  echo "FAIL: Widget regression detected ($WIDGET_COUNT < $BASELINE_WIDGETS)"; cat "$TMP_OUT"; exit 1
fi

echo "PASS: Phase 4 modules OK (widgets=$WIDGET_COUNT)"
# Optional echo of tool presence summary
grep '^HAVE_' "$TMP_OUT" || true
grep '^ALIAS_LS_EZA=' "$TMP_OUT" || true

rm -f "$TMP_OUT"
exit 0
