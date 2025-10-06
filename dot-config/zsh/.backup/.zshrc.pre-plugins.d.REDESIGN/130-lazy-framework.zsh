#!/usr/bin/env zsh
# 130-LAZY-FRAMEWORK.ZSH (inlined from legacy 35-lazy-framework.zsh)
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}
if [[ -n "${_LOADED_LAZY_FRAMEWORK_REDESIGN:-}" ]]; then return 0; fi
export _LOADED_LAZY_FRAMEWORK_REDESIGN=1
_lazy_debug() { [[ -n "${ZSH_DEBUG:-}" ]] && zf::debug "[LAZY-FRAMEWORK] $1" || true; }
_lazy_debug "Loading enhanced lazy loading framework (v2.1.0)"
if [[ -n "${PERF_SEGMENT_LOG:-}" ]]; then
	zmodload zsh/datetime 2>/dev/null || true
	_perf_timestamp_ms() { printf '%s' "$EPOCHREALTIME" | awk -F. '{ms=$1*1000; if(NF>1){ms+=substr($2"000",1,3)+0} printf "%d",ms}' 2>/dev/null || echo 0; }
	_perf_log_segment() { local n="$1" d="$2" t="${3:-LAZY_SEGMENT}"; [[ -n ${PERF_SEGMENT_LOG:-} ]] && print "$t $n $d" >>"$PERF_SEGMENT_LOG" 2>/dev/null || true; }
	_lazy_debug "Performance instrumentation initialized"
else
	_perf_timestamp_ms() { echo 0; }; _perf_log_segment() { :; }; _lazy_debug "Performance instrumentation disabled";
