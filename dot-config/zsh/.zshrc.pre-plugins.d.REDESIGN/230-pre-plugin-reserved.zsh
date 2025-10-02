#!/usr/bin/env zsh
# 230-pre-plugin-reserved.zsh (INLINE MIGRATION of legacy 85-pre-plugin-reserved.zsh)
# AI Authored Consolidation: Wrapper indirection removed; original file stubbed.
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) ${GUIDELINES_CHECKSUM:-vUNKNOWN}
# Purpose:
#   Reserved insertion point for future pre-plugin instrumentation OR lightweight governance hooks.
#   Ensures a robust pre_plugin_total segment is emitted even in constrained environments.
# Notes:
#   - This module may run very late in the pre-plugin phase; it tolerates partially missing timing vars.
#   - Reconstructed metrics are best-effort and guarded for safety (nounset friendly).

[[ -n ${_LOADED_PRE_RESERVED_SLOT:-} ]] && return 0
_LOADED_PRE_RESERVED_SLOT=1
export _LOADED_PRE_RESERVED_SLOT

# ----------------------------------------------------------------------------
# Helper: Convert EPOCHREALTIME style value (sec.frac) to integer milliseconds
# ----------------------------------------------------------------------------
__preplugin_ms_from_epoch() {
	local ts="$1" sec frac
	[[ -z $ts ]] && return 1
	case $ts in
		*.*) sec=${ts%%.*}; frac=${ts#*.} ;;
		*)   sec=$ts; frac=0 ;;
	esac
	frac="${frac}000"           # pad
	frac=${frac%%[!0-9]*}        # strip non-digits
	frac=${frac:0:3}             # first three digits => ms
	print $(( sec * 1000 + ${frac:-0} ))
}

# Ensure end realtime + ms ---------------------------------------------------
if [[ -z ${PRE_PLUGIN_END_REALTIME:-} ]]; then
	zmodload zsh/datetime 2>/dev/null || true
	PRE_PLUGIN_END_REALTIME=$EPOCHREALTIME
	export PRE_PLUGIN_END_REALTIME
	if command -v awk >/dev/null 2>&1; then
		PRE_PLUGIN_END_MS=$(printf '%s' "$PRE_PLUGIN_END_REALTIME" | awk -F. '{ms=($1*1000); if(NF>1){ ms+=substr($2 "000",1,3)+0 } printf "%d", ms }' 2>/dev/null || echo "")
	else
		PRE_PLUGIN_END_MS=$(__preplugin_ms_from_epoch "$PRE_PLUGIN_END_REALTIME" || echo "")
	fi
	[[ -n ${PRE_PLUGIN_END_MS:-} ]] && export PRE_PLUGIN_END_MS
fi

# Reconstruct missing START_MS if possible ----------------------------------
if [[ -z ${PRE_PLUGIN_START_MS:-} && -n ${PRE_PLUGIN_START_REALTIME:-} ]]; then
	if command -v awk >/dev/null 2>&1; then
		PRE_PLUGIN_START_MS=$(printf '%s' "$PRE_PLUGIN_START_REALTIME" | awk -F. '{ms=($1*1000); if(NF>1){ ms+=substr($2 "000",1,3)+0 } printf "%d", ms }' 2>/dev/null || echo "")
	else
		PRE_PLUGIN_START_MS=$(__preplugin_ms_from_epoch "$PRE_PLUGIN_START_REALTIME" || echo "")
	fi
	[[ -n ${PRE_PLUGIN_START_MS:-} ]] && export PRE_PLUGIN_START_MS
fi

# Compute total when both endpoints present ---------------------------------
if [[ -z ${PRE_PLUGIN_TOTAL_MS:-} && -n ${PRE_PLUGIN_START_MS:-} && -n ${PRE_PLUGIN_END_MS:-} ]]; then
	(( PRE_PLUGIN_TOTAL_MS = PRE_PLUGIN_END_MS - PRE_PLUGIN_START_MS ))
	(( PRE_PLUGIN_TOTAL_MS < 0 )) && PRE_PLUGIN_TOTAL_MS=0
	export PRE_PLUGIN_TOTAL_MS
fi

# Emit segment(s) if possible ------------------------------------------------
if [[ -n ${PERF_SEGMENT_LOG:-} && -n ${PRE_PLUGIN_TOTAL_MS:-} ]]; then
	print "PRE_PLUGIN_COMPLETE ${PRE_PLUGIN_TOTAL_MS}" >>"$PERF_SEGMENT_LOG" 2>/dev/null || true
	print "SEGMENT name=pre_plugin_total ms=${PRE_PLUGIN_TOTAL_MS} phase=pre_plugin sample=${PERF_SAMPLE_CONTEXT:-unknown}" >>"$PERF_SEGMENT_LOG" 2>/dev/null || true
elif [[ -n ${PERF_SEGMENT_LOG:-} && -z ${PRE_PLUGIN_TOTAL_MS:-} && -z ${_PREPLUGIN_SEGMENT_MISSED_LOGGED:-} ]]; then
	print "#WARN pre_plugin_total segment not emitted (missing start/end ms)" >>"$PERF_SEGMENT_LOG" 2>/dev/null || true
	_PREPLUGIN_SEGMENT_MISSED_LOGGED=1
fi

# Lightweight debug trace (guarded) -----------------------------------------
if typeset -f zf::debug >/dev/null 2>&1; then
	zf::debug "# [pre-plugin] 230-pre-plugin-reserved loaded (total_ms=${PRE_PLUGIN_TOTAL_MS:-n/a})"
fi

export PRE_PLUGIN_RESERVED_VERSION="1.0.0"
return 0
