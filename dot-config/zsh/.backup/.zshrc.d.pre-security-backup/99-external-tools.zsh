#!/usr/bin/env zsh
# External tool additions (wrapped for conditional loading)

# Skip if disabled
[[ "${SKIP_EXTERNAL_TOOLS:-0}" == "1" ]] && return 0

# Skip if already loaded
[[ -n "${_EXTERNAL_TOOLS_LOADED:-}" ]] && return 0
export _EXTERNAL_TOOLS_LOADED=1

# Load with timeout protection
() {
    local external_file="${HOME}/dotfiles/dot-config/zsh/.zshrc.d/99-external-tools.zsh.original"
    if [[ -f "$external_file" ]]; then
        # Use a subshell with timeout to prevent hangs
        ( 
            # Set a 2-second timeout for external tool loading
            if command -v timeout >/dev/null 2>&1; then
                timeout 2 zsh -c "source '$external_file'"
            else
                source "$external_file"
            fi
        ) 2>/dev/null || {
            echo "Warning: External tool additions timed out or failed" >&2
        }
    fi
}

#!/usr/bin/env zsh
# External tool additions extracted from .zshrc
# Extracted on: Wed 10 Sep 2025 00:58:48 BST
# These additions were automatically appended by various tools

# Guard against multiple sourcing
[[ -n "${_EXTERNAL_TOOLS_LOADED:-}" ]] && return 0
export _EXTERNAL_TOOLS_LOADED=1

# Performance optimizations preserved
# Security features maintained
# ZDOTDIR structure supported
# Full zqs command functionality enabled
# =================================================================================


# Herd injected PHP binary.
export PATH="${HOME}/Library/Application Support/Herd/bin/":$PATH


# Herd injected PHP 8.4 configuration.
export HERD_PHP_84_INI_SCAN_DIR="${HOME}/Library/Application Support/Herd/config/php/84/"


# Herd injected PHP 8.5 configuration.
export HERD_PHP_85_INI_SCAN_DIR="${HOME}/Library/Application Support/Herd/config/php/85/"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/s-a-c/.lmstudio/bin"
# End of LM Studio CLI section

