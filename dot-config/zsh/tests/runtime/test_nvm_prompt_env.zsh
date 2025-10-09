#!/usr/bin/env zsh
# test_nvm_prompt_env.zsh - Runtime assertion harness for nvm lazy stub & starship prompt
# Fails with non-zero exit on any unmet condition.
# Usage:
#   ZF_ENABLE_STARSHIP=1 ZSH_DEBUG=1 ZDOTDIR=$PWD zsh tests/runtime/test_nvm_prompt_env.zsh
#   (Run from repo root where $PWD points to zsh config root.)

_fail() { print -u2 "[FAIL] $1"; exit 1 }
_info() { print -u2 "[INFO] $1" }

# Record start
_info "Starting nvm + prompt runtime validation"

# 1. Validate nvm presence (lazy acceptable)
if ! type -t nvm >/dev/null 2>&1; then
  _info "nvm function missing pre-use; attempting first call to materialize via fallback or plugin"
  nvm --version >/dev/null 2>&1 || true
fi

type -t nvm >/dev/null 2>&1 || _fail "nvm function still missing after initial invocation attempt"

# 2. Probe nvm operational
nvm_current=$(nvm current 2>/dev/null || true)
[[ -n ${nvm_current:-} ]] || _info "nvm current returned empty (may be system default)"

# 3. Starship prompt (only if opted in)
if [[ ${ZF_ENABLE_STARSHIP:-0} == 1 ]]; then
  # Force a prompt cycle to ensure deferred precmd path executes if p10k present
  if [[ -z ${__ZF_PROMPT_INIT_DONE:-} ]]; then
    : # run a benign command to trigger precmd hooks
    true
  fi
  [[ -n ${__ZF_PROMPT_INIT_DONE:-} ]] || _fail "Starship prompt guard not set (__ZF_PROMPT_INIT_DONE)"
  [[ ${STARSHIP_SHELL:-} == "starship" ]] || _fail "STARSHIP_SHELL not set to 'starship' (value='${STARSHIP_SHELL:-unset}')"
  _info "Starship prompt active with STARSHIP_SHELL=${STARSHIP_SHELL}"
else
  _info "ZF_ENABLE_STARSHIP!=1; skipping starship assertions"
fi

_info "All runtime assertions passed"
exit 0
