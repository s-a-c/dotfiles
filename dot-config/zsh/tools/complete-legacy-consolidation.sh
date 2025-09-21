#!/usr/bin/env bash
set -euo pipefail

echo "🔧 COMPLETING LEGACY CONSOLIDATION"
echo "=================================="
echo ""

cd /Users/s-a-c/dotfiles/dot-config/zsh

CONSOLIDATED_DIR=".zshrc.d.legacy/consolidated-modules"

echo "=== 1. Adding Missing Async-Cache Functionality ==="
echo ""

# Add async-cache functionality to 01-core-infrastructure.zsh
echo "📝 Adding async-cache functionality to core infrastructure..."

# Extract async-cache functionality and append to core infrastructure
cat >> "$CONSOLIDATED_DIR/01-core-infrastructure.zsh" << 'EOF'

# ==============================================================================
# SECTION: ASYNC CACHE AND COMPILATION SYSTEM
# ==============================================================================
# Purpose: Intelligent caching system with async plugin loading, configuration
#          compilation, and performance optimization
# Source: Consolidated from 00_22-async-cache.zsh

# Prevent multiple async-cache loading
if [[ -n "${ZSH_ASYNC_CACHE_LOADED:-}" ]]; then
    return 0
fi

debug_log "Loading async cache and compilation system..."

# Async cache configuration
export ZSH_ASYNC_CACHE_VERSION="1.0.0"
export ZSH_ASYNC_CACHE_LOADED="$(date -u '+%Y-%m-%dT%H:%M:%S %Z' 2>/dev/null || echo 'loaded')"

export ZSH_CACHE_DIR="${ZSH_CACHE_DIR:-${ZDOTDIR:-$HOME/.config/zsh}/.cache}"
export ZSH_COMPILED_DIR="$ZSH_CACHE_DIR/compiled"
export ZSH_ASYNC_DIR="$ZSH_CACHE_DIR/async"
export ZSH_CACHE_MANIFEST="$ZSH_CACHE_DIR/cache-manifest.zsh"

# Create cache directories
mkdir -p "$ZSH_CACHE_DIR" "$ZSH_COMPILED_DIR" "$ZSH_ASYNC_DIR" 2>/dev/null || true

# Async and caching configuration
export ZSH_ENABLE_ASYNC="${ZSH_ENABLE_ASYNC:-true}"
export ZSH_ENABLE_COMPILATION="${ZSH_ENABLE_COMPILATION:-true}"
export ZSH_CACHE_TTL="${ZSH_CACHE_TTL:-86400}"  # 24 hours
export ZSH_ASYNC_TIMEOUT="${ZSH_ASYNC_TIMEOUT:-30}"  # 30 seconds

# Cache state tracking
typeset -gA ZSH_CACHE_REGISTRY
typeset -gA ZSH_ASYNC_JOBS
typeset -g ZSH_CACHE_INITIALIZED="false"

# Initialize cache system
init_cache_system() {
    debug_log "Initializing cache system..."

    # Create cache manifest if it doesn't exist
    if [[ ! -f "$ZSH_CACHE_MANIFEST" ]]; then
        cat > "$ZSH_CACHE_MANIFEST" << 'MANIFEST_EOF'
#!/opt/homebrew/bin/zsh
# ZSH Cache Manifest - Auto-generated
# Do not edit manually

# Cache registry
typeset -gA ZSH_CACHE_REGISTRY

# Cache metadata
export ZSH_CACHE_CREATED="$(date -u '+%Y-%m-%dT%H:%M:%S %Z')"
export ZSH_CACHE_VERSION="1.0.0"

MANIFEST_EOF
        debug_log "Created cache manifest: $ZSH_CACHE_MANIFEST"
    fi

    # Load existing cache manifest
    if [[ -f "$ZSH_CACHE_MANIFEST" ]]; then
        source "$ZSH_CACHE_MANIFEST"
        debug_log "Loaded cache manifest with ${#ZSH_CACHE_REGISTRY[@]} entries"
    fi

    ZSH_CACHE_INITIALIZED="true"
}

