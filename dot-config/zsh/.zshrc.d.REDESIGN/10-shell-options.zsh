#!/usr/bin/env zsh
# ==============================================================================
# 05-SHELL-OPTIONS.ZSH - Centralized Shell Options (REDESIGN v2)
# ==============================================================================
# Purpose: Single source of truth for all setopt/unsetopt commands and
#          interactive shell configuration
# Consolidates: 00-centralized-shell-options.zsh and 05-interactive-options.zsh
# Load Order: Early (05-) after core infrastructure
# Author: ZSH Configuration Redesign System
# Created: 2025-09-22
# Version: 2.0.0
# ==============================================================================

# Prevent multiple loading
if [[ -n "${_SHELL_OPTIONS_REDESIGN:-}" ]]; then
    return 0
fi
export _SHELL_OPTIONS_REDESIGN=1

# Debug helper
_options_debug() {
    [[ -n "${ZSH_DEBUG:-}" ]] && zf::debug "[OPTIONS] $1" || true
}

_options_debug "Loading centralized shell options (v2.0.0)"

# ==============================================================================
# SECTION 1: UNIVERSAL OPTIONS (always set)
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

# === Prompt Configuration ===
setopt PROMPT_SUBST             # Allow parameter expansion in prompts (required for many prompt plugins)

_options_debug "Universal shell options configured (nounset disabled for plugin safety)"

# Enforce plugin-safe unset behavior at runtime too, in case any plugin enables nounset
# Also seed Starship status vars before any other precmd runs to avoid parameter-not-set
if [[ -o interactive ]]; then
    _zqs__enforce_no_nounset() { unsetopt UNSET; }
    _zqs__seed_starship_vars_precmd() {
        typeset -gi STARSHIP_CMD_STATUS 2>/dev/null || true
        STARSHIP_CMD_STATUS=${STARSHIP_CMD_STATUS:-0}
        typeset -ga STARSHIP_PIPE_STATUS 2>/dev/null || true
        : ${STARSHIP_PIPE_STATUS:=()}
    }
    _zqs__seed_starship_vars_preexec() {
        typeset -gi STARSHIP_CMD_STATUS 2>/dev/null || true
        STARSHIP_CMD_STATUS=${STARSHIP_CMD_STATUS:-0}
        typeset -ga STARSHIP_PIPE_STATUS 2>/dev/null || true
        : ${STARSHIP_PIPE_STATUS:=()}
    }
    typeset -ga precmd_functions 2>/dev/null || true
    typeset -ga preexec_functions 2>/dev/null || true
    # Prepend seeders so they run before any other hooks
    if (( ${precmd_functions[(I)_zqs__seed_starship_vars_precmd]} )); then
        :
    else
        precmd_functions=( _zqs__seed_starship_vars_precmd ${precmd_functions[@]} )
    fi
    if (( ${preexec_functions[(I)_zqs__seed_starship_vars_preexec]} )); then
        :
    else
        preexec_functions=( _zqs__seed_starship_vars_preexec ${preexec_functions[@]} )
    fi
    # Ensure nounset is disabled at the start of both hooks
    if (( ${precmd_functions[(I)_zqs__enforce_no_nounset]} )); then
        :
    else
        precmd_functions=( _zqs__enforce_no_nounset ${precmd_functions[@]} )
    fi
    if (( ${preexec_functions[(I)_zqs__enforce_no_nounset]} )); then
        :
    else
        preexec_functions=( _zqs__enforce_no_nounset ${preexec_functions[@]} )
    fi
fi


# ==============================================================================
# SECTION 2: INTERACTIVE-ONLY OPTIONS
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

    # === Command Correction and Expansion ===
    setopt CORRECT                  # Try to correct the spelling of commands
    setopt GLOB_COMPLETE            # Generate glob patterns as completion matches

    # === Job Control ===
    setopt LONG_LIST_JOBS           # List jobs in the long format by default
    setopt AUTO_RESUME              # Attempt to resume existing job before creating a new process
    setopt NOTIFY                   # Report status of background jobs immediately
    setopt BG_NICE                  # Run all background jobs at a lower priority
    setopt HUP                      # Send SIGHUP to running jobs when shell exits

    # === Input/Output Enhancement ===
    setopt INTERACTIVE_COMMENTS     # Allow comments in interactive shell
    setopt RC_QUOTES               # Allow 'Henry''s Garage' instead of 'Henry'\\''s Garage'
    setopt COMBINING_CHARS          # Combine zero-length punctuation characters (accents) with the base character

    # === Flow Control ===
    setopt NO_FLOW_CONTROL          # Disable flow control commands (C-s/C-q)

    # === Sound and Visual Feedback ===
    setopt NO_BEEP                  # Don't beep on error

    _options_debug "Interactive shell options configured"
