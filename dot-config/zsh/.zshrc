# Copyright 2006-2024 Joseph Block <jpb@unixorn.net>
#
# BSD licensed, see LICENSE.txt
#
# Set this to use case-sensitive completion
# CASE_SENSITIVE="true"
#
# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"
#
# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"
#
# Version 1.0.0
#
# If you want to change settings that are in this file, the easiest way
# to do it is by adding a file to $ZDOTDIR/.zshrc.d or $ZDOTDIR/.zshrc.pre-plugins.d that
# redefines the settings.
#
# All files in there will be sourced, and keeping your customizations
# there will keep you from having to maintain a separate fork of the
# quickstart kit.

# =================================================================================
# === ZQS Framework with ZDOTDIR Support ===
# =================================================================================

# ZQS profiling support
if [[ -f "$ZDOTDIR/.zqs-zprof-enabled" ]]; then
    zmodload zsh/zprof
fi

# Check if a command exists - use builtin command instead of external which
function can_haz() {
    builtin command -v "$1" >/dev/null 2>&1
}

function zqs-debug() {
    if [[ -f "$ZDOTDIR/.zqs-debug-mode" ]]; then
            zsh_debug_echo "$@"
    fi
}

# Fix weirdness with intellij
if [[ -z "${INTELLIJ_ENVIRONMENT_READER}" ]]; then
    export POWERLEVEL9K_INSTANT_PROMPT='quiet'
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of .zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Valid font modes:
# flat, awesome-patched, awesome-fontconfig, nerdfont-complete, nerdfont-fontconfig
if [[ -r "$ZDOTDIR/.powerlevel9k_font_mode" ]]; then
    POWERLEVEL9K_MODE=$(head -1 "$ZDOTDIR/.powerlevel9k_font_mode")
fi

# Unset COMPLETION_WAITING_DOTS in a file in $ZDOTDIR/.zshrc.d if you want red dots to be displayed while waiting for completion
export COMPLETION_WAITING_DOTS="true"

# =================================================================================
# === ZQS Settings System (adapted for ZDOTDIR) ===
# =================================================================================

# Provide a unified way for the quickstart to get/set settings.
if [[ -f "$ZDOTDIR/.zqs-settings-path" ]]; then
    _ZQS_SETTINGS_DIR=$(cat "$ZDOTDIR/.zqs-settings-path")
else
    _ZQS_SETTINGS_DIR="$ZDOTDIR/.zqs-settings"
fi
export _ZQS_SETTINGS_DIR

# _zqs-* functions are internal tooling for the quickstart. Modifying or unsetting
# them is likely to break things badly.

_zqs-trigger-init-rebuild() {
    # Remove compiled init files from localized zgen/zgenom locations.
    # Prefer localized variables if set; fall back to ~/.zgen and ~/.zgenom for backwards compatibility.
    rm -f "${ZGEN_DIR:-${HOME}/.zgen}/init.zsh"
    rm -f "${ZGENOM_PARENT_DIR:-${HOME}}/.zgenom/init.zsh"
}