# Generate cache key
generate_cache_key() {
    local source_file="$1"
    local cache_type="${2:-compiled}"

    if [[ ! -f "$source_file" ]]; then
        return 1
    fi

    # Generate hash based on file path and modification time
    local file_hash=$(echo "$source_file:$(stat -f "%m" "$source_file" 2>/dev/null || echo "0")" | shasum -a 256 | cut -d' ' -f1)
    local cache_key="${cache_type}_${file_hash}"

    echo "$cache_key"
}

# Check cache validity
is_cache_valid() {
    local source_file="$1"
    local cache_file="$2"
    local ttl="${3:-$ZSH_CACHE_TTL}"

    # Check if cache file exists
    if [[ ! -f "$cache_file" ]]; then
        return 1
    fi

    # Check if source file is newer than cache
    if [[ "$source_file" -nt "$cache_file" ]]; then
        return 1
    fi

    # Check TTL
    local cache_age=$(( $(date +%s) - $(stat -f "%m" "$cache_file" 2>/dev/null || echo "0") ))
    if [[ $cache_age -gt $ttl ]]; then
        return 1
    fi

    return 0
}

# Compile ZSH configuration
compile_config() {
    local source_file="$1"
    local compiled_file="$2"

    debug_log "Compiling configuration: $source_file -> $compiled_file"

    if [[ ! -f "$source_file" ]]; then
        error_log "Source file not found: $source_file"
        return 1
    fi

    # Create compiled directory if needed
    mkdir -p "$(dirname "$compiled_file")" 2>/dev/null || true

    # Compile the configuration
    if zcompile "$compiled_file" "$source_file" 2>/dev/null; then
        # Update cache registry
        local cache_key=$(generate_cache_key "$source_file" "compiled")
        ZSH_CACHE_REGISTRY[$cache_key]="$compiled_file:$(date +%s)"
        debug_log "Configuration compiled successfully: $source_file"
        return 0
    else
        warn_log "Configuration compilation failed: $source_file"
        return 1
    fi
}

# Clean expired cache
clean_expired_cache() {
    debug_log "Cleaning expired cache entries..."

    local cleaned_count=0

    # Clean compiled files
    if [[ -d "$ZSH_COMPILED_DIR" ]]; then
        find "$ZSH_COMPILED_DIR" -name "*.zwc" -type f -mtime +1 -delete 2>/dev/null
    fi

    # Clean async files
    if [[ -d "$ZSH_ASYNC_DIR" ]]; then
        find "$ZSH_ASYNC_DIR" -name "*.zsh" -type f -mtime +1 -delete 2>/dev/null
        find "$ZSH_ASYNC_DIR" -name "*.log" -type f -mtime +7 -delete 2>/dev/null
    fi

    debug_log "Cache cleanup completed"
}

# Cache status command
cache-status() {
    echo "========================================"
    echo "ZSH Cache and Compilation Status"
    echo "========================================"
    echo "Version: $ZSH_ASYNC_CACHE_VERSION"
    echo "Async Enabled: $ZSH_ENABLE_ASYNC"
    echo "Compilation Enabled: $ZSH_ENABLE_COMPILATION"
    echo "Cache TTL: ${ZSH_CACHE_TTL}s"
    echo ""
    echo "Cache Directories:"
    echo "  Cache Dir: $ZSH_CACHE_DIR"
    echo "  Compiled Dir: $ZSH_COMPILED_DIR"
    echo "  Async Dir: $ZSH_ASYNC_DIR"
    echo ""
    echo "Cache Registry: ${#ZSH_CACHE_REGISTRY[@]} entries"
    echo "Async Jobs: ${#ZSH_ASYNC_JOBS[@]} active"
}

# Initialize cache system on load
init_cache_system

debug_log "Async cache and compilation system loaded successfully"

# ==============================================================================
# END: ASYNC CACHE AND COMPILATION SYSTEM
# ==============================================================================
EOF

echo "✅ Added async-cache functionality to 01-core-infrastructure.zsh"
echo ""

echo "=== 2. Renumbering Modules to 01-09 Sequence ==="
echo ""