else
    _options_debug "Non-interactive shell - interactive options skipped"
fi

# ==============================================================================
# SECTION 3: PLUGIN-SPECIFIC SAFETY OPTIONS
# ==============================================================================

# Ensure ZLE is enabled for interactive sessions (if available)
if [[ -o interactive ]] && command -v zle >/dev/null 2>&1; then
    # Only attempt to set ZLE if it's not explicitly disabled
    if ! [[ -o NO_ZLE ]]; then
        setopt ZLE 2>/dev/null || _options_debug "ZLE enablement failed (this is normal in some environments)"
    fi
fi

_options_debug "Plugin-safe options configured"

# ==============================================================================
# SECTION 4: AUTOSUGGESTIONS INTEGRATION
# ==============================================================================

# Autosuggestions configuration (consolidated from autosuggestions-enablement)
if [[ -o interactive ]]; then
    # Configure autosuggestions behavior
    export ZSH_AUTOSUGGEST_MANUAL_REBIND="${ZSH_AUTOSUGGEST_MANUAL_REBIND:-1}"
    export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="${ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE:-20}"
    export ZSH_AUTOSUGGEST_USE_ASYNC="${ZSH_AUTOSUGGEST_USE_ASYNC:-1}"
    export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    export ZSH_AUTOSUGGEST_COMPLETION_IGNORE="git *"
    export ZSH_AUTOSUGGEST_HISTORY_IGNORE="${ZSH_AUTOSUGGEST_HISTORY_IGNORE:-"(cd *|ls *|ll *|la *)"}"

    # Dynamic autosuggestions control based on terminal performance
    if [[ "${TERM:-}" =~ ^(dumb|emacs|screen\.linux)$ ]]; then
        export ZSH_AUTOSUGGEST_DISABLE=1
        _options_debug "Autosuggestions disabled for terminal: $TERM"
    elif [[ -n "${SSH_CLIENT:-}" ]] && [[ "${ZSH_AUTOSUGGEST_SSH_DISABLE:-0}" == "1" ]]; then
        export ZSH_AUTOSUGGEST_DISABLE=1
        _options_debug "Autosuggestions disabled for SSH session"
    else
        _options_debug "Autosuggestions configured for optimal performance"
    fi
fi

# ==============================================================================
# SECTION 5: VALIDATION AND SAFETY CHECKS
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

    # Check that prompt substitution is enabled
    if [[ -o PROMPT_SUBST ]]; then
        _options_debug "✅ PROMPT_SUBST is enabled"
    else
        _options_debug "⚠️  PROMPT_SUBST is disabled - may break prompts"
        validation_failed=1
    fi

    return $validation_failed
}

# Run validation
_validate_plugin_safety

# ==============================================================================
# SECTION 6: ENVIRONMENT-SPECIFIC ADJUSTMENTS
# ==============================================================================

# Terminal-specific optimizations
case "${TERM:-}" in
    screen*|tmux*)
        # Screen/tmux specific settings
        setopt NO_AUTO_NAME_DIRS    # Don't auto-add variable names to directory stack
        _options_debug "Applied screen/tmux optimizations"
        ;;
    xterm*|alacritty|wezterm|kitty)
        # Modern terminal optimizations
        setopt COMBINING_CHARS      # Better unicode support
        _options_debug "Applied modern terminal optimizations"
        ;;
esac

# macOS-specific options
if [[ "$(uname -s)" == "Darwin" ]]; then
    # macOS terminal integration
    _options_debug "Applied macOS-specific options"
fi

# ==============================================================================
# MODULE COMPLETION
# ==============================================================================

export SHELL_OPTIONS_VERSION="2.0.0"
export SHELL_OPTIONS_LOADED_AT="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'unknown')"

_options_debug "Centralized shell options configuration complete"

# Clean up helper function
unset -f _options_debug _validate_plugin_safety

# ==============================================================================
# END OF SHELL OPTIONS MODULE
# ==============================================================================
