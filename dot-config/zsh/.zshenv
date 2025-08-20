# Fixed .zshenv - Core environment setup
# This file is sourced by all zsh instances (login, interactive, scripts)
# Keep minimal - only essential environment variables and PATH setup

# Conditionally disable verbose output during normal startup
# Allow debugging when ZSH_DEBUG_VERBOSE is set
if [[ -z "$ZSH_DEBUG_VERBOSE" ]]; then
    setopt NO_VERBOSE
    setopt NO_XTRACE
    # Also disable function tracing globally
    setopt NO_FUNCTION_ARGZERO
fi

# Simple, safe PATH - MUST BE FIRST
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"
[[ -d /run/current-system/sw/bin ]] && PATH="/run/current-system/sw/bin:$PATH"
[[ -d /opt/homebrew/bin ]] && PATH="/opt/homebrew/bin:$PATH"
[[ -d $HOME/.local/bin ]] && PATH="$HOME/.local/bin:$PATH"
# DISABLE THIS FOR NOW - CAUSING HANGS: typeset -U path PATH

export ZSH_DEBUG=${ZSH_DEBUG:-0}

[[ $ZSH_DEBUG == 1 ]] && {
    printf "# ++++++ %s:zshenv ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
    # Add this check to detect errant file creation:
    if [[ -f "${ZDOTDIR:-$HOME}/2" ]] || [[ -f "${ZDOTDIR:-$HOME}/3" ]]; then
        echo "Warning: Numbered files detected - check for redirection typos" >&2
    fi
}

# TEMPORARILY DISABLED: Emergency command function overrides
# These were causing severe command interference preventing normal operations
# The .NG prevention systems provide better alternatives
#
# CRITICAL: Define essential command functions IMMEDIATELY in .zshenv
# This ensures they're available for ALL zsh instances, including scripts
# function sed() { /usr/bin/sed "$@"; }
# function tr() { /usr/bin/tr "$@"; }
# function uname() { /usr/bin/uname "$@"; }
# function dirname() { /usr/bin/dirname "$@"; }
# function basename() { /usr/bin/basename "$@"; }
# function cat() { /bin/cat "$@"; }
# function cc() { /usr/bin/cc "$@"; }
# function make() { /usr/bin/make "$@"; }
# function ld() { /usr/bin/ld "$@"; }

# Export these functions globally
# typeset -gf sed tr uname dirname basename cat cc make ld

# Developer tools PATH - these append to the basic PATH set above
[[ -d "/Applications/Xcode.app/Contents/Developer/usr/bin" ]] && PATH="$PATH:/Applications/Xcode.app/Contents/Developer/usr/bin"
[[ -d "/Library/Developer/CommandLineTools/usr/bin" ]] && PATH="$PATH:/Library/Developer/CommandLineTools/usr/bin"

# Export build environment variables IMMEDIATELY
export CC="/usr/bin/cc"
export CXX="/usr/bin/c++"
export CPP="/usr/bin/cpp"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

# Disable zgenom's automatic compinit (add before zgenom load calls)
# TEMPORARILY DISABLED - Re-enabling auto compinit to fix completion issues
# export ZGEN_AUTOLOAD_COMPINIT=0
# export ZGENOM_AUTO_COMPINIT=0

# DISABLED - POTENTIALLY CAUSING HANGS: Prevent duplicate entries in PATH and FPATH arrays
# typeset -x PATH FPATH
# typeset -aUx path fpath

# PATH deduplication disabled for now due to hangs

# Create safe command wrappers
command_exists() { command -v "$1" >/dev/null 2>&1; }
safe_uname() { command_exists uname && uname "$@" || echo "unknown"; }
safe_sed() { command_exists sed && sed "$@" || echo "sed not available"; }