# Create temporary directory for renumbering
TEMP_DIR=$(mktemp -d)
echo "📁 Using temporary directory: $TEMP_DIR"

# Copy modules with new numbers
echo "📝 Renumbering consolidated modules..."

cp "$CONSOLIDATED_DIR/01-core-infrastructure.zsh" "$TEMP_DIR/01-core-infrastructure.zsh"
cp "$CONSOLIDATED_DIR/02-performance-monitoring.zsh" "$TEMP_DIR/02-performance-monitoring.zsh"
cp "$CONSOLIDATED_DIR/02-security-integrity.zsh" "$TEMP_DIR/03-security-integrity.zsh"
cp "$CONSOLIDATED_DIR/05-environment-options.zsh" "$TEMP_DIR/04-environment-options.zsh"
cp "$CONSOLIDATED_DIR/06-completion-system.zsh" "$TEMP_DIR/05-completion-system.zsh"
cp "$CONSOLIDATED_DIR/07-user-interface.zsh" "$TEMP_DIR/06-user-interface.zsh"
cp "$CONSOLIDATED_DIR/08-development-tools.zsh" "$TEMP_DIR/07-development-tools.zsh"
cp "$CONSOLIDATED_DIR/09-legacy-compatibility.zsh" "$TEMP_DIR/08-legacy-compatibility.zsh"

echo "=== 3. Creating 09-external-integrations.zsh ==="
echo ""

# Create the missing 9th module for external integrations
cat > "$TEMP_DIR/09-external-integrations.zsh" << 'EOF'
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
export ZSH_EXTERNAL_INTEGRATIONS_LOADED="$(date '+%Y-%m-%d %H:%M:%S')"

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
    if command -v direnv >/dev/null 2>&1; then
        eval "$(direnv hook zsh)"
        _ext_debug "Direnv integration enabled"
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
EOF

echo "✅ Created 09-external-integrations.zsh"
echo ""

echo "=== 4. Replacing Old Modules with Renumbered Ones ==="
echo ""

# Backup old modules
BACKUP_DIR=".zshrc.d.legacy/consolidated-modules.backup-$(date +%Y%m%d-%H%M%S)"
echo "📁 Creating backup: $BACKUP_DIR"
cp -r "$CONSOLIDATED_DIR" "$BACKUP_DIR"

# Remove old modules
rm -f "$CONSOLIDATED_DIR"/*.zsh

# Copy renumbered modules back
echo "📝 Installing renumbered modules..."
cp "$TEMP_DIR"/*.zsh "$CONSOLIDATED_DIR"/

# Cleanup temp directory
rm -rf "$TEMP_DIR"

echo "✅ Module renumbering complete!"
echo ""

echo "=== 5. Final Module Structure ==="
echo ""
ls -la "$CONSOLIDATED_DIR"/ | sed 's/^/  /'

echo ""
echo "=== 6. Module Summary ==="
echo ""

for module in "$CONSOLIDATED_DIR"/*.zsh; do
    if [[ -f "$module" ]]; then
        echo "📄 $(basename "$module"):"
        echo "  Size: $(wc -l < "$module") lines"
        echo "  Functions: $(grep -c "^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*(" "$module" 2>/dev/null || echo "0")"
        echo ""
    fi
done

echo "🎉 LEGACY CONSOLIDATION COMPLETED!"
echo ""
echo "✅ All 9 consolidated modules are ready:"
echo "   01-core-infrastructure.zsh     - Core functions, logging, caching"
echo "   02-performance-monitoring.zsh  - Performance measurement and monitoring"  
echo "   03-security-integrity.zsh      - Security checks and plugin integrity"
echo "   04-environment-options.zsh     - Environment variables and ZSH options"
echo "   05-completion-system.zsh       - Completion management and configuration"
echo "   06-user-interface.zsh          - UI, prompts, aliases, and keybindings"
echo "   07-development-tools.zsh       - Development environment and tools"
echo "   08-legacy-compatibility.zsh    - Legacy compatibility and migration shims"
echo "   09-external-integrations.zsh   - External tools and service integrations"
echo ""
echo "📁 Backup of old modules: $BACKUP_DIR"