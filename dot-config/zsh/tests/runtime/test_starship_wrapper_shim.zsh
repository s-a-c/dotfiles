#!/usr/bin/env zsh
# test_starship_wrapper_shim.zsh - Verify deprecated wrapper does not set guard or init prompt by itself and sets suppression flag
# Usage: ZDOTDIR=$PWD zsh tests/runtime/test_starship_wrapper_shim.zsh
set -euo pipefail

_fail(){ print -u2 "[FAIL] $1"; exit 1 }
_info(){ print -u2 "[INFO] $1"; }

ZDOTDIR=${ZDOTDIR:-$PWD}

if ! command -v starship >/dev/null 2>&1; then
  _info "starship binary missing; skipping wrapper shim test"; exit 0
fi

# Capture state after sourcing wrapper only
out=$(ZDOTDIR=$ZDOTDIR zsh -i -c 'source $ZDOTDIR/starship-init-wrapper.zsh; echo GUARD=${__ZF_PROMPT_INIT_DONE:-unset}; echo SHELLVAR=${STARSHIP_SHELL:-unset}; echo SUPPRESS=${ZSH_STARSHIP_SUPPRESS_AUTOINIT:-unset}' ) || true

echo "$out" | grep -q 'GUARD=unset' || _fail "Wrapper shim incorrectly set guard"
echo "$out" | grep -q 'SHELLVAR=unset' || _fail "Wrapper shim modified STARSHIP_SHELL unexpectedly"
echo "$out" | grep -q 'SUPPRESS=1' || _fail "Wrapper shim did not export suppression flag"

_info "Wrapper shim test passed"
exit 0