## [_path]
{
    function _path_remove() {
        for ARG in "$@"; do
            while [[ ":${PATH}:" == *":${ARG}:"* ]]; do
                # Delete path by parts to avoid accidentally removing sub paths
                [[ "${PATH}" == "${ARG}" ]] && PATH=""
                PATH=${PATH//":${ARG}:"/":"} # delete any instances in the middle
                PATH=${PATH/#"${ARG}:"/}     # delete any instance at the beginning
                PATH=${PATH/%":${ARG}"/}     # delete any instance at the end
            done
        done
        export PATH
    }

    function _path_append() {
        for ARG in "$@"; do
            _path_remove "${ARG}"
            [[ -d "${ARG}" ]] && export PATH="${PATH:+"${PATH}:"}${ARG}"
        done
    }

    function _path_prepend() {
        for ARG in "$@"; do
            _path_remove "${ARG}"
            [[ -d "${ARG}" ]] && export PATH="${ARG}${PATH:+":${PATH}"}"
        done
    }

    # DISABLED: Add user local bin to PATH - XDG_BIN_HOME not defined yet
    # _path_prepend "${XDG_BIN_HOME}"
}


## XDG Base Directory Specification
## https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
export XDG_BIN_HOME=${XDG_BIN_HOME:="${HOME}/.local/bin"}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:="${HOME}/.cache"}
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:="${HOME}/.config"}
export XDG_DATA_HOME=${XDG_DATA_HOME:="${HOME}/.local/share"}
export XDG_STATE_HOME=${XDG_STATE_HOME:="${HOME}/.local/state"}

# Platform-specific XDG_RUNTIME_DIR setup
# Now safe to use uname since PATH is set
case "$(uname -s)" in
    Darwin)
        export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:="${HOME}/Library/Caches/TemporaryItems"}
        mkdir -p "${XDG_RUNTIME_DIR}"
        ;;
    Linux)
        # Linux-specific setup if needed
        ;;
    MINGW32_NT*|MINGW64_NT*)
        # Windows setup if needed
        ;;
esac

# Zsh-specific directories
export ZDOTDIR=${ZDOTDIR:="${XDG_CONFIG_HOME}/zsh"}
export ZSH_CACHE_DIR=${ZSH_CACHE_DIR:="${XDG_CACHE_HOME}/zsh"}
export ZSH_COMPDUMP="${ZSH_CACHE_DIR:-${HOME}}/.zcompdump-${SHORT_HOST:-$(hostname -s)}-${ZSH_VERSION}"

typeset -gxa ZSH_AUTOSUGGEST_STRATEGY
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

typeset -gxa GLOBALIAS_FILTER_VALUES
GLOBALIAS_FILTER_VALUES=("sudo" "man" "which" "bob")


# Create required directories
mkdir -p "${ZSH_CACHE_DIR}"

# Plugin manager setup - zgenom configuration
export ZGENOM_PARENT_DIR="${ZDOTDIR}"
export ZGEN_SOURCE="${ZDOTDIR}/.zqs-zgenom"
export ZGENOM_SOURCE_FILE="${ZGEN_SOURCE}/zgenom.zsh"
export ZGEN_DIR="${ZDOTDIR}/.zgenom"
export ZGEN_INIT="${ZGEN_DIR}/init.zsh"
export ZGENOM_BIN_DIR="${ZGEN_DIR}/_bin"

# Oh-My-ZSH configuration for zgenom
export ZGEN_OH_MY_ZSH_REPO="ohmyzsh/ohmyzsh"
export ZGEN_OH_MY_ZSH_BRANCH="master"

# Ensure zgenom functions are in fpath for autoloading
if [[ -d "${ZGEN_SOURCE}/functions" ]]; then
    fpath=("${ZGEN_SOURCE}/functions" $fpath)
fi

# Disable macOS session restore
export SHELL_SESSIONS_DISABLE=1

# History configuration
export HISTDUP=erase
export HISTFILE="${ZDOTDIR}/.zsh_history"
export HISTSIZE=1000000
export HISTTIMEFORMAT='%F %T %z %a %V '
export SAVEHIST=1100000

# Core application settings
export DISPLAY=:0.0
export LANG='en_GB.UTF-8'
export LC_ALL='en_GB.UTF-8'
export TIME_STYLE=long-iso

set_editor() {
    # Set editors if available (with fallback)
    local editors=(nvim hx vim nano)
    for e in $editors; do
        [[ -n "$e" ]] &&
            command -v "$e" >/dev/null 2>&1 &&
            { export EDITOR="$e"; break; }
    done
}

set_visual() {
    # Set editors if available (with fallback)
    set_editor
    local editors=(code-insiders code zed hx "$EDITOR")
    for e in $editors; do
        [[ -n "$e" ]] &&
            command -v "$e" >/dev/null 2>&1 &&
            { export VISUAL="$e"; break; }
    done
}
set_visual

