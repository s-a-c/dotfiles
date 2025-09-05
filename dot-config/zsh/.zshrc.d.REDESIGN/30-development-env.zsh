#!/opt/homebrew/bin/zsh
# 30-development-env.zsh
: ${_LOADED_30_DEVELOPMENT_ENV:=1}
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v900f08def0e6f7959ffd283aebb73b625b3473f5e49c57e861c6461b50a62ef2
#
# PURPOSE:
#   Timing instrumentation for development environment initialization phase.
#   Emits a granular post-plugin segment marker so we can attribute cost
#   separate from other post-plugin modules.
#
# MARKER:
#   POST_PLUGIN_SEGMENT 30-dev-env <delta_ms>
#
# NOTES:
#   - Designed to be lightweight & idempotent.
#   - Insert real dev environment setup logic between START/END placeholders.
#   - Only emits when PERF_SEGMENT_LOG is set (perf-capture context).
#
zmodload zsh/datetime 2>/dev/null || true
typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }
if [[ -n ${PERF_SEGMENT_LOG:-} && -z ${POST_SEG_30_DEV_ENV_START_MS:-} ]]; then
  POST_SEG_30_DEV_ENV_START_MS=$(printf '%s' "$EPOCHREALTIME" | awk -F. '{ms=$1*1000;if(NF>1){ms+=substr($2"000",1,3)+0}printf "%d",ms}')
  export POST_SEG_30_DEV_ENV_START_MS
fi
# === Development environment setup placeholder START ===
# (Future: language toolchains, SDK path exports, virtual env lazy hooks, etc.)
# === Development environment setup placeholder END ===
if [[ -n ${PERF_SEGMENT_LOG:-} && -n ${POST_SEG_30_DEV_ENV_START_MS:-} && -z ${POST_SEG_30_DEV_ENV_MS:-} ]]; then
  local __post_seg_30_end_ms __post_seg_30_delta
  __post_seg_30_end_ms=$(printf '%s' "$EPOCHREALTIME" | awk -F. '{ms=$1*1000;if(NF>1){ms+=substr($2"000",1,3)+0}printf "%d",ms}')
  if [[ -n $__post_seg_30_end_ms ]]; then
    (( __post_seg_30_delta = __post_seg_30_end_ms - POST_SEG_30_DEV_ENV_START_MS ))
    POST_SEG_30_DEV_ENV_MS=$__post_seg_30_delta
    export POST_SEG_30_DEV_ENV_MS
    if [[ $__post_seg_30_delta -ge 0 ]]; then
      print "POST_PLUGIN_SEGMENT 30-dev-env $__post_seg_30_delta" >>"${PERF_SEGMENT_LOG}" 2>/dev/null || true
    fi
    zsh_debug_echo "# [post-plugin][perf] segment=30-dev-env delta=${POST_SEG_30_DEV_ENV_MS}ms"
  fi
fi