fi
typeset -gA _LAZY_REGISTRY _LAZY_STATE _LAZY_ERRORS _LAZY_LOAD_TIMES
typeset -g _LAZY_LAST_COMMAND=""
_lazy_debug "Lazy loading registry initialized"
lazy_register() { local force=0 start_time="$(_perf_timestamp_ms)"; while [[ $# -gt 0 ]]; do case "$1" in -f|--force) force=1; shift;; --) shift; break;; -*) _lazy_debug "Warning: Unknown flag '$1' ignored"; shift;; *) break;; esac; done; local cmd="$1" loader="$2"; [[ -z $cmd || -z $loader ]] && { _lazy_debug "Usage: lazy_register [-f|--force] <command> <loader_function>"; return 1; }; if command -v "$cmd" >/dev/null 2>&1 && [[ $force -eq 0 ]]; then _lazy_debug "Skipping '$cmd' (already available)"; return 0; fi; if [[ -n "${_LAZY_REGISTRY[$cmd]:-}" && $force -eq 0 ]]; then _lazy_debug "Command '$cmd' already registered"; return 2; fi; if ! declare -f "$loader" >/dev/null 2>&1; then _lazy_debug "Error: Loader function '$loader' not found for '$cmd'"; return 3; fi; if [[ $force -eq 1 ]] && declare -f "$cmd" >/dev/null 2>&1; then unfunction "$cmd" 2>/dev/null || true; _lazy_debug "Force override applied to '$cmd'"; fi; _LAZY_REGISTRY[$cmd]="$loader"; _LAZY_STATE[$cmd]="registered"; eval "${cmd}() { lazy_dispatch '${cmd}' \"$@\"; }"; local end_time="$(_perf_timestamp_ms)"; _perf_log_segment "lazy-register-${cmd}" $((end_time-start_time)) "LAZY_REGISTER"; _lazy_debug "Registered '$cmd' -> loader '$loader'"; }
lazy_dispatch() { local cmd="$1"; shift || true; local start_time="$(_perf_timestamp_ms)"; _LAZY_LAST_COMMAND="$cmd"; _lazy_debug "Dispatching lazy command: $cmd"; [[ -n "${_LAZY_REGISTRY[$cmd]:-}" ]] || { _lazy_debug "Error: No loader registered for '$cmd'"; _LAZY_ERRORS[$cmd]="no loader"; return 3; }; local state="${_LAZY_STATE[$cmd]:-registered}" loader="${_LAZY_REGISTRY[$cmd]}"; case "$state" in loaded) if declare -f "$cmd" >/dev/null 2>&1 && ! _function_contains_lazy_dispatch "$cmd"; then "$cmd" "$@"; return $?; fi ;; loading) _lazy_debug "Error: Recursion detected while loading '$cmd'"; _LAZY_STATE[$cmd]="failed"; _LAZY_ERRORS[$cmd]="recursion"; return 5 ;; failed) _lazy_debug "Error: Previous load attempt failed for '$cmd'"; return 4 ;; esac; _LAZY_STATE[$cmd]="loading"; declare -f "$loader" >/dev/null 2>&1 || { _lazy_debug "Error: Loader '$loader' disappeared for '$cmd'"; _LAZY_STATE[$cmd]="failed"; _LAZY_ERRORS[$cmd]="loader disappeared"; return 3; }; local load_start="$(_perf_timestamp_ms)"; if ! "$loader" "$cmd"; then local load_end="$(_perf_timestamp_ms)"; _LAZY_STATE[$cmd]="failed"; _LAZY_ERRORS[$cmd]="loader execution failed"; _perf_log_segment "lazy-load-failed-${cmd}" $((load_end-load_start)) "LAZY_LOAD_FAILED"; _lazy_debug "Error: Loader failed for '$cmd'"; return 4; fi; declare -f "$cmd" >/dev/null 2>&1 || { _LAZY_STATE[$cmd]="failed"; _LAZY_ERRORS[$cmd]="function not defined by loader"; _lazy_debug "Error: Loader did not define function '$cmd'"; return 6; }; local load_end="$(_perf_timestamp_ms)" load_time=$((load_end-load_start)); _LAZY_STATE[$cmd]="loaded"; _LAZY_LOAD_TIMES[$cmd]="$load_time"; _perf_log_segment "lazy-load-${cmd}" "$load_time" "LAZY_LOAD_SUCCESS"; local total_time=$((load_end-start_time)); _perf_log_segment "lazy-dispatch-${cmd}" "$total_time" "LAZY_DISPATCH"; _lazy_debug "Successfully loaded '$cmd' (load ${load_time}ms total ${total_time}ms)"; "$cmd" "$@"; }
_function_contains_lazy_dispatch() { local body="$(functions "$1" 2>/dev/null || true)"; [[ $body == *"lazy_dispatch"* ]]; }
is_lazy_registered() { [[ -n "${_LAZY_REGISTRY[$1]:-}" ]]; }
is_lazy_loaded() { [[ "${_LAZY_STATE[$1]:-}" == loaded ]]; }
is_lazy_failed() { [[ "${_LAZY_STATE[$1]:-}" == failed ]]; }
list_lazy_commands() { local cmd; for cmd in "${(@k)_LAZY_REGISTRY}"; do printf "% -20s % -12s %s\n" "$cmd" "${_LAZY_STATE[$cmd]:-unknown}" "${_LAZY_LOAD_TIMES[$cmd]:-N/A}ms"; done; }
lazy_performance_summary() { echo "=== Lazy Loading Performance Summary ==="; local total=0 loaded=0 total_time=0 cmd; for cmd in "${(@k)_LAZY_REGISTRY}"; do ((total++)); if [[ ${_LAZY_STATE[$cmd]} == loaded ]]; then ((loaded++)); ((total_time+=${_LAZY_LOAD_TIMES[$cmd]:-0})); fi; done; echo "Total registered commands: $total"; echo "Loaded commands: $loaded"; echo "Total load time: ${total_time}ms"; ((loaded>0)) && echo "Average load time: $((total_time/loaded))ms"; }
export LAZY_FRAMEWORK_VERSION="2.1.0" LAZY_FRAMEWORK_LOADED_AT="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo unknown)"
_lazy_debug "Enhanced lazy loading framework ready"
return 0
