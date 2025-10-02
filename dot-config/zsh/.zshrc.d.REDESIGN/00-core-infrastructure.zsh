#!/usr/bin/env zsh
# ==============================================================================
# 00-CORE-INFRASTRUCTURE.ZSH - Core Shell Infrastructure (REDESIGN v2)
# ==============================================================================
# Purpose: Core shell infrastructure including timeout protection, logging,
#          standard helpers, and execution detection
# Consolidates: 01-core-infrastructure.zsh and foundation components
# Load Order: First (00-) to establish core infrastructure
# Author: ZSH Configuration Redesign System
# Created: 2025-09-22
# Version: 2.0.0
# ==============================================================================

# Prevent multiple loading
if [[ -n "${_CORE_INFRASTRUCTURE_REDESIGN:-}" ]]; then
    return 0
fi
export _CORE_INFRASTRUCTURE_REDESIGN=1

# Debug helper
_core_debug() {
    [[ -n "${ZSH_DEBUG:-}" ]] && zf::debug "[CORE] $1" || true
}

_core_debug "Loading core infrastructure (v2.0.0)"

# ==============================================================================
# SECTION 1: TIMEOUT PROTECTION
# ==============================================================================

# Define timeout wrapper if not available
if ! command -v timeout >/dev/null 2>&1; then
    # Simple timeout implementation using background job
    timeout() {
        local duration="$1"
        shift

        # Run command in background
        "$@" &
        local cmd_pid=$!

        # Start timeout monitor
        (
            sleep "$duration"
            kill -TERM "$cmd_pid" 2>/dev/null
            sleep 2
            kill -KILL "$cmd_pid" 2>/dev/null
        ) &
        local timeout_pid=$!

        # Wait for command to complete
        if wait "$cmd_pid" 2>/dev/null; then
            kill "$timeout_pid" 2>/dev/null
            return 0
        else
            return 124  # timeout exit code
        fi
    }
    _core_debug "Custom timeout implementation installed"
fi

# ==============================================================================
# SECTION 2: SOURCE/EXECUTE DETECTION
# ==============================================================================

is_being_sourced() {
    # ZSH-native source detection - reliable and no BASH dependencies
    [[ "${ZSH_EVAL_CONTEXT}" == *:file ]] || [[ "${(%):-%x}" != "${(%):-%N}" ]]
}

is_being_executed() {
    ! is_being_sourced
}

get_execution_context() {
    if is_being_sourced; then
        echo "sourced"
    else
        echo "executed"
    fi
}

exit_or_return() {
    local exit_code="${1:-0}"
    if is_being_sourced; then
        return "$exit_code"
    else
        exit "$exit_code"
    fi
}

handle_error() {
    local error_msg="$1"
    local exit_code="${2:-1}"
    echo "Error: $error_msg" >&2
    exit_or_return "$exit_code"
}

# Context-aware command execution
execute_if_sourced() {
    if is_being_sourced; then
        "$@"
    fi
}

execute_if_executed() {
    if is_being_executed; then
        "$@"
    fi
}

# Get script name regardless of execution context
get_script_name() {
    # Use ZSH-native variables only
    local script_name="${(%):-%N}"
    if [[ -n "$script_name" ]]; then
        # Use ZSH parameter expansion instead of basename to avoid PATH issues
        echo "${script_name:t}"
    else
        echo "unknown"
    fi
}

