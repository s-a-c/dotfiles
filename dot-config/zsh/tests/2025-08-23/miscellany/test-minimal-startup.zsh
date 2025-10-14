<<<<<<< HEAD
#!/usr/bin/env zsh
=======
#!/opt/homebrew/bin/zsh
>>>>>>> origin/develop
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
<<<<<<< HEAD
    zf::debug "✓ Source/execute detection loaded"
=======
        zsh_debug_echo "✓ Source/execute detection loaded"
>>>>>>> origin/develop
fi

# 2. Standard Helpers (essential)
if [[ -f "$ZDOTDIR/.zshrc.d/00_00-standard-helpers.zsh" ]]; then
    export ZSH_HELPERS_TESTING=1
    source "$ZDOTDIR/.zshrc.d/00_00-standard-helpers.zsh"
<<<<<<< HEAD
    zf::debug "✓ Standard helpers loaded"
=======
        zsh_debug_echo "✓ Standard helpers loaded"
>>>>>>> origin/develop
fi

# 3. Basic Environment (essential)
if [[ -f "$ZDOTDIR/.zshrc.d/00_01-environment.zsh" ]]; then
    source "$ZDOTDIR/.zshrc.d/00_01-environment.zsh"
<<<<<<< HEAD
    zf::debug "✓ Basic environment loaded"
=======
        zsh_debug_echo "✓ Basic environment loaded"
>>>>>>> origin/develop
fi

# 4. Path System (essential)
if [[ -f "$ZDOTDIR/.zshrc.d/00_02-path-system.zsh" ]]; then
    source "$ZDOTDIR/.zshrc.d/00_02-path-system.zsh"
<<<<<<< HEAD
    zf::debug "✓ Path system loaded"
=======
        zsh_debug_echo "✓ Path system loaded"
>>>>>>> origin/develop
fi

echo "Minimal ZSH configuration loaded successfully"
echo "Ready for interactive use"
