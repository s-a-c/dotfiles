#!/usr/bin/env zsh
# ==============================================================================
# ZSH Legacy Configuration: Completion System Module
# ==============================================================================
# Purpose: Comprehensive completion system with centralized management, 
#          performance optimization, intelligent caching, and instrumentation
# 
# Consolidated from:
#   - DISABLED-00_20-completion-management.zsh (centralized management)
#   - DISABLED-00_28-completion-finalization.zsh (safe initialization)
#   - DISABLED-10_70-completion.zsh (integration and styles)
#   - 50-completion-history.zsh (REDESIGN performance instrumentation)
#   - 55-compinit-instrument.zsh (REDESIGN timing instrumentation)
#
# Dependencies: 01-core-infrastructure.zsh (for logging and path helpers)
# Load Order: Early-Mid (60-69 range, after core but before UI)
# Author: ZSH Legacy Consolidation System
# Created: 2025-09-15
# Version: 1.0.0
# ==============================================================================

# Prevent multiple loading
if [[ -n "${_COMPLETION_SYSTEM_LOADED:-}" ]]; then
    return 0
fi
export _COMPLETION_SYSTEM_LOADED=1

# Debug helper - use core infrastructure if available
_comp_debug() {
    if command -v debug_log >/dev/null 2>&1; then
        debug_log "$1"
    elif [[ -n "${ZSH_DEBUG:-}" ]]; then
        echo "[COMP-DEBUG] $1" >&2
    fi
}

_comp_debug "Loading completion system module..."

# ==============================================================================
# SECTION 1: CONFIGURATION AND GLOBAL SETTINGS
# ==============================================================================
# Purpose: Set up centralized completion configuration and directory management

_comp_debug "Setting up completion configuration..."

# 1.1. Version and metadata
export ZSH_COMPLETION_SYSTEM_VERSION="1.0.0"
export ZSH_COMPLETION_SYSTEM_LOADED="$(date '+%Y-%m-%d %H:%M:%S')"

# 1.2. Feature toggles and configuration
export ZSH_ENABLE_COMPLETION_MANAGEMENT="${ZSH_ENABLE_COMPLETION_MANAGEMENT:-true}"
export ZSH_COMPLETION_REBUILD_DAYS="${ZSH_COMPLETION_REBUILD_DAYS:-7}"
export ZSH_COMPLETION_CLEANUP_OLD="${ZSH_COMPLETION_CLEANUP_OLD:-true}"
export ZSH_COMPINIT_INSTRUMENT="${ZSH_COMPINIT_INSTRUMENT:-1}"
export ZSH_COMPINIT_STRATEGY="${ZSH_COMPINIT_STRATEGY:-fast}"
export ZSH_COMPINIT_FAST_FALLBACK="${ZSH_COMPINIT_FAST_FALLBACK:-1}"

# 1.3. Centralized directory configuration
export ZSH_COMPLETION_DIR="${ZDOTDIR:-$HOME/.config/zsh}/.completions"
export ZSH_COMPLETION_CACHE_DIR="${ZSH_COMPLETION_DIR}/cache"
export ZSH_COMPDUMP_FILE="${ZSH_COMPLETION_DIR}/zcompdump"
export ZSH_COMPDUMP_LOCK="${ZSH_COMPDUMP_FILE}.lock"

# Override plugin manager settings
export ZSH_COMPDUMP="$ZSH_COMPDUMP_FILE"  # Oh-My-Zsh
export ZGEN_CUSTOM_COMPDUMP="$ZSH_COMPDUMP_FILE"  # Zgenom
export ZGEN_COMPINIT_DIR_FLAG="-d $ZSH_COMPDUMP_FILE"  # Zgenom flags

# Create completion directories
mkdir -p "$ZSH_COMPLETION_DIR" "$ZSH_COMPLETION_CACHE_DIR" 2>/dev/null || true

_comp_debug "Completion directories configured: $ZSH_COMPLETION_DIR"

# ==============================================================================
# SECTION 2: PERFORMANCE INSTRUMENTATION
# ==============================================================================
# Purpose: Timing and performance measurement for completion operations

_comp_debug "Setting up performance instrumentation..."

# 2.1. High-precision timing utilities
zmodload zsh/datetime 2>/dev/null || true

