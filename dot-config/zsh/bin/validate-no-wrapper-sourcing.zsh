#!/usr/bin/env bash
# validate-no-wrapper-sourcing.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) ${GUIDELINES_CHECKSUM:-vUNKNOWN}
# Purpose: Ensure redesigned pre-plugin modules (100-240 range) no longer source legacy numeric originals.
# Strategy: Grep for patterns like 'source ${0:A:h}/[0-9]' inside .zshrc.pre-plugins.d.REDESIGN files.
# Exit non-zero if any offending sourcing statements are found.

set -euo pipefail

ZDOTDIR=${ZDOTDIR:-$(cd "$(dirname "$0")/.." && pwd)}
REDESIGN_DIR="$ZDOTDIR/.zshrc.pre-plugins.d.REDESIGN"

if [[ ! -d $REDESIGN_DIR ]]; then
  echo "ERROR: Redesign directory not found: $REDESIGN_DIR" >&2
  exit 2
fi

pattern='source \${0:A:h}/[0-9]'
offenders=$(grep -E -n "$pattern" "$REDESIGN_DIR"/*.zsh || true)

if [[ -n $offenders ]]; then
  echo "FAIL: Found legacy wrapper sourcing statements:" >&2
  echo "$offenders" >&2
  exit 1
fi

echo "PASS: No legacy wrapper sourcing statements detected in redesign modules." >&2
exit 0