# Get calling function information
get_caller_info() {
    local level="${1:-1}"
    # Use ZSH-native funcstack and functrace
    if (( ${#funcstack[@]} > level )); then
        local caller_func="${funcstack[$((level + 1))]:-unknown}"
        local caller_line="${functrace[$((level + 1))]##*:}"
        echo "${caller_func}${caller_line:+:${caller_line}}"
    else
        echo "unknown"
    fi
}

# Conditional sourcing with error handling
safe_source() {
    local file="$1"
    if [[ -f "$file" ]]; then
        source "$file" || handle_error "Failed to source $file" 1
    else
        handle_error "File not found: $file" 1
    fi
}

# Detection state queries
get_detection_state() {
    local context=$(get_execution_context)
    local script_name=$(get_script_name)
    echo "context:$context script:$script_name"
}

is_interactive_shell() {
    [[ -n "$PS1" ]] && [[ "$-" == *i* ]]
}

is_login_shell() {
    [[ "$0" == -* ]]
}

_core_debug "Source/execute detection functions loaded"

# ==============================================================================
# PLUGIN MANAGEMENT UTILITIES
# ==============================================================================

# Quick zgenom reset utility for development
zf::reset_zgenom() {
    local zgenom_init="${ZGEN_INIT:-${ZDOTDIR:-$HOME}/.zqs-zgenom/init.zsh}"
    local zgenom_dir="${ZGEN_DIR:-${ZDOTDIR:-$HOME}/.zqs-zgenom}"

    if [[ -f "$zgenom_init" ]]; then
        rm -f "$zgenom_init"
        zf::log "[ZGENOM] Removed init file: $zgenom_init"
    fi

    if [[ -d "$zgenom_dir" ]]; then
        find "$zgenom_dir" -name ".zcompdump*" -delete 2>/dev/null || true
        zf::log "[ZGENOM] Cleared completion dumps"
    fi

    zf::log "[ZGENOM] Reset complete - will regenerate on next startup"
}

# ==============================================================================
# PLUGIN COMPATIBILITY AND SAFETY FIXES (UNIVERSAL)
# ==============================================================================

# Note: Plugin compatibility fixes have been moved to pre-plugin phase
# (25-lazy-integrations.zsh) to ensure parameters are available during plugin loading
# This ensures autopair and other widget-based plugins initialize correctly

# Global logging configuration
ZSH_LOG_LEVEL="${ZSH_LOG_LEVEL:-INFO}"
ZSH_LOG_FORMAT="${ZSH_LOG_FORMAT:-%T [%L] %M}"
ZSH_LOG_FILE="${ZSH_LOG_FILE:-}"

# Logging level hierarchy
declare -A LOG_LEVELS=(
    [DEBUG]=0
    [INFO]=1
    [WARN]=2
    [ERROR]=3
    [FATAL]=4
)

# Core logging function
zsh_log() {
    local level="$1"
    local message="$2"
    local context="${3:-$(get_script_name)}"

    # Check if we should log this level
    local current_level_num="${LOG_LEVELS[$ZSH_LOG_LEVEL]:-1}"
    local message_level_num="${LOG_LEVELS[$level]:-1}"

    if [[ $message_level_num -ge $current_level_num ]]; then
        local timestamp=$(date '+%H:%M:%S' 2>/dev/null || echo 'unknown')
        local formatted_message

        # Format the message
        formatted_message="${ZSH_LOG_FORMAT}"
        formatted_message="${formatted_message//\%T/$timestamp}"
        formatted_message="${formatted_message//\%L/$level}"
        formatted_message="${formatted_message//\%M/$message}"
        formatted_message="${formatted_message//\%C/$context}"

        # Output to stderr for immediate visibility
        echo "$formatted_message" >&2

        # Also log to file if specified
        if [[ -n "$ZSH_LOG_FILE" ]]; then
            echo "$formatted_message" >> "$ZSH_LOG_FILE" 2>/dev/null
        fi
    fi
}

# Convenience logging functions
zsh_debug() { zsh_log "DEBUG" "$1" "${2:-}" }
zsh_info() { zsh_log "INFO" "$1" "${2:-}" }
zsh_warn() { zsh_log "WARN" "$1" "${2:-}" }
zsh_error() { zsh_log "ERROR" "$1" "${2:-}" }
zsh_fatal() { zsh_log "FATAL" "$1" "${2:-}" }

_core_debug "Unified logging system initialized"

# ==============================================================================
# SECTION 4: STANDARD HELPER FUNCTIONS
# ==============================================================================

# File and directory utilities
ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" 2>/dev/null || {
            zsh_error "Failed to create directory: $dir"
            return 1
        }
    fi
}

safe_cd() {
    local target="$1"
    if [[ -d "$target" ]]; then
        cd "$target" || {
            zsh_error "Failed to change directory to: $target"
            return 1
        }
    else
        zsh_error "Directory does not exist: $target"
        return 1
    fi
}

# String utilities
trim_string() {
    local string="$1"
    # Remove leading and trailing whitespace
    string="${string#"${string%%[![:space:]]*}"}"
    string="${string%"${string##*[![:space:]]}"}"
    echo "$string"
}

join_array() {
    local delimiter="$1"
    shift
    local first="$1"
    shift
    printf %s "$first" "${@/#/$delimiter}"
}

function_exists() {
    declare -f "$1" >/dev/null 2>&1
}

# Environment utilities
get_shell_info() {
    echo "Shell: $SHELL ($ZSH_VERSION)"
    echo "SHLVL: $SHLVL"
    echo "Context: $(get_execution_context)"
    echo "Interactive: $(is_interactive_shell && echo 'yes' || echo 'no')"
    echo "Login: $(is_login_shell && echo 'yes' || echo 'no')"
}

# Performance timing utilities with fallbacks
start_timer() {
    local timer_name="${1:-default}"
    local current_time

    # Try multiple approaches to get time
    if command -v date >/dev/null 2>&1; then
        current_time=$(date +%s%3N 2>/dev/null || date +%s000 2>/dev/null || echo "${EPOCHSECONDS}000")
    else
        current_time="${EPOCHSECONDS}000"
    fi

    eval "TIMER_${timer_name}=$current_time"
}

stop_timer() {
    local timer_name="${1:-default}"
    local current_time

    # Try multiple approaches to get time
    if command -v date >/dev/null 2>&1; then
        current_time=$(date +%s%3N 2>/dev/null || date +%s000 2>/dev/null || echo "${EPOCHSECONDS}000")
    else
        current_time="${EPOCHSECONDS}000"
    fi

    local start_var="TIMER_${timer_name}"
    local start_time="${(P)start_var:-}"

    if [[ -n "$start_time" ]]; then
        local elapsed=$((current_time - start_time))
        echo "Timer $timer_name: ${elapsed}ms"
        return 0
    else
        zsh_error "Timer $timer_name was not started"
        return 1
    fi
}

_core_debug "Standard helper functions loaded"

# ==============================================================================
# SECTION 5: ERROR HANDLING AND RECOVERY
# ==============================================================================

# Enhanced error handling with recovery options
safe_eval() {
    local command="$1"
    local error_msg="${2:-Command failed}"
    local recovery_cmd="${3:-}"

    if eval "$command" 2>/dev/null; then
        return 0
    else
        zsh_error "$error_msg: $command"
        if [[ -n "$recovery_cmd" ]]; then
            zsh_info "Attempting recovery: $recovery_cmd"
            eval "$recovery_cmd"
            return $?
        fi
        return 1
    fi
}

# Trap-based cleanup system
declare -a CLEANUP_FUNCTIONS=()

register_cleanup() {
    local cleanup_func="$1"
    CLEANUP_FUNCTIONS+=("$cleanup_func")
}

run_cleanup() {
    # Safe cleanup with parameter checking
    if [[ -n "${CLEANUP_FUNCTIONS[@]:-}" ]]; then
        local func
        for func in "${CLEANUP_FUNCTIONS[@]}"; do
            if function_exists "$func"; then
                echo "Running cleanup function: $func" >&2
                "$func" 2>/dev/null || echo "Cleanup function failed: $func" >&2
            fi
        done
    fi
}

# Register cleanup to run on shell exit
trap run_cleanup EXIT

_core_debug "Error handling and recovery system initialized"

# ==============================================================================
# SECTION 6: ZF:: NAMESPACE FUNCTIONS (FROM POSTPLUGIN)
# ==============================================================================

# Enhanced capability detection (one-time)
_zf_have_date_nano=0
if command -v date >/dev/null 2>&1; then
    # Check whether %N supported (GNU / some BSDs)
    if (date +%s%N >/dev/null 2>&1); then
        _zf_have_date_nano=1
    fi
fi

# Namespaced logging helpers
zf::log() {
    [[ "${ZSH_DEBUG:-0}" == "1" ]] || return 0
    print -u2 "[zf][debug] $*"
}

zf::warn() {
    print -u2 "[zf][warn] $*"
}

# Command presence checking with cache
typeset -gA _zf_cmd_cache
zf::ensure_cmd() {
    local cmd="$1" hint="${2:-}"
    [[ -n "$cmd" ]] || {
        zf::warn "ensure_cmd: missing command name"
        return 1
    }
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

# Assertions (non-fatal by default)
zf::assert() {
    local condition="$1"
    shift
    local message="$*"
    if eval "$condition"; then
        return 0
    fi
    zf::warn "Assertion failed: $condition ${message:+-- $message}"
    if [[ "${ZF_ASSERT_EXIT:-0}" == "1" ]]; then
        return 1
    fi
    return 1
}

# High-precision timing utilities
_zf_now_ns() {
    if ((_zf_have_date_nano == 1)); then
        date +%s%N
    else
        # Fallback ms -> convert to pseudo-ns (ms * 1_000_000) for difference arithmetic
        printf '%s000000' "$(date +%s 2>/dev/null || echo 0)"
    fi
}

_zf_diff_ms() {
    # Args: start_ns end_ns
    local start="$1" end="$2"
    local diff=$((end - start))
    printf '%d' $((diff / 1000000))
}

# Run a command and store its duration (ms) in a variable name
zf::time_block() {
    local out_var="$1"
    shift
    [[ -n "$out_var" ]] || {
        zf::warn "time_block: missing output var"
        return 2
    }
    local _start _end _ms
    _start="$(_zf_now_ns)"
    "$@"
    local rc=$?
    _end="$(_zf_now_ns)"
    _ms="$(_zf_diff_ms "$_start" "$_end")"
    printf -v "$out_var" '%s' "$_ms"
    return $rc
}

# Segment emission support
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
        zf::log "segment-lib missing; skipped segment '$label'"
    fi
}

# Timed command execution with optional segment emission
zf::with_timing() {
    local label="$1"
    shift
    [[ -n "$label" ]] || {
        zf::warn "with_timing: missing label"
        return 2
    }
    local _start _end _ms rc
    _start="$(_zf_now_ns)"
    "$@"
    rc=$?
    _end="$(_zf_now_ns)"
    _ms="$(_zf_diff_ms "$_start" "$_end")"
    zf::log "with_timing '$label' took ${_ms}ms (rc=$rc)"
    if [[ "${ZF_WITH_TIMING_EMIT:-auto}" == "1" || ("${ZF_WITH_TIMING_EMIT:-auto}" == "auto" && "$(zf::have_segment_lib; echo $?)" = "0") ]]; then
        zf::emit_segment "$label" "$_ms"
    fi
    return $rc
}

# Function tracing (debug only)
zf::trace_fn() {
    [[ "${ZSH_DEBUG:-0}" == "1" ]] || return 0
    local fn="$1"
    [[ -n "$fn" ]] || {
        zf::warn "trace_fn: missing function name"
        return 2
    }
    typeset -f "$fn" >/dev/null 2>&1 || {
        zf::warn "trace_fn: function '$fn' not found"
        return 1
    }
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

_core_debug "zf:: namespace functions integrated"

# ==============================================================================
# SECTION 7: PRE-PLUGIN CONSOLIDATED FUNCTIONS
# ==============================================================================

# Path safety functions (consolidated from 00-path-safety.zsh)
zf::path_safe_command() {
    local cmd="$1"; shift
    [[ -n "$cmd" ]] || {
        zf::warn "path_safe_command: missing command name"
        return 1
    }

    # Try command as-is first (uses PATH)
    if command -v "$cmd" >/dev/null 2>&1; then
        "$cmd" "$@"
        return $?
    fi

    # Try common system locations as fallback
    local -a locations=(
        "/usr/bin/$cmd"
        "/bin/$cmd"
        "/opt/homebrew/bin/$cmd"
        "/usr/local/bin/$cmd"
    )

    for location in "${locations[@]}"; do
        if [[ -x "$location" ]]; then
            "$location" "$@"
            return $?
        fi
    done

    zf::warn "Command '$cmd' not found in PATH or standard locations"
    return 1
}

# Enhanced safe command wrappers
zf::safe_date() { zf::path_safe_command date "$@"; }
zf::safe_mkdir() { zf::path_safe_command mkdir "$@"; }
zf::safe_dirname() { zf::path_safe_command dirname "$@"; }
zf::safe_basename() { zf::path_safe_command basename "$@"; }
zf::safe_readlink() { zf::path_safe_command readlink "$@"; }

# SSH agent management (consolidated from 30-ssh-agent.zsh)
zf::ssh_agent_valid() {
    [[ -S ${SSH_AUTH_SOCK:-} ]] || return 1

    # Check if validation is disabled
    if [[ "${ZSH_SSH_AGENT_VALIDATE:-1}" == "0" ]]; then
        return 0
    fi

    # ssh-add -l: 0 => keys listed, 1 => no identities, both acceptable
    ssh-add -l >/dev/null 2>&1
    case $? in
        0 | 1) return 0 ;;
        *) return 1 ;;
    esac
}

zf::ssh_spawn_agent() {
    local agent_out
    agent_out="$(ssh-agent -s 2>/dev/null)" || return 1
    eval "$agent_out" 2>/dev/null || return 1

    # Basic sanity check
    [[ -n ${SSH_AUTH_SOCK:-} && -S ${SSH_AUTH_SOCK} && -n ${SSH_AGENT_PID:-} ]] || return 1
    return 0
}

zf::ssh_ensure_agent() {
    # Check if SSH agent functionality is disabled
    if [[ "${ZSH_SSH_AGENT_ENABLE:-1}" == "0" ]]; then
        zf::log "SSH agent disabled via ZSH_SSH_AGENT_ENABLE"
        return 0
    fi

    # Idempotent fast path
    if [[ -n ${_SSH_AGENT_VALIDATED:-} ]]; then
        zf::log "SSH agent already validated (${_SSH_AGENT_LAST_ACTION:-unknown})"
        return 0
    fi

    # Case 1: Existing valid agent → reuse
    if zf::ssh_agent_valid; then
        : ${_SSH_AGENT_SPAWN_COUNT:=0}
        _SSH_AGENT_LAST_ACTION="reuse"
        _SSH_AGENT_VALIDATED=1
        zf::log "Reusing existing SSH agent: $SSH_AUTH_SOCK"
        return 0
    fi

    # Case 2: Invalid or absent socket → attempt spawn
    if zf::ssh_spawn_agent; then
        # Validate new agent
        if zf::ssh_agent_valid; then
            : ${_SSH_AGENT_SPAWN_COUNT:=0}
            ((_SSH_AGENT_SPAWN_COUNT++))
            _SSH_AGENT_LAST_ACTION="spawn"
            _SSH_AGENT_VALIDATED=1
            zf::log "Spawned new SSH agent: pid=$SSH_AGENT_PID sock=$SSH_AUTH_SOCK"
            return 0
        else
            _SSH_AGENT_LAST_ACTION="failed"
            zf::warn "SSH agent spawn validation failed"
            # Cleanup to avoid misleading state
            unset SSH_AUTH_SOCK SSH_AGENT_PID
            return 1
        fi
    else
        _SSH_AGENT_LAST_ACTION="failed"
        zf::warn "SSH agent spawn attempt failed"
        return 1
    fi
}

# Performance measurement (consolidated from 40-performance-and-controls.zsh)
zf::perf_checkpoint() {
    local checkpoint_name="$1"
    local current_time_ms

    [[ -n "$checkpoint_name" ]] || {
        zf::warn "perf_checkpoint: missing checkpoint name"
        return 1
    }

    # Get current time in milliseconds
    if ((_zf_have_date_nano == 1)); then
        current_time_ms=$(date +%s%3N 2>/dev/null || echo "$(date +%s)000")
    else
        current_time_ms="$(date +%s 2>/dev/null || echo 0)000"
    fi

    # Calculate elapsed time from last checkpoint
    local elapsed=0
    if [[ -n "${ZSH_PERF_LAST_CHECKPOINT:-}" && "$current_time_ms" =~ ^[0-9]+$ && "$ZSH_PERF_LAST_CHECKPOINT" =~ ^[0-9]+$ ]]; then
        elapsed=$((current_time_ms - ZSH_PERF_LAST_CHECKPOINT))
    fi

    # Log to performance segment log if available
    if [[ -n "${PERF_SEGMENT_LOG:-}" ]]; then
        zf::safe_mkdir -p "$(dirname "$PERF_SEGMENT_LOG")"
        echo "CHECKPOINT ${checkpoint_name} ${elapsed}" >> "$PERF_SEGMENT_LOG" 2>/dev/null || true
    fi

    zf::log "Performance checkpoint '$checkpoint_name': ${elapsed}ms elapsed"
    export ZSH_PERF_LAST_CHECKPOINT="$current_time_ms"
}

# Enhanced lazy loading registry (consolidated from 15-lazy-framework.zsh)
typeset -gA _ZF_LAZY_REGISTRY         # Command -> Loader function mapping
typeset -gA _ZF_LAZY_STATE            # Command -> State (registered|loading|loaded|failed)
typeset -gA _ZF_LAZY_ERRORS           # Command -> Error messages
typeset -gA _ZF_LAZY_LOAD_TIMES       # Command -> Load time in milliseconds

zf::lazy_register() {
    local force=0 cmd loader

    # Parse command-line flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--force) force=1; shift ;;
            --) shift; break ;;
            -*) zf::warn "Unknown flag '$1' ignored in lazy_register"; shift ;;
            *) break ;;
        esac
    done

    cmd="$1" loader="$2"
    if [[ -z "$cmd" ]] || [[ -z "$loader" ]]; then
        zf::warn "Usage: zf::lazy_register [-f|--force] <command> <loader_function>"
        return 1
    fi

    # Check if command already exists (skip if not forcing)
    if command -v "$cmd" >/dev/null 2>&1 && [[ $force -eq 0 ]]; then
        zf::log "Skipping '$cmd' (already available; use --force to override)"
        return 0
    fi

    # Check if already registered (idempotent unless forcing)
    if [[ -n "${_ZF_LAZY_REGISTRY[$cmd]:-}" ]] && [[ $force -eq 0 ]]; then
        zf::log "Command '$cmd' already registered"
        return 2
    fi

    # Verify loader function exists
    if ! declare -f "$loader" >/dev/null 2>&1; then
        zf::warn "Loader function '$loader' not found for '$cmd'"
        return 3
    fi

    # If forcing, remove existing function definition
    if [[ $force -eq 1 ]] && declare -f "$cmd" >/dev/null 2>&1; then
        unfunction "$cmd" 2>/dev/null || true
        zf::log "Force override applied to '$cmd' (existing function removed)"
    fi

    # Register in lazy system
    _ZF_LAZY_REGISTRY[$cmd]="$loader"
    _ZF_LAZY_STATE[$cmd]="registered"

    # Generate lazy stub function
    eval "${cmd}() { zf::lazy_dispatch '${cmd}' \"\$@\"; }"

    zf::log "Lazy registered '$cmd' -> '$loader'"
    return 0
}