_comp_now_ms() {
    if [[ -n "${EPOCHREALTIME:-}" ]]; then
        printf '%s' "$EPOCHREALTIME" | awk -F. '{ms=($1*1000); if(NF>1){ms+=substr($2"000",1,3)+0} printf "%d", ms}'
    else
        date +%s 2>/dev/null | awk '{printf "%d",$1*1000}'
    fi
}

# 2.2. Segment timing for completion phases
typeset -gA _COMP_SEGMENT_START

_comp_segment() {
    local name="$1" action="$2"
    
    if [[ "$action" == "start" ]]; then
        _COMP_SEGMENT_START[$name]=$(_comp_now_ms)
        _comp_debug "Started timing segment: $name"
    elif [[ "$action" == "end" && -n "${_COMP_SEGMENT_START[$name]:-}" ]]; then
        local end_ms=$(_comp_now_ms)
        local delta=$(( end_ms - _COMP_SEGMENT_START[$name] ))
        (( delta < 0 )) && delta=0
        
        # Log to performance segment file if available
        if [[ -n "${PERF_SEGMENT_LOG:-}" && -w "${PERF_SEGMENT_LOG}" ]]; then
            local sample="${PERF_SAMPLE_CONTEXT:-unknown}"
            echo "SEGMENT name=completion/${name} ms=${delta} phase=post_plugin sample=${sample}" >> "${PERF_SEGMENT_LOG}" 2>/dev/null || true
            echo "POST_PLUGIN_SEGMENT completion/${name} ${delta}" >> "${PERF_SEGMENT_LOG}" 2>/dev/null || true
        fi
        
        _comp_debug "Completed segment: $name (${delta}ms)"
        unset "_COMP_SEGMENT_START[$name]"
        echo "$delta"
    fi
}

# ==============================================================================
# SECTION 3: COMPLETION FILE MANAGEMENT
# ==============================================================================
# Purpose: Manage .zcompdump files, cleanup, and rebuild logic

_comp_debug "Setting up completion file management..."

# 3.1. Clean up old and scattered .zcompdump files
cleanup_old_compdump_files() {
    if [[ "$ZSH_COMPLETION_CLEANUP_OLD" != "true" ]]; then
        return 0
    fi

    _comp_debug "Cleaning up old .zcompdump files..."

    local cleanup_locations=(
        "$HOME/.zcompdump*"
        "${ZDOTDIR:-$HOME/.config/zsh}/.zcompdump*"
        "${ZDOTDIR:-$HOME/.config/zsh}/.zgenom/zcompdump_*"
        "${ZSH:-$HOME/.oh-my-zsh}/cache/.zcompdump*"
    )

    local cleaned_files=0

    for pattern in "${cleanup_locations[@]}"; do
        for file in ${~pattern}(N); do
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
                _comp_debug "Removed old compdump: $file"
            fi
        done
    done

    if [[ $cleaned_files -gt 0 ]]; then
        _comp_debug "Cleaned up $cleaned_files old .zcompdump files"
    fi
}

# 3.2. Check if completion rebuild is needed
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

# ==============================================================================
# SECTION 4: ADVANCED COMPLETION STYLES AND CONFIGURATION
# ==============================================================================
# Purpose: Configure zstyle settings for optimal completion experience

_comp_debug "Setting up advanced completion styles..."

setup_completion_styles() {
    _comp_segment "styles-setup" "start"
    
    # Basic completion styles
    zstyle ':completion:*' menu select 2>/dev/null
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 2>/dev/null
    zstyle ':completion:*' use-cache on 2>/dev/null
    zstyle ':completion:*' cache-path "$ZSH_COMPLETION_CACHE_DIR" 2>/dev/null

    # Advanced completion styles
    zstyle ':completion:*' verbose yes
    zstyle ':completion:*:descriptions' format '%B%d%b'
    zstyle ':completion:*:messages' format '%d'
    zstyle ':completion:*:warnings' format 'No matches for: %d'
    zstyle ':completion:*' group-name ''
    
    # Case-insensitive completion
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
    
    # Completion for specific commands
    zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
    zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
    
    # Directory completion
    zstyle ':completion:*:cd:*' ignore-parents parent pwd
    zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
    
    # Git completion optimizations
    zstyle ':completion:*:*:git:*' script /opt/homebrew/share/zsh/site-functions/git-completion.bash 2>/dev/null || true
    zstyle ':completion:*:*:git*:*' ignore-line true
    
    # SSH completion
    zstyle ':completion:*:(ssh|scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
    zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
    zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host users hosts-ipaddr
    zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
    zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
    zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'
    
    _comp_segment "styles-setup" "end"
    _comp_debug "Advanced completion styles configured"
}

