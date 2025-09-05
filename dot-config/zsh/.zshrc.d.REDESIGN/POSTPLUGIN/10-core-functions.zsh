#!/opt/homebrew/bin/zsh
# ============================================================================
# 10-core-functions.zsh  (Stage 3 – Post-Plugin Core Scaffold)
#
# Responsibility:
#   Central namespace of lightweight reusable helpers (logging, assertions,
#   timing, safe command checks, structured error emission, future segment
#   helper wrappers). Designed to be:
#     - Fast (≈0–1ms load)
#     - Idempotent (safe to re-source)
#     - Namespace-safe (zf:: prefix only)
#
# Non-Goals (now):
#   - Heavy profiling / statistical aggregation (can arrive later in perf module).
#   - Async job orchestration (handled by later stages).
#   - Direct plugin manipulation (belongs to feature / UI layers).
#
# Invariants (I*):
#   I1: Re-sourcing does not redefine functions with different bodies.
#   I2: Logging suppressed unless explicitly enabled (ZSH_DEBUG=1).
#   I3: Timing helpers degrade gracefully if `date` high-res not available.
#   I4: Assertions never leave partial state (clean exit path).
#   I5: Segment emission wrappers no-op safely if segment-lib not loaded.
#
# Exported Sentinels:
#   ZSH_CORE_FUNCTIONS_GUARD=1
#   ZSH_CORE_FUNCTIONS_VERSION=1
#
# Provided Functions (zf:: namespace):
#   zf::log <msg...>                       - Debug log (stderr) when ZSH_DEBUG=1
#   zf::warn <msg...>                      - Always warn to stderr (prefixed)
#   zf::ensure_cmd <cmd> [hint]            - Return 0 if command exists else 1 (optional hint output)
#   zf::assert <condition> <message>       - Fail with message (non-fatal by default unless ZF_ASSERT_EXIT=1)
#   zf::time_block <var> <command...>      - Run command; store duration (ms) in <var>
#   zf::with_timing <label> <command...>   - Run command; emit segment or debug log with timing
#   zf::emit_segment <label> [ms]          - Wrapper: call segment-lib if present
#   zf::trace_fn <fn-name>                 - Wrap existing fn with entry/exit logs (debug only)
#   zf::have_segment_lib                   - Predicate: 0 if segment-lib functions present
#
# Timing Strategy:
#   Prefer nanoseconds via $(date +%s%N) when available.
#   Fallback to ms granularity via $(date +%s) * 1000.
#
# Testing Hooks (anticipated):
#   test-core-functions-ensure-cmd.zsh      - validates ensure_cmd logic
#   test-core-functions-assert.zsh          - ensures assertion path & env overrides
#   test-core-functions-time-block.zsh      - validates timing monotonicity
#   test-core-functions-segment-wrapper.zsh - segment emission no-op vs active
#
# Performance:
#   Sourcing: function definitions only; no external calls except capability sniff.
#   Acceptable upper bound: ≤1ms incremental in baseline measurement.
#
# Future Extension Points:
#   - zf::retry <n> <cmd...>
#   - zf::memoize <key> <cmd...>
#   - Structured JSON log adapter (if ever required)
# ============================================================================

# Idempotency guard
if [[ -n "${ZSH_CORE_FUNCTIONS_GUARD:-}" ]]; then
    return 0
fi
export ZSH_CORE_FUNCTIONS_GUARD=1
export ZSH_CORE_FUNCTIONS_VERSION=1

# -----------------------------------------------------------------------------
# Internal capability detection (one-time)
# -----------------------------------------------------------------------------
_zf_have_date_nano=0
if command -v date >/dev/null 2>&1; then
    # Check whether %N supported (GNU / some BSDs)
    if ( date +%s%N >/dev/null 2>&1 ); then
        _zf_have_date_nano=1
    fi
fi

# -----------------------------------------------------------------------------
# Logging Helpers
# -----------------------------------------------------------------------------
zf::log() {
    [[ "${ZSH_DEBUG:-0}" == "1" ]] || return 0
    print -u2 "[zf][debug] $*"
}

zf::warn() {
    print -u2 "[zf][warn] $*"
}

# -----------------------------------------------------------------------------
# Command Presence (cached)
# -----------------------------------------------------------------------------
typeset -gA _zf_cmd_cache
zf::ensure_cmd() {
    local cmd="$1" hint="${2:-}"
    [[ -n "$cmd" ]] || { zf::warn "ensure_cmd: missing command name"; return 1; }
    local key="cmd_$cmd"
    if [[ -n "${_zf_cmd_cache[$key]:-}" ]]; then
        [[ "${_zf_cmd_cache[$key]}" == "1" ]] && return 0 || return 1
    fi
    if command -v "$cmd" >/dev/null 2>&1; then
        _zf_cmd_cache[$key]=1
        return 0
    fi
    _zf_cmd_cache[$key]=0
    [[ -n "$hint" ]] && zf::warn "Missing command '$cmd' ($hint)"
    return 1
}

