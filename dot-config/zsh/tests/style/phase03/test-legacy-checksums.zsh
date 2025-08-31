#!/usr/bin/env zsh
# test-legacy-checksums.zsh
# Ensures legacy (.zshrc, pre-plugin, post-plugin) files match frozen checksum snapshot.
set -euo pipefail
ZDOTDIR=${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}
SCRIPT="$ZDOTDIR/tools/verify-legacy-checksums.zsh"
if [[ ! -x $SCRIPT ]]; then
    echo "FAIL missing verifier script: $SCRIPT" >&2
    exit 1
fi
if ! output=$($SCRIPT 2>&1); then
    echo "FAIL legacy checksum drift detected" >&2
    echo "$output" >&2
    exit 1
fi
echo "PASS legacy checksums intact"
