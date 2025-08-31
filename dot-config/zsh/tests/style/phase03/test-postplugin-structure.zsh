#!/usr/bin/env zsh
# test-postplugin-structure.zsh
# Validates redesigned post-plugin skeleton directory contents when flag enabled or directory present.
set -euo pipefail
ZDOTDIR=${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}
BASE="$ZDOTDIR/.zshrc.d.REDESIGN"
if [[ ! -d $BASE ]]; then
    echo "SKIP post-plugin redesign directory missing"; exit 0
fi
expected=(00-security-integrity.zsh 05-interactive-options.zsh 10-core-functions.zsh 20-essential-plugins.zsh 30-development-env.zsh 40-aliases-keybindings.zsh 50-completion-history.zsh 60-ui-prompt.zsh 70-performance-monitoring.zsh 80-security-validation.zsh 90-splash.zsh)
missing=()
for f in $expected; do
    [[ -f $BASE/$f ]] || missing+=$f
done
if (( ${#missing} )); then
    echo "FAIL missing post-plugin skeleton files: ${missing[*]}" >&2
    exit 1
fi
# Check count matches exactly
actual_count=$(ls -1 $BASE/*.zsh 2>/dev/null | wc -l | tr -d ' ')
if [[ $actual_count -ne ${#expected} ]]; then
    echo "FAIL unexpected file count in post-plugin redesign: got $actual_count expected ${#expected}" >&2
    exit 1
fi
# Verify ordering numeric prefixes strictly monotonic
prev=-1
for f in $expected; do
    prefix=${f%%-*}
    if [[ ${prefix#0} -le $prev ]]; then
        echo "FAIL non-monotonic prefix ordering at $f" >&2
        exit 1
    fi
    prev=${prefix#0}
done
echo "PASS post-plugin structure (${#expected} files)"
