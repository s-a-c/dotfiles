#!/usr/bin/env zsh
# test_starship_prompt.zsh - Runtime validation for Starship gating semantics
# Usage: ZDOTDIR=$PWD zsh tests/runtime/test_starship_prompt.zsh
# Exits non-zero on failure.

set -euo pipefail

_fail(){ print -u2 "[FAIL] $1"; return 1 }
_info(){ print -u2 "[INFO] $1" }

_run(){ local label=$1; shift; eval "$@" 2>/dev/null }

ZDOTDIR=${ZDOTDIR:-$PWD}

if ! command -v starship >/dev/null 2>&1; then
  _info "starship binary missing; skipping starship tests"; exit 0
fi

tmpdir=${TMPDIR:-/tmp}/starship-test-$RANDOM
mkdir -p "$tmpdir"

# Case A: Enabled (default), p10k absent -> immediate init
mv "$ZDOTDIR/.p10k.zsh" "$tmpdir/.p10k.zsh.bak" 2>/dev/null || true

outA=$(ZSH_DISABLE_STARSHIP=0 ZDOTDIR=$ZDOTDIR zsh -i -c 'echo GUARD=${__ZF_PROMPT_INIT_DONE:-unset}; echo MODE=${STARSHIP_SHELL:-unset}' ) || true
echo "$outA" | grep -q 'GUARD=1' || _fail "Case A guard not set" || exit 1
echo "$outA" | grep -q 'MODE=starship' || _fail "Case A starship not active" || exit 1

# Restore p10k for subsequent tests if it was there
mv "$tmpdir/.p10k.zsh.bak" "$ZDOTDIR/.p10k.zsh" 2>/dev/null || true

# Case B: Disabled hard -> guard unset, STARSHIP_SHELL unset
outB=$(ZSH_DISABLE_STARSHIP=1 ZDOTDIR=$ZDOTDIR zsh -i -c 'echo GUARD=${__ZF_PROMPT_INIT_DONE:-unset}; echo MODE=${STARSHIP_SHELL:-unset}' ) || true
echo "$outB" | grep -q 'GUARD=unset' || _fail "Case B guard unexpectedly set" || exit 1
echo "$outB" | grep -q 'MODE=unset' || _fail "Case B starship unexpectedly active" || exit 1

# Case C: Enabled with p10k present -> guard set after first precmd; we allow immediate check; if not set, fail.
# (Simplified: we only verify it initializes at all in single interactive run.)
touch "$ZDOTDIR/.p10k.zsh"
outC=$(ZSH_DISABLE_STARSHIP=0 ZDOTDIR=$ZDOTDIR zsh -i -c 'echo GUARD=${__ZF_PROMPT_INIT_DONE:-unset}; echo MODE=${STARSHIP_SHELL:-unset}' ) || true
echo "$outC" | grep -q 'GUARD=1' || _fail "Case C guard not set" || exit 1
echo "$outC" | grep -q 'MODE=starship' || _fail "Case C starship not active" || exit 1

# Case D: Inherited STARSHIP_SHELL=bash should be cleared and replaced by starship
outD=$(STARSHIP_SHELL=bash ZSH_DISABLE_STARSHIP=0 ZDOTDIR=$ZDOTDIR zsh -i -c 'echo D_GUARD=${__ZF_PROMPT_INIT_DONE:-unset}; echo D_MODE=${STARSHIP_SHELL:-unset}' ) || true
echo "$outD" | grep -q 'D_MODE=starship' || _fail "Case D did not override inherited STARSHIP_SHELL (output: $outD)" || exit 1

# Case E: Force immediate even with p10k present
touch "$ZDOTDIR/.p10k.zsh"
outE=$(ZSH_STARSHIP_FORCE_IMMEDIATE=1 ZSH_DISABLE_STARSHIP=0 ZDOTDIR=$ZDOTDIR zsh -i -c 'echo E_GUARD=${__ZF_PROMPT_INIT_DONE:-unset}; echo E_MODE=${STARSHIP_SHELL:-unset}' ) || true
echo "$outE" | grep -q 'E_GUARD=1' || _fail "Case E guard not set (output: $outE)" || exit 1
echo "$outE" | grep -q 'E_MODE=starship' || _fail "Case E starship not active (output: $outE)" || exit 1

# Case F: Force immediate in a single -c by sourcing prompt file directly (no precmd cycle)
outF=$(ZSH_STARSHIP_FORCE_IMMEDIATE=1 ZSH_DISABLE_STARSHIP=0 ZDOTDIR=$ZDOTDIR zsh -i -c 'source $ZDOTDIR/.zshrc.d.00/520-prompt-starship.zsh; typeset -f zf::prompt_init >/dev/null && echo F_HAVE_FN=1 || echo F_HAVE_FN=0; zf::prompt_init; echo F_GUARD=${__ZF_PROMPT_INIT_DONE:-unset}; echo F_MODE=${STARSHIP_SHELL:-unset}' ) || true
echo "$outF" | grep -q 'F_HAVE_FN=1' || _fail "Case F function not defined (output: $outF)" || exit 1
echo "$outF" | grep -q 'F_GUARD=1' || _fail "Case F guard not set (output: $outF)" || exit 1
echo "$outF" | grep -q 'F_MODE=starship' || _fail "Case F starship not active (output: $outF)" || exit 1

_info "All starship prompt tests passed"
exit 0
