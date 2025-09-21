# ==============================================================================
# CRITICAL STARTUP STANZA - MUST BE FIRST
# Sets essential environment variables before any other shell initialization
# ==============================================================================
# RULE (Path Resolution):
#   Avoid using the brittle form `${0:A:h}` directly inside any redesign or plugin
#   module (especially when code may be compiled / cached by a plugin manager).
#   Instead, use the helper `zf::script_dir` (defined later in this file) or,
#   for very early bootstrap contexts, `resolve_script_dir` with an optional
#   path argument. These helpers are resilient to symlinks and compilation
#   contexts and defer to `${(%):-%N}` rather than `$0` where appropriate.
#   Migration Plan:
#     - New code MUST use `zf::script_dir` or `resolve_script_dir`.
#     - Existing `${0:A:h}` usages should be incrementally refactored.
# ==============================================================================

# Minimal debug logger used during early startup
zsh_debug_echo() {
    # Always echo to stdout for visibility in early non-interactive contexts,
    # and optionally log to the debug file when ZSH_DEBUG=1.
    echo "$@"
    if [[ "${ZSH_DEBUG:-0}" == "1" && -n "${ZSH_DEBUG_LOG:-}" ]]; then
        print -r -- "$@" >> "$ZSH_DEBUG_LOG"
    fi
}

# EMERGENCY IFS PROTECTION - Prevent corruption during startup
if [[ "$IFS" != $' \t\n' ]]; then
    unset IFS
    IFS=$' \t\n'
    export IFS
fi

# Emergency PATH fix if corrupted with literal $sep
if [[ "$PATH" == *'$sep'* ]]; then
    PATH="${PATH//\$sep/:}"
    export PATH
fi

# Minimal safe PATH augmentation (append-preserving; do not clobber user/front-loaded entries)
# If PATH is empty (very constrained subshell), seed it; otherwise append any missing core dirs.
if [[ -z "${PATH:-}" ]]; then
    PATH="/opt/homebrew/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"
else
    for __core_dir in /opt/homebrew/bin /run/current-system/sw/bin /usr/local/bin /usr/bin /bin /usr/local/sbin /usr/sbin /sbin; do
        [ -d "$__core_dir" ] || continue
        case ":$PATH:" in
            *:"$__core_dir":*) ;;        # already present (preserve first occurrence)
            *) PATH="${PATH}:$__core_dir" ;;
        esac
    done
    unset __core_dir
fi
export PATH

# XDG Base Directory Specification (set early so other code can rely on them)
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"
export XDG_BIN_HOME="${XDG_BIN_HOME:-${HOME}/.local/bin}"
mkdir -p "${XDG_CONFIG_HOME}" "${XDG_CACHE_HOME}" "${XDG_DATA_HOME}" "${XDG_STATE_HOME}" "${XDG_BIN_HOME}" 2>/dev/null || true

export ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"

RIPGREP_CONFIG_PATH="${RIPGREP_CONFIG_PATH:-${XDG_CONFIG_HOME}/ripgrep/ripgreprc}"

# Allow a localized override file to run early. This file may set ZDOTDIR
# or other site/user-specific values. It's safe to source here because it is
# expected to be conservative and provide defaults only.
_local_zshenv_local="${XDG_CONFIG_HOME:-${HOME}/.config}/zsh/.zshenv.local"
if [[ -f "${_local_zshenv_local}" ]]; then
    # shellcheck disable=SC1090
    source "${_local_zshenv_local}"
fi
unset _local_zshenv_local

# Prefer XDG user bin early in PATH if present
[[ -d ${XDG_BIN_HOME} ]] && PATH="${XDG_BIN_HOME}:${PATH}"
export PATH

# Set ZDOTDIR to an XDG-friendly localized default but do not overwrite

# ------------------------------------------------------------------------------
# Robustly canonicalize ZDOTDIR (resolve symlinks) WITHOUT breaking on systems
# that lack `realpath`. We only canonicalize if ZDOTDIR is set and points to a
# directory so we don't accidentally touch unrelated values.
# ------------------------------------------------------------------------------
if [[ -n "${ZDOTDIR:-}" && -d "${ZDOTDIR}" ]]; then
    if command -v realpath >/dev/null 2>&1; then
        # Use realpath when available (portable and resolves symlinks)
        ZDOTDIR="$(realpath "${ZDOTDIR}")"
    else
        # Fallback: attempt to cd into dir and print the physical path (pwd -P)
        # If that fails for any reason, leave ZDOTDIR as-is.
        _zd_prev_pwd=""
        _zd_prev_pwd="$PWD" 2>/dev/null || true
        if cd "${ZDOTDIR}" 2>/dev/null; then
            ZDOTDIR="$(pwd -P 2>/dev/null || pwd)"
            # return to previous working directory
            cd "$_zd_prev_pwd" 2>/dev/null || true
        fi
        unset _zd_prev_pwd
    fi
