# Core Environment Setup - New Generation ZSH Configuration
# This file handles essential environment variables and basic setup
# Load time target: <50ms

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
}

# Essential environment variables only - keep minimal for speed
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

# ZSH-specific environment
export ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
export ZSH_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh"

# Create cache and data directories if they don't exist
[[ ! -d "$ZSH_CACHE_DIR" ]] && mkdir -p "$ZSH_CACHE_DIR"
[[ ! -d "$ZSH_DATA_DIR" ]] && mkdir -p "$ZSH_DATA_DIR"

# History configuration - essential for all sessions
export HISTFILE="$ZSH_DATA_DIR/history"
export HISTSIZE="1000000"
export SAVEHIST="1000000"
export HISTDUP="erase"

# Essential shell options for immediate functionality
setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format
setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history
setopt HIST_FIND_NO_DUPS         # Do not display a previously found event
setopt HIST_IGNORE_ALL_DUPS      # Delete an old recorded event if a new event is a duplicate
setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again
setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space
setopt HIST_SAVE_NO_DUPS         # Do not write a duplicate event to the history file
setopt HIST_VERIFY               # Do not execute immediately upon history expansion
setopt SHARE_HISTORY             # Share history between all sessions

# Essential navigation options
setopt AUTO_CD                   # Change directory without cd command
setopt AUTO_PUSHD                # Make cd push the old directory onto the directory stack
setopt PUSHD_IGNORE_DUPS         # Don't push multiple copies of the same directory
setopt PUSHD_MINUS               # Exchanges meanings of +/- when used with a number

# Essential completion behavior
setopt COMPLETE_IN_WORD          # Complete from both ends of a word
setopt ALWAYS_TO_END             # Move cursor to the end of a completed word
setopt PATH_DIRS                 # Perform path search even on command names with slashes
setopt AUTO_MENU                 # Show completion menu on a successive tab press
setopt AUTO_LIST                 # Automatically list choices on ambiguous completion
setopt AUTO_PARAM_SLASH          # If completed parameter is a directory, add a trailing slash
setopt EXTENDED_GLOB             # Needed for file modification glob modifiers with compinit

# Disable problematic options that can slow down startup
unsetopt MENU_COMPLETE           # Do not autoselect the first completion entry
unsetopt FLOWCONTROL             # Disable start/stop characters in shell editor

# Create essential directories
[[ ! -d "$HISTFILE:h" ]] && mkdir -p "$HISTFILE:h"

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [00-core] Environment setup complete" >&2
