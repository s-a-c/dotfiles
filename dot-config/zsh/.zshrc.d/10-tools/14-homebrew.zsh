# Homebrew Configuration
# This file configures Homebrew for optimal performance
# Load time target: <50ms

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
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
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [homebrew] Homebrew not found" >&2
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

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [10-tools] Homebrew configured ($HOMEBREW_PREFIX)" >&2
