#!/usr/bin/env bash
set -Eeuo pipefail

echo "[enforce-harness] scanning tests for direct 'zsh -i' usage..."

mapfile -t files < <(git ls-files 'tests/**' ':!**/fixtures/**' ':!**/.bash-harness-for-zsh-template.bash')

violations=()
for f in "${files[@]}"; do
  if grep -nE '(^|[^#])\bzsh\s+-i\b' "$f" | grep -vE '\.bash-harness-for-zsh-template\.bash|tools/' >/dev/null 2>&1; then
    violations+=("$f")
  fi
done

if ((${#violations[@]})); then
  echo "ERROR: Direct 'zsh -i' invocations detected. Tests must use ./.bash-harness-for-zsh-template.bash"
  printf ' - %s\n' "${violations[@]}"
  exit 1
fi

echo "[enforce-harness] OK: no direct interactive zsh usage found."