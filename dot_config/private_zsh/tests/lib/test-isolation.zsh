#!/usr/bin/env zsh
# .config/zsh/tests/lib/test-isolation.zsh
#
# Test Isolation Framework for ZSH Configuration Tests
# Provides comprehensive test isolation with setup/teardown hooks,
# environment sandboxing, and temporary directory management.
#
# Features:
# - Per-test environment isolation
# - Automatic cleanup of temporary resources
# - Environment variable snapshot/restore
# - File system isolation with temporary directories
# - Process cleanup and signal handling
# - Test fixture management
#
# Usage:
#   source tests/lib/test-isolation.zsh
#   isolation_start_test "test-name"
#   # ... run test code ...
#   isolation_end_test
#

set -u

# Global isolation state
typeset -g ISOLATION_ACTIVE=0
typeset -g ISOLATION_TEST_NAME=""
typeset -g ISOLATION_TEMP_DIR=""
typeset -g ISOLATION_ORIGINAL_ENV=()
typeset -g ISOLATION_TEMP_FILES=()
typeset -g ISOLATION_CLEANUP_FUNCTIONS=()
typeset -g ISOLATION_BACKGROUND_PIDS=()
typeset -g ISOLATION_FIXTURES_DIR="${ZDOTDIR}/tests/fixtures"
typeset -g ISOLATION_DEBUG=${ISOLATION_DEBUG:-0}

# Configuration
typeset -g ISOLATION_PRESERVE_ENV=${ISOLATION_PRESERVE_ENV:-"HOME ZDOTDIR ZSH_CACHE_DIR ZSH_LOG_DIR PATH USER SHELL"}
typeset -g ISOLATION_TEMP_PREFIX=${ISOLATION_TEMP_PREFIX:-"zsh-test"}
typeset -g ISOLATION_MAX_TEMP_AGE=${ISOLATION_MAX_TEMP_AGE:-3600}  # 1 hour

# Debug logging
_isolation_debug() {
    if (( ISOLATION_DEBUG )); then
        printf "[ISOLATION] %s\n" "$*" >&2
    fi
}

# Error handling
_isolation_error() {
    printf "[ISOLATION ERROR] %s\n" "$*" >&2
    return 1
}

# Initialize isolation system
isolation_init() {
    _isolation_debug "Initializing test isolation system"

    # Create fixtures directory if it doesn't exist
    if [[ ! -d "$ISOLATION_FIXTURES_DIR" ]]; then
        mkdir -p "$ISOLATION_FIXTURES_DIR" || {
            _isolation_error "Failed to create fixtures directory: $ISOLATION_FIXTURES_DIR"
            return 1
        }
    fi

    # Clean up old temporary directories
    _isolation_cleanup_old_temps

    # Setup signal handlers for cleanup
    trap 'isolation_emergency_cleanup' EXIT INT TERM

    _isolation_debug "Isolation system initialized"
    return 0
}

# Start test isolation
isolation_start_test() {
    local test_name="${1:-unnamed-test}"

    if (( ISOLATION_ACTIVE )); then
        _isolation_error "Test isolation already active for: $ISOLATION_TEST_NAME"
        return 1
    fi

    _isolation_debug "Starting isolation for test: $test_name"

    ISOLATION_ACTIVE=1
    ISOLATION_TEST_NAME="$test_name"
    ISOLATION_TEMP_FILES=()
    ISOLATION_CLEANUP_FUNCTIONS=()
    ISOLATION_BACKGROUND_PIDS=()

    # Create test-specific temporary directory
    _isolation_create_temp_dir || return 1

    # Snapshot environment variables
    _isolation_snapshot_environment || return 1

    # Setup test environment
    _isolation_setup_test_environment || return 1

    _isolation_debug "Test isolation started for: $test_name"
    return 0
}

# End test isolation and cleanup
isolation_end_test() {
    if (( ! ISOLATION_ACTIVE )); then
        _isolation_debug "No active test isolation to end"
        return 0
    fi

    _isolation_debug "Ending isolation for test: $ISOLATION_TEST_NAME"

    # Run cleanup functions in reverse order
    local cleanup_func
    for cleanup_func in "${(@Oa)ISOLATION_CLEANUP_FUNCTIONS}"; do
        _isolation_debug "Running cleanup function: $cleanup_func"
        eval "$cleanup_func" || _isolation_error "Cleanup function failed: $cleanup_func"
    done

    # Kill background processes
    _isolation_kill_background_processes

    # Restore environment
    _isolation_restore_environment

    # Clean up temporary files and directories
    _isolation_cleanup_temp_resources

    # Reset state
    ISOLATION_ACTIVE=0
    ISOLATION_TEST_NAME=""
    ISOLATION_TEMP_DIR=""
    ISOLATION_ORIGINAL_ENV=()
    ISOLATION_TEMP_FILES=()
    ISOLATION_CLEANUP_FUNCTIONS=()
    ISOLATION_BACKGROUND_PIDS=()

    _isolation_debug "Test isolation ended"
    return 0
}

