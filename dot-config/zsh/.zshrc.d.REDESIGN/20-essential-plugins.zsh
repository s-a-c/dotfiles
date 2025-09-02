# 20-essential-plugins.zsh
: ${_LOADED_20_ESSENTIAL_PLUGINS:=1}
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v900f08def0e6f7959ffd283aebb73b625b3473f5e49c57e861c6461b50a62ef2
#
# PURPOSE:
#   Lightweight timing instrumentation for the "20-essential-plugins" post‑plugin
#   segment. Emits a granular marker so perf tooling can break down large
#   post_plugin_cost_ms into sub-segments.
#
# MARKER FORMAT (written to $PERF_SEGMENT_LOG):
#   POST_PLUGIN_SEGMENT 20-essential <delta_ms>
#
# Notes:
#   - Only runs once (idempotent via POST_SEG_20_ESSENTIAL_MS).
#   - Safe if PERF_SEGMENT_LOG unset (no-op).
#   - Placeholder for future essential plugin sourcing logic (insert between START and END comments).
#
zmodload zsh/datetime 2>/dev/null || true

# Capture start (only if logging enabled and not already captured)
if [[ -n ${PERF_SEGMENT_LOG:-} && -z ${POST_SEG_20_ESSENTIAL_START_MS:-} ]]; then
  POST_SEG_20_ESSENTIAL_START_MS=$(printf '%s' "$EPOCHREALTIME" | awk -F. '{ms = ($1*1000); if (NF>1){ ms+=substr($2 "000",1,3)+0 } printf "%d", ms }' 2>/dev/null || echo "")
  export POST_SEG_20_ESSENTIAL_START_MS
fi

# === Essential plugin loading placeholder START ===
# (Add actual essential plugin sourcing here in future iterations)
# === Essential plugin loading placeholder END ===

# Emit end + delta once
if [[ -n ${PERF_SEGMENT_LOG:-} && -n ${POST_SEG_20_ESSENTIAL_START_MS:-} && -z ${POST_SEG_20_ESSENTIAL_MS:-} ]]; then
  local __post_seg_20_end_ms __post_seg_20_delta
  __post_seg_20_end_ms=$(printf '%s' "$EPOCHREALTIME" | awk -F. '{ms = ($1*1000); if (NF>1){ ms+=substr($2 "000",1,3)+0 } printf "%d", ms }' 2>/dev/null || echo "")
  if [[ -n $__post_seg_20_end_ms ]]; then
    (( __post_seg_20_delta = __post_seg_20_end_ms - POST_SEG_20_ESSENTIAL_START_MS ))
    POST_SEG_20_ESSENTIAL_MS=$__post_seg_20_delta
    export POST_SEG_20_ESSENTIAL_MS
    if [[ $__post_seg_20_delta -ge 0 ]]; then
      print "POST_PLUGIN_SEGMENT 20-essential $__post_seg_20_delta" >>"${PERF_SEGMENT_LOG}" 2>/dev/null || true
    fi
    zsh_debug_echo "# [post-plugin][perf] segment=20-essential delta=${POST_SEG_20_ESSENTIAL_MS}ms"
  fi
fi
