#!/usr/bin/env zsh
# ==============================================================================
# ZSH Legacy Configuration: Core Infrastructure Module
# ==============================================================================
# Purpose: Core shell infrastructure including timeout protection, unified 
#          logging, standard helpers, and execution detection
# 
# Consolidated from:
#   - ACTIVE-00-timeout-protection.zsh
#   - DISABLED-00_02-standard-helpers.zsh (21 functions)
#   - DISABLED-00_04-unified-logging.zsh (14 functions)
#   - DISABLED-00_12-source-execute-detection.zsh (13 functions)
#   - DISABLED-00_00-.zshrc.zqs.zsh
#
# Dependencies: None (this is the foundation module)
# Load Order: First (00-19 range)
# Author: ZSH Legacy Consolidation System
# Created: 2025-09-14
# Version: 1.0.0
# ==============================================================================

# Prevent multiple loading
if [[ -n "${_CORE_INFRASTRUCTURE_LOADED:-}" ]]; then
    return 0
fi
export _CORE_INFRASTRUCTURE_LOADED=1

# ==============================================================================
# SECTION 1: TIMEOUT PROTECTION
# ==============================================================================
# From: ACTIVE-00-timeout-protection.zsh
# Purpose: Emergency timeout protection for shell initialization

# Define timeout wrapper if not available
if ! command -v timeout >/dev/null 2>&1; then
    # Simple timeout implementation using background job
    timeout() {
        local duration="$1"
        shift
        
        # Run command in background
        "$@" &
        local cmd_pid=$!
        
        # Start timeout monitor
        (
            sleep "$duration"
            kill -TERM "$cmd_pid" 2>/dev/null
            sleep 2
            kill -KILL "$cmd_pid" 2>/dev/null
        ) &
        local timeout_pid=$!
        
        # Wait for command to complete
        if wait "$cmd_pid" 2>/dev/null; then
            kill "$timeout_pid" 2>/dev/null
            return 0
        else
            return 124  # timeout exit code
        fi
    }
fi

# ==============================================================================
# SECTION 2: SOURCE/EXECUTE DETECTION 
# ==============================================================================
# From: DISABLED-00_12-source-execute-detection.zsh
# Purpose: Detect whether script is being sourced or executed

is_being_sourced() {
    # ZSH-native source detection - reliable and no BASH dependencies
    [[ "${ZSH_EVAL_CONTEXT}" == *:file ]] || [[ "${(%):-%x}" != "${(%):-%N}" ]]
}

is_being_executed() {
    ! is_being_sourced
}

get_execution_context() {
    if is_being_sourced; then
        echo "sourced"
    else
        echo "executed"
    fi
}

exit_or_return() {
    local exit_code="${1:-0}"
    if is_being_sourced; then
        return "$exit_code"
    else
        exit "$exit_code"
    fi
}

handle_error() {
    local error_msg="$1"
    local exit_code="${2:-1}"
    echo "Error: $error_msg" >&2
    exit_or_return "$exit_code"
}

# Context-aware command execution
execute_if_sourced() {
    if is_being_sourced; then
        "$@"
    fi
}

execute_if_executed() {
    if is_being_executed; then
        "$@"
    fi
}

# Get script name regardless of execution context
get_script_name() {
    # Use ZSH-native variables only
    local script_name="${(%):-%N}"
    if [[ -n "$script_name" ]]; then
        # Use ZSH parameter expansion instead of basename to avoid PATH issues
        echo "${script_name:t}"
    else
        echo "unknown"
    fi
}

