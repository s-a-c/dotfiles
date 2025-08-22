# Early completion system initialization
# Ensures compdef is available before plugins load

[[ "$ZSH_DEBUG" == "1" ]] && printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2

# Load and initialize the completion system early
autoload -U compinit

# Fast completion initialization (skip security check for performance)
# Only do a full security check once a day
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit -d "${ZDOTDIR:-$HOME}/.zcompdump"
else
    compinit -C -d "${ZDOTDIR:-$HOME}/.zcompdump"
fi

# Ensure completion functions are in fpath
if [[ -d "${ZDOTDIR:-$PWD}/completions" ]]; then
  fpath=("${ZDOTDIR:-$PWD}/completions" $fpath)
fi

[[ "$ZSH_DEBUG" == "1" ]] && echo "# Completion system initialized early" >&2
