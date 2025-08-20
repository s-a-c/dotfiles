#!/usr/bin/env zsh
# zgenom initialization - ensures zgenom is properly loaded
# This must run after fpath setup but before plugin loading

# Only proceed if ZGEN_SOURCE is set and exists
if [[ -z "${ZGEN_SOURCE}" ]] || [[ ! -d "${ZGEN_SOURCE}" ]]; then
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [zgenom-init] ZGEN_SOURCE not set or invalid, skipping zgenom initialization" >&2
    return 1
fi

# Autoload all zgenom functions from the functions directory
if [[ -d "${ZGEN_SOURCE}/functions" ]]; then
    # Load core zgenom functions
    for func in "${ZGEN_SOURCE}/functions"/*; do
        if [[ -r "$func" ]]; then
            autoload -Uz "${func:t}"
        fi
    done
    
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [zgenom-init] Autoloaded zgenom functions from ${ZGEN_SOURCE}/functions" >&2
fi

# Source zgenom.zsh to set up the main zgenom function
if [[ -r "${ZGEN_SOURCE}/zgenom.zsh" ]]; then
    source "${ZGEN_SOURCE}/zgenom.zsh"
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [zgenom-init] Sourced zgenom.zsh" >&2
else
    echo "Warning: Cannot find zgenom.zsh at ${ZGEN_SOURCE}/zgenom.zsh" >&2
fi
