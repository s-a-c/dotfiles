#!/usr/bin/env zsh
# async-tasks.zsh
# Compliant with [${HOME}/dotfiles/dot-config/ai/guidelines.md](${HOME}/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Declarative async task registration layer (Phase A shadow mode) for the ZSH
#   redesign. Complements async-dispatcher.zsh by:
#     - Loading / validating the manifest (if dispatcher did not already)
#     - Registering baseline shadow tasks (theme extras, completion cache scan)
#     - Providing hooks to bootstrap shadow execution safely AFTER synchronous
#       prompt readiness instrumentation has been emitted.
#
# SCOPE (Phase A):
#   - Does NOT remove any synchronous behavior yet; tasks are no-op / harmless.
#   - Enables early variance observation and segment emission in shadow mode.
#   - Prepares structure for Phase B/C activation without large diff churn.
#
# LATER PHASE ADDITIONS (Not included here yet):
#   - Real command bodies for each deferral candidate
#   - zpty worker pooling
#   - Adaptive concurrency & overhead accounting
#   - Watchdog / timeout enforcement (logical placeholders only now)
#
# USAGE:
#   Source late in post-plugin sequence (after segment-lib & perf tools) but
#   before final prompt_ready marker or immediately after it (shadow tolerant).
#
#   Typical sequence inside redesign:
#     source tools/async-dispatcher.zsh        # if not auto-sourced elsewhere
#     source tools/async-tasks.zsh
#     async_tasks_phaseA_shadow_bootstrap      # registers + launches (shadow)
#
# ENV VARIABLES REFERENCED:
#   ASYNC_MODE=off|shadow|on  (Phase A expects 'shadow' to observe)
#   ASYNC_DEBUG_VERBOSE=1     (verbose logging)
#   ASYNC_TASK_THEME_EXTRAS=1 (optional per-task feature flag enabling)
#   ASYNC_TASK_COMPLETION_CACHE=1
#
# SAFETY / NO-OP GUARANTEES:
#   - If dispatcher not available or ASYNC_MODE=off: silent skip.
#   - If already registered tasks exist, duplicates are ignored (idempotent).
#
# ---------------------------------------------------------------------------

# Defensive: ensure zsh
if [[ -z ${ZSH_VERSION:-} ]]; then
    return 0
fi

# ---------------------------------------------------------------------------
# Resolve script & repo paths (best-effort, tolerant)
# ---------------------------------------------------------------------------
# %N gives current sourced file (zsh feature).
# PATH RESOLUTION RULE:
#   Do NOT rely on the brittle form ${0:A:h}; instead use zf::script_dir / resolve_script_dir
#   (defined in .zshenv) which is resilient to plugin manager compilation contexts.
__ASYNC_TASKS_SRC="${(%):-%N}"

# If the source cannot be confidently determined (generic name or empty), attempt resilient resolution.
if [[ "$__ASYNC_TASKS_SRC" == "async-tasks.zsh" || -z "$__ASYNC_TASKS_SRC" ]]; then
    if typeset -f zf::script_dir >/dev/null 2>&1; then
        __ASYNC_TASKS_DIR="$(zf::script_dir "${(%):-%N}")"
    elif typeset -f resolve_script_dir >/dev/null 2>&1; then
        __ASYNC_TASKS_DIR="$(resolve_script_dir "${(%):-%N}")"
    else
        # Last resort: assume conventional layout tools/ under current PWD
        __ASYNC_TASKS_DIR="${PWD%/}/tools"
    fi
    if [[ -r "${__ASYNC_TASKS_DIR}/async-tasks.zsh" ]]; then
        __ASYNC_TASKS_SRC="${__ASYNC_TASKS_DIR}/async-tasks.zsh"
    fi
else
    # Derive directory from resolved absolute path
    __ASYNC_TASKS_DIR="${__ASYNC_TASKS_SRC:A:h}"
fi

# Repo root inference (strip trailing tools path component)
__ASYNC_REPO_ROOT="${__ASYNC_TASKS_DIR%/dot-config/zsh/tools*}"

# ---------------------------------------------------------------------------
# Source dispatcher if not already present
# ---------------------------------------------------------------------------
if ! typeset -f async_dispatch_init >/dev/null 2>&1; then
    if [[ -r "${__ASYNC_TASKS_DIR}/async-dispatcher.zsh" ]]; then
        source "${__ASYNC_TASKS_DIR}/async-dispatcher.zsh"
    else
        print -- "[async-tasks][warn] async-dispatcher.zsh not found; async tasks file inert" >&2
        return 0
    fi
fi

# ---------------------------------------------------------------------------
# Internal utilities
# ---------------------------------------------------------------------------
_async_tasks_debug() {
    [[ -n ${ASYNC_DEBUG_VERBOSE:-} ]] || return 0
    print -- "[async-tasks][debug] $*" >&2
}

_async_tasks_info() {
    print -- "[async-tasks] $*" >&2
}

# ---------------------------------------------------------------------------
# Manifest Path Helper
# ---------------------------------------------------------------------------
async_tasks_manifest_path() {
    # Prefer repo docs location
    local p1="${__ASYNC_REPO_ROOT}/dot-config/zsh/docs/redesignv2/async/manifest.json"
    [[ -r "$p1" ]] && print -- "$p1" && return 0
    # Fallback: relative to current dir
    [[ -r "./docs/redesignv2/async/manifest.json" ]] && print -- "./docs/redesignv2/async/manifest.json" && return 0
    return 1
}

