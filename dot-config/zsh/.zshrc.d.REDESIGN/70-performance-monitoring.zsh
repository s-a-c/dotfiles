#!/opt/homebrew/bin/zsh
# 70-performance-monitoring.zsh
# Performance monitoring coordination and async metrics export.
#
# NOTE (path resolution):
#   Do NOT use the brittle form ${0:A:h} directly. We rely on the resilient
#   helpers (zf::script_dir / resolve_script_dir) defined in .zshenv. This avoids
#   plugin-manager compilation context issues.

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
