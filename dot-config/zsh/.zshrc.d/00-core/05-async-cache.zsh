#!/opt/homebrew/bin/zsh
# ==============================================================================
# ZSH Configuration: Advanced Caching and Async Loading System
# ==============================================================================
# Purpose: Intelligent caching system with async plugin loading, configuration
#          compilation, and performance optimization to minimize startup time
#          while maintaining full functionality through background processing
#          and intelligent cache management.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-22
# Version: 1.0
# Load Order: 5th in 00-core (after environment, before plugins)
# Dependencies: 01-source-execute-detection.zsh, 00-standard-helpers.zsh
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. SOURCE/EXECUTE DETECTION INTEGRATION
# ------------------------------------------------------------------------------

# Guard against multiple sourcing in non-testing environments
if [[ -n "${ZSH_ASYNC_CACHE_LOADED:-}" && -z "${ZSH_ASYNC_TESTING:-}" ]]; then
    return 0
fi

# Load source/execute detection system if not already loaded
if [[ -z "${ZSH_SOURCE_EXECUTE_LOADED:-}" ]]; then
    local detection_script="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00-core/01-source-execute-detection.zsh"
    if [[ -f "$detection_script" ]]; then
        source "$detection_script"
    else
        echo "WARNING: Source/execute detection system not found: $detection_script" >&2
        echo "Async cache will work but without context-aware features" >&2
    fi
fi

# Use context-aware logging if detection system is available
if declare -f context_echo >/dev/null 2>&1; then
    _async_log() {
        context_echo "$1" "${2:-INFO}"
    }
    _async_error() {
        local message="$1"
        local exit_code="${2:-1}"
        if declare -f handle_error >/dev/null 2>&1; then
            handle_error "Async Cache: $message" "$exit_code" "async"
        else
            echo "ERROR [async]: $message" >&2
            if declare -f is_being_executed >/dev/null 2>&1 && is_being_executed; then
                exit "$exit_code"
            else
                return "$exit_code"
            fi
        fi
    }
else
    # Fallback logging functions
    _async_log() {
        echo "# [async] $1" >&2
    }
    _async_error() {
        echo "ERROR [async]: $1" >&2
        return "${2:-1}"
    }
fi

## 1. Global Configuration and Cache Setup
#=============================================================================

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
    _async_log "Loading advanced caching and async loading system v1.0"
}

# 1.1. Set global async cache version for tracking
export ZSH_ASYNC_CACHE_VERSION="1.0.0"
export ZSH_ASYNC_CACHE_LOADED="$(command -v date >/dev/null && date -u '+%Y-%m-%d %H:%M:%S UTC' || echo 'loaded')"

# 1.2. Cache configuration
export ZSH_CACHE_DIR="${ZDOTDIR:-$HOME/.config/zsh}/.cache"
export ZSH_COMPILED_DIR="$ZSH_CACHE_DIR/compiled"
export ZSH_ASYNC_DIR="$ZSH_CACHE_DIR/async"
export ZSH_CACHE_MANIFEST="$ZSH_CACHE_DIR/cache-manifest.zsh"

# Create cache directories
mkdir -p "$ZSH_CACHE_DIR" "$ZSH_COMPILED_DIR" "$ZSH_ASYNC_DIR" 2>/dev/null || true

# 1.3. Async and caching configuration
export ZSH_ENABLE_ASYNC="${ZSH_ENABLE_ASYNC:-true}"
export ZSH_ENABLE_COMPILATION="${ZSH_ENABLE_COMPILATION:-true}"
export ZSH_CACHE_TTL="${ZSH_CACHE_TTL:-86400}"  # 24 hours
export ZSH_ASYNC_TIMEOUT="${ZSH_ASYNC_TIMEOUT:-30}"  # 30 seconds

# 1.4. Cache state tracking
typeset -gA ZSH_CACHE_REGISTRY
typeset -gA ZSH_ASYNC_JOBS
typeset -g ZSH_CACHE_INITIALIZED="false"

## 2. Cache Management System
#=============================================================================