# -----------------------------------------------------------------------------
# Assertions
#   By default they DO NOT exit the shell. Set ZF_ASSERT_EXIT=1 to make failures fatal.
# -----------------------------------------------------------------------------
zf::assert() {
    local condition="$1"; shift
    local message="$*"
    if eval "$condition"; then
        return 0
    fi
    zf::warn "Assertion failed: $condition ${message:+-- $message}"
    if [[ "${ZF_ASSERT_EXIT:-0}" == "1" ]]; then
        return 1  # Prefer returning non-zero so callers can decide; external harness can treat as fatal.
    fi
    return 1
}

# -----------------------------------------------------------------------------
# Time Utilities
# -----------------------------------------------------------------------------
_zf_now_ns() {
    if (( _zf_have_date_nano == 1 )); then
        date +%s%N
    else
        # Fallback ms -> convert to pseudo-ns (ms * 1_000_000) for difference arithmetic
        printf '%s000000' "$(date +%s 2>/dev/null || echo 0)"
    fi
}

_zf_diff_ms() {
    # Args: start_ns end_ns
    local start="$1" end="$2"
    # Avoid bc/awk; pure shell integer arithmetic
    local diff=$(( end - start ))
    # If fallback path used (ms * 1e6), dividing by 1e6 returns ms.
    printf '%d' $(( diff / 1000000 ))
}

# Run a command and store its duration (ms) in a variable name
zf::time_block() {
    local out_var="$1"; shift
    [[ -n "$out_var" ]] || { zf::warn "time_block: missing output var"; return 2; }
    local _start _end _ms
    _start="$(_zf_now_ns)"
    # Run the command with stderr/stdout preserved
    "$@"
    local rc=$?
    _end="$(_zf_now_ns)"
    _ms="$(_zf_diff_ms "$(_start)" "$(_end)")"
    # Indirect assignment
    printf -v "$out_var" '%s' "$_ms"
    return $rc
}

# -----------------------------------------------------------------------------
# Segment Emission Wrapper
#   Delegates to segment-lib when present. We do not import heavy libs here.
# -----------------------------------------------------------------------------
zf::have_segment_lib() {
    typeset -f emit_segment >/dev/null 2>&1 && return 0
    return 1
}

zf::emit_segment() {
    local label="$1" ms="$2"
    [[ -z "$label" ]] && return 0
    if zf::have_segment_lib; then
        if [[ -n "$ms" ]]; then
            emit_segment "$label" "$ms"
        else
            emit_segment "$label"
        fi
    else
        # Silent no-op (debug log only if requested)
        zf::log "segment-lib missing; skipped segment '$label'"
    fi
}

# -----------------------------------------------------------------------------
# with_timing: run a command, measure ms, optionally emit segment
# Usage:
#   zf::with_timing label command [args...]
# Env:
#   ZF_WITH_TIMING_EMIT=1 -> emit segment (default if segment lib exists)
# -----------------------------------------------------------------------------
zf::with_timing() {
    local label="$1"; shift
    [[ -n "$label" ]] || { zf::warn "with_timing: missing label"; return 2; }
    local _start _end _ms rc
    _start="$(_zf_now_ns)"
    "$@"
    rc=$?
    _end="$(_zf_now_ns)"
    _ms="$(_zf_diff_ms "$_start" "$_end")"
    zf::log "with_timing '$label' took ${_ms}ms (rc=$rc)"
    if [[ "${ZF_WITH_TIMING_EMIT:-auto}" == "1" || ( "${ZF_WITH_TIMING_EMIT:-auto}" == "auto" && "$(zf::have_segment_lib; echo $?)" = "0" ) ]]; then
        zf::emit_segment "$label" "$_ms"
    fi
    return $rc
}

# -----------------------------------------------------------------------------
# trace_fn: wrap a function to log entry + exit (debug only)
# -----------------------------------------------------------------------------
zf::trace_fn() {
    [[ "${ZSH_DEBUG:-0}" == "1" ]] || return 0
    local fn="$1"
    [[ -n "$fn" ]] || { zf::warn "trace_fn: missing function name"; return 2; }
    typeset -f "$fn" >/dev/null 2>&1 || { zf::warn "trace_fn: function '$fn' not found"; return 1; }
    # Preserve original
    local original="_zf_orig_${fn}"
    if ! typeset -f "$original" >/dev/null 2>&1; then
        eval "$(typeset -f "$fn" | sed "1s/${fn} ()/${original} ()/")"
    fi
    eval "${fn}() {
        zf::log \"ENTER ${fn}:\$*\"
        ${original} \"\$@\"
        local rc=\$?
        zf::log \"LEAVE ${fn} rc=\$rc\"
        return \$rc
    }"
    zf::log "trace_fn activated for $fn"
}

# -----------------------------------------------------------------------------
# Self-test (very light, only in explicit debug mode)
# -----------------------------------------------------------------------------
if [[ "${ZSH_DEBUG:-0}" == "1" ]]; then
  zf::log "core-functions sourced (nano=${_zf_have_date_nano})"
  zf::ensure_cmd printf >/dev/null || zf::warn "printf missing? (unexpected)"
fi

# End of 10-core-functions.zsh