# ==============================================================================
# SECTION 5: FPATH MANAGEMENT
# ==============================================================================
# Purpose: Manage function path for completion discovery

_comp_debug "Setting up fpath management..."

setup_completion_fpath() {
    _comp_segment "fpath-setup" "start"
    
    local completion_dirs=(
        "${ZDOTDIR:-$HOME/.config/zsh}/completions"
        "${ZDOTDIR:-$HOME/.config/zsh}/.zsh-completions.d"
        "/opt/homebrew/share/zsh/site-functions"
        "/usr/local/share/zsh/site-functions"
        "${HOME}/.local/share/zsh/completions"
    )

    local added_dirs=0
    for dir in "${completion_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            # Add to fpath if not already present
            if [[ -z ${fpath[(r)$dir]} ]]; then
                fpath=("$dir" $fpath)
                added_dirs=$((added_dirs + 1))
                _comp_debug "Added to fpath: $dir"
            fi
        fi
    done

    # Ensure fpath is unique
    typeset -gU fpath
    
    _comp_segment "fpath-setup" "end"
    _comp_debug "fpath configured with $added_dirs completion directories"
}

# ==============================================================================
# SECTION 6: COMPINIT INITIALIZATION WITH INSTRUMENTATION
# ==============================================================================
# Purpose: Initialize completion system with comprehensive timing and safety checks

_comp_debug "Setting up compinit initialization..."

initialize_completion_system() {
    if [[ "$ZSH_ENABLE_COMPLETION_MANAGEMENT" != "true" ]]; then
        _comp_debug "Completion management disabled"
        return 0
    fi

    # Skip if already initialized
    if [[ -n "${ZSH_COMPINIT_RAN:-}" || -n "${_COMPINIT_INITIALIZED:-}" || -n "${_COMPINIT_DONE:-}" ]]; then
        _comp_debug "Completion system already initialized"
        return 0
    fi

    _comp_segment "compinit-full" "start"
    _comp_debug "Initializing completion system..."

    # Clean up old files first
    cleanup_old_compdump_files

    # Setup fpath and styles
    setup_completion_fpath
    setup_completion_styles

    # Ensure compinit is available
    autoload -Uz compinit || {
        _comp_debug "compinit not available"
        return 1
    }

    local compinit_result=0
    local strategy="$ZSH_COMPINIT_STRATEGY"

    # Use lock file to prevent concurrent initialization
    if mkdir "$ZSH_COMPDUMP_LOCK" 2>/dev/null; then
        _comp_segment "compinit-exec" "start"
        
        # Determine initialization strategy
        case "$strategy" in
            fast|FAST)
                _comp_debug "Using fast compinit strategy"
                compinit -C -d "$ZSH_COMPDUMP_FILE" || compinit_result=$?
                ;;
            normal|NORMAL|std)
                _comp_debug "Using normal compinit strategy"
                compinit -d "$ZSH_COMPDUMP_FILE" || compinit_result=$?
                ;;
            secure|SECURE|audit)
                _comp_debug "Using secure compinit strategy"
                
                # Run compaudit first for security analysis
                local insecure_paths=()
                if autoload -Uz compaudit 2>/dev/null; then
                    while IFS= read -r p; do
                        [[ -n $p ]] && insecure_paths+=("$p")
                    done < <(compaudit 2>/dev/null)
                fi
                
                local insecure_count=${#insecure_paths[@]}
                if (( insecure_count > 0 )); then
                    _comp_debug "WARNING: ${insecure_count} insecure path(s) detected"
                fi
                
                compinit -d "$ZSH_COMPDUMP_FILE" || compinit_result=$?
                
                # Fallback to fast if secure fails and fallback is enabled
                if (( compinit_result != 0 )) && [[ "$ZSH_COMPINIT_FAST_FALLBACK" == "1" ]]; then
                    _comp_debug "Secure strategy failed, retrying with fast fallback"
                    compinit -C -d "$ZSH_COMPDUMP_FILE" || compinit_result=$?
                fi
                ;;
            *)
                # Default to checking if rebuild is needed
                if _completion_rebuild_needed; then
                    _comp_debug "Rebuilding completion system (stale or missing)"
                    compinit -d "$ZSH_COMPDUMP_FILE" || compinit_result=$?
                else
                    _comp_debug "Using cached completion system"
                    compinit -C -d "$ZSH_COMPDUMP_FILE" || compinit_result=$?
                fi
                ;;
        esac

        _comp_segment "compinit-exec" "end"

        # Compile the dump file for faster loading
        if [[ -f "$ZSH_COMPDUMP_FILE" && ( ! -f "${ZSH_COMPDUMP_FILE}.zwc" || "$ZSH_COMPDUMP_FILE" -nt "${ZSH_COMPDUMP_FILE}.zwc" ) ]]; then
            _comp_segment "zcompile" "start"
            if zcompile "$ZSH_COMPDUMP_FILE" 2>/dev/null; then
                _comp_debug "Compiled completion dump file"
            fi
            _comp_segment "zcompile" "end"
        fi

        # Remove lock
        rmdir "$ZSH_COMPDUMP_LOCK" 2>/dev/null || true
    else
        # Another process is initializing, wait briefly and use fast init
        _comp_debug "Another process initializing, using fast init"
        sleep 0.1
        compinit -C -d "$ZSH_COMPDUMP_FILE" 2>/dev/null || compinit -d "$ZSH_COMPDUMP_FILE" || compinit_result=$?
    fi

    # Mark as initialized if successful
    if (( compinit_result == 0 )); then
        export ZSH_COMPINIT_RAN=1
        export _COMPINIT_INITIALIZED=1
        export _COMPINIT_DONE=1
        _comp_debug "Completion system initialized successfully"
    else
        _comp_debug "Completion system initialization failed (rc=$compinit_result)"
    fi

    _comp_segment "compinit-full" "end"
    return $compinit_result
}