zf::lazy_dispatch() {
    local cmd="$1"; shift || true

    zf::log "Dispatching lazy command: $cmd"

    # Ensure command is registered
    if [[ -z "${_ZF_LAZY_REGISTRY[$cmd]:-}" ]]; then
        zf::warn "No loader registered for '$cmd'"
        _ZF_LAZY_ERRORS[$cmd]="no loader"
        return 3
    fi

    local state="${_ZF_LAZY_STATE[$cmd]:-registered}"
    local loader="${_ZF_LAZY_REGISTRY[$cmd]}"

    case "$state" in
        loaded)
            # Command already loaded, call directly if not a stub
            if declare -f "$cmd" >/dev/null 2>&1; then
                "$cmd" "$@"
                return $?
            fi
            ;;
        loading)
            zf::warn "Recursion detected while loading '$cmd'"
            _ZF_LAZY_STATE[$cmd]="failed"
            _ZF_LAZY_ERRORS[$cmd]="recursion"
            return 5
            ;;
        failed)
            zf::warn "Previous load attempt failed for '$cmd'"
            return 4
            ;;
    esac

    # Mark as loading to prevent recursion
    _ZF_LAZY_STATE[$cmd]="loading"

    # Execute loader function with timing
    local ms
    if zf::time_block ms "$loader"; then
        _ZF_LAZY_STATE[$cmd]="loaded"
        _ZF_LAZY_LOAD_TIMES[$cmd]="$ms"
        zf::log "Lazy loaded '$cmd' via '$loader' (${ms}ms)"

        # Call the now-loaded command
        "$cmd" "$@"
        return $?
    else
        _ZF_LAZY_STATE[$cmd]="failed"
        _ZF_LAZY_ERRORS[$cmd]="loader failed"
        zf::warn "Lazy loader '$loader' failed for '$cmd'"
        return 1
    fi
}