# Java setup (macOS specific)
if [[ -x "/usr/libexec/java_home" ]]; then
    JAVA_HOME="$(/usr/libexec/java_home 2>/dev/null)" && export JAVA_HOME
fi

# Less configuration with color support
export LESS=' --HILITE-UNREAD --LONG-PROMPT --no-histdups --ignore-case --incsearch --no-init --line-numbers --mouse --quit-if-one-screen --squeeze-blank-lines --status-column --tabs=4 --use-color --window=-4 --RAW-CONTROL-CHARS '

# D-Bus session setup (Linux compatibility)
export MY_SESSION_BUS_SOCKET="/tmp/dbus/${USER}.session.usock"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${MY_SESSION_BUS_SOCKET}"

# MCP server allowed directories for file operations
export ALLOWED_DIRECTORIES="/Users/s-a-c/Desktop,/Users/s-a-c/Downloads,/Users/s-a-c/Herd,/Users/s-a-c/Library,/Users/s-a-c/Projects,/Users/s-a-c/Work,/Users/s-a-c/.config,/Users/s-a-c/dotfiles,/Users/s-a-c/.local,/Users/s-a-c/.zshenv,/Users/s-a-c/.zshrc,/Users/s-a-c/.zprofile,/Users/s-a-c/.zlogin"


