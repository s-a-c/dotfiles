#!/usr/bin/env zsh
# test_prompt_timings.zsh - Compare prompt init timings between Powerlevel10k & Starship
# Produces TSV lines: mode	init_ms (best-effort). Exits 0 always (informational) unless hard errors.
# Usage (from repo root):
#   ZDOTDIR=$PWD zsh tests/runtime/test_prompt_timings.zsh

emulate -L zsh
setopt err_return no_unset

print -u2 "[timings] collecting prompt initialization metrics"

# Helper to launch a subshell and capture timing via env variables or heuristic.
_run_mode() {
  local mode=$1 tmpfile=$(mktemp)
  # We capture EPOCHREALTIME around shell startup; Starship reports _ZF_STARSHIP_INIT_MS; p10k lacks built-in here so heuristic.
  if [[ $mode == starship ]]; then
    ZF_ENABLE_STARSHIP=1 ZDOTDIR=$PWD zsh -i -c 'print -- MODE=starship_INIT_MS=${_ZF_STARSHIP_INIT_MS:-NA}' 2>/dev/null > $tmpfile || true
  else
    # p10k: measure total interactive shell wall time by wrapping with /usr/bin/env time if available.
    { EPOCHREALTIME_BEFORE=$(python - <<'PY'
import time; print(f"{time.time():.6f}")
PY
); ZDOTDIR=$PWD zsh -i -c 'print -- MODE=p10k_READY=1' >/dev/null 2>&1; python - <<'PY'
import time; print(f"EPOCHREALTIME_AFTER={time.time():.6f}")
PY
; } > $tmpfile 2>/dev/null || true
  fi
  cat $tmpfile
  rm -f $tmpfile
}

starship_line=$(_run_mode starship)
p10k_block=$(_run_mode p10k)

# Parse
starship_ms=$(print $starship_line | sed -n 's/.*MODE=starship_INIT_MS=\([^ ]*\).*/\1/p')
if [[ -z $starship_ms ]]; then starship_ms=NA; fi

p10k_after=$(print $p10k_block | sed -n 's/.*EPOCHREALTIME_AFTER=\([^ ]*\).*/\1/p')
p10k_before=$(print $p10k_block | sed -n 's/.*EPOCHREALTIME_BEFORE=\([^ ]*\).*/\1/p')
if [[ -n $p10k_after && -n $p10k_before ]]; then
  # Convert seconds diff to ms
  p10k_ms=$(printf '%.0f' "$(awk -v a=$p10k_before -v b=$p10k_after 'BEGIN{print (b-a)*1000}')")
else
  p10k_ms=NA
fi

print "mode\tinit_ms"
print "starship\t$starship_ms"
print "p10k_total_shell\t$p10k_ms"

exit 0
