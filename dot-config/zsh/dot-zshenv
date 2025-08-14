# Fixed .zshenv - Core environment setup
# This file is sourced by all zsh instances (login, interactive, scripts)
# Keep minimal - only essential environment variables and PATH setup

[[ -n "$ZSH_DEBUG" ]] && printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2

# Ensure system paths are available FIRST - critical for basic commands
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

# Prevent duplicate entries in PATH and FPATH arrays
typeset -x PATH FPATH
typeset -aUx path fpath

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

# Create required directories
mkdir -p "${ZSH_CACHE_DIR}"

# Plugin manager setup - zgenom configuration
export ZGENOM_PARENT_DIR="${ZDOTDIR}"
export ZGENOM_SOURCE_FILE="${ZGENOM_PARENT_DIR}/zgenom/zgenom.zsh"
export ZGEN_DIR="${ZDOTDIR}/.zgenom"
export ZGENOM_BIN_DIR="${ZGEN_DIR}/_bin"

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

# Set editors if available (with fallback)
if command -v nvim >/dev/null 2>&1; then
    export EDITOR="$(command -v nvim)"
else
    export EDITOR="$(command -v vim || command -v vi)"
fi

if command -v hx >/dev/null 2>&1; then
    export VISUAL="$(command -v hx)"
else
    export VISUAL="${EDITOR}"
fi

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

# PATH manipulation functions
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

# Source bob environment only once if it exists
if [[ -f "${HOME}/.local/share/bob/env/env.sh" ]]; then
    builtin source "${HOME}/.local/share/bob/env/env.sh"
fi

# Add user local bin to PATH
_path_prepend "${XDG_BIN_HOME}"

# History management functions
function disablehistory() {
    function zshaddhistory() { return 1 }
}

function enablehistory() {
    unset -f zshaddhistory
}
