
[[ -n "$ZSH_DEBUG" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
    # Add this check to detect errant file creation:
    if [[ -f "${ZDOTDIR:-$HOME}/2" ]] || [[ -f "${ZDOTDIR:-$HOME}/3" ]]; then
        echo "Warning: Numbered files detected - check for redirection typos" >&2
    fi
}

# compinit execution guard - ensure only one execution per session
init_completion_once() {
    [[ -n "$_ZSH_COMPLETION_INITIALIZED" ]] && return 0
    autoload -Uz compinit
    compinit -d "$ZSH_COMPDUMP"
    export _ZSH_COMPLETION_INITIALIZED=1
}
init_completion_once