# Environment and debug utilities (consolidated from 05-environment-setup.zsh)
zf::env_check() {
    local var_name="$1"
    local expected_value="${2:-}"

    local actual_value="${(P)var_name:-}"
    if [[ -n "$expected_value" ]]; then
        [[ "$actual_value" == "$expected_value" ]]
    else
        [[ -n "$actual_value" ]]
    fi
}

zf::env_default() {
    local var_name="$1" default_value="$2"
    if [[ -z "${(P)var_name:-}" ]]; then
        export "$var_name"="$default_value"
        zf::log "Set environment default: $var_name=$default_value"
    fi
}

zf::info() {
    print -u2 "[zf][info] $*"
}

zf::error() {
    print -u2 "[zf][error] $*"
}

# macOS integration functions (consolidated from 25-macos-integration.zsh)
zf::macos_detect() {
    [[ "$(uname -s)" == "Darwin" ]]
}

zf::macos_version() {
    if ! zf::macos_detect; then
        return 1
    fi

    if command -v sw_vers >/dev/null 2>&1; then
        sw_vers -productVersion 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

zf::macos_defaults_load() {
    if ! zf::macos_detect; then
        zf::warn "macos_defaults_load: not running on macOS"
        return 1
    fi

    zf::log "Loading macOS defaults (deferred)"

    # Enable key repeat for all applications
    defaults write -g ApplePressAndHoldEnabled -bool false 2>/dev/null || true

    # Set a faster key repeat rate
    defaults write -g KeyRepeat -int 2 2>/dev/null || true
    defaults write -g InitialKeyRepeat -int 15 2>/dev/null || true

    # Show hidden files in Finder
    defaults write com.apple.finder AppleShowAllFiles -bool true 2>/dev/null || true

    # Show file extensions in Finder
    defaults write -g AppleShowAllExtensions -bool true 2>/dev/null || true

    # Disable DS_Store files on network volumes
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true 2>/dev/null || true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true 2>/dev/null || true

    zf::log "macOS defaults applied"
}

# Development environment detection and integration (consolidated from 30-development-integrations.zsh)
zf::dev_detect_env() {
    local -A dev_indicators=(
        [".git"]="git"
        [".gitignore"]="git"
        ["package.json"]="node"
        ["Cargo.toml"]="rust"
        ["go.mod"]="go"
        ["requirements.txt"]="python"
        ["Pipfile"]="python"
        ["pyproject.toml"]="python"
        ["Gemfile"]="ruby"
        ["composer.json"]="php"
        ["pom.xml"]="java"
        ["build.gradle"]="java"
        ["Dockerfile"]="docker"
        ["docker-compose.yml"]="docker"
        [".env"]="dotenv"
    )

    local detected_envs=()
    local current_dir="$PWD"

    # Check current and parent directories
    while [[ "$current_dir" != "/" ]]; do
        for indicator in "${(@k)dev_indicators}"; do
            if [[ -e "$current_dir/$indicator" ]]; then
                local env_type="${dev_indicators[$indicator]}"
                if [[ ! " ${detected_envs[*]} " =~ " $env_type " ]]; then
                    detected_envs+=("$env_type")
                fi
            fi
        done
        current_dir="${current_dir%/*}"
        [[ "$current_dir" == "" ]] && break
    done

    if [[ ${#detected_envs[@]} -gt 0 ]]; then
        echo "${(j:,:)detected_envs}"
    fi
}

zf::dev_load_direnv() {
    if ! command -v direnv >/dev/null 2>&1; then
        zf::warn "direnv not found"
        return 1
    fi

    zf::log "Loading direnv integration"
    eval "$(direnv hook zsh)"
    export DIRENV_LOG_FORMAT=""  # Suppress direnv log output by default
}

# Additional performance measurement functions (consolidated from 40-performance-and-controls.zsh)
zf::perf_measure_startup() {
    local iterations="${1:-5}"
    local total_time=0
    local i

    echo "Measuring ZSH startup time (${iterations} iterations)..."

    for i in $(seq 1 $iterations); do
        local start_time end_time elapsed
        start_time="$(_zf_now_ns)"

        # Use timeout to prevent hanging
        timeout 10s zsh -i -c exit >/dev/null 2>&1
        local exit_code=$?

        if [[ $exit_code -eq 0 ]]; then
            end_time="$(_zf_now_ns)"
            elapsed="$(_zf_diff_ms "$start_time" "$end_time")"
            total_time=$((total_time + elapsed))
            echo "  Iteration $i: ${elapsed}ms"
        else
            echo "  Iteration $i: FAILED (timeout or error)"
        fi
    done

    if [[ $total_time -gt 0 ]]; then
        local average=$((total_time / iterations))
        echo "Average startup time: ${average}ms"
        return 0
    fi
    return 1
}

zf::perf_feature_toggle() {
    local feature="$1"
    local state="${2:-toggle}"

    case "$feature" in
        autosuggest)
            if [[ "$state" == "on" ]] || ([[ "$state" == "toggle" ]] && [[ "${ZSH_AUTOSUGGEST_DISABLE:-0}" == "1" ]]); then
                unset ZSH_AUTOSUGGEST_DISABLE
                echo "Autosuggestions enabled"
            else
                export ZSH_AUTOSUGGEST_DISABLE=1
                echo "Autosuggestions disabled"
            fi
            ;;
        debug)
            if [[ "$state" == "on" ]] || ([[ "$state" == "toggle" ]] && [[ -z "${ZSH_DEBUG:-}" ]]); then
                export ZSH_DEBUG=1
                echo "Debug mode enabled"
            else
                unset ZSH_DEBUG
                echo "Debug mode disabled"
            fi
            ;;
        perf-trace)
            if [[ "$state" == "on" ]] || ([[ "$state" == "toggle" ]] && [[ "${PERF_SEGMENT_TRACE:-0}" == "0" ]]); then
                export PERF_SEGMENT_TRACE=1
                echo "Performance tracing enabled"
            else
                export PERF_SEGMENT_TRACE=0
                echo "Performance tracing disabled"
            fi
            ;;
        *)
            zf::warn "Unknown feature: $feature (available: autosuggest, debug, perf-trace)"
            return 1
            ;;
    esac
}

_core_debug "Pre-plugin consolidated functions integrated into zf:: namespace"

# ==============================================================================
# MODULE COMPLETION
# ==============================================================================

export CORE_INFRASTRUCTURE_VERSION="2.0.1"
# Safe date formatting with fallbacks
if command -v date >/dev/null 2>&1; then
    export CORE_INFRASTRUCTURE_LOADED_AT="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'unknown')"
else
    export CORE_INFRASTRUCTURE_LOADED_AT="unknown"
fi

_core_debug "Core infrastructure ready"

# Clean up helper function
unset -f _core_debug

# ==============================================================================
# END OF CORE INFRASTRUCTURE MODULE
# ==============================================================================
