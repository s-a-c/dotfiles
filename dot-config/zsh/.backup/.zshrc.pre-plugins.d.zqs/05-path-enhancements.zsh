#!/usr/bin/env zsh
# 05-path-enhancements.zsh - Enhanced PATH management for ZQS
# Part of the migration to symlinked ZQS .zshrc

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
        zf::debug "# [pre-plugin-ext] Added Homebrew sbin to PATH: ${BREW_PREFIX}/sbin"
    fi

    # Skip bin directory - already prioritized in .zshenv as /opt/homebrew/bin
    # if [[ -d "${BREW_PREFIX}/bin" ]]; then
    #     export PATH="$PATH:${BREW_PREFIX}/bin"  # REMOVED - redundant
    # fi
fi

zf::debug "# [pre-plugin-ext] PATH enhancements loaded"