# 2.1. Initialize cache system
_init_cache_system() {
    _async_log "Initializing cache system..."

    # Create cache manifest if it doesn't exist
    if [[ ! -f "$ZSH_CACHE_MANIFEST" ]]; then
        cat > "$ZSH_CACHE_MANIFEST" << 'EOF'
#!/opt/homebrew/bin/zsh
# ZSH Cache Manifest - Auto-generated
# Do not edit manually

# Cache registry
typeset -gA ZSH_CACHE_REGISTRY

# Cache metadata
export ZSH_CACHE_CREATED="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
export ZSH_CACHE_VERSION="1.0.0"

EOF
        _async_log "Created cache manifest: $ZSH_CACHE_MANIFEST"
    fi

    # Load existing cache manifest
    if [[ -f "$ZSH_CACHE_MANIFEST" ]]; then
        source "$ZSH_CACHE_MANIFEST"
        _async_log "Loaded cache manifest with ${#ZSH_CACHE_REGISTRY[@]} entries"
    fi

    ZSH_CACHE_INITIALIZED="true"
}

# 2.2. Generate cache key
_generate_cache_key() {
    local source_file="$1"
    local cache_type="${2:-compiled}"

    if [[ ! -f "$source_file" ]]; then
        echo ""
        return 1
    fi

    # Generate hash based on file path and modification time
    local file_hash=$(echo "$source_file:$(stat -f "%m" "$source_file" 2>/dev/null || echo "0")" | shasum -a 256 | cut -d' ' -f1)
    local cache_key="${cache_type}_${file_hash}"

    echo "$cache_key"
}

# 2.3. Check cache validity
_is_cache_valid() {
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

## 3. Configuration Compilation System
#=============================================================================

# 3.1. Compile ZSH configuration
_compile_config() {
    local source_file="$1"
    local compiled_file="$2"

    _async_log "Compiling configuration: $source_file -> $compiled_file"

    if [[ ! -f "$source_file" ]]; then
        _async_error "Source file not found: $source_file"
        return 1
    fi

    # Create compiled directory if needed
    mkdir -p "$(dirname "$compiled_file")" 2>/dev/null || true

    # Compile the configuration
    local compile_start_time=$(date +%s.%N 2>/dev/null || date +%s)

    if zcompile "$compiled_file" "$source_file" 2>/dev/null; then
        local compile_end_time=$(date +%s.%N 2>/dev/null || date +%s)
        local compile_duration
        if command -v bc >/dev/null 2>&1; then
            compile_duration=$(echo "scale=3; ($compile_end_time - $compile_start_time) * 1000" | bc 2>/dev/null || echo "unknown")
        else
            compile_duration="<1"
        fi

        # Update cache registry
        local cache_key=$(_generate_cache_key "$source_file" "compiled")
        ZSH_CACHE_REGISTRY[$cache_key]="$compiled_file:$(date +%s)"

        _async_log "Configuration compiled successfully: $source_file (${compile_duration}ms)"
        return 0
    else
        _async_log "Configuration compilation failed: $source_file" "WARN"
        return 1
    fi
}

# 3.2. Load compiled configuration
_load_compiled_config() {
    local source_file="$1"

    if [[ "$ZSH_ENABLE_COMPILATION" != "true" ]]; then
        source "$source_file"
        return $?
    fi

    local cache_key=$(_generate_cache_key "$source_file" "compiled")
    local compiled_file="$ZSH_COMPILED_DIR/${cache_key}.zwc"

    # Check if we have a valid compiled version
    if _is_cache_valid "$source_file" "$compiled_file"; then
        _async_log "Loading compiled configuration: $compiled_file" "DEBUG"
        source "$compiled_file"
        return $?
    else
        # Compile in background and load source for now
        if [[ "$ZSH_ENABLE_ASYNC" == "true" ]]; then
            _async_compile_config "$source_file" "$compiled_file" &
        else
            _compile_config "$source_file" "$compiled_file"
        fi

        # Load source file immediately
        source "$source_file"
        return $?
    fi
}

# 3.3. Async compilation
_async_compile_config() {
    local source_file="$1"
    local compiled_file="$2"

    # Run compilation in background
    (
        _compile_config "$source_file" "$compiled_file"
        # Update cache manifest
        _update_cache_manifest
    ) &

    local job_pid=$!
    ZSH_ASYNC_JOBS["compile_${cache_key}"]="$job_pid:$(date +%s)"

    _async_log "Started async compilation: $source_file (PID: $job_pid)" "DEBUG"
}

## 4. Async Plugin Loading System
#=============================================================================

# 4.1. Async plugin loader
_async_load_plugin() {
    local plugin_name="$1"
    local plugin_source="$2"
    local plugin_type="${3:-oh-my-zsh}"

    _async_log "Starting async plugin load: $plugin_name"

    # Create async loading script
    local async_script="$ZSH_ASYNC_DIR/load_${plugin_name}.zsh"
    cat > "$async_script" << EOF
#!/opt/homebrew/bin/zsh
# Async plugin loader for: $plugin_name
# Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')

# Load plugin based on type
case "$plugin_type" in
    "oh-my-zsh")
        if command -v zgenom >/dev/null 2>&1; then
            zgenom oh-my-zsh "$plugin_source"
        fi
        ;;
    "github")
        if command -v zgenom >/dev/null 2>&1; then
            zgenom load "$plugin_source"
        fi
        ;;
    "local")
        if [[ -f "$plugin_source" ]]; then
            source "$plugin_source"
        fi
        ;;
