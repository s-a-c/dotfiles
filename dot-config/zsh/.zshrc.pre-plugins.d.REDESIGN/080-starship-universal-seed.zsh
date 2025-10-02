#!/usr/bin/env zsh
# ==============================================================================
# 080-STARSHIP-UNIVERSAL-SEED.ZSH (REDESIGN)
# ==============================================================================
# Purpose  : Unified, idempotent early seeding of all STARSHIP_* variables needed
#            by starship, wrapper instrumentation, and diagnostic tooling under
#            `set -u` without triggering 'parameter not set' errors.
# Replaces : 07-starship-universal-seed.zsh, 09-starship-universal-seed.zsh
# Load Ord : Early (080) – after environment base & before any precmd/preexec
# Author   : ZSH Configuration Redesign System
# Version  : 2.1.0
# Policy   : Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md] v${GUIDELINES_CHECKSUM:-pending}
# ==============================================================================

# Idempotency guard
if [[ -n ${_ZQS_REDESIGN_STARSHIP_UNIFIED_SEEDED:-} ]]; then
  return 0
fi
_ZQS_REDESIGN_STARSHIP_UNIFIED_SEEDED=1

# Integer & status scalars (only define if absent)
# Note: Keep the list alphabetically grouped by functional category for diff clarity.
for _sv in \
  STARSHIP_CMD_BG \
  STARSHIP_CMD_END_TIME \
  STARSHIP_CMD_ERR \
  STARSHIP_CMD_ERRCODE \
  STARSHIP_CMD_ERRLINE \
  STARSHIP_CMD_ERRNO \
  STARSHIP_CMD_EXIT_REASON \
  STARSHIP_CMD_JOBS \
  STARSHIP_CMD_SIG \
  STARSHIP_CMD_START_TIME \
  STARSHIP_CMD_STATUS \
  STARSHIP_DURATION_MS \
  STARSHIP_JOBS_COUNT; do
  if ! (( ${+_sv} )); then typeset -gi ${_sv}=0; fi
done

# Textual context (empty string initialization)
for _ctx in \
  STARSHIP_CMD_ERRCTX \
  STARSHIP_CMD_ERRFILE \
  STARSHIP_CMD_ERRFUNC \
  STARSHIP_CMD_ERRMSG; do
  if ! (( ${+_ctx} )); then typeset -g ${_ctx}=""; fi
done

# Arrays (ensure declared & empty, do not clobber if user pre-populated)
if ! (( ${+STARSHIP_PIPE_STATUS} )); then typeset -ga STARSHIP_PIPE_STATUS; STARSHIP_PIPE_STATUS=(); fi
if ! (( ${+STARSHIP_CMD_PIPESTATUS} )); then typeset -ga STARSHIP_CMD_PIPESTATUS; STARSHIP_CMD_PIPESTATUS=(); fi

unset _sv _ctx

# Optional debug trace (silent unless explicitly enabled)
if [[ ${ZSH_DEBUG:-0} == 1 && -n ${ZSH_DEBUG_LOG:-} ]]; then
  print -r -- "[STARSHIP-SEED][080][unified] +CMD_STATUS=$(( ${+STARSHIP_CMD_STATUS} )) val=${STARSHIP_CMD_STATUS:-unset}" >>"$ZSH_DEBUG_LOG" 2>/dev/null || true
fi

# End of file
