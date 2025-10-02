#!/usr/bin/env zsh
# ==============================================================================
# ZSH Configuration: Centralized Completion Management
# ==============================================================================
# Purpose: Manage .zcompdump files to prevent proliferation and ensure
#          consistent completion system initialization across all ZSH sessions
#          with intelligent caching, cleanup, and performance optimization.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-22
# Version: 1.0
# Load Order: 3rd in 00-core (after path system, before other utilities)
# Dependencies: 01-source-execute-detection.zsh, 00-standard-helpers.zsh
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. SOURCE/EXECUTE DETECTION INTEGRATION
# ------------------------------------------------------------------------------

# Guard against multiple sourcing in non-040-testing environments
if [[ -n "${ZSH_COMPLETION_MANAGEMENT_LOADED:-}" && -z "${ZSH_COMPLETION_TESTING:-}" ]]; then
    return 0
fi

# Load source/execute detection system if not already loaded
if [[ -z "${ZSH_SOURCE_EXECUTE_LOADED:-}" ]]; then
    local detection_script="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00_01-source-execute-detection.zsh"
    if [[ -f "$detection_script" ]]; then
        source "$detection_script"
    else
        zf::debug "WARNING: Source/execute detection system not found: $detection_script"
        zf::debug "Completion management will work but without context-aware features"
    fi
fi

# Use context-aware logging if detection system is available
if declare -f context_zf::debug >/dev/null 2>&1; then
    # Legacy logging functions are now provided by unified logging system
    # These are kept as compatibility aliases in 00_04-unified-logging.zsh
    # No need to redefine here
    :
else
    # Fallback to unified logging system if context detection not available
    _comp_log() { zsh_log "${2:-INFO}" "completion" "$1"; }
    _comp_error() { zsh_error "completion" "$1" "$2"; }
fi

# 1. Global Configuration and Completion Setup
#=============================================================================

[[ "$ZSH_DEBUG" == "1" ]] && {
        zf::debug "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
    _comp_log "Loading centralized completion management system v1.0"
}

# 1.1. Set global completion management version for tracking
export ZSH_COMPLETION_MANAGEMENT_VERSION="1.0.0"
export ZSH_COMPLETION_MANAGEMENT_LOADED="2025-08-26T19:51:00Z"

# 1.2. Centralized completion configuration
export ZSH_COMPLETION_DIR="${ZDOTDIR:-$HOME/.config/zsh}/.completions"
export ZSH_COMPLETION_CACHE_DIR="${ZSH_COMPLETION_DIR}/cache"
export ZSH_COMPDUMP_FILE="${ZSH_COMPLETION_DIR}/zcompdump"
export ZSH_COMPDUMP_LOCK="${ZSH_COMPDUMP_FILE}.lock"

# Create completion directories
mkdir -p "$ZSH_COMPLETION_DIR" "$ZSH_COMPLETION_CACHE_DIR" 2>/dev/null || true

# 1.3. Completion management settings
export ZSH_ENABLE_COMPLETION_MANAGEMENT="${ZSH_ENABLE_COMPLETION_MANAGEMENT:-true}"
export ZSH_COMPLETION_REBUILD_DAYS="${ZSH_COMPLETION_REBUILD_DAYS:-7}"  # Rebuild weekly
export ZSH_COMPLETION_CLEANUP_OLD="${ZSH_COMPLETION_CLEANUP_OLD:-true}"  # Clean old files

# 1.4. Override plugin manager completion settings
export ZSH_COMPDUMP="$ZSH_COMPDUMP_FILE"  # Oh-My-Zsh
export ZGEN_CUSTOM_COMPDUMP="$ZSH_COMPDUMP_FILE"  # Zgenom
export ZGEN_COMPINIT_DIR_FLAG="-d $ZSH_COMPDUMP_FILE"  # Zgenom flags

# 2. Completion File Management
#=============================================================================

# 2.1. Clean up old and scattered .zcompdump files
_cleanup_old_compdump_files() {
    if [[ "$ZSH_COMPLETION_CLEANUP_OLD" != "true" ]]; then
        return 0
    fi

    _comp_log "Cleaning up old .zcompdump files..." "DEBUG"

    local cleanup_locations=(
        "$HOME/.zcompdump*"
        "${ZDOTDIR:-$HOME/.config/zsh}/.zcompdump*"
        "${ZDOTDIR:-$HOME/.config/zsh}/.zgenom/zcompdump_*"
        "${ZSH:-$HOME/.oh-my-zsh}/cache/.zcompdump*"
    )

    local cleaned_files=0

    for pattern in "${cleanup_locations[@]}"; do
for file in $~pattern(N); do
            # Skip if it's our centralized file or doesn't exist
            if [[ "$file" == "$ZSH_COMPDUMP_FILE" ]] || [[ ! -f "$file" ]]; then
                continue
            fi

            # Skip if file is very recent (less than 1 hour old)
            if [[ -n "$(find "$file" -mtime -1h 2>/dev/null)" ]]; then
                continue
            fi

            # Remove old file
            if rm -f "$file" 2>/dev/null; then
                cleaned_files=$((cleaned_files + 1))
                _comp_log "Removed old compdump: $file" "DEBUG"
            fi
        done
    done

    if [[ $cleaned_files -gt 0 ]]; then
        _comp_log "Cleaned up $cleaned_files old .zcompdump files"
    fi
}

