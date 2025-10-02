#!/usr/bin/env zsh
# ==============================================================================
# ZSH Legacy Configuration: Legacy Compatibility Module
# ==============================================================================
# Purpose: Compatibility shims and legacy support functions for redesign
#          compatibility and zf:: namespace functions
# 
# Consolidated from:
#   - ACTIVE-10-legacy-compatibility-shims.zsh (compatibility functions)
#
# Dependencies: 01-core-infrastructure.zsh (for logging functions)
# Load Order: Late (90-99 range)
# Author: ZSH Legacy Consolidation System
# Created: 2025-09-14
# Version: 1.0.0
# ==============================================================================

# Prevent multiple loading
if [[ -n "${_LEGACY_COMPATIBILITY_LOADED:-}" ]]; then
    return 0
fi
export _LEGACY_COMPATIBILITY_LOADED=1

# Debug helper - use core infrastructure if available
_compat_debug() {
    if command -v debug_log >/dev/null 2>&1; then
        debug_log "$1"
    elif [[ -n "${ZSH_DEBUG:-}" ]]; then
        echo "[COMPAT-DEBUG] $1" >&2
    fi
}

_compat_debug "Loading legacy compatibility module..."

# ==============================================================================
# SECTION 1: REDESIGN COMPATIBILITY SHIMS
# ==============================================================================
# Purpose: Provide compatibility between legacy and redesign modes

_compat_debug "Setting up redesign compatibility..."

# Detect if redesign modules are available and active
_detect_redesign_mode() {
    local redesign_active=0
    
    # Check for redesign environment variables
    if [[ -n "${ZSH_ENABLE_PREPLUGIN_REDESIGN:-}" ]] || [[ -n "${ZSH_ENABLE_POSTPLUGIN_REDESIGN:-}" ]]; then
        redesign_active=1
    fi
    
    # Check for redesign directory structures
    if [[ -d "${ZDOTDIR}/.zshrc.d.REDESIGN" ]] || [[ -d "${ZDOTDIR}/.zshrc.pre-plugins.d.REDESIGN" ]]; then
        redesign_active=1
    fi
    
    return $((1 - redesign_active))  # Return 0 if active, 1 if not
}

# Set compatibility mode based on detection
if _detect_redesign_mode; then
    export LEGACY_REDESIGN_COMPAT_MODE="active"
    _compat_debug "Redesign mode detected - compatibility shims active"
else
    export LEGACY_REDESIGN_COMPAT_MODE="legacy"
    _compat_debug "Legacy mode detected - standard operation"
fi

# ==============================================================================
# SECTION 2: ZF:: NAMESPACE FUNCTIONS
# ==============================================================================
# Purpose: Provide zf:: namespace functions expected by tests and other components

_compat_debug "Setting up zf:: namespace functions..."

# Core zf:: namespace functions for test compatibility
zf::log() {
    local level="${1:-INFO}"
    local message="$2"
    local context="${3:-legacy-compat}"
    
    if command -v zsh_log >/dev/null 2>&1; then
        zsh_log "$level" "$message" "$context"
    else
        echo "[$level] [$context] $message" >&2
    fi
}

zf::debug() {
    zf::log "DEBUG" "$1" "${2:-legacy-compat}"
}

zf::info() {
    zf::log "INFO" "$1" "${2:-legacy-compat}"
}

zf::warn() {
    zf::log "WARN" "$1" "${2:-legacy-compat}"
}

zf::error() {
    zf::log "ERROR" "$1" "${2:-legacy-compat}"
}

# File and directory utilities
zf::ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || {
            zf::error "Failed to create directory: $dir"
            return 1
        }
    fi
    zf::debug "Directory ensured: $dir"
}

zf::file_exists() {
    [[ -f "$1" ]]
}

zf::dir_exists() {
    [[ -d "$1" ]]
}

zf::is_readable() {
    [[ -r "$1" ]]
}

zf::is_writable() {
    [[ -w "$1" ]]
}