# Create temporary directory for test
_isolation_create_temp_dir() {
    local temp_base="${TMPDIR:-/tmp}"
    local temp_name="${ISOLATION_TEMP_PREFIX}-$$-$(date +%s)"

    ISOLATION_TEMP_DIR="${temp_base}/${temp_name}"

    if ! mkdir -p "$ISOLATION_TEMP_DIR"; then
        _isolation_error "Failed to create temporary directory: $ISOLATION_TEMP_DIR"
        return 1
    fi

    # Ensure directory is writable
    if [[ ! -w "$ISOLATION_TEMP_DIR" ]]; then
        _isolation_error "Temporary directory not writable: $ISOLATION_TEMP_DIR"
        return 1
    fi

    _isolation_debug "Created temporary directory: $ISOLATION_TEMP_DIR"
    return 0
}

# Snapshot current environment
_isolation_snapshot_environment() {
    ISOLATION_ORIGINAL_ENV=()

    # Snapshot preserved environment variables
    local var
    for var in ${=ISOLATION_PRESERVE_ENV}; do
        if [[ -v "$var" ]]; then
            ISOLATION_ORIGINAL_ENV+=("$var=${(P)var}")
        else
            ISOLATION_ORIGINAL_ENV+=("$var=__UNSET__")
        fi
    done

    _isolation_debug "Snapshotted environment: ${#ISOLATION_ORIGINAL_ENV} variables"
    return 0
}

# Setup isolated test environment
_isolation_setup_test_environment() {
    # Set test-specific environment variables
    export TEST_TEMP_DIR="$ISOLATION_TEMP_DIR"
    export TEST_NAME="$ISOLATION_TEST_NAME"
    export TEST_ISOLATION_ACTIVE=1

    # Create common test subdirectories
    mkdir -p "$ISOLATION_TEMP_DIR"/{cache,logs,config,data}

    # Override cache and log directories for isolation
    export ZSH_CACHE_DIR="$ISOLATION_TEMP_DIR/cache"
    export ZSH_LOG_DIR="$ISOLATION_TEMP_DIR/logs"

    _isolation_debug "Test environment configured"
    return 0
}

# Restore original environment
_isolation_restore_environment() {
    _isolation_debug "Restoring original environment"

    local env_entry var val
    for env_entry in "${ISOLATION_ORIGINAL_ENV[@]}"; do
        if [[ "$env_entry" == *=__UNSET__* ]]; then
            var="${env_entry%=__UNSET__*}"
            unset "$var" 2>/dev/null || true
        else
            var="${env_entry%%=*}"
            val="${env_entry#*=}"
            export "$var"="$val"
        fi
    done

    # Unset test-specific variables
    unset TEST_TEMP_DIR TEST_NAME TEST_ISOLATION_ACTIVE 2>/dev/null || true

    _isolation_debug "Environment restored"
}

# Clean up temporary resources
_isolation_cleanup_temp_resources() {
    _isolation_debug "Cleaning up temporary resources"

    # Remove temporary files
    local temp_file
    for temp_file in "${ISOLATION_TEMP_FILES[@]}"; do
        if [[ -e "$temp_file" ]]; then
            _isolation_debug "Removing temporary file: $temp_file"
            rm -f "$temp_file" || _isolation_error "Failed to remove: $temp_file"
        fi
    done

    # Remove temporary directory
    if [[ -n "$ISOLATION_TEMP_DIR" && -d "$ISOLATION_TEMP_DIR" ]]; then
        _isolation_debug "Removing temporary directory: $ISOLATION_TEMP_DIR"
        rm -rf "$ISOLATION_TEMP_DIR" || _isolation_error "Failed to remove: $ISOLATION_TEMP_DIR"
    fi
}

# Kill background processes started during test
_isolation_kill_background_processes() {
    local pid
    for pid in "${ISOLATION_BACKGROUND_PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            _isolation_debug "Killing background process: $pid"
            kill -TERM "$pid" 2>/dev/null || kill -KILL "$pid" 2>/dev/null || true
        fi
    done
}