fi

# Create common cache/log dirs (do not fail startup if mkdir fails)
# Recreate ensured dirs now anchored to canonical ZDOTDIR
export ZSH_CACHE_DIR="${XDG_CACHE_HOME}/zsh"
export ZSH_LOG_DIR="${ZDOTDIR}/logs"
mkdir -p "$ZSH_CACHE_DIR" "$ZSH_LOG_DIR" 2>/dev/null || true

# Provide a short session id for debug/log filenames
export ZSH_SESSION_ID="${ZSH_SESSION_ID:-$$-$(date +%s 2>/dev/null || echo 'unknown')}"
export ZSH_DEBUG_LOG="${ZSH_LOG_DIR}/${ZSH_SESSION_ID}-zsh-debug.log"

# Basic optional debug flag
export ZSH_DEBUG="${ZSH_DEBUG:-0}"

# Performance monitoring flag - set early to prevent module initialization errors
export _PERFORMANCE_MONITORING_LOADED="${_PERFORMANCE_MONITORING_LOADED:-1}"

# Set BREW_PREFIX early for module compatibility
if [[ -z "${BREW_PREFIX:-}" ]]; then
    if [[ -d "/opt/homebrew" ]]; then
        export BREW_PREFIX="/opt/homebrew"
    elif [[ -d "/usr/local" ]]; then
        export BREW_PREFIX="/usr/local"
    fi
fi

# Set DESK_ENV to empty to prevent undefined variable errors
export DESK_ENV="${DESK_ENV:-}"

# Set QUICKSTART_KIT_REFRESH_IN_DAYS to prevent undefined variable errors
typeset -gi QUICKSTART_KIT_REFRESH_IN_DAYS=${QUICKSTART_KIT_REFRESH_IN_DAYS:-7}

# ==============================================================================
# REDESIGN FLAGS AND PATH BASELINE CAPTURE
# ==============================================================================
# Redesign toggles (pre-plugin ON, post-plugin OFF)
export ZSH_ENABLE_PREPLUGIN_REDESIGN=1
unset ZSH_ENABLE_POSTPLUGIN_REDESIGN
: ${ZSH_ENABLE_POSTPLUGIN_REDESIGN:=}   # Keep it empty/unset

# Composer home following XDG with safe fallback
typeset -gx COMPOSER_HOME="${COMPOSER_HOME:-${XDG_DATA_HOME:-${HOME}/.local/share}/composer}"

# Ensure directory exists with safe perms
[[ -d $COMPOSER_HOME ]] || mkdir -p "$COMPOSER_HOME"

# Add Composer vendor/bin to PATH without reducing baseline
if [[ -d "$COMPOSER_HOME/vendor/bin" ]]; then
  _path_append "$COMPOSER_HOME/vendor/bin"
fi

# After PATH is fully defined, capture a snapshot and set an early sentinel
typeset -gx ZQS_BASELINE_PATH_SNAPSHOT="$PATH"
typeset -gx ZQS_EARLY_PATH_BOOTSTRAPPED=1
# Keep a normalized array view for later merge/dedupe operations
typeset -ga ZQS_BASELINE_path
ZQS_BASELINE_path=("${(s.:.)PATH}")

# Safe defaults for prompt variables to prevent nounset errors
typeset -g RPS1="${RPS1-}"
typeset -g PROMPT="${PROMPT-}"
typeset -g RPROMPT="${RPROMPT-}"
typeset -g vi_mode_in_opts="${vi_mode_in_opts-0}"
typeset -g AWS_PROFILE_REGION="${AWS_PROFILE_REGION-}"
typeset -g AWS_PROFILE="${AWS_PROFILE-}"
typeset -g AWS_DEFAULT_PROFILE="${AWS_DEFAULT_PROFILE-}"
typeset -g AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID-}"

# ------------------------------------------------------------------------------
# PATH Management Functions
# ------------------------------------------------------------------------------
# These functions automatically dedupe by removing the target path before
# pre/appending it, as suggested by the user

