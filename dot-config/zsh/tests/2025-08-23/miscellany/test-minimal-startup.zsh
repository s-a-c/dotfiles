#!/opt/homebrew/bin/zsh
# ==============================================================================
# Minimal ZSH Startup Performance Test
# ==============================================================================
# Purpose: Test startup time with minimal configuration to identify bottlenecks
# Usage: time zsh -c 'source test-minimal-startup.zsh; exit'
# ==============================================================================

# Disable all performance-impacting features
export ZSH_DEBUG=0
export ZSH_ENABLE_SANITIZATION=false
export ZSH_DISABLE_COMPFIX=true

# Set minimal ZDOTDIR for 040-testing
export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"

# Load only essential core components
echo "Loading minimal ZSH configuration..."

# 1. Source/Execute Detection (essential)
if [[ -f "$ZDOTDIR/.zshrc.d/00_01-source-execute-detection.zsh" ]]; then
    source "$ZDOTDIR/.zshrc.d/00_01-source-execute-detection.zsh"
        zsh_debug_echo "✓ Source/execute detection loaded"
fi

# 2. Standard Helpers (essential)
if [[ -f "$ZDOTDIR/.zshrc.d/00_00-standard-helpers.zsh" ]]; then
    export ZSH_HELPERS_TESTING=1
    source "$ZDOTDIR/.zshrc.d/00_00-standard-helpers.zsh"
        zsh_debug_echo "✓ Standard helpers loaded"
fi

# 3. Basic Environment (essential)
if [[ -f "$ZDOTDIR/.zshrc.d/00_01-environment.zsh" ]]; then
    source "$ZDOTDIR/.zshrc.d/00_01-environment.zsh"
        zsh_debug_echo "✓ Basic environment loaded"
fi

# 4. Path System (essential)
if [[ -f "$ZDOTDIR/.zshrc.d/00_02-path-system.zsh" ]]; then
    source "$ZDOTDIR/.zshrc.d/00_02-path-system.zsh"
        zsh_debug_echo "✓ Path system loaded"
fi

echo "Minimal ZSH configuration loaded successfully"
echo "Ready for interactive use"