# Clean up old temporary directories
_isolation_cleanup_old_temps() {
    local temp_base="${TMPDIR:-/tmp}"
    local cutoff_time=$(( $(date +%s) - ISOLATION_MAX_TEMP_AGE ))

    # Find and remove old test directories
    find "$temp_base" -maxdepth 1 -name "${ISOLATION_TEMP_PREFIX}-*" -type d 2>/dev/null | while IFS= read -r dir; do
        local dir_time
        if dir_time=$(stat -c %Y "$dir" 2>/dev/null) || dir_time=$(stat -f %m "$dir" 2>/dev/null); then
            if (( dir_time < cutoff_time )); then
                _isolation_debug "Removing old temporary directory: $dir"
                rm -rf "$dir" || true
            fi
        fi
    done
}

# Emergency cleanup (called on signals)
isolation_emergency_cleanup() {
    if (( ISOLATION_ACTIVE )); then
        _isolation_debug "Emergency cleanup triggered"
        isolation_end_test
    fi
}

# Test fixture management
isolation_create_fixture() {
    local fixture_name="$1"
    local fixture_content="${2:-}"

    if [[ -z "$fixture_name" ]]; then
        _isolation_error "Fixture name required"
        return 1
    fi

    local fixture_path="$ISOLATION_FIXTURES_DIR/$fixture_name"

    # Create fixture directory if needed
    local fixture_dir="${fixture_path%/*}"
    if [[ "$fixture_dir" != "$fixture_path" && ! -d "$fixture_dir" ]]; then
        mkdir -p "$fixture_dir" || return 1
    fi

    # Create fixture file
    if [[ -n "$fixture_content" ]]; then
        printf "%s" "$fixture_content" > "$fixture_path" || return 1
    else
        touch "$fixture_path" || return 1
    fi

    _isolation_debug "Created fixture: $fixture_path"
    printf "%s\n" "$fixture_path"
}

isolation_get_fixture() {
    local fixture_name="$1"
    local fixture_path="$ISOLATION_FIXTURES_DIR/$fixture_name"

    if [[ ! -e "$fixture_path" ]]; then
        _isolation_error "Fixture not found: $fixture_name"
        return 1
    fi

    printf "%s\n" "$fixture_path"
}

# Temporary file management
isolation_create_temp_file() {
    local suffix="${1:-.tmp}"
    local temp_file="$ISOLATION_TEMP_DIR/test-file-$$-$(date +%s)$suffix"

    touch "$temp_file" || {
        _isolation_error "Failed to create temporary file: $temp_file"
        return 1
    }

    ISOLATION_TEMP_FILES+=("$temp_file")
    _isolation_debug "Created temporary file: $temp_file"
    printf "%s\n" "$temp_file"
}

isolation_create_temp_dir() {
    local dir_name="${1:-test-dir-$$-$(date +%s)}"
    local temp_dir="$ISOLATION_TEMP_DIR/$dir_name"

    mkdir -p "$temp_dir" || {
        _isolation_error "Failed to create temporary directory: $temp_dir"
        return 1
    }

    _isolation_debug "Created temporary subdirectory: $temp_dir"
    printf "%s\n" "$temp_dir"
}

# Register cleanup function
isolation_register_cleanup() {
    local cleanup_func="$1"

    if [[ -z "$cleanup_func" ]]; then
        _isolation_error "Cleanup function required"
        return 1
    fi

    ISOLATION_CLEANUP_FUNCTIONS+=("$cleanup_func")
    _isolation_debug "Registered cleanup function: $cleanup_func"
}

# Register background process for cleanup
isolation_register_bg_process() {
    local pid="$1"

    if [[ -z "$pid" ]]; then
        _isolation_error "Process ID required"
        return 1
    fi

    ISOLATION_BACKGROUND_PIDS+=("$pid")
    _isolation_debug "Registered background process: $pid"
}

# Utility functions
isolation_is_active() {
    return $(( ! ISOLATION_ACTIVE ))
}

isolation_get_temp_dir() {
    if (( ! ISOLATION_ACTIVE )); then
        _isolation_error "No active test isolation"
        return 1
    fi
    printf "%s\n" "$ISOLATION_TEMP_DIR"
}

isolation_get_test_name() {
    if (( ! ISOLATION_ACTIVE )); then
        _isolation_error "No active test isolation"
        return 1
    fi
    printf "%s\n" "$ISOLATION_TEST_NAME"
}

# Initialize on source
isolation_init || {
    _isolation_error "Failed to initialize test isolation system"
    return 1
}
