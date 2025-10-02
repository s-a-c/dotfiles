#!/usr/bin/env zsh
# Test: guidelines checksum availability & format
# Ensures 015-guidelines-checksum-init.zsh exports a 64-hex GUIDELINES_CHECKSUM (or 'missing-guidelines').

set -euo pipefail

ZDOTDIR_REL="${ZDOTDIR:-$HOME}/.zshrc.pre-plugins.d.REDESIGN"
INIT_FILE="$ZDOTDIR_REL/015-guidelines-checksum-init.zsh"

if [[ ! -r $INIT_FILE ]]; then
  echo "SKIP: checksum init file missing" >&2
  exit 0
fi

# Source in a subshell to avoid polluting outer env
(
  set -e
  source "$INIT_FILE"
  if [[ -z ${GUIDELINES_CHECKSUM:-} ]]; then
    echo "FAIL: GUIDELINES_CHECKSUM not set" >&2
    exit 1
  fi
  if [[ $GUIDELINES_CHECKSUM == missing-guidelines ]]; then
    echo "OK: missing-guidelines (guidelines file absent)" >&2
    exit 0
  fi
  if [[ $GUIDELINES_CHECKSUM =~ ^[a-fA-F0-9]{64}$ ]]; then
    echo "OK: checksum format valid" >&2
    exit 0
  else
    echo "FAIL: checksum format invalid -> $GUIDELINES_CHECKSUM" >&2
    exit 1
  fi
)
