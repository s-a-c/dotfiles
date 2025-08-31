#!/usr/bin/env zsh
# Verifies legacy disabled post-plugin directory matches frozen inventory snapshot.
set -euo pipefail
ZDOTDIR=${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}
INV_FILE="$ZDOTDIR/docs/redesign/planning/postplugin-disabled-inventory.txt"
LEGACY_DIR="$ZDOTDIR/.zshrc.d.disabled"
if [[ ! -f $INV_FILE ]]; then echo "SKIP disabled inventory file missing"; exit 0; fi
if [[ ! -d $LEGACY_DIR ]]; then echo "SKIP disabled dir missing"; exit 0; fi
expected=(${(f)"$(grep -v '^[# ]' $INV_FILE | grep -v '^$')"})
expected=(${(on)expected})
actual=(${(f)"$(print -l $LEGACY_DIR/*(.N) 2>/dev/null | sed "s#$LEGACY_DIR/##" | sort)"})
typeset -A exp_map act_map
for f in $expected; do exp_map[$f]=1; done
for f in $actual; do act_map[$f]=1; done
missing=() extra=()
for f in $expected; do [[ -n ${act_map[$f]:-} ]] || missing+=$f; done
for f in $actual; do [[ -n ${exp_map[$f]:-} ]] || extra+=$f; done
if (( ${#missing} || ${#extra} )); then
  echo "FAIL post-plugin disabled drift detected" >&2
  (( ${#missing} )) && echo "  Missing: ${missing[*]}" >&2
  (( ${#extra} )) && echo "  Extra: ${extra[*]}" >&2
  exit 1
fi
echo "PASS post-plugin disabled inventory unchanged (${#expected} files)"
