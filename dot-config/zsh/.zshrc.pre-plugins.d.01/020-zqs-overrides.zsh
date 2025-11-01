#!/usr/bin/env zsh
# 020-zqs-overrides.zsh
#
# Purpose:
#   Overrides core Zsh Quickstart Kit (ZQS) functions to enhance functionality
#   and prevent warnings. This script ensures that vendor scripts (like FZF)
#   can be loaded without generating 'WARN_CREATE_GLOBAL' messages.
#
# Overrides:
#   - load-shell-fragments: Redefined to suppress warnings during sourcing and
#     to use zsh-native globbing for performance and safety, removing `ls` dependency.
#   - _zqs-get-setting: Redefined to declare local variables properly, preventing
#     warnings when WARN_CREATE_GLOBAL is enabled.
#
# Features:
#   - Performance monitoring for fragment loading.
#   - Optional filtering to load only `.zsh` files for improved security.
#   - Idempotent design ensures functions are overridden only once.

# Idempotency Guard
[[ -n ${_ZF_ZQS_OVERRIDES_DONE:-} ]] && return 0
_ZF_ZQS_OVERRIDES_DONE=1

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# --- Early command presence + PATH ensures ---

# Reliable command-exists check using `command -v`
if ! typeset -f zf::can_haz >/dev/null 2>&1; then
zf::can_haz() {
  command -v -- "$1" >/dev/null 2>&1
}
fi

# Ensure callers use the robust checker
if ! typeset -f can_haz >/dev/null 2>&1; then
can_haz() { zf::can_haz "$@"; }
fi

# Make Homebrew bin available early so vendor checks (e.g., fzf) see it
hb_bin="/opt/homebrew/bin"
if [[ -d "$hb_bin" ]]; then
  case ":$PATH:" in
    (*":$hb_bin:"*) ;;  # already present
    (*) PATH="$hb_bin:$PATH"; export PATH; hash -r ;;
  esac
fi

# --- Override load-shell-fragments ---

function load-shell-fragments() {
  # Suppress WARN_CREATE_GLOBAL for vendor scripts
  setopt LOCAL_OPTIONS no_warn_create_global

  local start_time=${EPOCHREALTIME:-0}
  local fragment_count=0

  if [[ -z ${1-} ]]; then
    echo "You must give load-shell-fragments a directory path" >&2
    return 1
  fi

  if [[ ! -d "$1" ]]; then
    echo "$1 is not a directory" >&2
    return 1
  fi

  # Determine glob pattern based on ZQS setting
  local glob_pattern="$1"/*(N)
  if [[ "${_ZQS_FILTER_ZSH_EXTENSIONS:-0}" == "1" ]]; then
    glob_pattern="$1"/*.zsh(N)
  fi

  # Use zsh glob expansion instead of external ls
  local _zqs_fragment
  for _zqs_fragment in ${~glob_pattern}; do
    [[ -f "$_zqs_fragment" && -r "$_zqs_fragment" ]] && {
      source "$_zqs_fragment"
      ((fragment_count++))
    }
  done

  if [[ "${ZSH_DEBUG:-0}" == "1" ]]; then
    local elapsed=$(( (EPOCHREALTIME - start_time) * 1000 ))
    zf::debug "# [load-fragments] Loaded $fragment_count files from $1 in ${elapsed}ms"
  fi
}

# ZQS Setting: Filter to .zsh files only (default: 0, load all)
: "${_ZQS_FILTER_ZSH_EXTENSIONS:=0}"

local filter_status="all files"
[[ "${_ZQS_FILTER_ZSH_EXTENSIONS}" == "1" ]] && filter_status=".zsh files only"
zf::debug "# [zqs-overrides] Overrode load-shell-fragments function (filter: $filter_status)"


# --- Override _zqs-get-setting ---

# Settings names have to be valid file names
_zqs-get-setting() {
  setopt LOCAL_OPTIONS no_warn_create_global

  local sfile="${_ZQS_SETTINGS_DIR}/${1}"
  local svalue

  if [[ -f "$sfile" ]]; then
    svalue=$(cat "$sfile")
  else
    if [[ $# -eq 2 ]]; then
      svalue=$2
    else
      svalue=''
    fi
  fi
  echo "$svalue"
}

zf::debug "# [zqs-overrides] Overrode _zqs-get-setting function"

return 0
