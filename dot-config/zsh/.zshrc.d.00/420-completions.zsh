#!/usr/bin/env zsh
# 330-completions.zsh - Phase 4: Completion system bootstrap + Carapace (advanced completions)
# Ensures compinit (and thus compdef) is available before any plugin-provided completion files execute.
# Adds lightweight guard so compinit runs only once and can be skipped.

if [[ "${ZF_DISABLE_CARAPACE:-0}" == 1 ]]; then
  return 0
fi

# Provide no-op debug if not defined yet
if ! typeset -f zf::debug >/dev/null 2>&1; then
  zf::debug() { :; }
fi

# Guarded compinit initialization (only if compdef not yet defined)
if [[ -z "${__ZF_COMPINIT_DONE:-}" ]] && ! typeset -f compdef >/dev/null 2>&1; then
  if autoload -Uz compinit 2>/dev/null; then
    # -i ignore insecure dirs; -C skip creation if dump already valid (fast path)
    if compinit -i -C 2>/dev/null; then
      __ZF_COMPINIT_DONE=1
      zf::debug "# [completions] compinit initialized (fast)"
    else
      # Fallback normal invocation
      if compinit -i 2>/dev/null; then
        __ZF_COMPINIT_DONE=1
        zf::debug "# [completions] compinit initialized (fallback)"
      else
        zf::debug "# [completions] compinit failed (continuing without completion system)"
      fi
    fi
  else
    zf::debug "# [completions] autoload compinit not available"
  fi
fi

# Carapace integration (optional)
if command -v carapace >/dev/null 2>&1; then
  eval "$(carapace _carapace)"
fi

# Manual validation:
#   carapace _carapace version 2>/dev/null | head -n 1
