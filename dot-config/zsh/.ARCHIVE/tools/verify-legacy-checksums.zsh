#!/usr/bin/env zsh
# verify-legacy-checksums.zsh
# Verifies current legacy files (.zshrc, pre-plugin, post-plugin) match frozen checksum snapshot.
set -euo pipefail
ZDOTDIR=${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}
SNAP="$ZDOTDIR/docs/redesign/planning/legacy-checksums.sha256"
if [[ ! -f $SNAP ]]; then
    echo "ERROR: checksum snapshot missing: $SNAP" >&2
    exit 2
fi
status=0
while IFS= read -r line; do
    [[ -z $line || $line == \#* ]] && continue
    sum_ref=${line%%    *}
    file=${line#*    }
    if [[ ! -f $ZDOTDIR/$file ]]; then
        echo "MISSING: $file" >&2
        status=1
        continue
    fi
    sum_cur=$(shasum -a 256 "$ZDOTDIR/$file" | awk '{print $1}')
    if [[ $sum_cur != $sum_ref ]]; then
        echo "MISMATCH: $file" >&2
        echo "    expected $sum_ref" >&2
        echo "    actual     $sum_cur" >&2
        status=1
    fi
done < "$SNAP"
if [[ $status -ne 0 ]]; then
    echo "FAIL legacy checksum verification" >&2
    exit 1
fi
echo "PASS legacy checksum verification"