# 2.2. Check if completion rebuild is needed
_completion_rebuild_needed() {
    # Always rebuild if file doesn't exist
    if [[ ! -f "$ZSH_COMPDUMP_FILE" ]]; then
        return 0
    fi

    # Check if file is older than rebuild threshold
    if command -v find >/dev/null 2>&1; then
        if [[ -n "$(find "$ZSH_COMPDUMP_FILE" -mtime +${ZSH_COMPLETION_REBUILD_DAYS} 2>/dev/null)" ]]; then
            return 0
        fi
    fi

    # Check if any completion directories are newer than dump file
    local completion_dirs=(
        "${ZDOTDIR:-$HOME/.config/zsh}/completions"
        "${ZDOTDIR:-$HOME/.config/zsh}/.zsh-completions.d"
        "/opt/homebrew/share/zsh/site-functions"
        "/usr/local/share/zsh/site-functions"
    )

    for dir in "${completion_dirs[@]}"; do
        if [[ -d "$dir" ]] && [[ "$dir" -nt "$ZSH_COMPDUMP_FILE" ]]; then
            return 0
        fi
    done

    return 1
}

# 2.3. Initialize completion system with centralized management
_initialize_completion_system() {
    if [[ "$ZSH_ENABLE_COMPLETION_MANAGEMENT" != "true" ]]; then
        return 0
    fi

    _comp_log "Initializing centralized completion system..." "DEBUG"

    # Clean up old files first
    _cleanup_old_compdump_files

    # Set up completion cache directory for zstyle
    zstyle ':completion:*' use-cache on
    zstyle ':completion:*' cache-path "$ZSH_COMPLETION_CACHE_DIR"

    # Add our completion directories to fpath
    local completion_dirs=(
        "${ZDOTDIR:-$HOME/.config/zsh}/completions"
        "${ZDOTDIR:-$HOME/.config/zsh}/.zsh-completions.d"
    )

    for dir in "${completion_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            fpath=("$dir" $fpath)
            _comp_log "Added to fpath: $dir" "DEBUG"
        fi
    done

    # Initialize completion system with centralized dump file
    autoload -Uz compinit

    # Use lock file to prevent concurrent initialization
    if mkdir "$ZSH_COMPDUMP_LOCK" 2>/dev/null; then
        local lock_acquired=true

        # Check if rebuild is needed
        if _completion_rebuild_needed; then
            _comp_log "Rebuilding completion system (file older than ${ZSH_COMPLETION_REBUILD_DAYS} days or missing)"
            compinit -d "$ZSH_COMPDUMP_FILE"
        else
            # Fast initialization without security check
            compinit -C -d "$ZSH_COMPDUMP_FILE"
        fi

        # Compile the dump file for faster loading
        if [[ -f "$ZSH_COMPDUMP_FILE" && ( ! -f "${ZSH_COMPDUMP_FILE}.zwc" || "$ZSH_COMPDUMP_FILE" -nt "${ZSH_COMPDUMP_FILE}.zwc" ) ]]; then
            zcompile "$ZSH_COMPDUMP_FILE" 2>/dev/null || true
            _comp_log "Compiled completion dump file" "DEBUG"
        fi

        # Remove lock
        rmdir "$ZSH_COMPDUMP_LOCK" 2>/dev/null || true
    else
        # Another process is initializing, wait briefly and use fast init
        sleep 0.1
        compinit -C -d "$ZSH_COMPDUMP_FILE" 2>/dev/null || compinit -d "$ZSH_COMPDUMP_FILE"
    fi

    _comp_log "Completion system initialized with centralized dump: $ZSH_COMPDUMP_FILE"
}

# 3. Completion Management Commands
#=============================================================================

# 3.1. Rebuild completions command
rebuild-completions() {
    zf::debug "🔄 Rebuilding ZSH completions..."

    # Remove existing dump files
    rm -f "$ZSH_COMPDUMP_FILE" "${ZSH_COMPDUMP_FILE}.zwc" 2>/dev/null

    # Clean up old scattered files
    _cleanup_old_compdump_files

    # Reinitialize
    _initialize_completion_system

    zf::debug "✅ Completions rebuilt successfully"
    zf::debug "📁 Completion dump: $ZSH_COMPDUMP_FILE"
}

