#!/usr/bin/env zsh
# LEGACY STUB: 60-macos-integration.zsh (migrated to 180-macos-integration.zsh)
return 0
        MACOS_VERSION_MINOR="${macos_version#*.}"
        MACOS_VERSION_MINOR="${MACOS_VERSION_MINOR%%.*}"
        export MACOS_VERSION_MAJOR MACOS_VERSION_MINOR
        zf::debug "[MACOS] Detected macOS version: $MACOS_VERSION_MAJOR.$MACOS_VERSION_MINOR"
    fi
fi

# ==============================================================================
# SECTION 2: HOMEBREW INTEGRATION
# ==============================================================================

# Enhanced Homebrew integration (already handled in path-safety, but reinforce)
if command -v brew >/dev/null 2>&1; then
    # Set Homebrew environment if not already set
    if [[ -z "${HOMEBREW_PREFIX:-}" ]]; then
        export HOMEBREW_PREFIX="$(brew --prefix 2>/dev/null)"
        zf::debug "[MACOS] Set HOMEBREW_PREFIX: $HOMEBREW_PREFIX"
    fi

    # Homebrew optimization settings
    export HOMEBREW_NO_ANALYTICS="${HOMEBREW_NO_ANALYTICS:-1}"
    export HOMEBREW_NO_AUTO_UPDATE="${HOMEBREW_NO_AUTO_UPDATE:-1}"
    export HOMEBREW_CLEANUP_PERIODIC_FULL_DAYS="${HOMEBREW_CLEANUP_PERIODIC_FULL_DAYS:-30}"

    # Homebrew shell environment (if not already loaded)
    if [[ -z "${HOMEBREW_SHELLENV_PREFIX:-}" ]] && [[ -x "$HOMEBREW_PREFIX/bin/brew" ]]; then
        eval "$("$HOMEBREW_PREFIX/bin/brew" shellenv)"
        export HOMEBREW_SHELLENV_PREFIX="$HOMEBREW_PREFIX"
        zf::debug "[MACOS] Loaded Homebrew shell environment"
    fi
else
    zf::debug "[MACOS] Homebrew not detected"
fi

# ==============================================================================
# SECTION 3: MACOS-SPECIFIC PATH ADDITIONS
# ==============================================================================

# Add macOS-specific paths that might not be in base PATH
local -a macos_paths=(
    "/usr/local/MacGPG2/bin"        # GPG Tools
    "/Library/TeX/texbin"           # LaTeX/TeXLive
    "/Applications/Postgres.app/Contents/Versions/latest/bin"  # Postgres.app
    "/opt/X11/bin"                  # X11 (if installed)
)

for macos_path in "${macos_paths[@]}"; do
    if [[ -d "$macos_path" ]] && [[ ":$PATH:" != *":$macos_path:"* ]]; then
        export PATH="$PATH:$macos_path"
        zf::debug "[MACOS] Added macOS path: $macos_path"
    fi
done

# ==============================================================================
# SECTION 4: MACOS SECURITY AND PRIVACY
# ==============================================================================

# macOS security settings for development
if [[ "${MACOS_DEV_SECURITY:-1}" == "1" ]]; then
    # Disable Gatekeeper path randomization for consistent development
    export OBJC_DISABLE_INITIALIZE_FORK_SAFETY="${OBJC_DISABLE_INITIALIZE_FORK_SAFETY:-YES}"
    zf::debug "[MACOS] Set development security environment"
fi

# ==============================================================================
# SECTION 5: MACOS COMMAND LINE TOOLS
# ==============================================================================

# Ensure Xcode command line tools are properly configured
if xcode-select -p >/dev/null 2>&1; then
    export XCODE_DEVELOPER_PATH="$(xcode-select -p 2>/dev/null)"
    zf::debug "[MACOS] Xcode developer path: $XCODE_DEVELOPER_PATH"
else
    zf::debug "[MACOS] Xcode command line tools not installed or not configured"
fi

# ==============================================================================
# SECTION 6: MACOS DEFAULTS (DEFERRED SETUP)
# ==============================================================================

# Register macOS defaults for lazy loading (now using zf:: namespace)
if command -v zf::lazy_register >/dev/null 2>&1; then
    zf::lazy_register macos-defaults zf::macos_defaults_load
    zf::debug "[MACOS] macOS defaults registered for lazy loading via zf:: namespace"
else
    # Fallback to legacy lazy framework if available
    if command -v lazy_register >/dev/null 2>&1; then
        # Create legacy wrapper for zf:: function
        _load_macos_defaults() { zf::macos_defaults_load "$@"; }
        lazy_register macos-defaults _load_macos_defaults
        zf::debug "[MACOS] macOS defaults registered for lazy loading via legacy framework"
    else
        zf::debug "[MACOS] No lazy framework available, skipping deferred defaults"
    fi
fi

# ==============================================================================
# SECTION 7: MACOS CLIPBOARD INTEGRATION
# ==============================================================================

# Clipboard aliases (pbcopy/pbpaste should be available by default)
if command -v pbcopy >/dev/null 2>&1 && command -v pbpaste >/dev/null 2>&1; then
    export MACOS_CLIPBOARD_AVAILABLE=1
    zf::debug "[MACOS] macOS clipboard utilities available"
else
    zf::debug "[MACOS] macOS clipboard utilities not available"
fi

# ==============================================================================
# SECTION 8: MACOS TERMINAL INTEGRATION
# ==============================================================================

# Terminal.app and iTerm2 integration
case "${TERM_PROGRAM:-}" in
    "Apple_Terminal")
        export TERMINAL_APP="Terminal"
        zf::debug "[MACOS] Running in Terminal.app"
        ;;
    "iTerm.app")
        export TERMINAL_APP="iTerm2"
        zf::debug "[MACOS] Running in iTerm2"
        # iTerm2 shell integration (if available and not loaded)
        if [[ -e "$HOME/.iterm2_shell_integration.zsh" ]] && [[ -z "${ITERM_SHELL_INTEGRATION_INSTALLED:-}" ]]; then
            source "$HOME/.iterm2_shell_integration.zsh"
            zf::debug "[MACOS] Loaded iTerm2 shell integration"
        fi
        ;;
    *)
        export TERMINAL_APP="Other"
        zf::debug "[MACOS] Running in terminal: ${TERM_PROGRAM:-unknown}"
        ;;
esac

# ==============================================================================
# SECTION 9: MACOS PERFORMANCE OPTIMIZATION
# ==============================================================================

# macOS-specific performance settings
if [[ "${MACOS_PERFORMANCE_MODE:-1}" == "1" ]]; then
    # Disable crash reporter dialog
    export CRASHREPORTER_DISABLE_DIALOG="${CRASHREPORTER_DISABLE_DIALOG:-1}"

    # Reduce Motion (can help with terminal performance)
    if [[ "${MACOS_REDUCE_MOTION:-0}" == "1" ]]; then
        defaults write com.apple.universalaccess reduceMotion -bool true 2>/dev/null || true
        zf::debug "[MACOS] Enabled reduce motion for performance"
    fi
fi

# ==============================================================================
# NAMESPACE MIGRATION COMPLETE
# ==============================================================================
# All functions migrated to zf:: namespace. Use zf::macos_* functions directly.

# ==============================================================================
# MODULE COMPLETION
# ==============================================================================

export MACOS_INTEGRATION_VERSION="2.0.0"
export MACOS_INTEGRATION_LOADED_AT="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'unknown')"

zf::debug "[MACOS] macOS integration ready"

# Legacy functions removed - using zf:: namespace directly

# ==============================================================================
# END OF MACOS INTEGRATION MODULE
# ==============================================================================
