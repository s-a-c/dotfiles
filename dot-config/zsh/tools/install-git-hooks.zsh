#!/usr/bin/env zsh
# install-git-hooks.zsh - Symlink custom hooks from .githooks into .git/hooks
set -euo pipefail
ROOT_DIR=${0:A:h:h}
HOOK_SRC="$ROOT_DIR/.githooks"
HOOK_DST="$ROOT_DIR/.git/hooks"
[[ -d $HOOK_SRC ]] || { echo "[install-git-hooks] Source dir missing: $HOOK_SRC" >&2; exit 1; }
[[ -d $HOOK_DST ]] || { echo "[install-git-hooks] Destination dir missing: $HOOK_DST (run git init?)" >&2; exit 1; }
for hook in $HOOK_SRC/*(.N); do
  base=${hook:t}
  target="$HOOK_DST/$base"
  if [[ -L $target || -f $target ]]; then
    rm -f "$target"
  fi
  ln -s "${hook}" "$target"
  chmod +x "$hook"
  echo "Linked $base"
done
echo "Custom hooks installed."