## [_path.remove]
function _path_remove() {
    for ARG in "$@"; do
        while [[ ":${PATH}:" == *":${ARG}:"* ]]; do
            ## Delete path by parts so we can never accidentally remove sub paths
            [[ "${PATH}" == "${ARG}" ]] && PATH=""
            PATH=${PATH//":${ARG}:"/:}  ## delete any instances in the middle
            PATH=${PATH/#"${ARG}:"/}  ## delete any instance at the beginning
            PATH=${PATH/%":${ARG}"/}  ## delete any instance at the end
            export PATH
        done
    done
}

## [_path.append]
function _path_append() {
    for ARG in "$@"; do
        _path_remove "${ARG}"
        [[ -d "${ARG}" ]] && export PATH="${PATH:+"${PATH}:"}${ARG}"
    done
}

## [_path.prepend]
function _path_prepend() {
    for ARG in "$@"; do
        _path_remove "${ARG}"
        [[ -d "${ARG}" ]] && export PATH="${ARG}${PATH:+":${PATH}"}"
    done
}

zsh_debug_echo "[DEBUG] early .zshenv:" || true
zsh_debug_echo "    ZDOTDIR=${ZDOTDIR}" || true
zsh_debug_echo "    ZSH_CACHE_DIR=${ZSH_CACHE_DIR}" || true
zsh_debug_echo "    ZSH_LOG_DIR=${ZSH_LOG_DIR}" || true

# ------------------------------------------------------------------------------
# Utility: PATH de-duplication (preserve first occurrence)
# ------------------------------------------------------------------------------
function path_dedupe() {
    # Portable-ish PATH de-duplication (avoid zsh-only ${(j:...)} join & advanced array ops)
    # Flags:
    #   --verbose  : emit counts to stderr
    #   --dry-run  : print deduped PATH without exporting
    local verbose=0 dry=0 arg p _before=0 _after=0 _x
    for arg in "$@"; do
        case "$arg" in
            --verbose) verbose=1 ;;
            --dry-run) dry=1 ;;
        esac
    done
    local original="$PATH"
    # Build deduped list preserving first occurrence order
    local IFS=:
    local seen_list=""
    for p in $PATH; do
        [ -z "$p" ] && continue
        case ":$seen_list:" in
            *:"$p":*) continue ;;
            *) seen_list="${seen_list:+$seen_list:}$p" ;;
        esac
    done
    local deduped="$seen_list"
    if [ "$dry" -eq 1 ]; then
        printf '%s\n' "${deduped:-$original}"
        return 0
    fi
    if [ "$deduped" != "$original" ]; then
        PATH="$deduped"
        export PATH
    fi
    PATH_DEDUP_DONE=1
    if [ "$verbose" -eq 1 ]; then
        IFS=:; for _x in $original; do _before=$((_before+1)); done
        IFS=:; for _x in $deduped; do _after=$((_after+1)); done
        printf '[path_dedupe] entries(before)=%s entries(after)=%s\n' "$_before" "$_after" >&2
    fi
}

# Deduplicate initial PATH (idempotent)
path_dedupe >/dev/null 2>&1 || true

