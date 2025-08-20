#!/usr/bin/env zsh
# zgenom fpath setup - ensures zgenom functions directory is in fpath
# This must run before zgenom is loaded to prevent autoload errors

# Set zgenom source directory - use the one from .zshenv
if [[ -z "${ZGEN_SOURCE}" ]]; then
    # Primary location from .zshenv should be available
    export ZGEN_SOURCE="${ZDOTDIR}/zgenom"
fi

# Verify ZGEN_SOURCE points to correct directory
if [[ ! -d "${ZGEN_SOURCE}/functions" ]]; then
    echo "Warning: ZGEN_SOURCE=${ZGEN_SOURCE} does not contain functions directory" >&2
    # Try fallback locations
    local possible_locations=(
        "${ZDOTDIR}/zgenom"
        "$HOME/.config/zsh/zgenom" 
        "$HOME/dotfiles/dot-config/zsh/zgenom"
    )
    
    for location in "${possible_locations[@]}"; do
        if [[ -d "$location/functions" ]]; then
            export ZGEN_SOURCE="$location"
            echo "Using zgenom from: $location" >&2
            break
        fi
    done
fi

# Ensure zgenom functions directory exists and is readable
if [[ -d "${ZGEN_SOURCE}/functions" && -r "${ZGEN_SOURCE}/functions" ]]; then
    # Add zgenom functions directory to fpath if not already present
    if [[ ! " ${fpath[*]} " =~ " ${ZGEN_SOURCE}/functions " ]]; then
        fpath=("${ZGEN_SOURCE}/functions" $fpath)
        
        # Debug output (enable with: export ZSH_DEBUG_FPATH=1)
        if [[ -n "${ZSH_DEBUG_FPATH}" ]]; then
            echo "[DEBUG] Added ${ZGEN_SOURCE}/functions to fpath"
            echo "[DEBUG] fpath now contains: ${fpath[1,5]} ..."
        fi
    fi
else
    # Warn if zgenom functions directory is missing
    echo "Warning: zgenom functions directory not found or not readable: ${ZGEN_SOURCE}/functions" >&2
fi

# Verify critical zgenom functions are available for autoload
for func in __zgenom __zgenom_out __zgenom_err; do
    if [[ ! -f "${ZGEN_SOURCE}/functions/${func}" ]]; then
        echo "Warning: Missing zgenom function file: ${ZGEN_SOURCE}/functions/${func}" >&2
    fi
done

# Export for use by zgenom.zsh
export ZGEN_SOURCE
