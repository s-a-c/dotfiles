#!/usr/bin/env zsh
# ==============================================================================
# CENTRALIZED SHELL OPTIONS CONFIGURATION
# ==============================================================================
# Purpose: Single source of truth for all setopt/unsetopt commands
# Load Order: Early post-plugin (00) to set options after plugin initialization
# Author: ZSH Configuration Consolidation
# Created: 2025-09-21
# Version: 1.0.0
# ==============================================================================

# Prevent multiple loading
if [[ -n "${_CENTRALIZED_OPTIONS_LOADED:-}" ]]; then
    return 0
fi
export _CENTRALIZED_OPTIONS_LOADED=1

# Debug helper
_options_debug() {
    if [[ -n "${ZSH_DEBUG:-}" ]]; then
        echo "[OPTS-DEBUG] $1" >&2
    fi
}

_options_debug "Loading centralized shell options..."

# ==============================================================================
# UNIVERSAL OPTIONS (always set, regardless of interactive state)
# ==============================================================================

# === Globbing Options ===
setopt EXTENDED_GLOB            # Use extended globbing syntax
setopt GLOB_DOTS                # Include dotfiles in glob patterns  
setopt NUMERIC_GLOB_SORT        # Sort filenames numerically when it makes sense
setopt NO_CASE_GLOB             # Case insensitive globbing

# === Error Handling and Safety ===
# IMPORTANT: NO_UNSET (nounset) is explicitly DISABLED for plugin compatibility
# Many plugins and zsh functions rely on unset variables being empty strings
unsetopt UNSET                  # Allow referencing undefined variables (plugin-safe)
setopt PIPE_FAIL                # Return exit code of rightmost command to exit with non-zero status

# === Path and File Handling ===
setopt PATH_DIRS                # Perform path search even on command names with slashes

_options_debug "Universal shell options configured (nounset disabled for plugin safety)"

# ==============================================================================
# INTERACTIVE-ONLY OPTIONS
# ==============================================================================

if [[ -o interactive ]]; then
    _options_debug "Configuring interactive shell options..."
    
    # === History Management ===
    setopt HIST_VERIFY              # Show command with history expansion to user before running it
    setopt HIST_EXPIRE_DUPS_FIRST   # Delete duplicates first when HISTFILE size exceeds HISTSIZE
    setopt HIST_IGNORE_DUPS         # Don't record an entry that was just recorded again
    setopt HIST_IGNORE_ALL_DUPS     # Delete old recorded entry if new entry is a duplicate
    setopt HIST_FIND_NO_DUPS        # Don't display a line previously found
    setopt HIST_IGNORE_SPACE        # Don't record an entry starting with a space
    setopt HIST_SAVE_NO_DUPS        # Don't write duplicate entries in the history file
    setopt HIST_REDUCE_BLANKS       # Remove superfluous blanks before recording entry
    setopt SHARE_HISTORY            # Share history between all sessions
    setopt EXTENDED_HISTORY         # Write the history file in the ":start:elapsed;command" format

    # === Directory Navigation ===
    setopt AUTO_CD                  # If command is a directory name, cd to it
    setopt AUTO_PUSHD               # Make cd push the old directory onto the directory stack
    setopt PUSHD_IGNORE_DUPS        # Don't push the same dir twice
    setopt PUSHD_MINUS              # Exchanges the meanings of '+' and '-' with pushd
    setopt CDABLE_VARS              # If argument to cd is not a directory, try expanding it as variable

    # === Completion System ===
    setopt COMPLETE_IN_WORD         # Complete from both ends of a word
    setopt ALWAYS_TO_END            # Move cursor to the end of a completed word
    setopt AUTO_MENU                # Show completion menu on a successive tab press
    setopt AUTO_LIST                # Automatically list choices on ambiguous completion
    setopt AUTO_PARAM_SLASH         # If completed parameter is a directory, add a trailing slash
    setopt MENU_COMPLETE            # Insert the first completion match immediately

    # === Command Correction and Expansion ===
    setopt CORRECT                  # Try to correct the spelling of commands
    setopt CORRECT_ALL              # Try to correct the spelling of all arguments in a line
    setopt GLOB_COMPLETE            # Generate glob patterns as completion matches

    # === Job Control ===
    setopt LONG_LIST_JOBS           # List jobs in the long format by default
    setopt AUTO_RESUME              # Attempt to resume existing job before creating a new process
    setopt NOTIFY                   # Report status of background jobs immediately
    setopt BG_NICE                  # Run all background jobs at a lower priority
    setopt HUP                      # Send SIGHUP to running jobs when shell exits

    # === Input/Output Enhancement ===
    setopt INTERACTIVE_COMMENTS     # Allow comments in interactive shell
    setopt RC_QUOTES               # Allow 'Henry''s Garage' instead of 'Henry'\''s Garage'
    setopt COMBINING_CHARS          # Combine zero-length punctuation characters (accents) with the base character
    
    _options_debug "Interactive shell options configured"
else
    _options_debug "Non-interactive shell - interactive options skipped"
fi

# ==============================================================================
# PLUGIN-SPECIFIC SAFETY OPTIONS
# ==============================================================================
# These options are set specifically to ensure compatibility with common plugins

# Ensure ZLE is enabled for interactive sessions (if available)
if [[ -o interactive ]] && command -v zle >/dev/null 2>&1; then
    # Only attempt to set ZLE if it's not explicitly disabled
    if ! [[ -o NO_ZLE ]]; then
        setopt ZLE 2>/dev/null || _options_debug "ZLE enablement failed (this is normal in some environments)"
    fi
fi

# Ensure proper expansion behavior for plugins
setopt PROMPT_SUBST             # Allow parameter expansion in prompts (required for many prompt plugins)

_options_debug "Plugin-safe options configured"

# ==============================================================================
# VALIDATION AND SAFETY CHECKS
# ==============================================================================

# Verify critical plugin-safety options
_validate_plugin_safety() {
    local validation_failed=0
    
    # Check that nounset is disabled
    if [[ -o UNSET ]]; then
        _options_debug "⚠️  UNSET (nounset) is enabled - this may break plugins!"
        validation_failed=1
    else
        _options_debug "✅ UNSET (nounset) is disabled - plugin-safe"
    fi
    
    # Check that extended globbing is enabled (required by many plugins)
    if [[ -o EXTENDED_GLOB ]]; then
        _options_debug "✅ EXTENDED_GLOB is enabled"
    else
        _options_debug "⚠️  EXTENDED_GLOB is disabled - may cause issues"
        validation_failed=1
    fi
    
    return $validation_failed
}

# Run validation
_validate_plugin_safety

# ==============================================================================
# EXPORT MODULE METADATA
# ==============================================================================

export CENTRALIZED_OPTIONS_VERSION="1.0.0"
export CENTRALIZED_OPTIONS_LOADED="$(date '+%Y-%m-%d %H:%M:%S')"

_options_debug "Centralized shell options configuration complete"

# Clean up helper function
unset -f _options_debug _validate_plugin_safety

# ==============================================================================
# END OF CENTRALIZED SHELL OPTIONS
# ==============================================================================