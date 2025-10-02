#!/usr/bin/env zsh
# 65-vcs-gitstatus-instrument.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Instrument initialization of the gitstatus / VCS prompt backend so its cost
#   becomes a discrete timing segment (gitstatus_init) within post‑plugin phase.
#   Git status daemons (e.g. romkatv/gitstatus used by Powerlevel10k) can add
#   measurable cold latency. Capturing this early enables targeted optimization
#   and regression gating (perf-diff tooling).
#
# FEATURES:
#   - Detects and sources a gitstatus plugin script (common locations, overrideable).
#   - Measures sourcing + (optionally) initial daemon readiness (configurable wait).
#   - Emits unified SEGMENT line (segment-lib) AND legacy POST_PLUGIN_SEGMENT line.
#   - Idempotent: skips if already initialized (sentinel _GITSTATUS_INIT_DONE or env).
#   - Low overhead fallback timing if segment-lib.zsh not yet loaded.
#
# CONFIG FLAGS:
#   ZSH_GITSTATUS_INSTRUMENT=0        Disable this module (default: enabled).
#   ZSH_GITSTATUS_PROBE_PATH=<file>   Explicit path to gitstatus plugin to source.
#   ZSH_GITSTATUS_WAIT_MS=<int>       Extra wait (ms) after sourcing to observe daemon
#                                     readiness (default 120; set 0 to skip).
#   ZSH_GITSTATUS_MAX_POLLS=<int>     Max polling iterations while waiting (default auto).
#   ZSH_GITSTATUS_VERBOSE=1           Extra debug logging if set.
#
# SEGMENT LABEL:
#   gitstatus_init (phase=post_plugin)
#
# EMITTED LINES (when PERF_SEGMENT_LOG set):
#   SEGMENT name=gitstatus_init ms=<delta> phase=post_plugin sample=<context>
#   POST_PLUGIN_SEGMENT gitstatus_init <delta>
#
# DETECTION / READINESS:
#   - Success criteria: environment variable GITSTATUS_DAEMON_PID defined OR functions
#     gitstatus_prompt or prompt_gitstatus_user defined (heuristics).
#   - Optional wait loop polls every ~10ms up to budget (ZSH_GITSTATUS_WAIT_MS).
#
# FALLBACK / SAFETY:
#   - If no candidate file found, module exits quietly.
#   - If sourcing fails, segment still ends (delta measures failure path).
#
# FUTURE EXTENSIONS:
#   - Add gitstatus daemon spawn vs first query separation.
#   - Track daemon cold start vs warm reuse (cache PID).
#
# ORDER:
#   Placed after 60-p10k-instrument (theme) so we can isolate residual git status
#   overhead that the theme may trigger, OR earlier if you want raw daemon cost.
#
# -----------------------------------------------------------------------------

# Prevent double load
[[ -n ${_LOADED_65_VCS_GITSTATUS_INSTRUMENT:-} ]] && return
_LOADED_65_VCS_GITSTATUS_INSTRUMENT=1

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

if [[ "${ZSH_GITSTATUS_INSTRUMENT:-1}" == "0" ]]; then
    zf::debug "# [gitstatus][instrument] disabled via ZSH_GITSTATUS_INSTRUMENT=0"
    return 0
fi

# If already initialized (theme or earlier module), skip
if [[ -n ${_GITSTATUS_INIT_DONE:-} || -n ${GITSTATUS_DAEMON_PID:-} ]]; then
    zf::debug "# [gitstatus][instrument] already initialized (sentinel present)"
    return 0
fi

# Try to source segment-lib for uniform timing
__gs_seg_lib="${ZDOTDIR:-$HOME/.config/zsh}/tools/segment-lib.zsh"
if [[ -r "${__gs_seg_lib}" ]]; then
    # shellcheck disable=SC1090
    source "${__gs_seg_lib}" 2>/dev/null || true
fi
unset __gs_seg_lib

# Provide fallback clock if segment-lib absent
if ! typeset -f _zsh_perf_segment_start >/dev/null 2>&1; then
    __gs_now_ms() {
        zmodload zsh/datetime 2>/dev/null || true
        local rt=$EPOCHREALTIME
        [[ -z $rt ]] && echo "" && return
        printf '%s' "$rt" | awk -F. '{ms=($1*1000); if(NF>1){ms+=substr($2"000",1,3)+0} printf "%d", ms}'
    }
fi

# Candidate path resolution
__gs_candidates=()

if [[ -n ${ZSH_GITSTATUS_PROBE_PATH:-} ]]; then
    __gs_candidates+=("${ZSH_GITSTATUS_PROBE_PATH}")
