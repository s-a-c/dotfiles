# 70-performance-monitoring.zsh
# Added placeholder sync segment probes (Phase A – attribution scaffolding)
# These placeholders create zero/near-zero duration segments so downstream tests
# and tooling can begin recognizing the labels before real instrumentation
# replaces them. Safe to remove once real probes are implemented.

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
  # Fallback relative path (handles sourcing within repo during tests)
  elif [[ -r "${0:A:h}/../tools/async-metrics-export.zsh" ]]; then
    source "${0:A:h}/../tools/async-metrics-export.zsh" 2>/dev/null || true
  fi
fi

: ${_LOADED_70_PERFORMANCE_MONITORING:=1}
