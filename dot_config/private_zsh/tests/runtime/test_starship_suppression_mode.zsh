#!/usr/bin/env zsh
# test_starship_suppression_mode.zsh - Verify suppression flag exposes functions without auto init
# Usage: ZDOTDIR=$PWD zsh tests/runtime/test_starship_suppression_mode.zsh
set -euo pipefail

_fail(){ print -u2 "[FAIL] $1"; exit 1 }
_info(){ print -u2 "[INFO] $1"; }

ZDOTDIR=${ZDOTDIR:-$PWD}

if ! command -v starship >/dev/null 2>&1; then
  _info "starship binary missing; skipping suppression mode test"; exit 0
fi

# Source unified file in suppression mode
out=$(ZSH_STARSHIP_SUPPRESS_AUTOINIT=1 ZDOTDIR=$ZDOTDIR zsh -i -c 'source $ZDOTDIR/.zshrc.d.00/520-prompt-starship.zsh; echo HAVE_FN=$([[ $(typeset -f zf::prompt_init) ]] && echo 1 || echo 0); echo GUARD=${__ZF_PROMPT_INIT_DONE:-unset}; echo MODE=${STARSHIP_SHELL:-unset}' ) || true

echo "$out" | grep -q 'HAVE_FN=1' || _fail "Suppression mode did not define zf::prompt_init"
echo "$out" | grep -q 'GUARD=unset' || _fail "Suppression mode unexpectedly initialized prompt"
echo "$out" | grep -q 'MODE=unset' || _fail "Suppression mode unexpectedly set STARSHIP_SHELL"

# Now explicitly initialize to ensure manual init works after suppression
out2=$(ZSH_STARSHIP_SUPPRESS_AUTOINIT=1 ZDOTDIR=$ZDOTDIR zsh -i -c 'source $ZDOTDIR/.zshrc.d.00/520-prompt-starship.zsh; zf::prompt_init; echo GUARD=${__ZF_PROMPT_INIT_DONE:-unset}; echo MODE=${STARSHIP_SHELL:-unset}' ) || true

echo "$out2" | grep -q 'GUARD=1' || _fail "Manual init after suppression failed to set guard"
echo "$out2" | grep -q 'MODE=starship' || _fail "Manual init after suppression failed to set STARSHIP_SHELL=starship"

_info "Suppression mode test passed"
exit 0