# ==============================================================================
# SECTION 7: BASH COMPLETION INTEGRATION
# ==============================================================================
# Purpose: Enable bash completion compatibility

_comp_debug "Setting up bash completion integration..."

setup_bash_completions() {
    _comp_segment "bashcompinit" "start"
    
    if autoload -Uz bashcompinit 2>/dev/null; then
        if bashcompinit 2>/dev/null; then
            _comp_debug "Bash completions enabled"
        else
            _comp_debug "Failed to enable bash completions"
        fi
    else
        _comp_debug "bashcompinit not available"
    fi
    
    _comp_segment "bashcompinit" "end"
}

# ==============================================================================
# SECTION 8: HISTORY CONFIGURATION
# ==============================================================================
# Purpose: Configure ZSH history settings for better completion experience

_comp_debug "Setting up history configuration..."

setup_history_configuration() {
    if [[ -n "${_HISTORY_CONFIGURED:-}" ]]; then
        _comp_debug "History already configured"
        return 0
    fi

    _comp_segment "history-setup" "start"

    # Set history file and limits
    export HISTFILE="${HISTFILE:-${ZDOTDIR:-$HOME}/.zsh_history}"
    export HISTSIZE="${HISTSIZE:-10000}"
    export SAVEHIST="${SAVEHIST:-10000}"

    # History options for better experience
    setopt HIST_IGNORE_DUPS      # Don't record duplicate entries
    setopt HIST_IGNORE_SPACE     # Don't record entries starting with space
    setopt HIST_VERIFY           # Show command before executing from history
    setopt SHARE_HISTORY         # Share history between sessions
    setopt HIST_REDUCE_BLANKS    # Remove extra blanks from commands
    setopt HIST_IGNORE_ALL_DUPS  # Remove older duplicates
    setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicates first when trimming history

    export _HISTORY_CONFIGURED=1
    _comp_segment "history-setup" "end"
    _comp_debug "History configured with HISTFILE=$HISTFILE"
}

