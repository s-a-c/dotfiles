# ZSH Core Environment Setup - PRE-PLUGIN PHASE
# This file consolidates essential environment setup that must happen before plugins
# CONSOLIDATED FROM: 000-emergency-system-fix.zsh + 010-setopt.zsh + 020-secure-env.zsh

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
    echo "# [core-environment] Essential system and environment setup" >&2
}

## [core-environment.emergency-system] - Critical system command availability
# MERGED FROM: 000-emergency-system-fix.zsh
# These MUST be available immediately for system stability

# IMMEDIATELY export system PATH to ensure commands are available
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/local/sbin:$PATH"

# Add developer tools IMMEDIATELY
[[ -d "/Applications/Xcode.app/Contents/Developer/usr/bin" ]] && export PATH="/Applications/Xcode.app/Contents/Developer/usr/bin:$PATH"
[[ -d "/Library/Developer/CommandLineTools/usr/bin" ]] && export PATH="/Library/Developer/CommandLineTools/usr/bin:$PATH"

# PATH is now properly managed in .zshenv - no function wrappers needed

# Export build environment variables IMMEDIATELY
export CC="/usr/bin/cc"
export CXX="/usr/bin/c++"
export CPP="/usr/bin/cpp"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

# Ensure DEVELOPER_DIR exists
[[ ! -d "$DEVELOPER_DIR" && -d "/Library/Developer/CommandLineTools" ]] && export DEVELOPER_DIR="/Library/Developer/CommandLineTools"

## [core-environment.shell-options] - Essential shell behavior
# MERGED FROM: 010-setopt.zsh
# Core shell options that must be set before plugins load

# History options
setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format
setopt HIST_EXPIRE_DUPS_FIRST   # Expire a duplicate event first when trimming history
setopt HIST_FIND_NO_DUPS        # Do not display a previously found event
setopt HIST_IGNORE_ALL_DUPS     # Delete an old recorded event if a new event is a duplicate
setopt HIST_IGNORE_DUPS         # Do not record an event that was just recorded again
setopt HIST_IGNORE_SPACE        # Do not record an event starting with a space
setopt HIST_SAVE_NO_DUPS        # Do not write a duplicate event to the history file
setopt HIST_VERIFY              # Do not execute immediately upon history expansion
setopt INC_APPEND_HISTORY       # Write to the history file immediately, not when the shell exits
setopt SHARE_HISTORY            # Share history between all sessions

# Directory options
setopt AUTO_CD                  # If a command is not found, and there is a directory whose name is the command, cd to that directory
setopt AUTO_PUSHD              # Make cd push the old directory onto the directory stack
setopt PUSHD_IGNORE_DUPS       # Don't push multiple copies of the same directory onto the directory stack
setopt PUSHD_SILENT            # Do not print the directory stack after pushd or popd

# Completion options (basic ones needed before plugins)
setopt AUTO_LIST               # Automatically list choices on an ambiguous completion
setopt AUTO_MENU               # Show completion menu on successive tab press
setopt AUTO_PARAM_SLASH        # If a parameter is completed whose content is the name of a directory, then add a trailing slash
setopt COMPLETE_IN_WORD        # Complete from both ends of a word
setopt HASH_LIST_ALL           # Whenever a command completion is attempted, make sure the entire command path is hashed first

# Globbing options
setopt EXTENDED_GLOB           # Use extended globbing syntax
setopt GLOB_DOTS              # Do not require a leading '.' in a filename to be matched explicitly
setopt NO_CASE_GLOB           # Case insensitive globbing
setopt NUMERIC_GLOB_SORT      # Sort filenames numerically when it makes sense

# General options
setopt CORRECT                # Try to correct the spelling of commands
setopt INTERACTIVECOMMENTS    # Allow comments even in interactive shells
setopt NO_BEEP               # Don't beep on error
setopt PROMPT_SUBST          # Enable parameter expansion, command substitution, and arithmetic expansion in prompts
setopt TRANSIENT_RPROMPT     # Remove right prompt when command is executed

## [core-environment.security] - Security and environment protection
# MERGED FROM: 020-secure-env.zsh
# Security settings that must be established early

# Secure PATH construction - prevent PATH injection
typeset -gU path PATH          # Keep PATH unique and global
typeset -gU fpath FPATH        # Keep FPATH unique and global

# Secure environment variable handling
export TMPDIR="${TMPDIR:-/tmp}"
export TMP="${TMP:-$TMPDIR}"
export TEMP="${TEMP:-$TMPDIR}"

# Secure umask
umask 022

# Prevent core dumps for security
ulimit -c 0 2>/dev/null

# Secure history settings
export HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
export HISTSIZE=50000
export SAVEHIST=50000

# Secure temporary directories
[[ ! -d "$TMPDIR" ]] && mkdir -p "$TMPDIR" && chmod 755 "$TMPDIR"

## [core-environment.build-environment] - Development environment setup
# Configure development environment for optimal builds

# Rust build environment configuration
setup_rust_environment() {
    # Set up Cargo environment for faster builds
    [[ -z "$CARGO_TARGET_DIR" ]] && {
        export CARGO_TARGET_DIR="/tmp/cargo-builds"
        mkdir -p "$CARGO_TARGET_DIR" 2>/dev/null
    }

    # Set up SDK path for macOS builds
    if [[ "$(uname -s 2>/dev/null)" == "Darwin" ]]; then
        export CARGO_BUILD_TARGET_DIR="$CARGO_TARGET_DIR"

        # Set up SDK path if xcrun is available
        if command -v xcrun >/dev/null 2>&1; then
            local sdk_path
            sdk_path="$(xcrun --show-sdk-path 2>/dev/null)"
            [[ -n "$sdk_path" && -d "$sdk_path" ]] && export SDKROOT="$sdk_path"
        fi
    fi

    return 0
}

# Only set up Rust environment if we have basic tools available
if command -v cc >/dev/null 2>&1 && command -v uname >/dev/null 2>&1; then
    setup_rust_environment
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [core-environment] Rust build environment configured" >&2
fi

## [core-environment.variables] - Essential environment variables
# Pre-declare variables that will be set by plugins to avoid warnings
typeset -g BUN_INSTALL="${BUN_INSTALL:-${XDG_DATA_HOME:-$HOME/.local/share}/bun}"
typeset -g DOTNET_CLI_HOME="${DOTNET_CLI_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/dotnet}"
typeset -g DOTNET_ROOT="${DOTNET_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/dotnet}"
typeset -g NVM_SCRIPT_SOURCE="${NVM_SCRIPT_SOURCE:-}"
typeset -g SSH_AGENT_PID="${SSH_AGENT_PID:-}"

## [core-environment.health-check] - System health verification
emergency_health_check() {
    local critical_commands=("sed" "tr" "uname" "dirname" "basename" "cat" "cc")
    local available_commands=()

    for cmd in "${critical_commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            available_commands+=("$cmd")
        fi
    done

    if [[ ${#available_commands[@]} -eq ${#critical_commands[@]} ]]; then
        [[ "$ZSH_DEBUG" == "1" ]] && echo "✅ All critical system commands available" >&2
        return 0
    else
        echo "⚠️  Missing critical commands: $(printf '%s ' "${critical_commands[@]}")" >&2
        echo "⚠️  Available commands: $(printf '%s ' "${available_commands[@]}")" >&2
        return 1
    fi
}

# Run health check
emergency_health_check

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [core-environment] ✅ Core environment, security, and system setup completed" >&2
