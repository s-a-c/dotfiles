#!/usr/bin/env zsh
# test_starship_stale_guard_repair.zsh - Ensure stale guard with wrong STARSHIP_SHELL triggers repair
set -euo pipefail

_fail(){ print -u2 "[FAIL] $1"; exit 1 }
_info(){ print -u2 "[INFO] $1"; }

ZDOTDIR=${ZDOTDIR:-$PWD}

if ! command -v starship >/dev/null 2>&1; then
  _info "starship binary missing; skipping stale guard repair test"; exit 0
fi

# Simulate stale state: guard preset + wrong shell marker, then source unified file which should repair and re-init
out=$(ZDOTDIR=$ZDOTDIR __ZF_PROMPT_INIT_DONE=1 STARSHIP_SHELL=bash zsh -i -c 'source $ZDOTDIR/.zshrc.d.00/520-prompt-starship.zsh; echo AFTER_GUARD=${__ZF_PROMPT_INIT_DONE:-unset} MODE=${STARSHIP_SHELL:-unset}' ) || true

echo "$out" | grep -q 'AFTER_GUARD=1' || _fail "Repaired init did not set guard again"
echo "$out" | grep -q 'MODE=starship' || _fail "Repaired init did not normalize STARSHIP_SHELL=starship"

_info "Stale guard repair test passed"
exit 0
