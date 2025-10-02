#!/usr/bin/env zsh
# ==============================================================================
# ZSH Configuration: Ensure Homebrew Git Takes Precedence
# ==============================================================================
# Purpose: Force Homebrew git to be used instead of Apple's git
# Priority: Critical - fixes "command not found: git" issues with plugins
# Load Order: Early (00_02) to run before plugin initialization
# ==============================================================================

zf::debug "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
#!/usr/bin/env zsh
# Homebrew Configuration
# This file configures Homebrew for optimal performance
# Load time target: <50ms

[[ "$ZSH_DEBUG" == "1" ]] && {
        zf::debug "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
}

# Homebrew paths - check common installation locations
if [[ -x "/opt/homebrew/bin/brew" ]]; then
    # Apple Silicon Mac
    HOMEBREW_PREFIX="/opt/homebrew"
elif [[ -x "/usr/local/bin/brew" ]]; then
    # Intel Mac
    HOMEBREW_PREFIX="/usr/local"
else
    # Homebrew not found
    zf::debug "# [homebrew] Homebrew not found"
    return 0
fi

# Add Homebrew to PATH
_path_prepend "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin"

# Essential Homebrew environment variables
export HOMEBREW_PREFIX
export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX"

# Performance optimizations
export HOMEBREW_NO_AUTO_UPDATE=1        # Disable auto-update for faster commands
export HOMEBREW_NO_ANALYTICS=1          # Disable analytics
export HOMEBREW_NO_INSECURE_REDIRECT=1  # Security
export HOMEBREW_CASK_OPTS="--require-sha"  # Security for casks

# Completion setup (will be handled by completion system)
if [[ -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]]; then
    fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
fi

# Add Homebrew-installed packages to PATH if they exist
homebrew_tool_paths=(
    "$HOMEBREW_PREFIX/opt/go/bin"
    "$HOMEBREW_PREFIX/opt/php/bin"
    "$HOMEBREW_PREFIX/share/npm/bin"
)

for tool_path in "${homebrew_tool_paths[@]}"; do
    [[ -d "$tool_path" ]] && _path_prepend "$tool_path"
done

# Ensure Homebrew git takes precedence over Apple git
if [[ -x "$HOMEBREW_PREFIX/bin/git" ]]; then
    # Use proper _field functions now that they're fixed for ZSH

    # Remove system git paths temporarily to reorder them
    _field_remove PATH "/usr/bin"
    _field_remove PATH "/Applications/Xcode.app/Contents/Developer/usr/bin"
    _field_remove PATH "/Library/Developer/CommandLineTools/usr/bin"

    # Ensure Homebrew git comes first
    _field_prepend PATH "/opt/homebrew/bin"

    # Re-add system paths after Homebrew (so Homebrew takes precedence)
    _field_append PATH "/usr/bin"
    _field_append PATH "/Applications/Xcode.app/Contents/Developer/usr/bin"
    _field_append PATH "/Library/Developer/CommandLineTools/usr/bin"

    # Verify git is now Homebrew version
    if command -v git >/dev/null 2>&1; then
        local git_version=$(git --version 2>/dev/null)
        if [[ "$git_version" == *"2.51.0"* ]]; then
            zf::debug "✅ Homebrew git (2.51.0) now active"
        else
            zf::debug "⚠️  Warning: git version is $git_version, expected Homebrew 2.51.0"
        fi
    fi
else
    zf::debug "⚠️  Homebrew git not found at $HOMEBREW_PREFIX/bin/git"
fi

zf::debug "# [00_02] Git priority configuration complete"