else
    __base="${ZDOTDIR:-$HOME/.config/zsh}"
    __home="${HOME}"
    __gs_candidates+=(
        "${__base}/.zsh/gitstatus/gitstatus.plugin.zsh"
        "${__base}/.zsh/plugins/gitstatus/gitstatus.plugin.zsh"
        "${__base}/plugins/gitstatus/gitstatus.plugin.zsh"
        "${__base}/gitstatus/gitstatus.plugin.zsh"
        "${__home}/.cache/gitstatus/gitstatus.plugin.zsh"
        "${__home}/.oh-my-zsh/custom/plugins/gitstatus/gitstatus.plugin.zsh"
        "${__home}/.oh-my-zsh/custom/themes/powerlevel10k/gitstatus/gitstatus.plugin.zsh"
    )
fi

__gs_plugin=""
for f in "${__gs_candidates[@]}"; do
    if [[ -r "$f" ]]; then
        __gs_plugin="$f"
        break
    fi
done
unset f __gs_candidates

if [[ -z ${__gs_plugin} ]]; then
    zf::debug "# [gitstatus][instrument] plugin file not found (skipping)"
    return 0
fi

zf::debug "# [gitstatus][instrument] using plugin=${__gs_plugin}"

# Timing start
if typeset -f _zsh_perf_segment_start >/dev/null 2>&1; then
    _zsh_perf_segment_start gitstatus_init post_plugin
else
    __gs_start_ms=$(__gs_now_ms)
fi

# Source plugin
# shellcheck disable=SC1090
if ! source "${__gs_plugin}" 2>/dev/null; then
    zf::debug "# [gitstatus][instrument] ERROR: failed sourcing ${__gs_plugin}"
fi

# Optional readiness wait
__wait_ms=${ZSH_GITSTATUS_WAIT_MS:-120}
if [[ "$__wait_ms" =~ ^[0-9]+$ ]] && ((__wait_ms > 0)); then
    __poll_interval_ms=10
    __max_polls=$(((__wait_ms + __poll_interval_ms - 1) / __poll_interval_ms))
    if [[ -n ${ZSH_GITSTATUS_MAX_POLLS:-} && ${ZSH_GITSTATUS_MAX_POLLS} =~ ^[0-9]+$ ]]; then
        __max_polls=${ZSH_GITSTATUS_MAX_POLLS}
    fi
    __poll_i=0
    while ((__poll_i < __max_polls)); do
        if [[ -n ${GITSTATUS_DAEMON_PID:-} ]] || typeset -f gitstatus_prompt >/dev/null 2>&1 || typeset -f prompt_gitstatus_user >/dev/null 2>&1; then
            break
        fi
        sleep 0.01 # ~10ms
        ((__poll_i++))
    done
    zf::debug "# [gitstatus][instrument] readiness wait loops=${__poll_i}/${__max_polls} pid=${GITSTATUS_DAEMON_PID:-none}"
fi

_GITSTATUS_INIT_DONE=1
export _GITSTATUS_INIT_DONE

# End timing
if typeset -f _zsh_perf_segment_end >/dev/null 2>&1; then
    _zsh_perf_segment_end gitstatus_init post_plugin
else
    __gs_end_ms=$(__gs_now_ms)
    if [[ -n ${__gs_start_ms:-} && -n ${__gs_end_ms:-} ]]; then
        ((__gs_delta = __gs_end_ms - __gs_start_ms))
        local sample="${PERF_SAMPLE_CONTEXT:-unknown}"
        if [[ -n ${PERF_SEGMENT_LOG:-} && -w ${PERF_SEGMENT_LOG:-/dev/null} ]]; then
            print "SEGMENT name=gitstatus_init ms=${__gs_delta} phase=post_plugin sample=${sample}" >>"${PERF_SEGMENT_LOG}" 2>/dev/null || true
            print "POST_PLUGIN_SEGMENT gitstatus_init ${__gs_delta}" >>"${PERF_SEGMENT_LOG}" 2>/dev/null || true
        fi
        zf::debug "# [gitstatus][instrument][fallback] delta=${__gs_delta}ms"
        unset sample
    fi
fi

if [[ "${ZSH_GITSTATUS_VERBOSE:-0}" == "1" ]]; then
    zf::debug "# [gitstatus][instrument] daemon_pid=${GITSTATUS_DAEMON_PID:-unset}"
fi

# Cleanup temp vars
unset __gs_plugin __gs_start_ms __gs_end_ms __gs_delta __wait_ms __poll_interval_ms __max_polls __poll_i

# Remove fallback helpers if created
if typeset -f __gs_now_ms >/dev/null 2>&1; then
    unset -f __gs_now_ms 2>/dev/null || true
fi

# End 65-vcs-gitstatus-instrument.zsh