# ---------------------------------------------------------------------------
# Phase A shadow task registration
# NOTE: Commands intentionally minimal (no heavy work) – they exist only to
#       exercise dispatcher infrastructure and segment emission.
# ---------------------------------------------------------------------------
async_tasks_register_shadow_defaults() {
    [[ ${ASYNC_MODE:-off} == shadow ]] || {
        _async_tasks_debug "Skipping default shadow tasks (ASYNC_MODE=${ASYNC_MODE:-off})"
        return 0
    }

    # Avoid duplicate registration by checking one known ID
    if [[ -n ${__ASYNC_TASK_CMD[theme_extras]:-} ]]; then
        _async_tasks_debug "Shadow default tasks already registered"
        return 0
    fi

    # Feature flags: when unset we still register (shadow safe) unless explicitly disabled later phases.
    : ${ASYNC_TASK_THEME_EXTRAS:=1}
    : ${ASYNC_TASK_COMPLETION_CACHE:=1}

    # theme_extras (placeholder – real workload added in active phases)
    async_register_task \
        theme_extras \
        cosmetic \
        800 \
        async_task_theme_extras \
        ASYNC_TASK_THEME_EXTRAS \
        ': ${ASYNC_TEST_FAKE_LATENCY_MS:=0}; ((ASYNC_TEST_FAKE_LATENCY_MS>0)) && sleep "$(awk -v ms=$ASYNC_TEST_FAKE_LATENCY_MS '\''BEGIN{printf "%.3f", ms/1000}'\'')" || true'

    # completion_cache_scan (placeholder)
    async_register_task \
        completion_cache_scan \
        cosmetic \
        1500 \
        async_task_completion_cache_scan \
        ASYNC_TASK_COMPLETION_CACHE \
        ': ${ASYNC_TEST_FAKE_LATENCY_MS:=0}; ((ASYNC_TEST_FAKE_LATENCY_MS>0)) && sleep "$(awk -v ms=$ASYNC_TEST_FAKE_LATENCY_MS '\''BEGIN{printf "%.3f", ms/1000}'\'')" || true'

    _async_tasks_info "Registered Phase A shadow tasks: theme_extras, completion_cache_scan"
}

# ---------------------------------------------------------------------------
# Hook integration
# We attach a lightweight precmd hook that:
#   1. Collects finished tasks.
#   2. Emits flush segment (handled by dispatcher).
#   3. Automatically detaches when all tasks are terminal.
# ---------------------------------------------------------------------------
_async_tasks_precmd_flush() {
    [[ ${ASYNC_MODE:-off} == shadow || ${ASYNC_MODE:-off} == on ]] || return 0
    typeset -f async_flush_cycle >/dev/null 2>&1 || return 0
    async_flush_cycle

    # Auto-detach logic
    local all_done=1 id st
    for id st in ${(kv)__ASYNC_TASK_STATUS}; do
        case "$st" in
            pending|running) all_done=0; break ;;
        esac
    done
    if (( all_done )); then
        # Remove self from precmd_functions
        local new=()
        local f
        for f in ${precmd_functions[@]}; do
            [[ $f == "_async_tasks_precmd_flush" ]] && continue
            new+=("$f")
        done
        precmd_functions=("${new[@]}")
        _async_tasks_debug "All async shadow tasks terminal; removed precmd flush hook"
        async_summary 2>/dev/null || true
    fi
}

# ---------------------------------------------------------------------------
# Public bootstrap (Phase A)
# ---------------------------------------------------------------------------
async_tasks_phaseA_shadow_bootstrap() {
    # Initialize dispatcher (safe to call multiple times)
    async_dispatch_init

    [[ ${ASYNC_MODE:-off} == shadow ]] || {
        _async_tasks_debug "Bootstrap skipped (ASYNC_MODE=${ASYNC_MODE:-off} not shadow)"
        return 0
    }

    async_tasks_register_shadow_defaults

    # Launch tasks only after prompt_ready instrumentation scheduled / executed.
    # Caller decides exact ordering; safe to launch multiple times (idempotent).
    async_launch_shadow_tasks

    # Install precmd flush hook if not present
    # Ensure precmd_functions is a global array (prevent 'parameter not set' errors in minimal envs)
    if [[ -z ${precmd_functions+x} ]]; then
        typeset -ga precmd_functions
    elif [[ "$(typeset -p precmd_functions 2>/dev/null)" != *"-a precmd_functions"* ]]; then
        # If it exists but not as an array, re-declare as array (edge case)
        unset precmd_functions
        typeset -ga precmd_functions
    fi
    local present=0 f
    for f in ${precmd_functions[@]:-}; do
        [[ $f == "_async_tasks_precmd_flush" ]] && present=1 && break
    done
    (( present )) || precmd_functions+=(_async_tasks_precmd_flush)
    _async_tasks_debug "Async shadow bootstrap complete (precmd hook active)"
}

# ---------------------------------------------------------------------------
# Optional automatic bootstrap:
#   If ASYNC_TASKS_AUTORUN=1 and ASYNC_MODE=shadow, register immediately.
#   This allows sourcing file alone to start observation in controlled CI env.
# ---------------------------------------------------------------------------
if [[ ${ASYNC_TASKS_AUTORUN:-0} == 1 && ${ASYNC_MODE:-off} == shadow ]]; then
    async_tasks_phaseA_shadow_bootstrap
fi

# End of file
