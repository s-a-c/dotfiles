#!/usr/bin/env bash
set -euo pipefail

declare -a FUNCS=(
  "zsh-quickstart-select-powerlevel10k"
  "zsh-quickstart-select-bullet-train"
  "_update-zsh-quickstart"
  "_check-for-zsh-quickstart-update"
  "zqs-help"
)

main() {
  local missing=0
  for f in "${FUNCS[@]}"; do
    local res
    res=$(ZDOTDIR="$PWD" timeout 10s zsh -i -c "typeset -f $f >/dev/null && echo FOUND || echo MISSING; exit" 2>&1 || true)
    echo "$f: $res"
    if ! echo "$res" | grep -q FOUND; then
      missing=1
    fi
  done
  if [[ $missing -ne 0 ]]; then
    echo "FAIL: One or more ZQS functions missing"
    exit 1
  fi
  echo "OK: All ZQS functions present"
}

main "$@"