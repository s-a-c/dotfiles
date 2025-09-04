# 70-performance-monitoring.zsh
# Added placeholder sync segment probes (Phase A – attribution scaffolding)
# These placeholders create zero/near-zero duration segments so downstream tests
# and tooling can begin recognizing the labels before real instrumentation
# replaces them. Safe to remove once real probes are implemented.
#
# NOTE (path resolution):
#   Do NOT use the brittle form ${0:A:h} directly. We rely on the resilient
#   helpers (zf::script_dir / resolve_script_dir) defined in .zshenv. This avoids
#   plugin-manager compilation context issues.

# Guard to avoid duplicate emission
if [[ -z ${_ZSH_PERF_PLACEHOLDER_SYNC_SEGMENTS_DONE:-} ]]; then
    _ZSH_PERF_PLACEHOLDER_SYNC_SEGMENTS_DONE=1

    # Fallback stubs if segment-lib not yet loaded (no-op timing)
    if ! typeset -f _zsh_perf_segment_start >/dev/null 2>&1; then
        _zsh_perf_segment_start() { :; }
        _zsh_perf_segment_end() { :; }
    fi

    # Placeholder post_plugin segments (will later move to precise phases/files)
    # Rationale:
    #   - Enables early test coverage & budget list stabilization.
    #   - Prevents “missing segment” warnings from gating logic while real probes
    #     are introduced incrementally in their owning modules.
    for __seg in syntax_highlight_init history_backend_init theme_extras_init completion_cache_scan vcs_helpers_init fzf_tools_init ; do
        _zsh_perf_segment_start "${__seg}" post_plugin
        _zsh_perf_segment_end   "${__seg}" post_plugin
    done
fi

# Export async metrics (Phase A shadow – best-effort; non-fatal)
if [[ -z ${ASYNC_METRICS_EXPORTED_70:-} ]]; then
    ASYNC_METRICS_EXPORTED_70=1
    # Primary expected location under ZDOTDIR tools
    if [[ -r ${ZDOTDIR:-$HOME/.config/zsh}/tools/async-metrics-export.zsh ]]; then
        source "${ZDOTDIR:-$HOME/.config/zsh}/tools/async-metrics-export.zsh" 2>/dev/null || true
    # Fallback using resilient script directory resolver
    else
        # Prefer namespaced helper if loaded; fallback to resolve_script_dir
        if typeset -f zf::script_dir >/dev/null 2>&1; then
        __pm_dir="$(zf::script_dir "${(%):-%N}")"
        elif typeset -f resolve_script_dir >/dev/null 2>&1; then
        __pm_dir="$(resolve_script_dir "${(%):-%N}")"
        else
        # Last-resort: fall back to PWD (still avoiding ${0:A:h})
        __pm_dir="$PWD"
        fi
        if [[ -n "${__pm_dir:-}" && -r "${__pm_dir}/../tools/async-metrics-export.zsh" ]]; then
        # shellcheck disable=SC1090
        source "${__pm_dir}/../tools/async-metrics-export.zsh" 2>/dev/null || true
        fi
        unset __pm_dir
    fi
fi

: ${_LOADED_70_PERFORMANCE_MONITORING:=1}