# Get calling function information
get_caller_info() {
    local level="${1:-1}"
    # Use ZSH-native funcstack and functrace
    if (( ${#funcstack[@]} > level )); then
        local caller_func="${funcstack[$((level + 1))]:-unknown}"
        local caller_line="${functrace[$((level + 1))]##*:}"
        echo "${caller_func}${caller_line:+:${caller_line}}"
    else
        echo "unknown"
    fi
}

# Conditional sourcing with error handling
safe_source() {
    local file="$1"
    if [[ -f "$file" ]]; then
        source "$file" || handle_error "Failed to source $file" 1
    else
        handle_error "File not found: $file" 1
    fi
}

# Detection state queries
get_detection_state() {
    local context=$(get_execution_context)
    local script_name=$(get_script_name)
    echo "context:$context script:$script_name"
}

is_interactive_shell() {
    [[ -n "$PS1" ]] && [[ "$-" == *i* ]]
}

is_login_shell() {
    [[ "$0" == -* ]]
}

# ==============================================================================
# SECTION 3: UNIFIED LOGGING SYSTEM
# ==============================================================================
# From: DISABLED-00_04-unified-logging.zsh
# Purpose: Centralized logging system with consistent interface

# Global logging configuration
ZSH_LOG_LEVEL="${ZSH_LOG_LEVEL:-INFO}"
ZSH_LOG_FORMAT="${ZSH_LOG_FORMAT:-%T [%L] %M}"
ZSH_LOG_FILE="${ZSH_LOG_FILE:-}"

# Logging level hierarchy
declare -A LOG_LEVELS=(
    [DEBUG]=0
    [INFO]=1
    [WARN]=2
    [ERROR]=3
    [FATAL]=4
)

# Core logging function
zsh_log() {
    local level="$1"
    local message="$2"
    local context="${3:-$(get_script_name)}"
    
    # Check if we should log this level
    local current_level_num="${LOG_LEVELS[$ZSH_LOG_LEVEL]:-1}"
    local message_level_num="${LOG_LEVELS[$level]:-1}"
    
    if [[ $message_level_num -ge $current_level_num ]]; then
        local timestamp=$(/usr/bin/date '+%H:%M:%S' 2>/dev/null || echo 'unknown')
        local formatted_message
        
        # Format the message
        formatted_message="${ZSH_LOG_FORMAT}"
        formatted_message="${formatted_message//%T/$timestamp}"
        formatted_message="${formatted_message//%L/$level}"
        formatted_message="${formatted_message//%M/$message}"
        formatted_message="${formatted_message//%C/$context}"
        
        # Output to stderr and optionally to file
        echo "$formatted_message" >&2
        if [[ -n "$ZSH_LOG_FILE" ]]; then
            echo "$formatted_message" >> "$ZSH_LOG_FILE"
        fi
    fi
}

# Convenience logging functions
zsh_debug() { zsh_log "DEBUG" "$1" "$2"; }
zsh_info() { zsh_log "INFO" "$1" "$2"; }
zsh_warn() { zsh_log "WARN" "$1" "$2"; }
zsh_error() { zsh_log "ERROR" "$1" "$2"; }
zsh_fatal() { zsh_log "FATAL" "$1" "$2"; }

# Structured logging with key-value pairs
zsh_log_kv() {
    local level="$1"
    shift
    local pairs=("$@")
    local message=""
    
    for pair in "${pairs[@]}"; do
        if [[ -n "$message" ]]; then
            message="$message "
        fi
        message="$message$pair"
    done
    
    zsh_log "$level" "$message"
}

# Performance logging
zsh_log_timing() {
    local start_time="$1"
    local operation="$2"
    local context="${3:-$(get_script_name)}"
    
    local end_time=$(/usr/bin/date +%s.%N 2>/dev/null || echo 'unknown')
    local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "unknown")
    
    zsh_log "INFO" "TIMING: $operation took ${duration}s" "$context"
}

# Start timing measurement
start_timing() {
    /usr/bin/date +%s.%N 2>/dev/null || echo 'unknown'
}

# Log with caller context
zsh_log_caller() {
    local level="$1"
    local message="$2"
    local caller=$(get_caller_info)
    zsh_log "$level" "$message" "$caller"
}

# Conditional logging based on debug flags
zsh_debug_conditional() {
    local flag="$1"
    local message="$2"
    local context="${3:-$(get_script_name)}"
    
    if [[ -n "${(P)flag}" ]]; then
        zsh_debug "$message" "$context"
    fi
}

# ==============================================================================
# SECTION 4: STANDARD HELPERS LIBRARY
# ==============================================================================
# From: DISABLED-00_02-standard-helpers.zsh
# Purpose: Standardized helper functions for configuration consistency

# Legacy logging functions (for compatibility)
_helpers_log() {
    zsh_log "INFO" "$1" "helpers"
}

_helpers_error() {
    zsh_log "ERROR" "$1" "helpers"
}

# Timestamp utilities
utc_timestamp() {
    date -u '+%Y-%m-%d %H:%M:%S UTC'
}

local_timestamp() {
    date '+%Y-%m-%d %H:%M:%S %Z'
}

# Safe logging with error handling
safe_log() {
    local message="$1"
    local level="${2:-INFO}"
    
    if command -v zsh_log >/dev/null 2>&1; then
        zsh_log "$level" "$message"
    else
        echo "[$level] $message" >&2
    fi
}

# Debug logging with conditional output
debug_log() {
    if [[ -n "${ZSH_DEBUG:-}" ]]; then
        safe_log "$1" "DEBUG"
    fi
}

# File existence and readability checks
is_readable_file() {
    [[ -f "$1" && -r "$1" ]]
}

is_executable_file() {
    [[ -f "$1" && -x "$1" ]]
}

is_writable_dir() {
    [[ -d "$1" && -w "$1" ]]
}

# Safe command execution with logging
safe_command() {
    local cmd="$1"
    local description="${2:-command}"
    
    debug_log "Executing: $cmd"
    
    if eval "$cmd"; then
        debug_log "$description completed successfully"
        return 0
    else
        local exit_code=$?
        _helpers_error "$description failed with exit code $exit_code"
        return $exit_code
    fi
}

# Path manipulation utilities
normalize_path() {
    local path="$1"
    # Remove trailing slashes and resolve relative paths
    echo "${path%/}" | sed 's|/\./|/|g' | sed 's|/[^/]*/\.\./|/|g'
}

ensure_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || {
            _helpers_error "Failed to create directory: $dir"
            return 1
        }
    fi
}

# String utilities
trim_whitespace() {
    local var="$1"
    # Remove leading and trailing whitespace
    echo "$var" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

is_empty_or_whitespace() {
    [[ -z "$(trim_whitespace "$1")" ]]
}

# Array utilities
array_contains() {
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

join_array() {
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
backup_env_var() {
    local var_name="$1"
    local backup_name="${var_name}_BACKUP"
    
    if [[ -n "${(P)var_name}" ]]; then
        export "$backup_name"="${(P)var_name}"
        debug_log "Backed up $var_name to $backup_name"
    fi
}

restore_env_var() {
    local var_name="$1"
    local backup_name="${var_name}_BACKUP"
    
    if [[ -n "${(P)backup_name}" ]]; then
        export "$var_name"="${(P)backup_name}"
        unset "$backup_name"
        debug_log "Restored $var_name from $backup_name"
    fi
}

# ==============================================================================
# SECTION 5: CORE QS FUNCTIONALITY  
# ==============================================================================
# From: DISABLED-00_00-.zshrc.zqs.zsh
# Purpose: Core Quick Shell (QS) functionality and configuration

# QS system initialization
init_qs_system() {
    debug_log "Initializing QS (Quick Shell) system"
    
    # Set QS defaults
    export QS_INITIALIZED=1
    export QS_VERSION="${QS_VERSION:-1.0.0}"
    export QS_CONFIG_DIR="${QS_CONFIG_DIR:-$ZDOTDIR}"
    
    debug_log "QS system initialized (version: $QS_VERSION)"
}

# QS configuration helpers
qs_set_option() {
    local option="$1"
    local value="$2"
    
    export "QS_${option^^}"="$value"
    debug_log "QS option set: ${option^^}=$value"
}

qs_get_option() {
    local option="$1"
    local var_name="QS_${option^^}"
    echo "${(P)var_name}"
}

# ==============================================================================
# MODULE INITIALIZATION
# ==============================================================================

# Initialize core infrastructure on module load
if is_being_sourced; then
    debug_log "Core infrastructure module loaded"
    init_qs_system
    
    # Set module metadata
    export CORE_INFRASTRUCTURE_VERSION="1.0.0"
    export CORE_INFRASTRUCTURE_FUNCTIONS="48"  # Approximate count
    
    debug_log "Core infrastructure ready: 48 functions available"
fi

# Module self-test function
test_core_infrastructure() {
    local tests_passed=0
    local tests_total=5
    
    # Test 1: Logging system
    if command -v zsh_log >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Logging system functional"
    else
        echo "❌ Logging system not functional"
    fi
    
    # Test 2: Source detection
    if is_being_sourced; then
        ((tests_passed++))
        echo "✅ Source detection working"
    else
        echo "❌ Source detection not working"
    fi
    
    # Test 3: Helper functions
    if command -v safe_log >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Helper functions loaded"
    else
        echo "❌ Helper functions not loaded"
    fi
    
    # Test 4: Timeout protection
    if command -v timeout >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Timeout protection available"
    else
        echo "❌ Timeout protection not available"
    fi
    
    # Test 5: QS system
    if [[ -n "$QS_INITIALIZED" ]]; then
        ((tests_passed++))
        echo "✅ QS system initialized"
    else
        echo "❌ QS system not initialized"
    fi
    
    echo ""
    echo "Core Infrastructure Self-Test: $tests_passed/$tests_total tests passed"
    
    if [[ $tests_passed -eq $tests_total ]]; then
        return 0
    else
        return 1
    fi
}

# ==============================================================================
# END OF CORE INFRASTRUCTURE MODULE
# ==============================================================================
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