# String utilities
zf::trim() {
    local str="$1"
    echo "${str}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

zf::upper() {
    echo "${1}" | tr '[:lower:]' '[:upper:]'
}

zf::lower() {
    echo "${1}" | tr '[:upper:]' '[:lower:]'
}

# Array utilities  
zf::array_contains() {
    local element="$1"
    shift
    local array=("$@")
    
    for item in "${array[@]}"; do
        if [[ "$item" == "$element" ]]; then
            return 0
        fi
    done
    return 1
}

zf::join() {
    local delimiter="$1"
    shift
    local array=("$@")
    
    local result=""
    for item in "${array[@]}"; do
        if [[ -n "$result" ]]; then
            result="$result$delimiter"
        fi
        result="$result$item"
    done
    echo "$result"
}

# Environment utilities
zf::env_set() {
    [[ -n "${(P)1}" ]]
}

zf::env_default() {
    local var_name="$1"
    local default_value="$2"
    
    if ! zf::env_set "$var_name"; then
        export "$var_name"="$default_value"
        zf::debug "Set environment default: $var_name=$default_value"
    fi
}

# Command utilities
zf::command_exists() {
    command -v "$1" >/dev/null 2>&1
}

zf::safe_command() {
    local cmd="$1"
    local description="${2:-command}"
    
    zf::debug "Executing: $cmd"
    
    if eval "$cmd"; then
        zf::debug "$description completed successfully"
        return 0
    else
        local exit_code=$?
        zf::error "$description failed with exit code $exit_code"
        return $exit_code
    fi
}

# Process utilities
zf::is_process_running() {
    local process_name="$1"
    pgrep -f "$process_name" >/dev/null 2>&1
}

zf::wait_for_process() {
    local process_name="$1"
    local timeout="${2:-30}"
    local counter=0
    
    while ! zf::is_process_running "$process_name" && [[ $counter -lt $timeout ]]; do
        sleep 1
        ((counter++))
    done
    
    zf::is_process_running "$process_name"
}

# ==============================================================================
# SECTION 3: SSH AGENT COMPATIBILITY
# ==============================================================================
# Purpose: SSH agent helper functions for compatibility

_compat_debug "Setting up SSH agent compatibility functions..."

# SSH agent status check
zf::ssh_agent_status() {
    if [[ -n "$SSH_AUTH_SOCK" ]] && [[ -S "$SSH_AUTH_SOCK" ]]; then
        return 0
    else
        return 1
    fi
}

# SSH agent key management
zf::ssh_add_key() {
    local key_path="${1:-$HOME/.ssh/id_rsa}"
    
    if ! zf::ssh_agent_status; then
        zf::warn "SSH agent not available"
        return 1
    fi
    
    if [[ -f "$key_path" ]]; then
        ssh-add "$key_path" 2>/dev/null
        zf::info "SSH key added: $key_path"
    else
        zf::warn "SSH key not found: $key_path"
        return 1
    fi
}

zf::ssh_list_keys() {
    if zf::ssh_agent_status; then
        ssh-add -l 2>/dev/null || zf::info "No SSH keys loaded"
    else
        zf::warn "SSH agent not available"
        return 1
    fi
}

# ==============================================================================
# SECTION 4: PLUGIN SYSTEM COMPATIBILITY
# ==============================================================================
# Purpose: Compatibility functions for plugin systems

_compat_debug "Setting up plugin system compatibility..."

# Plugin loading compatibility
zf::load_plugin() {
    local plugin_name="$1"
    local plugin_path="$2"
    
    if [[ -z "$plugin_name" ]]; then
        zf::error "Plugin name required"
        return 1
    fi
    
    # If path not provided, try to find plugin
    if [[ -z "$plugin_path" ]]; then
        # Look in common plugin directories
        local plugin_dirs=(
            "${ZDOTDIR}/plugins"
            "${HOME}/.oh-my-zsh/plugins"
            "${HOME}/.zsh/plugins"
        )
        
        for dir in "${plugin_dirs[@]}"; do
            if [[ -f "$dir/$plugin_name/$plugin_name.plugin.zsh" ]]; then
                plugin_path="$dir/$plugin_name/$plugin_name.plugin.zsh"
                break
            elif [[ -f "$dir/$plugin_name.zsh" ]]; then
                plugin_path="$dir/$plugin_name.zsh"
                break
            fi
        done
    fi
    
    if [[ -f "$plugin_path" ]]; then
        source "$plugin_path"
        zf::info "Loaded plugin: $plugin_name"
    else
        zf::warn "Plugin not found: $plugin_name"
        return 1
    fi
}

# Plugin status check
zf::plugin_loaded() {
    local plugin_name="$1"
    
    # Check if plugin functions/variables are available
    # This is a simple heuristic - real implementation would be more sophisticated
    if declare -f "${plugin_name}_plugin_loaded" >/dev/null 2>&1; then
        return 0
    else
        local loaded_var="${plugin_name}_LOADED"
        if [[ -n "${(P)loaded_var}" ]]; then
            return 0
        else
            return 1
        fi
    fi
}

# ==============================================================================
# SECTION 5: PERFORMANCE COMPATIBILITY
# ==============================================================================
# Purpose: Performance monitoring compatibility functions

_compat_debug "Setting up performance compatibility functions..."

# Performance timing
zf::timer_start() {
    local timer_name="${1:-default}"
    export "ZF_TIMER_${timer_name:u}_START"="$(date +%s.%N)"
    zf::debug "Timer started: $timer_name"
}

zf::timer_end() {
    local timer_name="${1:-default}"
    local start_var="ZF_TIMER_${timer_name:u}_START"
    local start_time="${(P)start_var}"
    
    if [[ -n "$start_time" ]]; then
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "unknown")
        zf::info "Timer $timer_name: ${duration}s"
        unset "$start_var"
        echo "$duration"
    else
        zf::warn "Timer $timer_name was not started"
        return 1
    fi
}