# ==============================================================================
# SECTION 9: COMPLETION MANAGEMENT COMMANDS
# ==============================================================================
# Purpose: Provide user commands for completion system management

_comp_debug "Setting up completion management commands..."

# 9.1. Rebuild completions command
rebuild-completions() {
    echo "🔄 Rebuilding ZSH completions..."

    # Remove existing dump files
    rm -f "$ZSH_COMPDUMP_FILE" "${ZSH_COMPDUMP_FILE}.zwc" 2>/dev/null

    # Clean up old scattered files
    cleanup_old_compdump_files

    # Clear initialization flags
    unset ZSH_COMPINIT_RAN _COMPINIT_INITIALIZED _COMPINIT_DONE

    # Reinitialize
    initialize_completion_system

    echo "✅ Completions rebuilt successfully"
    echo "📁 Completion dump: $ZSH_COMPDUMP_FILE"
}

# 9.2. Show completion status
completion-status() {
    echo "========================================================"
    echo "ZSH Completion System Status"
    echo "========================================================"
    echo "Version: $ZSH_COMPLETION_SYSTEM_VERSION"
    echo "Management Enabled: $ZSH_ENABLE_COMPLETION_MANAGEMENT"
    echo "Rebuild Threshold: ${ZSH_COMPLETION_REBUILD_DAYS} days"
    echo "Cleanup Old Files: $ZSH_COMPLETION_CLEANUP_OLD"
    echo "Compinit Strategy: $ZSH_COMPINIT_STRATEGY"
    echo ""

    echo "Completion Files:"
    echo "  Dump File: $ZSH_COMPDUMP_FILE"
    if [[ -f "$ZSH_COMPDUMP_FILE" ]]; then
        local file_age
        if command -v stat >/dev/null 2>&1; then
            file_age=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$ZSH_COMPDUMP_FILE" 2>/dev/null || echo "unknown")
        else
            file_age="unknown"
        fi
        echo "    Status: ✅ Exists (modified: $file_age)"

        if [[ -f "${ZSH_COMPDUMP_FILE}.zwc" ]]; then
            echo "    Compiled: ✅ Yes"
        else
            echo "    Compiled: ❌ No"
        fi
    else
        echo "    Status: ❌ Missing"
    fi

    echo "  Cache Dir: $ZSH_COMPLETION_CACHE_DIR"
    if [[ -d "$ZSH_COMPLETION_CACHE_DIR" ]]; then
        local cache_files=$(find "$ZSH_COMPLETION_CACHE_DIR" -type f 2>/dev/null | wc -l)
        echo "    Status: ✅ Exists ($cache_files cache files)"
    else
        echo "    Status: ❌ Missing"
    fi

    echo ""
    echo "Completion Directories in fpath:"
    local comp_dirs=0
    for dir in $fpath; do
        if [[ "$dir" == *"completion"* ]] || [[ "$dir" == *"zsh/site-functions"* ]]; then
            if [[ -d "$dir" ]]; then
                local func_count=$(find "$dir" -name "_*" -type f 2>/dev/null | wc -l)
                echo "  ✅ $dir ($func_count functions)"
                comp_dirs=$((comp_dirs + 1))
            fi
        fi
    done

    if [[ $comp_dirs -eq 0 ]]; then
        echo "  ⚠️ No completion directories found in fpath"
    fi

    echo ""
    echo "Initialization Status:"
    if [[ -n "${ZSH_COMPINIT_RAN:-}" ]]; then
        echo "  ✅ Compinit executed"
    else
        echo "  ❌ Compinit not executed"
    fi
    
    if [[ -n "${_COMPINIT_INITIALIZED:-}" ]]; then
        echo "  ✅ Initialization completed"
    else
        echo "  ❌ Initialization not completed"
    fi
}

# 9.3. Clean up old completion files
cleanup-old-completions() {
    echo "🧹 Cleaning up old .zcompdump files..."

    local original_setting="$ZSH_COMPLETION_CLEANUP_OLD"
    export ZSH_COMPLETION_CLEANUP_OLD="true"

    cleanup_old_compdump_files

    export ZSH_COMPLETION_CLEANUP_OLD="$original_setting"

    echo "✅ Cleanup complete"
}

# ==============================================================================
# MODULE INITIALIZATION
# ==============================================================================