# 3.2. Show completion status
completion-status() {
    zf::debug "========================================================"
    zf::debug "ZSH Completion Management Status"
    zf::debug "========================================================"
    zf::debug "Version: $ZSH_COMPLETION_MANAGEMENT_VERSION"
    zf::debug "Management Enabled: $ZSH_ENABLE_COMPLETION_MANAGEMENT"
    zf::debug "Rebuild Threshold: ${ZSH_COMPLETION_REBUILD_DAYS} days"
    zf::debug "Cleanup Old Files: $ZSH_COMPLETION_CLEANUP_OLD"
    zf::debug ""

    zf::debug "Completion Files:"
    zf::debug "  Dump File: $ZSH_COMPDUMP_FILE"
    if [[ -f "$ZSH_COMPDUMP_FILE" ]]; then
        local file_age
        if command -v stat >/dev/null 2>&1; then
            file_age=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$ZSH_COMPDUMP_FILE" 2>/dev/null || zf::debug "unknown")
        else
            file_age="unknown"
        fi
        zf::debug "    Status: ✅ Exists (modified: $file_age)"

        if [[ -f "${ZSH_COMPDUMP_FILE}.zwc" ]]; then
            zf::debug "    Compiled: ✅ Yes"
        else
            zf::debug "    Compiled: ❌ No"
        fi
    else
        zf::debug "    Status: ❌ Missing"
    fi

    zf::debug "  Cache Dir: $ZSH_COMPLETION_CACHE_DIR"
    if [[ -d "$ZSH_COMPLETION_CACHE_DIR" ]]; then
        local cache_files=$(find "$ZSH_COMPLETION_CACHE_DIR" -type f 2>/dev/null | wc -l)
        zf::debug "    Status: ✅ Exists ($cache_files cache files)"
    else
        zf::debug "    Status: ❌ Missing"
    fi

    zf::debug ""
    zf::debug "Completion Directories in fpath:"
    local comp_dirs=0
    for dir in $fpath; do
        if [[ "$dir" == *"completion"* ]] || [[ "$dir" == *"zsh/site-functions"* ]]; then
            if [[ -d "$dir" ]]; then
                local func_count=$(find "$dir" -name "_*" -type f 2>/dev/null | wc -l)
                zf::debug "  ✅ $dir ($func_count functions)"
                comp_dirs=$((comp_dirs + 1))
            fi
        fi
    done

    if [[ $comp_dirs -eq 0 ]]; then
        zf::debug "  ⚠️ No completion directories found in fpath"
    fi

    zf::debug ""
    zf::debug "Old .zcompdump Files:"
    local old_files=0
    local check_locations=(
        "$HOME/.zcompdump*"
        "${ZDOTDIR:-$HOME/.config/zsh}/.zcompdump*"
        "${ZDOTDIR:-$HOME/.config/zsh}/.zgenom/zcompdump_*"
    )

    for pattern in "${check_locations[@]}"; do
for file in $~pattern(N); do
            if [[ -f "$file" && "$file" != "$ZSH_COMPDUMP_FILE" ]]; then
                zf::debug "  ⚠️ $file"
                old_files=$((old_files + 1))
            fi
        done
    done

    if [[ $old_files -eq 0 ]]; then
        zf::debug "  ✅ No old .zcompdump files found"
    else
        zf::debug "  💡 Run 'cleanup-old-completions' to remove old files"
    fi
}

# 3.3. Clean up old completion files
cleanup-old-completions() {
    zf::debug "🧹 Cleaning up old .zcompdump files..."

    local original_setting="$ZSH_COMPLETION_CLEANUP_OLD"
    export ZSH_COMPLETION_CLEANUP_OLD="true"

    _cleanup_old_compdump_files

    export ZSH_COMPLETION_CLEANUP_OLD="$original_setting"

    zf::debug "✅ Cleanup complete"
}

# 4. Initialization
#=============================================================================

# 4.1. Initialize completion management system
_initialize_completion_system

[[ "$ZSH_DEBUG" == "1" ]] && _comp_log "✅ Centralized completion management loaded successfully"

# ------------------------------------------------------------------------------
# 5. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

# Main function for when script is executed directly
completion_management_main() {
    zf::debug "========================================================"
    zf::debug "ZSH Centralized Completion Management"
    zf::debug "========================================================"
    zf::debug "Version: $ZSH_COMPLETION_MANAGEMENT_VERSION"
    zf::debug "Loaded: $ZSH_COMPLETION_MANAGEMENT_LOADED"
    zf::debug ""

    if declare -f get_execution_context >/dev/null 2>&1; then
        zf::debug "Execution Context: $(get_execution_context)"
        zf::debug ""
    fi

    completion-status

    if declare -f safe_exit >/dev/null 2>&1; then
        safe_exit 0
    else
        exit 0
    fi
}

# Use context-aware execution if detection system is available
if declare -f is_being_executed >/dev/null 2>&1; then
    if is_being_executed; then
        completion_management_main "$@"
    fi
elif [[ "${(%):-%N}" == "$0" ]] || [[ "${(%):-%N}" == *"completion-management"* ]]; then
    # Fallback detection for direct execution
    completion_management_main "$@"
fi

# ==============================================================================
# END: Centralized Completion Management
# ==============================================================================