# System resource monitoring
zf::memory_usage() {
    if command -v ps >/dev/null 2>&1; then
        ps -o pid,ppid,pmem,comm -p $$ 2>/dev/null | tail -1
    else
        zf::warn "Memory usage monitoring not available"
    fi
}

zf::cpu_usage() {
    if command -v ps >/dev/null 2>&1; then
        ps -o pid,ppid,pcpu,comm -p $$ 2>/dev/null | tail -1
    else
        zf::warn "CPU usage monitoring not available"
    fi
}

# ==============================================================================
# SECTION 6: TEST COMPATIBILITY
# ==============================================================================
# Purpose: Functions specifically for test compatibility

_compat_debug "Setting up test compatibility functions..."

# Test assertion helpers
zf::assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Assertion failed}"
    
    if [[ "$expected" == "$actual" ]]; then
        zf::debug "Assertion passed: $message"
        return 0
    else
        zf::error "Assertion failed: $message (expected: '$expected', actual: '$actual')"
        return 1
    fi
}

zf::assert_not_empty() {
    local value="$1"
    local message="${2:-Value should not be empty}"
    
    if [[ -n "$value" ]]; then
        zf::debug "Assertion passed: $message"
        return 0
    else
        zf::error "Assertion failed: $message (value is empty)"
        return 1
    fi
}

zf::assert_command_exists() {
    local command="$1"
    local message="${2:-Command should exist}"
    
    if zf::command_exists "$command"; then
        zf::debug "Assertion passed: $message ($command exists)"
        return 0
    else
        zf::error "Assertion failed: $message ($command not found)"
        return 1
    fi
}

# Mock functions for testing
zf::mock_command() {
    local command_name="$1"
    local mock_output="$2"
    
    eval "${command_name}() { echo '${mock_output}'; }"
    zf::debug "Mocked command: $command_name"
}

zf::unmock_command() {
    local command_name="$1"
    unfunction "$command_name" 2>/dev/null
    zf::debug "Unmocked command: $command_name"
}

# ==============================================================================
# MODULE INITIALIZATION
# ==============================================================================

_compat_debug "Initializing legacy compatibility module..."

# Set compatibility metadata
export LEGACY_COMPATIBILITY_VERSION="1.0.0"
export LEGACY_COMPATIBILITY_LOADED="$(command -v date >/dev/null 2>&1 && date '+%Y-%m-%d %H:%M:%S' || echo 'startup')"
export LEGACY_COMPATIBILITY_FUNCTIONS=$(declare -f | command grep -c "^zf::" 2>/dev/null || echo '0')

# Initialize compatibility based on mode
if [[ "$LEGACY_REDESIGN_COMPAT_MODE" == "active" ]]; then
    zf::info "Legacy compatibility active - redesign mode detected"
else
    zf::info "Legacy compatibility active - legacy mode"
fi

_compat_debug "Legacy compatibility module ready ($LEGACY_COMPATIBILITY_FUNCTIONS functions)"

# ==============================================================================
# MODULE SELF-TEST
# ==============================================================================

test_legacy_compatibility() {
    local tests_passed=0
    local tests_total=8
    
    # Test 1: Core zf:: functions
    if command -v zf::log >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Core zf:: functions loaded"
    else
        echo "❌ Core zf:: functions not loaded"
    fi
    
    # Test 2: File utilities
    if command -v zf::ensure_dir >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ File utility functions loaded"
    else
        echo "❌ File utility functions not loaded"
    fi
    
    # Test 3: String utilities
    if command -v zf::trim >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ String utility functions loaded"
    else
        echo "❌ String utility functions not loaded"
    fi
    
    # Test 4: SSH agent functions
    if command -v zf::ssh_agent_status >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ SSH agent functions loaded"
    else
        echo "❌ SSH agent functions not loaded"
    fi
    
    # Test 5: Plugin functions
    if command -v zf::load_plugin >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Plugin compatibility functions loaded"
    else
        echo "❌ Plugin compatibility functions not loaded"
    fi
    
    # Test 6: Performance functions
    if command -v zf::timer_start >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Performance functions loaded"
    else
        echo "❌ Performance functions not loaded"
    fi
    
    # Test 7: Test helpers
    if command -v zf::assert_equals >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Test compatibility functions loaded"
    else
        echo "❌ Test compatibility functions not loaded"
    fi
    
    # Test 8: Module metadata
    if [[ -n "$LEGACY_COMPATIBILITY_VERSION" ]]; then
        ((tests_passed++))
        echo "✅ Module metadata available"
    else
        echo "❌ Module metadata missing"
    fi
    
    echo ""
    echo "Legacy Compatibility Self-Test: $tests_passed/$tests_total tests passed"
    echo "📊 zf:: functions available: $LEGACY_COMPATIBILITY_FUNCTIONS"
    echo "🔗 Compatibility mode: $LEGACY_REDESIGN_COMPAT_MODE"
    
    if [[ $tests_passed -eq $tests_total ]]; then
        return 0
    else
        return 1
    fi
}

# ==============================================================================
# END OF LEGACY COMPATIBILITY MODULE
# ==============================================================================