## [_field]
{
    function _field_append() {
        ## SYNOPSIS: field_append varName fieldVal [sep]
        ##     SEP defaults to ':'
        ## Note: Forces fieldVal into the last position, if already present.
        ##             Duplicates are removed, too.
        ## EXAMPLE: field_append PATH /usr/local/bin
        local varName=$1 fieldVal=$2 IFS=${3:-':'}
        read -ra auxArr <<<"${!varName}"
        for i in "${!auxArr[@]}"; do
            [[ ${auxArr[i]} == "$fieldVal" ]] && unset 'auxArr[i]'
        done
        auxArr+=("$fieldVal")
        printf -v "$varName" '%s' "${auxArr[*]}"
    }

    function _field_contains() {
        ## SYNOPSIS: field_contains varName fieldVal [sep]
        ##     SEP defaults to ':'
        ## EXAMPLE: field_contains PATH /usr/local/bin
        local varName=$1 fieldVal=$2 IFS=${3:-':'}
        read -ra auxArr <<<"${!varName}"
        for i in "${!auxArr[@]}"; do
            [[ ${auxArr[i]} == "$fieldVal" ]] && return 0
        done
        return 1
    }

    function _field_delete() {
        ## SYNOPSIS: field_delete varName fieldNum [sep]
        ##     SEP defaults to ':'
        ## EXAMPLE: field_delete PATH 2
        local varName=$1 fieldNum=$2 IFS=${3:-':'}
        read -ra auxArr <<<"${!varName}"
        unset 'auxArr[fieldNum]'
        printf -v "$varName" '%s' "${auxArr[*]}"
    }

    function _field_find() {
        ## SYNOPSIS: field_find varName fieldVal [sep]
        ##     SEP defaults to ':'
        ## EXAMPLE: field_find PATH /usr/local/bin
        local varName=$1 fieldVal=$2 IFS=${3:-':'}
        read -ra auxArr <<<"${!varName}"
        for i in "${!auxArr[@]}"; do
            [[ ${auxArr[i]} == "$fieldVal" ]] && return 0
        done
        return 1
    }

    function _field_get() {
        ## SYNOPSIS: field_get varName fieldNum [sep]
        ##     SEP defaults to ':'
        ## EXAMPLE: field_get PATH 2
        printf "$# : $@"
        local varName=$1 fieldNum=$2 IFS=${3:-':'}
        read -ra auxArr <<<"${!varName}"
        printf '%s' "${auxArr[fieldNum]}"
    }

    function _field_insert() {
        ## SYNOPSIS: field_insert varName fieldNum fieldVal [sep]
        ##     SEP defaults to ':'
        ## EXAMPLE: field_insert PATH 2 /usr/local/bin
        local varName=$1 fieldNum=$2 fieldVal=$3 IFS=${4:-':'}
        read -ra auxArr <<<"${!varName}"
        auxArr=("${auxArr[@]:0:fieldNum}" "$fieldVal" "${auxArr[@]:fieldNum}")
        printf -v "$varName" '%s' "${auxArr[*]}"
    }

    function _field_prepend() {
        ## SYNOPSIS: field_prepend varName fieldVal [sep]
        ##     SEP defaults to ':'
        ## Note: Forces fieldVal into the first position, if already present.
        ##             Duplicates are removed, too.
        ## EXAMPLE: field_prepend PATH /usr/local/bin
        local varName=$1 fieldVal=$2 IFS=${3:-':'}
        read -ra auxArr <<<"${!varName}"
        for i in "${!auxArr[@]}"; do
            [[ ${auxArr[i]} == "$fieldVal" ]] && unset 'auxArr[i]'
        done
        auxArr=("$fieldVal" "${auxArr[@]}")
        printf -v "$varName" '%s' "${auxArr[*]}"
    }

    function _field_remove() {
        ## SYNOPSIS: field_remove varName fieldVal [sep]
        ##     SEP defaults to ':'
        ## Note: Duplicates are removed, too.
        ## EXAMPLE: field_remove PATH /usr/local/bin
        local varName=$1 fieldVal=$2 IFS=${3:-':'}
        read -ra auxArr <<<"${!varName}"
        for i in "${!auxArr[@]}"; do
            [[ ${auxArr[i]} == "$fieldVal" ]] && unset 'auxArr[i]'
        done
        printf -v "$varName" '%s' "${auxArr[*]}"
    }

    function _field_replace() {
        ## SYNOPSIS: field_replace varName fieldVal newFieldVal [sep]
        ##     SEP defaults to ':'
        ## EXAMPLE: field_replace PATH /usr/local/bin /usr/local/bin2
        local varName=$1 fieldVal=$2 newFieldVal=$3 IFS=${4:-':'}
        read -ra auxArr <<<"${!varName}"
        for i in "${!auxArr[@]}"; do
            [[ ${auxArr[i]} == "$fieldVal" ]] && auxArr[i]="$newFieldVal"
        done
        printf -v "$varName" '%s' "${auxArr[*]}"
    }

    function _field_set() {
        ## SYNOPSIS: field_set varName fieldNum fieldVal [sep]
        ##     SEP defaults to ':'
        ## EXAMPLE: field_set PATH 2 /usr/local/bin
        local varName=$1 fieldNum=$2 fieldVal=$3 IFS=${4:-':'}
        read -ra auxArr <<<"${!varName}"
        auxArr[fieldNum]="$fieldVal"
        printf -v "$varName" '%s' "${auxArr[*]}"
    }

    function _field_test() {
        ## SYNOPSIS: _field_test
        ## EXAMPLE: _field_test
        ## DESCRIPTION: Test function for the _field library.
        ##              It tests all the functions in the library.
        ##              It is not meant to be called directly.
        ##              It is meant to be called from the _test function.
        local varName=PATH fieldNum=2 fieldVal=/usr/local/bin fieldVal2=/usr/local/bin2
        local auxArr
        printf -v "$varName" '%s' '/usr/bin:/usr/local/bin:/bin:/usr/sbin'
        _field_get "$varName" "$fieldNum"
        _field_set "$varName" "$fieldNum" "$fieldVal"
        _field_insert "$varName" "$fieldNum" "$fieldVal"
        _field_delete "$varName" "$fieldNum"
        _field_find "$varName" "$fieldVal"
        _field_replace "$varName" "$fieldVal" "$fieldVal2"
        _field_contains "$varName" "$fieldVal"
        _field_append "$varName" "$fieldVal"
        _field_prepend "$varName" "$fieldVal"
        _field_append "$varName" "$fieldVal"
        _field_remove "$varName" "$fieldVal"
    }
}


# Load all environment files from .env directory
# This ensures API keys and other environment variables are available for all shell sessions,
# including non-interactive ones used by MCP servers
if [[ -d "${ZDOTDIR}/.env" ]]; then
  for env_file in "${ZDOTDIR}/.env"/*.env; do
    [[ -r "$env_file" ]] && source "$env_file"
  done
  unset env_file
fi

# History management functions
# Disables zsh history recording by overriding the zshaddhistory hook
# shellcheck disable=SC1073
function disablehistory() {
    function zshaddhistory() { return 1 }
}

# Re-enables zsh history recording by removing the zshaddhistory override
function enablehistory() {
    unset -f zshaddhistory
}
