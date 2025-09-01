#!/usr/bin/env zsh
# test-preplugin-structure.zsh
# Validates redesigned pre-plugin skeleton directory contents when flag enabled.
set -euo pipefail
ZDOTDIR=${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}
BASE="$ZDOTDIR/.zshrc.pre-plugins.d.redesigned"
if [[ ! -d $BASE ]]; then
    echo "SKIP pre-plugin redesign directory missing"; exit 0
fi
expected=(00-path-safety.zsh 05-fzf-init.zsh 10-lazy-framework.zsh 15-node-runtime-env.zsh 20-macos-defaults-deferred.zsh 25-lazy-integrations.zsh 30-ssh-agent.zsh 40-pre-plugin-reserved.zsh)
missing=()
for f in $expected; do
    [[ -f $BASE/$f ]] || missing+=$f
done
if (( ${#missing} )); then
    echo "FAIL missing pre-plugin skeleton files: ${missing[*]}" >&2
    exit 1
fi
echo "PASS pre-plugin structure (${#expected} files)"