esac

# Mark as loaded
echo "ASYNC_PLUGIN_LOADED:$plugin_name:\$(date +%s)" >> "$ZSH_ASYNC_DIR/loaded_plugins.log"
EOF

    chmod +x "$async_script"

    # Execute async loading
    (
        timeout "$ZSH_ASYNC_TIMEOUT" "$async_script" >/dev/null 2>&1
        local exit_code=$?
        if [[ $exit_code -eq 0 ]]; then
            echo "ASYNC_SUCCESS:$plugin_name:$(date +%s)" >> "$ZSH_ASYNC_DIR/async_results.log"
        else
            echo "ASYNC_FAILED:$plugin_name:$exit_code:$(date +%s)" >> "$ZSH_ASYNC_DIR/async_results.log"
        fi
    ) &

    local job_pid=$!
    ZSH_ASYNC_JOBS["plugin_${plugin_name}"]="$job_pid:$(date +%s)"

    _async_log "Started async plugin loading: $plugin_name (PID: $job_pid)" "DEBUG"
}

# 4.2. Check async job status
_check_async_jobs() {
    local completed_jobs=()

    for job_key in "${(@k)ZSH_ASYNC_JOBS}"; do
        local job_info="${ZSH_ASYNC_JOBS[$job_key]}"
        local job_pid="${job_info%:*}"
        local job_start="${job_info#*:}"

        # Check if job is still running
        if ! kill -0 "$job_pid" 2>/dev/null; then
            completed_jobs+=("$job_key")
            _async_log "Async job completed: $job_key" "DEBUG"
        else
            # Check for timeout
            local job_age=$(( $(date +%s) - job_start ))
            if [[ $job_age -gt $ZSH_ASYNC_TIMEOUT ]]; then
                kill "$job_pid" 2>/dev/null
                completed_jobs+=("$job_key")
                _async_log "Async job timed out: $job_key" "WARN"
            fi
        fi
    done

    # Remove completed jobs
    for job_key in "${completed_jobs[@]}"; do
        unset "ZSH_ASYNC_JOBS[$job_key]"
    done
}

## 5. Cache Maintenance and Utilities
#=============================================================================

# 5.1. Update cache manifest
_update_cache_manifest() {
    if [[ "$ZSH_CACHE_INITIALIZED" != "true" ]]; then
        return 0
    fi

    cat > "$ZSH_CACHE_MANIFEST" << EOF
#!/opt/homebrew/bin/zsh
# ZSH Cache Manifest - Auto-generated
# Last updated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')

# Cache registry
typeset -gA ZSH_CACHE_REGISTRY
EOF

    # Write cache registry
    for cache_key in "${(@k)ZSH_CACHE_REGISTRY}"; do
        echo "ZSH_CACHE_REGISTRY[$cache_key]=\"${ZSH_CACHE_REGISTRY[$cache_key]}\"" >> "$ZSH_CACHE_MANIFEST"
    done

    echo "" >> "$ZSH_CACHE_MANIFEST"
    echo "# Cache metadata" >> "$ZSH_CACHE_MANIFEST"
    echo "export ZSH_CACHE_UPDATED=\"$(date -u '+%Y-%m-%d %H:%M:%S UTC')\"" >> "$ZSH_CACHE_MANIFEST"
}

