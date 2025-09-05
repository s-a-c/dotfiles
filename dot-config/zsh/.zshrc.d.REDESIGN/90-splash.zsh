#!/opt/homebrew/bin/zsh
# 90-splash.zsh (Post-Plugin Finalization & Optional Splash)
: ${_LOADED_90_SPLASH:=1}
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   - Emit POST_PLUGIN timing segment marker consumed by perf-capture.zsh
#   - Provide optional (fully suppressible) splash/log summary hook
#
# TIMING INSTRUMENTATION:
#   Earlier modules exported:
#     PRE_PLUGIN_START_MS / PRE_PLUGIN_END_MS / PRE_PLUGIN_TOTAL_MS
#   Here we emit POST_PLUGIN_COMPLETE <post_plugin_ms> to $PERF_SEGMENT_LOG if available.
#
# DISABLE SPLASH:
#   Export ZSH_SPLASH_DISABLE=1 to suppress any future visual output (reserved for later features).

typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }

# Emit post-plugin timing marker once
if [[ -z ${POST_PLUGIN_END_MS:-} ]]; then
    zmodload zsh/datetime 2>/dev/null || true
    POST_PLUGIN_END_REALTIME=$EPOCHREALTIME
    POST_PLUGIN_END_MS=$(printf '%s' "$EPOCHREALTIME" | awk -F. '{ms = ($1 * 1000); if (NF>1){ ms += substr($2 "000",1,3)+0 } printf "%d", ms }' 2>/dev/null || echo "")
    export POST_PLUGIN_END_REALTIME POST_PLUGIN_END_MS
    if [[ -n ${PRE_PLUGIN_END_MS:-} && -n ${POST_PLUGIN_END_MS:-} ]]; then
        ((POST_PLUGIN_TOTAL_MS = POST_PLUGIN_END_MS - PRE_PLUGIN_END_MS))
        export POST_PLUGIN_TOTAL_MS
        zsh_debug_echo "# [post-plugin][perf] POST_PLUGIN_END_REALTIME=$POST_PLUGIN_END_REALTIME ms=${POST_PLUGIN_END_MS} total=${POST_PLUGIN_TOTAL_MS}"
        if [[ -n ${PERF_SEGMENT_LOG:-} ]]; then
            print "POST_PLUGIN_COMPLETE ${POST_PLUGIN_TOTAL_MS}" >>"$PERF_SEGMENT_LOG" 2>/dev/null || true
            print "SEGMENT name=post_plugin_total ms=${POST_PLUGIN_TOTAL_MS} phase=post_plugin sample=${PERF_SAMPLE_CONTEXT:-unknown}" >>"$PERF_SEGMENT_LOG" 2>/dev/null || true
        fi
    else
        zsh_debug_echo "# [post-plugin][perf] POST_PLUGIN_END_REALTIME=$POST_PLUGIN_END_REALTIME (missing PRE_PLUGIN_END_MS for delta)"
    fi
fi

# (Optional future splash output; currently no-op when disabled)
if [[ "${ZSH_SPLASH_DISABLE:-0}" == "1" ]]; then
    zsh_debug_echo "# [splash] disabled"
else
    zsh_debug_echo "# [splash] module loaded (no visual output by design)"
fi