_comp_debug "Initializing completion system module..."

# Initialize history configuration first
setup_history_configuration

# Initialize completion system
initialize_completion_system

# Setup bash completions if compinit succeeded
if [[ -n "${ZSH_COMPINIT_RAN:-}" ]]; then
    setup_bash_completions
fi

# Set completion system metadata
local completion_functions=0
if [[ -d "$ZSH_COMPLETION_DIR" ]]; then
    completion_functions=$(find "$ZSH_COMPLETION_DIR" -name "_*" -type f 2>/dev/null | wc -l)
fi

export COMPLETION_FUNCTIONS_COUNT=$completion_functions

_comp_debug "Completion system module ready ($completion_functions completion functions)"

# ==============================================================================
# MODULE SELF-TEST
# ==============================================================================

test_completion_system() {
    local tests_passed=0
    local tests_total=12
    
    # Test 1: Module loaded
    if [[ -n "$ZSH_COMPLETION_SYSTEM_VERSION" ]]; then
        ((tests_passed++))
        echo "✅ Module metadata available"
    else
        echo "❌ Module metadata missing"
    fi
    
    # Test 2: Directories created
    if [[ -d "$ZSH_COMPLETION_DIR" ]] && [[ -d "$ZSH_COMPLETION_CACHE_DIR" ]]; then
        ((tests_passed++))
        echo "✅ Completion directories created"
    else
        echo "❌ Completion directories missing"
    fi
    
    # Test 3: Compinit available
    if command -v compinit >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ compinit available"
    else
        echo "❌ compinit not available"
    fi
    
    # Test 4: History configured
    if [[ -n "$HISTFILE" ]] && [[ "$HISTSIZE" -gt 0 ]]; then
        ((tests_passed++))
        echo "✅ History configuration set"
    else
        echo "❌ History configuration missing"
    fi
    
    # Test 5: Completion styles set
    if zstyle -t ':completion:*' use-cache; then
        ((tests_passed++))
        echo "✅ Completion styles configured"
    else
        echo "❌ Completion styles not configured"
    fi
    
    # Test 6: Management commands available
    if command -v rebuild-completions >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Management commands available"
    else
        echo "❌ Management commands missing"
    fi
    
    # Test 7: fpath configured
    if [[ ${#fpath[@]} -gt 0 ]]; then
        ((tests_passed++))
        echo "✅ fpath configured"
    else
        echo "❌ fpath not configured"
    fi
    
    # Test 8: Performance instrumentation
    if command -v _comp_segment >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Performance instrumentation available"
    else
        echo "❌ Performance instrumentation missing"
    fi
    
    # Test 9: Initialization status
    if [[ -n "${ZSH_COMPINIT_RAN:-}" ]] || [[ -n "${_COMPINIT_INITIALIZED:-}" ]]; then
        ((tests_passed++))
        echo "✅ Completion system initialized"
    else
        echo "❌ Completion system not initialized"
    fi
    
    # Test 10: File management functions
    if command -v cleanup_old_compdump_files >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ File management functions available"
    else
        echo "❌ File management functions missing"
    fi
    
    # Test 11: Lock file handling
    if [[ ! -d "$ZSH_COMPDUMP_LOCK" ]]; then
        ((tests_passed++))
        echo "✅ No stale lock files"
    else
        echo "❌ Stale lock file present"
    fi
    
    # Test 12: Completion dump file
    if [[ -f "$ZSH_COMPDUMP_FILE" ]]; then
        ((tests_passed++))
        echo "✅ Completion dump file exists"
    else
        echo "❌ Completion dump file missing"
    fi
    
    echo ""
    echo "Completion System Self-Test: $tests_passed/$tests_total tests passed"
    echo "📁 Completion directory: $ZSH_COMPLETION_DIR"
    echo "📊 Completion functions: $COMPLETION_FUNCTIONS_COUNT"
    echo "🗂️  Module version: $ZSH_COMPLETION_SYSTEM_VERSION"
    echo "⚡ Strategy: $ZSH_COMPINIT_STRATEGY"
    
    if [[ $tests_passed -eq $tests_total ]]; then
        return 0
    else
        return 1
    fi
}

# ==============================================================================
# END OF COMPLETION SYSTEM MODULE
# ==============================================================================