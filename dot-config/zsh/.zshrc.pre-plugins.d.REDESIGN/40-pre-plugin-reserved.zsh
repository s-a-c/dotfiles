#!/opt/homebrew/bin/zsh
# 40-pre-plugin-reserved.zsh (Pre-Plugin Redesign Placeholder / Perf Marker Enhancements)
[[ -n ${_LOADED_PRE_RESERVED_SLOT:-} ]] && return
_LOADED_PRE_RESERVED_SLOT=1
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) ${GUIDELINES_CHECKSUM:-vUNKNOWN}
#
# PURPOSE:
#   Reserved insertion point for future pre-plugin instrumentation OR lightweight governance hooks.
#   Enhanced here to emit a robust pre_plugin_total SEGMENT even if awk is unavailable.
#
# FALLBACK STRATEGY:
#   - If awk missing, use shell parsing of EPOCHREALTIME to compute millisecond integers.
#   - If PRE_PLUGIN_START_MS missing but PRE_PLUGIN_START_REALTIME exists, attempt reconstruction.
#   - Emit SEGMENT only when PRE_PLUGIN_TOTAL_MS computed; otherwise log a diagnostic once.
#
# HELPERS --------------------------------------------------------------------
__preplugin_ms_from_epoch() {
  # Convert floating seconds (EPOCHREALTIME style "sec.frac") into integer ms.
  # Usage: __preplugin_ms_from_epoch "$EPOCHREALTIME"
  local ts="$1" sec frac
  [[ -z $ts ]] && return 1
  case "$ts" in
    *.*) sec=${ts%%.*}; frac=${ts#*.};;
    *) sec=$ts; frac=0;;
  esac
  frac="${frac}000"        # pad
  frac=${frac%%[!0-9]*}    # strip non-digits if any
  frac=${frac:0:3}         # keep three ms digits
  print $(( sec * 1000 + ${frac:-0} ))
}

# Ensure end realtime + ms ---------------------------------------------------
if [[ -z ${PRE_PLUGIN_END_REALTIME:-} ]]; then
  zmodload zsh/datetime 2>/dev/null || true
  PRE_PLUGIN_END_REALTIME=$EPOCHREALTIME
  export PRE_PLUGIN_END_REALTIME
  if command -v awk >/dev/null 2>&1; then
    PRE_PLUGIN_END_MS=$(printf '%s' "$PRE_PLUGIN_END_REALTIME" | awk -F. '{ms = ($1 * 1000); if (NF>1) { ms += substr($2 "000",1,3)+0 } printf "%d", ms }' 2>/dev/null || echo "")
  else
    PRE_PLUGIN_END_MS=$(__preplugin_ms_from_epoch "$PRE_PLUGIN_END_REALTIME" || echo "")
  fi
  [[ -n ${PRE_PLUGIN_END_MS:-} ]] && export PRE_PLUGIN_END_MS
fi

# Attempt to reconstruct missing START_MS (rare) -----------------------------
if [[ -z ${PRE_PLUGIN_START_MS:-} && -n ${PRE_PLUGIN_START_REALTIME:-} ]]; then
  if command -v awk >/dev/null 2>&1; then
    PRE_PLUGIN_START_MS=$(printf '%s' "$PRE_PLUGIN_START_REALTIME" | awk -F. '{ms = ($1 * 1000); if (NF>1) { ms += substr($2 "000",1,3)+0 } printf "%d", ms }' 2>/dev/null || echo "")
  else
    PRE_PLUGIN_START_MS=$(__preplugin_ms_from_epoch "$PRE_PLUGIN_START_REALTIME" || echo "")
  fi
  [[ -n ${PRE_PLUGIN_START_MS:-} ]] && export PRE_PLUGIN_START_MS
fi

# Compute total if both endpoints available ----------------------------------
if [[ -z ${PRE_PLUGIN_TOTAL_MS:-} && -n ${PRE_PLUGIN_START_MS:-} && -n ${PRE_PLUGIN_END_MS:-} ]]; then
  (( PRE_PLUGIN_TOTAL_MS = PRE_PLUGIN_END_MS - PRE_PLUGIN_START_MS ))
  (( PRE_PLUGIN_TOTAL_MS < 0 )) && PRE_PLUGIN_TOTAL_MS=0
  export PRE_PLUGIN_TOTAL_MS
fi

# Emit SEGMENT / markers -----------------------------------------------------
if [[ -n ${PERF_SEGMENT_LOG:-} && -n ${PRE_PLUGIN_TOTAL_MS:-} ]]; then
  print "PRE_PLUGIN_COMPLETE ${PRE_PLUGIN_TOTAL_MS}" >>"$PERF_SEGMENT_LOG" 2>/dev/null || true
  print "SEGMENT name=pre_plugin_total ms=${PRE_PLUGIN_TOTAL_MS} phase=pre_plugin sample=${PERF_SAMPLE_CONTEXT:-unknown}" >>"$PERF_SEGMENT_LOG" 2>/dev/null || true
elif [[ -n ${PERF_SEGMENT_LOG:-} && -z ${PRE_PLUGIN_TOTAL_MS:-} && -z ${_PREPLUGIN_SEGMENT_MISSED_LOGGED:-} ]]; then
  # Log once to aid diagnostics
  print "#WARN pre_plugin_total segment not emitted (missing start/end ms)" >>"$PERF_SEGMENT_LOG" 2>/dev/null || true
  _PREPLUGIN_SEGMENT_MISSED_LOGGED=1
fi

zsh_debug_echo "# [pre-plugin] 40-pre-plugin-reserved loaded (total_ms=${PRE_PLUGIN_TOTAL_MS:-n/a})"