# We need to load shell fragment files often enough to make it a function
function load-shell-fragments() {
    if [[ -z $1 ]]; then
        zsh_debug_echo "You must give load-shell-fragments a directory path"
    else
        if [[ -d "$1" ]]; then
            # Use zsh glob expansion instead of external /bin/ls to prevent job table overflow
            local fragments=("$1"/*(N))
            if [[ ${#fragments[@]} -gt 0 ]]; then
                local _zqs_fragment
                for _zqs_fragment in "${fragments[@]}"
                do
                    if [[ -r "$_zqs_fragment" ]]; then
                        source "$_zqs_fragment"
                    fi
                done
                unset _zqs_fragment
            fi
        else
            zsh_debug_echo "$1 is not a directory"
        fi
    fi
}

# Settings names have to be valid file names, and we're not doing any parsing here.
_zqs-get-setting() {
    # If there is a $2, we return that as the default value if there's
    # no settings file.
    local sfile="${_ZQS_SETTINGS_DIR}/${1}"
    local svalue
    if [[ -f "$sfile" ]] && [[ -r "$sfile" ]]; then
        # Use builtin read instead of external cat command to prevent job table overflow
        builtin read -r svalue < "$sfile" 2>/dev/null || svalue="${2:-}"
    else
        if [[ $# -eq 2 ]]; then
            svalue=$2
        else
            svalue=''
        fi
    fi
    # Use builtin print instead of zsh_debug_echo to avoid external commands
    builtin print -r -- "$svalue"
}

_zqs-set-setting() {
    if [[ $# -eq 2 ]]; then
        mkdir -p "$_ZQS_SETTINGS_DIR"
            zsh_debug_echo "$2" > "${_ZQS_SETTINGS_DIR}/$1"
    else
            zsh_debug_echo "Usage: _zqs-set-setting-value SETTINGNAME VALUE"
    fi
}

_zqs-delete-setting(){
    # We want to keep output clean when settings are cleared internally, so
    # use a separate function when called by a human we can display a warning
    # if the setting doesn't exist.
    local sfile="${_ZQS_SETTINGS_DIR}/${1}"
    if [[ -f "$sfile" ]]; then
        rm -f "$sfile"
    else
            zsh_debug_echo "There is no settings file for ${1}"
    fi
}

_zqs-purge-setting() {
    local sfile="${_ZQS_SETTINGS_DIR}/${1}"
    rm -f "$sfile"
}

# =================================================================================
# === Core ZSH Configuration ===
# =================================================================================

# Set glob options to avoid errors from unmatched globs
# NOTE: All setopt/unsetopt commands moved to 00_60-options.zsh for consistency
# This ensures single source of truth and eliminates duplicate option settings

# Keep a ton of history. You can override these without editing .zshrc by
# adding a file to $ZDOTDIR/.zshrc.d that changes these variables.
# NOTE: HISTSIZE and SAVEHIST are now set in .zshenv with larger values (2M+)
# NOTE: HISTFILE is now set in .zshenv to avoid conflicts
# export HISTSIZE=100000  # REMOVED - conflicts with .zshenv (2000000)
# export SAVEHIST=100100  # REMOVED - conflicts with .zshenv (2000200)
# HISTFILE=$ZDOTDIR/.zsh_history  # REMOVED - already set in .zshenv

# ZSH Man page referencing the history_ignore parameter - https://manpages.ubuntu.com/manpages/kinetic/en/man1/zshparam.1.html
HISTORY_IGNORE="(cd ..|l[s]#( *)#|pwd *|exit *|date *|* --help)"

# =================================================================================
# === PATH Management (CONSOLIDATED - removed duplicate logic) ===
# =================================================================================

# NOTE: Base PATH is already set in .zshenv with proper ordering
# Removed duplicate PATH setup that was conflicting with .zshenv configuration
# The following logic was redundant and has been moved to comments:

# REMOVED: Base PATH (already in .zshenv)
# PATH="$PATH:/sbin:/usr/sbin:/bin:/usr/bin"

# REMOVED: Conditional PATH additions (already handled in .zshenv)
# The .zshenv file already handles XDG_BIN_HOME and essential system paths
# Keeping only the Homebrew detection logic that's specific to .zshrc

# Deal with brew if it's installed - PATH already prioritized in .zshenv
# NOTE: /opt/homebrew/bin is already first in PATH via .zshenv
# Only add additional Homebrew paths if they're not already included
if can_haz brew; then
    BREW_PREFIX=$(brew --prefix)

    # Only add sbin if it's not already in PATH and exists
    if [[ -d "${BREW_PREFIX}/sbin" ]] && [[ ":$PATH:" != *":${BREW_PREFIX}/sbin:"* ]]; then
        # Prepend sbin to maintain Homebrew priority
        export PATH="${BREW_PREFIX}/sbin:$PATH"
    fi

    # Skip bin directory - already prioritized in .zshenv as /opt/homebrew/bin
    # if [[ -d "${BREW_PREFIX}/bin" ]]; then
    #     export PATH="$PATH:${BREW_PREFIX}/bin"  # REMOVED - redundant
    # fi
fi

# =================================================================================
# === Color Configuration ===
# =================================================================================

if [[ -z "$LSCOLORS" ]]; then
    export LSCOLORS='Exfxcxdxbxegedabagacad'
fi
if [[ -z "$LS_COLORS" ]]; then
    export LS_COLORS='di=1;34;40:ln=35;40:so=32;40:pi=33;40:ex=31;40:bd=34;46:cd=34;43:su=0;41:sg=0;46:tw=0;42:ow=0;43:'
fi

# =================================================================================
# === SSH Key Management (ZQS + Custom Security Features) ===
# =================================================================================

onepassword-agent-check() {
    # 1password ssh agent support
    zqs-debug "Checking for 1password"
    if [[ $(_zqs-get-setting use-1password-ssh-agent true) == 'true' ]]; then
        if [[ "$(uname -s)" == "Darwin" ]]; then
            local ONE_P_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
        fi
        if [[ "$(uname -s)" == "Linux" ]]; then
            local ONE_P_SOCK=~/.1password/agent.sock
        fi
        zqs-debug "ONE_P_SOCK=$ONE_P_SOCK"
        if [[ -r "$ONE_P_SOCK" ]];then
            export SSH_AUTH_SOCK="$ONE_P_SOCK"
        else
                zsh_debug_echo "Quickstart is set to use 1Password's ssh agent, but $ONE_P_SOCK isn't readable!"
        fi
        zqs-debug "Set SSH_AUTH_SOCK to $SSH_AUTH_SOCK"
    fi
}

load-our-ssh-keys() {
    # setup ssh-agent for 1password only if it's installed
    if can_haz op; then
        onepassword-agent-check
    fi
    # If keychain is installed let it take care of ssh-agent, else do it manually
    if can_haz keychain; then
        eval `keychain -q --eval`
    else
        if [ -z "$SSH_AUTH_SOCK" ]; then
            # Check for a currently running instance of the agent
            RUNNING_AGENT="$(ps -ax | grep 'ssh-agent -s' | grep -v grep | wc -l | tr -d '[:space:]')"
            if [ "$RUNNING_AGENT" = "0" ]; then
                if [ ! -d ~/.ssh ] ; then
                    mkdir -p ~/.ssh
                fi
                # Launch a new instance of the agent
                ssh-agent -s &> ~/.ssh/ssh-agent
            fi
            eval $(cat ~/.ssh/ssh-agent)
        fi
    fi

    local key_manager=ssh-add

    if can_haz keychain; then
        key_manager=keychain
    fi

    # Fun with SSH
    if [ $($key_manager -l | grep -c "The agent has no identities." ) -eq 1 ]; then
        if [[ "$(uname -s)" == "Darwin" ]]; then
            # macOS allows us to store ssh key pass phrases in the keychain
            # check if Monterey or higher
            if [[ $(sw_vers -productVersion | cut -d '.' -f 1) -ge "12" ]]; then
                # Load all ssh keys that have pass phrases stored in macOS keychain using new flags
                ssh-add --apple-load-keychain
            else
                ssh-add -qA
            fi
        fi

        for key in $(find ~/.ssh -type f -a \( -name '*id_rsa' -o -name '*id_dsa' -o -name '*id_ecdsa' -o -name '*id_ed25519' \))
        do
            if [ -f ${key} -a $(ssh-add -l | grep -F -c "$(ssh-keygen -l -f $key | awk '{print $2}')" ) -eq 0 ]; then
                $key_manager -q ${key}
            fi
        done
    fi
}

if [[ -z "$SSH_CLIENT" ]] || can_haz keychain; then
    # We're not on a remote machine, so load keys
    if [[ "$(_zqs-get-setting enable-ssh-askpass-require)" == 'true' ]]; then
        export SSH_ASKPASS_REQUIRE=never
    fi
    load_ssh_keys="$(_zqs-get-setting load-ssh-keys true)"
    if [[ "$load_ssh_keys" != "false" ]]; then
        load-our-ssh-keys
    fi
    unset load_ssh_keys
fi

# =================================================================================
# === Pre-Plugin Loading (Security & Custom Features) ===
# =================================================================================

# Load helper functions before we load zgenom setup
if [ -r "$ZDOTDIR/.zsh_functions" ]; then
    source "$ZDOTDIR/.zsh_functions"
fi

# Make it easy to prepend your own customizations that override
# the quickstart kit's defaults by loading all files from the
# $ZDOTDIR/.zshrc.pre-plugins.d directory
mkdir -p "$ZDOTDIR/.zshrc.pre-plugins.d"

if [[ ${ZSH_ENABLE_PREPLUGIN_REDESIGN:-0} == 1 && -d "$ZDOTDIR/.zshrc.pre-plugins.d.redesigned" ]]; then
    zsh_debug_echo "# [pre-plugin] Using redesigned pre-plugin directory (.zshrc.pre-plugins.d.redesigned)"
    load-shell-fragments "$ZDOTDIR/.zshrc.pre-plugins.d.redesigned"
else
    load-shell-fragments "$ZDOTDIR/.zshrc.pre-plugins.d"
fi

if [[ -d "$ZDOTDIR/.zshrc.pre-plugins.$(uname).d" ]]; then
    load-shell-fragments "$ZDOTDIR/.zshrc.pre-plugins.$(uname).d"
fi

# macOS doesn't have a python by default. This makes the omz python and
# zsh-completion-generator plugins sad, so if there isn't a python, alias
# it to python3
if ! can_haz python; then
    if can_haz python3; then
        alias python=python3
    fi
    # Ugly hack for zsh-completion-generator - but only do it if the user
    # hasn't already set GENCOMPL_PY
    if [[ -z "$GENCOMPL_PY" ]]; then
        export GENCOMPL_PY='python3'
        export ZSH_COMPLETION_HACK='true'
    fi
fi

# =================================================================================
# === Plugin Loading (ZQS Standard with ZDOTDIR Support) ===
# =================================================================================

# Now that we have $PATH set up and ssh keys loaded, configure zgenom.
# Start zgenom
# If there's a local checkout of zgenom inside the repo (useful for development
# or when zgenom is vendored into $ZDOTDIR), set XDG-aware variables so the
# vendored copy can resolve its own paths correctly before sourcing it.
# Initialize zgenom using ZGENOM_SOURCE_FILE if set (set in .zshenv).
if [[ -n "${ZGENOM_SOURCE_FILE:-}" && -f "${ZGENOM_SOURCE_FILE}" ]]; then
    source "${ZGENOM_SOURCE_FILE}"
else
    # Fallback resolution order:
    # 1) vendored .zqs-zgenom under $ZDOTDIR (preferred for localized installs)
    # 2) vendored zgenom under $ZDOTDIR/zgenom (legacy)
    # 3) global $HOME/.zgenom
    if [[ -f "$ZDOTDIR/.zqs-zgenom/zgenom.zsh" ]]; then
        export ZGENOM_SOURCE_FILE="$ZDOTDIR/.zqs-zgenom/zgenom.zsh"
        source "$ZGENOM_SOURCE_FILE"
    elif [[ -f "$ZDOTDIR/zgenom/zgenom.zsh" ]]; then
        export ZGENOM_SOURCE_FILE="$ZDOTDIR/zgenom/zgenom.zsh"
        source "$ZGENOM_SOURCE_FILE"
    elif [[ -f "${HOME}/.zgenom/zgenom.zsh" ]]; then
        export ZGENOM_SOURCE_FILE="${HOME}/.zgenom/zgenom.zsh"
        source "${HOME}/.zgenom/zgenom.zsh"
    else
        zsh_debug_echo "zgenom: no zgenom source found in ZGENOM_SOURCE_FILE, $ZDOTDIR/.zqs-zgenom, $ZDOTDIR/zgenom, or $HOME/.zgenom; skipping zgenom initialization"
    fi
fi

# Do not call `zgenom compdef` unconditionally here.
# Let .zgen-setup and zgenom decide whether/when to run compinit/compdef,
# or call compinit in a controlled, guarded location after fpath is finalized.

# Load safe setup if present
if [ -f "$ZDOTDIR/.zgen-setup" ]; then
    source "$ZDOTDIR/.zgen-setup"
fi

# Undo the hackery for issue 180
# Don't unset GENCOMPL_PY if we didn't set it
if [[ -n "$ZSH_COMPLETION_HACK" ]]; then
    unset GENCOMPL_PY
    unset ZSH_COMPLETION_HACK
fi

# =================================================================================
# === History and Completion Settings ===
# =================================================================================

# NOTE: All setopt/unsetopt commands have been moved to 00_60-options.zsh
# This eliminates duplicate option settings and provides a single source of truth

# Long running processes should return time after they complete. Specified
# in seconds.
REPORTTIME=${REPORTTIME:-2}
TIMEFMT="%U user %S system %P cpu %*Es total"

# Disable Oh-My-ZSH's internal updating. Let it get updated when user
# does a zgenom update.
DISABLE_AUTO_UPDATE=true

# =================================================================================
# === Key Bindings (ZQS Standard) ===
# =================================================================================

if [[ $(_zqs-get-setting handle-bindkeys true) == 'true' ]]; then
    # Expand aliases inline - see http://blog.patshead.com/2012/11/automatically-expaning-zsh-global-aliases---simplified.html
    globalias() {
        if [[ $LBUFFER =~ ' [A-Z0-9]+$' ]]; then
            zle _expand_alias
            zle expand-word
        fi
        zle self-insert
    }

    zle -N globalias

    bindkey " " globalias
    bindkey "^ " magic-space           # control-space to bypass completion
    bindkey -M isearch " " magic-space # normal space during searches
fi

# =================================================================================
# === Aliases and Custom Configuration ===
# =================================================================================

# Make it easier to customize the quickstart to your needs without
# having to maintain your own fork.

# Stuff that works on bash or zsh
if [ -r "$ZDOTDIR/.sh_aliases" ]; then
    source "$ZDOTDIR/.sh_aliases"
fi

# Stuff only tested on zsh, or explicitly zsh-specific
if [ -r "$ZDOTDIR/.zsh_aliases" ]; then
    source "$ZDOTDIR/.zsh_aliases"
fi

export LOCATE_PATH=/var/db/locate.database

# Load AWS credentials when present
if [ -f ~/.aws/aws_variables ]; then
    source ~/.aws/aws_variables
fi

# JAVA setup - needed for iam-* tools
if [ -d /Library/Java/Home ];then
    export JAVA_HOME=/Library/Java/Home
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
    # Load macOS-specific aliases
    [ -r "$ZDOTDIR/.macos_aliases" ] && source "$ZDOTDIR/.macos_aliases"
    if [ -d "$ZDOTDIR/.macos_aliases.d" ]; then
        load-shell-fragments "$ZDOTDIR/.macos_aliases.d"
    fi
fi

# =================================================================================
# === Enhanced ls/exa/eza Support ===
# =================================================================================

# Set up colorized ls when gls is present - it's installed by grc
if (( $+commands[gls] )); then
    alias ls="gls -F --color"
    alias l="gls -lAh --color"
    alias ll="gls -l --color"
    alias la='gls -A --color'
fi

# When present, use exa or eza (newest) instead of ls
if can_haz eza; then
    ls_analog='eza'
elif can_haz exa; then
    ls_analog='exa'
fi

if [ -v ls_analog ]; then
    if [[ "$($ls_analog --help | grep -c git)" == 0 ]]; then
        # Not every linux exa build has git support compiled in
        alias l="$ls_analog -al --icons --time-style=long-iso --group-directories-first --color-scale"
    else
        alias l="$ls_analog -al --icons --git --time-style=long-iso --group-directories-first --color-scale"
    fi
    alias ls="$ls_analog --group-directories-first"

    # Don't step on system-installed tree command
    if ! can_haz tree; then
        if [[ -z "$TREE_IGNORE" ]]; then
            TREE_IGNORE=".cache|cache|node_modules|vendor|.git"
        fi
        alias tree="$ls_analog --tree --ignore-glob=\"$TREE_IGNORE\""
    fi
    unset ls_analog
fi

# =================================================================================
# === Completion Configuration ===
# =================================================================================

# Speed up autocomplete, force prefix mapping
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$ZDOTDIR/.zsh/cache"
zstyle -e ':completion:*:default' list-colors 'reply=("${PREFIX:+=(#bi)($PREFIX:t)*==34=34}:${(s.:.)LS_COLORS}")';

# Load any custom zsh completions we've installed
if [[ -d "$ZDOTDIR/.zsh-completions.d" ]]; then
    load-shell-fragments "$ZDOTDIR/.zsh-completions.d"
fi
if [[ -d "$ZDOTDIR/.zsh-completions" ]]; then
        zsh_debug_echo "$ZDOTDIR/.zsh_completions is deprecated in favor of $ZDOTDIR/.zsh_completions.d"
    load-shell-fragments "$ZDOTDIR/.zsh-completions"
fi

# Load zmv
if [[ $(_zqs-get-setting no-zmv false) == 'false' ]]; then
    autoload -U zmv
fi

# =================================================================================
# === Post-Plugin Configuration ===
# =================================================================================

# Make it easy to append your own customizations that override the
# quickstart's defaults by loading all files from the $ZDOTDIR/.zshrc.d directory
mkdir -p "$ZDOTDIR/.zshrc.d"
load-shell-fragments "$ZDOTDIR/.zshrc.d"

if [[ -d "$ZDOTDIR/.zshrc.$(uname).d" ]]; then
    load-shell-fragments "$ZDOTDIR/.zshrc.$(uname).d"
fi

# Load work-specific fragments when present
if [[ -d "$ZDOTDIR/.zshrc.work.d" ]]; then
    load-shell-fragments "$ZDOTDIR/.zshrc.work.d"
fi

# If GOPATH is defined, add it to $PATH
if [[ -n "$GOPATH" ]]; then
    if [[ -d "$GOPATH" ]]; then
        export PATH="$PATH:$GOPATH"
    fi
fi

# Now that .zshrc.d has been processed, we dedupe $PATH using a ZSH builtin
# https://til.hashrocket.com/posts/7evpdebn7g-remove-duplicates-in-zsh-path
typeset -aU path;

# If desk is installed, load the Hook for desk activation
[[ -n "$DESK_ENV" ]] && source "$DESK_ENV"

# =================================================================================
# === Final Configuration ===
# =================================================================================

# Fix bracketed paste issue
# Closes #73
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(bracketed-paste)

# Load iTerm shell integrations if found.
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# To customize your prompt, run `p10k configure` or edit $ZDOTDIR/.p10k.zsh.
if [[ ! -f "$ZDOTDIR/.p10k.zsh" ]]; then
        zsh_debug_echo "Run p10k configure or edit $ZDOTDIR/.p10k.zsh to configure your prompt"
else
    source "$ZDOTDIR/.p10k.zsh"
fi

if [[ $(_zqs-get-setting list-ssh-keys true) == 'true' ]]; then
    echo
        zsh_debug_echo "Current SSH Keys:"
    ssh-add -l
    echo
fi

if [[ $(_zqs-get-setting control-c-decorator 'true') == 'true' ]]; then
    # Original source: https://vinipsmaker.wordpress.com/2014/02/23/my-zsh-config/
    # bash prints ^C when you're typing a command and control-c to cancel, so it
    # is easy to see it wasn't executed. By default, ZSH doesn't print the ^C.
    # We trap SIGINT to make it print the ^C.
    TRAPINT() {
        print -n -u2 '^C'
        return $((128+$1))
    }
fi

if ! can_haz fzf; then
        zsh_debug_echo "You'll need to install fzf or your history search will be broken."
    echo
        zsh_debug_echo "Install instructions can be found at https://github.com/junegunn/fzf/"
fi

# =================================================================================
# === Self-Update and Profiling ===
# =================================================================================

# Do selfupdate checking. We do this after processing $ZDOTDIR/.zshrc.d to make the
# refresh check interval easier to customize.
#
# If they unset QUICKSTART_KIT_REFRESH_IN_DAYS in one of the fragments
# in $ZDOTDIR/.zshrc.d, then we don't do any selfupdate checking at all.

if [[ ! -z "$QUICKSTART_KIT_REFRESH_IN_DAYS" ]]; then
    _check-for-zsh-quickstart-update
fi

# ZQS profiling output
if [[ -f "$ZDOTDIR/.zqs-zprof-enabled" ]]; then
    zprof
fi

# =================================================================================
# === ZQS Integration Complete ===
# Performance optimizations preserved
# Security features maintained
# ZDOTDIR structure supported
# Full zqs command functionality enabled
# =================================================================================


# Herd injected PHP binary.
export PATH="/Users/s-a-c/Library/Application Support/Herd/bin/":$PATH


# Herd injected PHP 8.4 configuration.
export HERD_PHP_84_INI_SCAN_DIR="/Users/s-a-c/Library/Application Support/Herd/config/php/84/"


# Herd injected PHP 8.5 configuration.
export HERD_PHP_85_INI_SCAN_DIR="/Users/s-a-c/Library/Application Support/Herd/config/php/85/"
