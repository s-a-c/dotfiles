#!/usr/bin/env bash
set -euo pipefail

main() {
  local out
  out=$(ZDOTDIR="$PWD" timeout 15s zsh -i -c '
    if [[ -n "$STARSHIP_SHELL" ]]; then
      echo STARSHIP_INITIALIZED
    else
      echo STARSHIP_NOT_INITIALIZED
    fi
    exit
  ' 2>&1 || true)

  echo "$out"
  if echo "$out" | grep -q STARSHIP_INITIALIZED; then
    echo "OK: Starship initialized"
    exit 0
  else
    echo "FAIL: Starship not initialized"
    exit 1
  fi
}

main "$@"