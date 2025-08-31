#!/usr/bin/env zsh
# test-preplugin-no-compinit.zsh
# Static design test: redesigned pre-plugin skeleton must not reference compinit.
set -euo pipefail
: ${ZDOTDIR:=${XDG_CONFIG_HOME:-$HOME/.config}/zsh}
BASE="$ZDOTDIR/.zshrc.pre-plugins.d.REDESIGN"
if [[ ! -d $BASE ]]; then
    echo "SKIP pre-plugin redesign directory missing"; exit 0
fi
if grep -R "compinit" "$BASE"/*.zsh >/dev/null 2>&1; then
    echo "FAIL pre-plugin skeleton must not reference compinit" >&2
    grep -n "compinit" "$BASE"/*.zsh >&2 || true
    exit 1
fi
echo "PASS pre-plugin no-compinit"
