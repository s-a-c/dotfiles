#!/usr/bin/env zsh
# ==============================================================================
# ZSH Legacy Configuration: External Integrations Module
# ==============================================================================
# Purpose: External tool integrations, platform-specific configurations,
#          and third-party service connections
# 
# Consolidated from:
#   - 99-external-tools.zsh (external tool integrations)
#   - Various platform and service-specific configurations
#
# Dependencies: 01-core-infrastructure.zsh (for logging and basic functions)
# Load Order: Last (09/09 - after all other legacy modules)
# Author: ZSH Legacy Consolidation System
# Created: 2025-09-15
# Version: 1.0.0
# ==============================================================================

# Prevent multiple loading
if [[ -n "${_EXTERNAL_INTEGRATIONS_LOADED:-}" ]]; then
    return 0
fi
export _EXTERNAL_INTEGRATIONS_LOADED=1

# Debug helper - use core infrastructure if available
_ext_debug() {
    if command -v debug_log >/dev/null 2>&1; then
        debug_log "$1"
    elif [[ -n "${ZSH_DEBUG:-}" ]]; then
        echo "[EXT-DEBUG] $1" >&2
    fi
}

_ext_debug "Loading external integrations module..."

# ==============================================================================
# SECTION 1: EXTERNAL TOOL INTEGRATIONS
# ==============================================================================
# Purpose: Integration with external tools and utilities

_ext_debug "Setting up external tool integrations..."

# 1.1. Version and metadata
export ZSH_EXTERNAL_INTEGRATIONS_VERSION="1.0.0"
export ZSH_EXTERNAL_INTEGRATIONS_LOADED="$(command -v date >/dev/null 2>&1 && date '+%Y-%m-%d %H:%M:%S' || echo 'startup')"

# 1.2. External tool configuration
export ZSH_ENABLE_EXTERNAL_TOOLS="${ZSH_ENABLE_EXTERNAL_TOOLS:-true}"

# 1.3. Tool detection and setup
setup_external_tools() {
    _ext_debug "Setting up external tool integrations..."

    # FZF integration
    if command -v fzf >/dev/null 2>&1; then
        export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:---height 40% --layout=reverse --border}"
        if [[ -f ~/.fzf.zsh ]]; then
            source ~/.fzf.zsh
        fi
        _ext_debug "FZF integration enabled"
    fi

    # Direnv integration
    if (( $+commands[direnv] )); then
        eval "$(direnv hook zsh)"
        _ext_debug "Direnv integration enabled"
    else
        _ext_debug "Direnv not installed; skipping hook"
    fi

    # Atuin integration
    if command -v atuin >/dev/null 2>&1; then
        eval "$(atuin init zsh --disable-up-arrow)"
        _ext_debug "Atuin integration enabled"
    fi

    # GitHub CLI integration
    if command -v gh >/dev/null 2>&1; then
        if [[ ! -f ~/.config/gh/hosts.yml ]]; then
            # Basic setup if not configured
            mkdir -p ~/.config/gh
        fi
        _ext_debug "GitHub CLI integration enabled"
    fi
}

# ==============================================================================
# SECTION 2: PLATFORM-SPECIFIC INTEGRATIONS
# ==============================================================================
# Purpose: Platform-specific configurations and integrations

_ext_debug "Setting up platform-specific integrations..."

# 2.1. macOS-specific integrations
setup_macos_integrations() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        _ext_debug "Setting up macOS integrations..."

        # Homebrew integration
        if command -v brew >/dev/null 2>&1; then
            # Add Homebrew completions
            if [[ -d "$(brew --prefix)/share/zsh/site-functions" ]]; then
                fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)
            fi
            _ext_debug "Homebrew integration enabled"
        fi

        # iTerm2 integration
        if [[ -f ~/.iterm2_shell_integration.zsh ]]; then
            source ~/.iterm2_shell_integration.zsh
            _ext_debug "iTerm2 shell integration enabled"
        fi

        # macOS-specific aliases
        alias ls="ls -G"
        alias ll="ls -alG"
        alias la="ls -aG"
        
        _ext_debug "macOS-specific configurations applied"
    fi
}

# 2.2. Linux-specific integrations
setup_linux_integrations() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        _ext_debug "Setting up Linux integrations..."

        # Linux-specific aliases
        alias ls="ls --color=auto"
        alias ll="ls -al --color=auto"
        alias la="ls -a --color=auto"
        
        _ext_debug "Linux-specific configurations applied"
    fi
}

# ==============================================================================
# SECTION 3: DEVELOPMENT ENVIRONMENT INTEGRATIONS
# ==============================================================================
# Purpose: Development environment and service integrations

_ext_debug "Setting up development environment integrations..."