# 5.2. Clean expired cache
_clean_expired_cache() {
    _async_log "Cleaning expired cache entries..."

    local cleaned_count=0
    local current_time=$(date +%s)

    # Clean compiled files
    if [[ -d "$ZSH_COMPILED_DIR" ]]; then
        find "$ZSH_COMPILED_DIR" -name "*.zwc" -type f -mtime +1 -delete 2>/dev/null
        cleaned_count=$((cleaned_count + $(find "$ZSH_COMPILED_DIR" -name "*.zwc" -type f -mtime +1 | wc -l)))
    fi

    # Clean async files
    if [[ -d "$ZSH_ASYNC_DIR" ]]; then
        find "$ZSH_ASYNC_DIR" -name "*.zsh" -type f -mtime +1 -delete 2>/dev/null
        find "$ZSH_ASYNC_DIR" -name "*.log" -type f -mtime +7 -delete 2>/dev/null
    fi

    _async_log "Cache cleanup completed: $cleaned_count files removed"
}

# 5.3. Cache status and management commands
cache-status() {
    echo "========================================================"
    echo "Advanced Caching and Async Loading Status"
    echo "========================================================"
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

    echo "Cache Statistics:"
    if [[ -d "$ZSH_COMPILED_DIR" ]]; then
        local compiled_count=$(find "$ZSH_COMPILED_DIR" -name "*.zwc" -type f | wc -l)
        echo "  Compiled Files: $compiled_count"
    fi

    if [[ -d "$ZSH_ASYNC_DIR" ]]; then
        local async_count=$(find "$ZSH_ASYNC_DIR" -name "*.zsh" -type f | wc -l)
        echo "  Async Scripts: $async_count"
    fi

    echo "  Cache Registry Entries: ${#ZSH_CACHE_REGISTRY[@]}"
    echo "  Active Async Jobs: ${#ZSH_ASYNC_JOBS[@]}"

    if [[ ${#ZSH_ASYNC_JOBS[@]} -gt 0 ]]; then
        echo ""
        echo "Active Async Jobs:"
        for job_key in "${(@k)ZSH_ASYNC_JOBS}"; do
            local job_info="${ZSH_ASYNC_JOBS[$job_key]}"
            local job_pid="${job_info%:*}"
            local job_start="${job_info#*:}"
            local job_age=$(( $(date +%s) - job_start ))
            echo "  - $job_key (PID: $job_pid, Age: ${job_age}s)"
        done
    fi
}

cache-clean() {
    echo "Cleaning cache..."
    _clean_expired_cache
    _update_cache_manifest
    echo "Cache cleaned successfully"
}

cache-rebuild() {
    echo "Rebuilding cache..."
    rm -rf "$ZSH_COMPILED_DIR" "$ZSH_ASYNC_DIR"
    mkdir -p "$ZSH_COMPILED_DIR" "$ZSH_ASYNC_DIR"
    unset ZSH_CACHE_REGISTRY
    typeset -gA ZSH_CACHE_REGISTRY
    _update_cache_manifest
    echo "Cache rebuilt successfully"
}

## 6. Initialization
#=============================================================================

# 6.1. Initialize cache system
_init_cache_system

# 6.2. Set up periodic cache maintenance
if [[ "$ZSH_ENABLE_ASYNC" == "true" ]]; then
    # Clean up completed async jobs periodically
    _check_async_jobs
fi

[[ "$ZSH_DEBUG" == "1" ]] && _async_log "✅ Advanced caching and async loading system loaded successfully"

# ------------------------------------------------------------------------------
# 7. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

# Main function for when script is executed directly
async_main() {
    echo "========================================================"
    echo "ZSH Advanced Caching and Async Loading System"
    echo "========================================================"
    echo "Version: $ZSH_ASYNC_CACHE_VERSION"
    echo "Loaded: $ZSH_ASYNC_CACHE_LOADED"
    echo ""

    if declare -f get_execution_context >/dev/null 2>&1; then
        echo "Execution Context: $(get_execution_context)"
        echo ""
    fi

    cache-status

    if declare -f safe_exit >/dev/null 2>&1; then
        safe_exit 0
    else
        exit 0
    fi
}

# Use context-aware execution if detection system is available
if declare -f is_being_executed >/dev/null 2>&1; then
    if is_being_executed; then
        async_main "$@"
    fi
elif [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${(%):-%N}" == *"async-cache"* ]]; then
    # Fallback detection for direct execution
    async_main "$@"
fi

# ==============================================================================
# END: Advanced Caching and Async Loading System
# ==============================================================================
