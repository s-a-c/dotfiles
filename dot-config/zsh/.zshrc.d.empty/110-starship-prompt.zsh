#!/usr/bin/env zsh
# 110-starship-prompt.zsh - Phase 7A Starship activation (guarded)
# Requires: starship present, prompt guard not yet set.
# Idempotent: uses __ZF_PROMPT_INIT_DONE set by wrapper.

# Skip if already initialized or binary missing
if [[ -n ${__ZF_PROMPT_INIT_DONE:-} ]]; then
  return 0
fi

if ! command -v starship >/dev/null 2>&1; then
  return 0
fi

# Source wrapper (which defines guard + zf::prompt_init)
if [[ -r ${ZDOTDIR:-$HOME/.config/zsh}/starship-init-wrapper.zsh ]]; then
  # shellcheck disable=SC1090
  source "${ZDOTDIR:-$HOME/.config/zsh}/starship-init-wrapper.zsh" || return 0
fi

# Initialize prompt (idempotent)
zf::prompt_init 2>/dev/null || starship_init_safe 2>/dev/null || true

return 0
