#!/usr/bin/env zsh

# Test script to verify the global variable warnings are fixed
# This script will source the problematic files and check for warnings

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
    # Add this check to detect errant file creation:
    if [[ -f "${ZDOTDIR:-$HOME}/2" ]] || [[ -f "${ZDOTDIR:-$HOME}/3" ]]; then
        echo "Warning: Numbered files detected - check for redirection typos" >&2
    fi
}

echo "Testing zsh configuration for global variable warnings..."
echo "=============================================="

# Enable warnings for debugging
setopt WARN_CREATE_GLOBAL

# Test the load-shell-fragments function
echo "\nTesting load-shell-fragments function:"
source ./.zshrc

# Test loading the pre-plugins directory which contains secure-env.zsh
echo "\nTesting secure-env.zsh loading:"
if [[ -d "./.zshrc.pre-plugins.d" ]]; then
    load-shell-fragments "./.zshrc.pre-plugins.d"
    echo "✓ Pre-plugins loaded successfully"
else
    echo "✗ .zshrc.pre-plugins.d directory not found"
fi

echo "\nConfiguration test completed."
echo "If no warnings appeared above, the global variable issues are fixed."