# 3.1. Cloud service integrations
setup_cloud_integrations() {
    _ext_debug "Setting up cloud service integrations..."

    # AWS CLI integration
    if command -v aws >/dev/null 2>&1; then
        # AWS CLI completion
        if command -v aws_completer >/dev/null 2>&1; then
            autoload bashcompinit && bashcompinit
            complete -C aws_completer aws
        fi
        _ext_debug "AWS CLI integration enabled"
    fi

    # Docker integration
    if command -v docker >/dev/null 2>&1; then
        # Docker completion is usually handled by the system
        _ext_debug "Docker integration enabled"
    fi

    # Kubernetes integration
    if command -v kubectl >/dev/null 2>&1; then
        # Kubectl completion
        if [[ ! -f ~/.zsh/completions/_kubectl ]]; then
            mkdir -p ~/.zsh/completions
            kubectl completion zsh > ~/.zsh/completions/_kubectl 2>/dev/null || true
        fi
        _ext_debug "Kubernetes integration enabled"
    fi
}

# 3.2. Version manager integrations
setup_version_managers() {
    _ext_debug "Setting up version manager integrations..."

    # Node Version Manager
    if [[ -d "$HOME/.nvm" ]]; then
        export NVM_DIR="$HOME/.nvm"
        if [[ -s "$NVM_DIR/nvm.sh" ]]; then
            source "$NVM_DIR/nvm.sh"
        fi
        if [[ -s "$NVM_DIR/bash_completion" ]]; then
            source "$NVM_DIR/bash_completion"
        fi
        _ext_debug "NVM integration enabled"
    fi

    # Python Version Manager
    if command -v pyenv >/dev/null 2>&1; then
        eval "$(pyenv init -)"
        _ext_debug "Pyenv integration enabled"
    fi

    # Ruby Version Manager
    if command -v rbenv >/dev/null 2>&1; then
        eval "$(rbenv init -)"
        _ext_debug "Rbenv integration enabled"
    fi
}

# ==============================================================================
# SECTION 4: EXTERNAL INTEGRATION MANAGEMENT
# ==============================================================================
# Purpose: Management commands for external integrations

_ext_debug "Setting up external integration management..."

# External integrations status
external-status() {
    echo "========================================"
    echo "External Integrations Status"
    echo "========================================"
    echo "Version: $ZSH_EXTERNAL_INTEGRATIONS_VERSION"
    echo "External Tools Enabled: $ZSH_ENABLE_EXTERNAL_TOOLS"
    echo "Platform: $OSTYPE"
    echo ""

    echo "Tool Integration Status:"
    
    local tools=("fzf" "direnv" "atuin" "gh" "aws" "docker" "kubectl" "brew")
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            echo "  ✅ $tool - available"
        else
            echo "  ❌ $tool - not found"
        fi
    done

    echo ""
    echo "Version Managers:"
    
    if [[ -d "$HOME/.nvm" ]]; then
        echo "  ✅ NVM - available"
    else
        echo "  ❌ NVM - not found"
    fi
    
    local version_managers=("pyenv" "rbenv")
    for vm in "${version_managers[@]}"; do
        if command -v "$vm" >/dev/null 2>&1; then
            echo "  ✅ $vm - available"
        else
            echo "  ❌ $vm - not found"
        fi
    done
}

# Reload external integrations
reload-external() {
    _ext_debug "Reloading external integrations..."
    
    setup_external_tools
    setup_macos_integrations
    setup_linux_integrations
    setup_cloud_integrations
    setup_version_managers
    
    echo "✅ External integrations reloaded"
}

# ==============================================================================
# MODULE INITIALIZATION
# ==============================================================================

_ext_debug "Initializing external integrations module..."

# Initialize all external integrations
if [[ "$ZSH_ENABLE_EXTERNAL_TOOLS" == "true" ]]; then
    setup_external_tools
    setup_macos_integrations
    setup_linux_integrations
    setup_cloud_integrations
    setup_version_managers
fi

# NOTE: Prompt system integration has been moved to 99-post-initialization.zsh
# This ensures proper timing after ZLE is fully initialized

_ext_debug "External integrations module ready"

# ==============================================================================
# MODULE SELF-TEST
# ==============================================================================

test_external_integrations() {
    local tests_passed=0
    local tests_total=5
    
    # Test 1: Module metadata
    if [[ -n "$ZSH_EXTERNAL_INTEGRATIONS_VERSION" ]]; then
        ((tests_passed++))
        echo "✅ Module metadata available"
    else
        echo "❌ Module metadata missing"
    fi
    
    # Test 2: Management commands
    if command -v external-status >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Management commands available"
    else
        echo "❌ Management commands missing"
    fi
    
    # Test 3: Platform detection
    if [[ -n "$OSTYPE" ]]; then
        ((tests_passed++))
        echo "✅ Platform detection working"
    else
        echo "❌ Platform detection failed"
    fi
    
    # Test 4: Tool integration functions
    if command -v setup_external_tools >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Tool integration functions available"
    else
        echo "❌ Tool integration functions missing"
    fi
    
    # Test 5: Version manager functions
    if command -v setup_version_managers >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Version manager functions available"
    else
        echo "❌ Version manager functions missing"
    fi
    
    echo ""
    echo "External Integrations Self-Test: $tests_passed/$tests_total tests passed"
    
    if [[ $tests_passed -eq $tests_total ]]; then
        return 0
    else
        return 1
    fi
}

# ==============================================================================
# END OF EXTERNAL INTEGRATIONS MODULE
# ==============================================================================
