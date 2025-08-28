# ==============================================================================
# CRITICAL STARTUP STANZA - MUST BE FIRST
# Sets essential environment variables before any other shell initialization
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

# Minimal safe PATH to avoid command-not-found in early init
export PATH="/opt/homebrew/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"

# XDG Base Directory Specification (set early so other code can rely on them)
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"
export XDG_BIN_HOME="${XDG_BIN_HOME:-${HOME}/.local/bin}"
mkdir -p "${XDG_CONFIG_HOME}" "${XDG_CACHE_HOME}" "${XDG_DATA_HOME}" "${XDG_STATE_HOME}" "${XDG_BIN_HOME}" 2>/dev/null || true

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
# if the variable was already defined (e.g. by a wrapper or environment).
# This makes the default robust for portable setups where the user may want
# to set ZDOTDIR externally.
export ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-${HOME}/.config}/zsh}"

# Create common cache/log dirs (do not fail startup if mkdir fails)
export ZSH_CACHE_DIR="${XDG_CACHE_HOME}/zsh"
export ZSH_LOG_DIR="${ZDOTDIR}/logs"
mkdir -p "$ZDOTDIR" "$ZSH_CACHE_DIR" "$ZSH_LOG_DIR" 2>/dev/null || true

# Provide a short session id for debug/log filenames
export ZSH_SESSION_ID="${ZSH_SESSION_ID:-$$-$(date +%s 2>/dev/null || echo 'unknown')}"
export ZSH_DEBUG_LOG="${ZSH_LOG_DIR}/${ZSH_SESSION_ID}-zsh-debug.log"

# Basic optional debug flag
export ZSH_DEBUG="${ZSH_DEBUG:-0}"

zsh_debug_echo "[DEBUG] early .zshenv: ZDOTDIR=${ZDOTDIR} ZSH_CACHE_DIR=${ZSH_CACHE_DIR} ZSH_LOG_DIR=${ZSH_LOG_DIR}" >> "${ZSH_DEBUG_LOG}" 2>/dev/null || true

# ------------------------------------------------------------------------------
# Utility: PATH de-duplication (preserve first occurrence)
# ------------------------------------------------------------------------------
path_dedupe() {
    local verbose=0 dry=0
    for arg in "$@"; do
        case $arg in
            --verbose) verbose=1 ;;
            --dry-run) dry=1 ;;
        esac
    done
    local original=$PATH
    local -a parts new
    local -A seen
    parts=(${=PATH})
    for p in "${parts[@]}"; do
        [[ -z $p ]] && continue
        if [[ -z ${seen[$p]:-} ]]; then
            new+="$p"
            seen[$p]=1
        fi
    done
    local deduped="${(j.:.)new}"
    if (( dry )); then
        print -r -- "${deduped:-$original}"
        return 0
    fi
    if [[ $deduped != $original ]]; then
        PATH=$deduped
        export PATH
    fi
    export PATH_DEDUP_DONE=1
    (( verbose )) && print -u2 "[path_dedupe] entries(before)=${#parts} entries(after)=${#new}"
}

# Deduplicate initial PATH (idempotent)
path_dedupe >/dev/null 2>&1 || true

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
        local _zd_prev_pwd
        _zd_prev_pwd="$PWD" 2>/dev/null || true
        if cd "${ZDOTDIR}" 2>/dev/null; then
            ZDOTDIR="$(pwd -P 2>/dev/null || pwd)"
            # return to previous working directory
            cd "$_zd_prev_pwd" 2>/dev/null || true
        fi
        unset _zd_prev_pwd
    fi
fi
export ZDOTDIR

# Recreate ensured dirs now anchored to canonical ZDOTDIR
mkdir -p "${ZDOTDIR}" "${ZSH_CACHE_DIR}" "${ZSH_LOG_DIR}" 2>/dev/null || true

# ------------------------------------------------------------------------------
# ZGENOM / plugin manager variables (use ZDOTDIR to localize installs)
# ------------------------------------------------------------------------------
ZGENOM_PARENT_DIR="${ZDOTDIR}"
ZGEN_SOURCE="${ZDOTDIR}/.zqs-zgenom"
ZGENOM_SOURCE_FILE="${ZGEN_SOURCE}/zgenom.zsh"
ZGEN_DIR="${ZDOTDIR}/.zgenom"
ZGEN_INIT="${ZGEN_DIR}/init.zsh"
ZGENOM_BIN_DIR="${ZGEN_DIR}/_bin"

export ZGENOM_PARENT_DIR ZGEN_SOURCE ZGENOM_SOURCE_FILE ZGEN_DIR ZGEN_INIT ZGENOM_BIN_DIR

# Add vendored zgenom functions to fpath early if present
if [[ -d "${ZGEN_SOURCE}/functions" ]]; then
    fpath=("${ZGEN_SOURCE}/functions" $fpath)
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