# ------------------------------------------------------------------------------
# Resilient Script Directory Resolution
# ------------------------------------------------------------------------------
# Public helper (core): resolve_script_dir [<path_or_script>]
#   - Resolves symlinks
#   - Uses zsh parameter expansion ${(%):-%N} when no argument given
#   - Returns canonical physical directory (pwd -P) or empty on failure
# Namespaced convenience (preferred in modules): zf::script_dir [<path_or_script>]
# ------------------------------------------------------------------------------
if ! typeset -f resolve_script_dir >/dev/null 2>&1; then
resolve_script_dir() {
    emulate -L zsh
    set -o no_unset
    local src="${1:-${(%):-%N}}"
    # If still empty (rare non-file contexts), fallback to PWD
    [[ -z "$src" ]] && { print -r -- "$PWD"; return 0; }
    # Resolve symlinks iteratively
    local link
    while [[ -h "$src" ]]; do
        link="$(readlink "$src" 2>/dev/null || true)"
        [[ -z "$link" ]] && break
        if [[ "$link" == /* ]]; then
            src="$link"
        else
            src="${src:h}/$link"
        fi
    done
    # Canonical directory
    builtin cd -q "${src:h}" 2>/dev/null || { print -r -- "${src:h}"; return 0; }
    pwd -P
}
fi

if ! typeset -f zf::script_dir >/dev/null 2>&1; then
zf::script_dir() {
    resolve_script_dir "${1:-}"
}
fi

export ZSH_SCRIPT_DIR_HELPERS=1
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Harness Watchdog
# Reworked: signal the parent interactive shell PID instead of exiting only the
# background subshell. Prevents hangs when perf-capture harness shells stall.
# Behavior:
#   - If PERF_HARNESS_TIMEOUT_SEC > 0, record HARNESS_PARENT_PID=$$ (if unset) and
#     launch a background watcher.
#   - After sleep(timeout) if still a harness context (PERF_PROMPT_HARNESS or
#     PERF_SEGMENT_LOG set) and parent PID alive, send TERM; after a short grace
#     (default 0.4s) send KILL if still running.
# Opt-out: set PERF_HARNESS_DISABLE_WATCHDOG=1
# ------------------------------------------------------------------------------
if [ "${PERF_HARNESS_TIMEOUT_SEC:-0}" -gt 0 ] && [ "${PERF_HARNESS_DISABLE_WATCHDOG:-0}" != "1" ]; then
    # Record parent PID for signaling (do not override if already set by caller)
    : "${HARNESS_PARENT_PID:=$$}"
    export HARNESS_PARENT_PID
    (
        timeout_sec="${PERF_HARNESS_TIMEOUT_SEC}"
        grace_ms="${PERF_HARNESS_GRACE_MS:-400}"
        sleep "${timeout_sec}"
        if [[ -n "${PERF_PROMPT_HARNESS:-}" || -n "${PERF_SEGMENT_LOG:-}" ]]; then
        if kill -0 "${HARNESS_PARENT_PID}" 2>/dev/null; then
            kill -TERM "${HARNESS_PARENT_PID}" 2>/dev/null || true
            # Convert grace to fractional seconds (numeric grace_ms -> ms to s.mmm; fallback 0.4s)
            case "$grace_ms" in
            ''|*[!0-9]*)
                sleep 0.4
                ;;
            *)
                _g="$grace_ms"
                sleep "$(printf '%d.%03d' $((_g/1000)) $((_g%1000)))"
                unset _g
                ;;
            esac
            kill -0 "${HARNESS_PARENT_PID}" 2>/dev/null && kill -KILL "${HARNESS_PARENT_PID}" 2>/dev/null || true
        fi
        fi
    ) &
fi
# ------------------------------------------------------------------------------
# Minimal perf harness mode (PERF_HARNESS_MINIMAL=1)
# Skips heavy plugin/theme initialization; loads only prompt-ready instrumentation
# and lightweight segment markers to allow perf-capture tooling to complete quickly
# in constrained CI sandboxes. Must appear before plugin manager / theme logic.
# ------------------------------------------------------------------------------
if [[ "${PERF_HARNESS_MINIMAL:-0}" == "1" ]]; then
    # Minimal perf harness path detected, but early return disabled to allow full interactive startup.
    # (Original minimal fast path intentionally bypassed.)
    ZSH_DEBUG=${ZSH_DEBUG:-0}
    export ZSH_PERF_PROMPT_MARKERS=1
    if [[ -f "${ZDOTDIR}/.zshrc.d.REDESIGN/95-prompt-ready.zsh" ]]; then
        source "${ZDOTDIR}/.zshrc.d.REDESIGN/95-prompt-ready.zsh"
    fi
    if [[ -f "${ZDOTDIR}/tools/segment-lib.zsh" ]]; then
        source "${ZDOTDIR}/tools/segment-lib.zsh"
    fi
    # return 0  # disabled
fi

# ------------------------------------------------------------------------------
# Helpers: command existence caching and safe wrappers
# ------------------------------------------------------------------------------
declare -gA _zsh_command_cache
has_command() {
    local cmd="$1"
    local cache_key="cmd_$cmd"
    [[ -z "$cmd" ]] && return 1
    if [[ -n "${_zsh_command_cache[$cache_key]:-}" ]]; then
        [[ "${_zsh_command_cache[$cache_key]}" == "1" ]] && return 0 || return 1
    fi
    if command -v "$cmd" >/dev/null 2>&1; then
        _zsh_command_cache[$cache_key]="1"
        return 0
    else
        _zsh_command_cache[$cache_key]="0"
        return 1
    fi
}
command_exists() { has_command "$@"; }

safe_git() {
    if [[ -x "/opt/homebrew/bin/git" ]]; then
        /opt/homebrew/bin/git "$@"
    elif [[ -x "/usr/local/bin/git" ]]; then
        /usr/local/bin/git "$@"
    else
        command git "$@"
    fi
}
# Provide backward-compatible wrapper if legacy references exist
if ! typeset -f _lazy_gitwrapper >/dev/null 2>&1; then
    _lazy_gitwrapper() { safe_git "$@"; }
fi

# ------------------------------------------------------------------------------
# ZGENOM / plugin manager variables (use ZDOTDIR to localize installs)
# Prefer non-dot `zgenom` locations but keep backwards compatible fallbacks.
# ------------------------------------------------------------------------------
ZGENOM_PARENT_DIR="${ZDOTDIR}"

# Resolve the zgenom source directory in priority order:
# 1) localized vendored .zqs-zgenom under $ZDOTDIR (preferred for localized installs)
# 2) localized zgenom under $ZDOTDIR (stow-friendly, no leading dot)
# 3) localized legacy .zgenom under $ZDOTDIR
# 4) user-home fallback ${HOME}/.zgenom
# If none exist, default to the stow-friendly name under ZDOTDIR so callers
# that write into the stowed config know the expected location.
if [[ -n "${ZDOTDIR:-}" && -d "${ZDOTDIR}/.zqs-zgenom" ]]; then
    ZGEN_SOURCE="${ZDOTDIR}/.zqs-zgenom"
elif [[ -n "${ZDOTDIR:-}" && -d "${ZDOTDIR}/zgenom" ]]; then
    ZGEN_SOURCE="${ZDOTDIR}/zgenom"
elif [[ -n "${ZDOTDIR:-}" && -d "${ZDOTDIR}/.zgenom" ]]; then
    ZGEN_SOURCE="${ZDOTDIR}/.zgenom"
elif [[ -d "${HOME}/.zgenom" ]]; then
    ZGEN_SOURCE="${HOME}/.zgenom"
else
    ZGEN_SOURCE="${ZDOTDIR}/zgenom"
fi

# Primary zgenom entry points derived from chosen source
ZGENOM_SOURCE_FILE=$ZGEN_SOURCE/zgenom.zsh

ZGEN_DIR="${ZGEN_SOURCE}"
ZGEN_INIT="${ZGEN_DIR}/init.zsh"
ZGENOM_BIN_DIR="${ZGEN_DIR}/_bin"

export ZGENOM_PARENT_DIR ZGEN_SOURCE ZGENOM_SOURCE_FILE ZGEN_DIR ZGEN_INIT ZGENOM_BIN_DIR

# Debug info (only prints when ZSH_DEBUG=1)
zsh_debug_echo "[DEBUG]: localized zgenom configuration:" || true
zsh_debug_echo "    ZGEN_SOURCE=$ZGEN_SOURCE" || true
zsh_debug_echo "    ZGENOM_SOURCE_FILE=$ZGENOM_SOURCE_FILE" || true
zsh_debug_echo "    ZGEN_DIR=$ZGEN_DIR" || true
zsh_debug_echo "    ZGEN_INIT=$ZGEN_INIT" || true
zsh_debug_echo "    ZGEN_AUTOLOAD_COMPINIT=$ZGEN_AUTOLOAD_COMPINIT" || true

# Completion behavior control: set to 0 to avoid automatic compinit while debugging.
# When you are confident completions/fpath are correct, you can set this to 1.
export ZGEN_AUTOLOAD_COMPINIT="${ZGEN_AUTOLOAD_COMPINIT:-0}"

# Feature flags (planning): pre-plugin redesign & plugin ecosystem toggles
# Pre-plugin: ENABLED (simpler modules), Post-plugin: DISABLED (avoid complex async/lazy loading)
export ZSH_ENABLE_PREPLUGIN_REDESIGN="${ZSH_ENABLE_PREPLUGIN_REDESIGN:-1}"
export ZSH_ENABLE_POSTPLUGIN_REDESIGN="${ZSH_ENABLE_POSTPLUGIN_REDESIGN:-0}"
export ZSH_ENABLE_NVM_PLUGINS="${ZSH_ENABLE_NVM_PLUGINS:-0}"
export ZSH_NODE_LAZY="${ZSH_NODE_LAZY:-1}"
export ZSH_ENABLE_ABBR="${ZSH_ENABLE_ABBR:-0}"

# ------------------------------------------------------------------
# Core PATH fallback (Stage 2 stabilization)
# Ensures essential system utilities (awk, date, mkdir, sed, grep, etc.)
# are available even in constrained early interactive shells invoked
# by performance harnesses or baseline scripts. This appends missing
# core directories without disturbing existing ordering when present.
# Safe: only appends; does not reorder front-of-line priorities.
# ------------------------------------------------------------------
{
    _core_added=0
    for __core_dir in /usr/local/bin /opt/homebrew/bin /usr/bin /bin /usr/sbin /sbin; do
        [ -d "$__core_dir" ] || continue
        case ":$PATH:" in
        *:"$__core_dir":*) ;;
        *)
            PATH="${PATH:+$PATH:}$__core_dir"
            _core_added=$(( _core_added + 1 ))
            ;;
        esac
    done
    export PATH
    unset __core_dir _core_added
}

# Optional: custom compdump location and compinit flags (keeps compdump in cache)
export ZGEN_CUSTOM_COMPDUMP="${ZGEN_CUSTOM_COMPDUMP:-${ZSH_CACHE_DIR}/zcompdump_${ZSH_VERSION:-unknown}}"
export ZGEN_COMPINIT_FLAGS="${ZGEN_COMPINIT_FLAGS:-${ZGEN_COMPINIT_FLAGS:-}}"

# Optional: oh-my-zsh repo/branch defaults used by some starter plugin lists
export ZGEN_OH_MY_ZSH_REPO="${ZGEN_OH_MY_ZSH_REPO:-ohmyzsh/ohmyzsh}"
export ZGEN_OH_MY_ZSH_BRANCH="${ZGEN_OH_MY_ZSH_BRANCH:-master}"

# Initialize fpath if not already set (prevents unbound variable errors)
: ${fpath:=()}

# Add vendored zgenom functions to fpath early if present (try source then dir)
if [[ -d "${ZGEN_SOURCE}/functions" ]]; then
    fpath=("${ZGEN_SOURCE}/functions" $fpath)
elif [[ -d "${ZGEN_DIR}/functions" ]]; then
    fpath=("${ZGEN_DIR}/functions" $fpath)
fi

# ------------------------------------------------------------------------------
# History defaults anchored in localized ZDOTDIR
# ------------------------------------------------------------------------------
export HISTFILE="${ZDOTDIR}/.zsh_history"
export HISTSIZE="${HISTSIZE:-2000000}"
export SAVEHIST="${SAVEHIST:-2000200}"
export HISTTIMEFORMAT="${HISTTIMEFORMAT:-'%F %T %z %a %V '}"
export HISTDUP="${HISTDUP:-erase}"

# ------------------------------------------------------------------------------
# Final early housekeeping
# ------------------------------------------------------------------------------
# Make sure .env files under ZDOTDIR/.env (if any) are loaded for both
# interactive and non-interactive shells. These files are expected to contain
# user-level environment variables and API keys the user wants available.
if [[ -d "${ZDOTDIR}/.env" ]]; then
    for env_file in "${ZDOTDIR}/.env"/*.env; do
        [[ -r "$env_file" ]] && source "$env_file"
    done
    unset env_file
fi

# Export a stable EDITOR/VISUAL if not already set (best-effort)
if [[ -z "${EDITOR:-}" ]]; then
    for e in nvim vim nano; do
        if command -v "$e" >/dev/null 2>&1; then
            export EDITOR="$e"
            break
        fi
    done
fi
if [[ -z "${VISUAL:-}" ]]; then
    for v in "$EDITOR" code code-insiders; do
        command -v "${v}" >/dev/null 2>&1 && { export VISUAL="$v"; break; } || true
    done
fi

# Set a sane default LANG/LC if unset
export LANG="${LANG:-en_GB.UTF-8}"
export LC_ALL="${LC_ALL:-${LANG}}"

# Ensure our path is exported (in case callers modified PATH after earlier changes)
export PATH

# Debug summary at end of .zshenv load when debugging is enabled
if [[ "${ZSH_DEBUG}" == "1" ]]; then
    zsh_debug_echo "[DEBUG] .zshenv completed: ZDOTDIR=${ZDOTDIR} ZSH_CACHE_DIR=${ZSH_CACHE_DIR} ZSH_LOG_DIR=${ZSH_LOG_DIR} PATH=${PATH}" >> "${ZSH_DEBUG_LOG}" 2>/dev/null || true
fi

# End of .zshenv
