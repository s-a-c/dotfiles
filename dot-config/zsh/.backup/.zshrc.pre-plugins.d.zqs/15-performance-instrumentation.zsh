#!/usr/bin/env zsh
# 15-performance-instrumentation.zsh - Performance monitoring for ZQS
# Part of the migration to symlinked ZQS .zshrc

# =================================================================================
# === Performance Instrumentation (ZGENOM timing) ===
# =================================================================================

# This file sets up performance monitoring hooks that will be used when
# ZQS loads zgenom. The actual zgenom loading happens in the main .zshrc,
# so we prepare the instrumentation here.

# Note: ZQS .zshrc will handle the actual zgenom loading and timing.
# This file ensures the timing variables are available and provides
# additional performance monitoring capabilities.

# Initialize performance timing if PERF_SEGMENT_LOG is set
if [[ -n ${PERF_SEGMENT_LOG:-} ]]; then
    # Ensure zsh/datetime module is loaded for high-resolution timing
    zmodload zsh/datetime 2>/dev/null || true

    # Helper function for consistent timing format
    _perf_timestamp_ms() {
        printf '%s' "$EPOCHREALTIME" | awk -F. '{ms=$1*1000; if(NF>1){ms+=substr($2"000",1,3)+0} printf "%d",ms}'
    }

    # Log performance segment helper
    _perf_log_segment() {
        local segment_name="$1"
        local duration_ms="$2"
        local segment_type="${3:-POST_PLUGIN_SEGMENT}"

        if [[ -n ${PERF_SEGMENT_LOG:-} ]]; then
            print "${segment_type} ${segment_name} ${duration_ms}" >>"${PERF_SEGMENT_LOG}" 2>/dev/null || true
            zf::debug "# [pre-plugin-ext][perf] segment=${segment_name} delta=${duration_ms}ms type=${segment_type}"
        fi
    }

    zf::debug "# [pre-plugin-ext] Performance instrumentation initialized (PERF_SEGMENT_LOG=${PERF_SEGMENT_LOG})"
else
    zf::debug "# [pre-plugin-ext] Performance instrumentation available but disabled (no PERF_SEGMENT_LOG)"
fi

# Pre-zgenom initialization marker
if [[ -n ${PERF_SEGMENT_LOG:-} && -z ${ZGENOM_INIT_START_MS:-} ]]; then
    ZGENOM_INIT_START_MS=$(_perf_timestamp_ms)
    export ZGENOM_INIT_START_MS
    zf::debug "# [pre-plugin-ext] ZGENOM timing start marker set: ${ZGENOM_INIT_START_MS}"
fi
