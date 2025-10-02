#!/usr/bin/env zsh
#=============================================================================
# File: 03-macos-defaults-deferred.zsh
# Purpose: 2.1 Deferred execution wrapper for macOS defaults configuration
# Dependencies: macOS (Darwin), ~/bin/macos-defaults-setup.zsh
# Author: Configuration management system
# Last Modified: 2025-08-20
#=============================================================================

# Load source/execute detection utils if present (optional)
{
    DETECTION_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00_01-source-execute-detection.zsh"
    if [ -r "$DETECTION_SCRIPT" ]; then
        export ZSH_SOURCE_EXECUTE_TESTING=false
        source "$DETECTION_SCRIPT"
    fi
}

[[ "$ZSH_DEBUG" == "1" ]] && {
    zf::debug "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
}

# 2.1 macOS-only execution guard
if [[ "$(uname)" != "Darwin" ]]; then
    return 0
fi

# 2.2 Interactive session check (only run in interactive sessions)
if [[ ! -o interactive ]]; then
    return 0
fi

# 2.3 Deferred macOS Defaults Execution Wrapper Function
_deferred_macos_defaults() {
    # 2.3.1 Working Directory Management - Save current working directory
    local original_cwd="$(pwd)"

    # 2.3.2 Configuration paths - use ZDOTDIR/XDG defaults
    local config_base="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
    local setup_script="$config_base/bin/macos-defaults-setup.zsh"
    local marker_file="$config_base/.macos-defaults-last-run"

    # Robust date values with fallbacks
    local log_date log_time
    log_date="$(date -u +%Y-%m-%d 2>/dev/null || printf 'unknown-date')"
    log_time="$(date -u +%H-%M-%S 2>/dev/null || printf '%(%s)T' -1 2>/dev/null || printf 'unknown-time')"

    # Setup logging with fallbacks
    local log_dir log_file
    log_dir="$config_base/logs/$log_date"
    mkdir -p "$log_dir" 2>/dev/null || true
    if [[ ! -d "$log_dir" ]]; then
        log_dir="${TMPDIR:-/tmp}/zsh-logs-${USER:-user}/$log_date"
        mkdir -p "$log_dir" 2>/dev/null || true
    fi
    [[ -d "$log_dir" ]] || log_dir="${TMPDIR:-/tmp}"

    log_file="$log_dir/deferred-macos-defaults_${log_time}.log"
    # Validate log_file usability; if invalid, disable file logging
    if [[ -z "$log_file" || ! -d "$log_dir" ]]; then
        log_file=""
    fi

    # 2.3.3 Setup comprehensive logging with proper guards
    _log_and_execute() {
        zf::debug "=============================================================================="
        zf::debug "Deferred macOS Defaults Wrapper Execution"
        zf::debug "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        [[ -n "$log_file" ]] && zf::debug "Log file: $log_file"
        zf::debug "=============================================================================="
        zf::debug ""

        # 2.3.4 Check if setup script exists
        if [[ ! -x "$setup_script" ]]; then
            zf::debug "❌ Setup script not found or not executable: $setup_script"
            return 1
        fi

        # 2.3.5 Determine if defaults need to be run
        local needs_run=false
        local run_reason=""

        # Check if marker file exists
        if [[ ! -f "$marker_file" ]]; then
            needs_run=true
            run_reason="First run - no marker file found"
        else
            # Check if setup script is newer than marker file
            if [[ "$setup_script" -nt "$marker_file" ]]; then
                needs_run=true
                run_reason="Setup script modified since last run"
            else
                # Check if it's been more than 24 hours since last run
                local marker_timestamp=$(stat -f %m "$marker_file" 2>/dev/null || zf::debug "0")
                local current_timestamp=$(date +%s)
                local time_diff=$((current_timestamp - marker_timestamp))
                local hours_diff=$((time_diff / 3600))

                if [[ $hours_diff -gt 24 ]]; then
                    needs_run=true
                    run_reason="More than 24 hours since last run ($hours_diff hours)"
                fi
            fi
        fi

        # 2.3.6 Execute or skip based on needs
        if [[ "$needs_run" == "true" ]]; then
            zf::debug "🔄 Running macOS defaults setup - $run_reason"
            zf::debug ""

            # Execute the setup script
            if "$setup_script"; then
                # Update marker file on successful completion
                zf::debug "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >"$marker_file"
                zf::debug ""
                zf::debug "✅ macOS defaults setup completed successfully"
                zf::debug "📄 Marker file updated: $marker_file"
            else
                local exit_code=$?
                zf::debug ""
                zf::debug "❌ macOS defaults setup failed with exit code: $exit_code"
                return 1
            fi
        else
            zf::debug "⏭️  Skipping macOS defaults setup - already up to date"
            zf::debug "📄 Last run: $(cat "$marker_file" 2>/dev/null || zf::debug "Unknown")"
        fi

        zf::debug ""
        zf::debug "=============================================================================="
        zf::debug "Deferred macOS defaults wrapper completed at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        zf::debug "=============================================================================="
    }

    # Execute with proper logging guards
    if [[ -n "$log_file" && "$ZSH_DEBUG" == "1" && -d "$log_dir" && -w "$log_dir" ]]; then
        # Extra validation to prevent empty tee calls
        if [[ "$log_file" != "" && "$log_file" != "/" && "$log_file" =~ .*/.* ]]; then
            _log_and_execute 2>&1 | tee -a "$log_file"
        else
            _log_and_execute 2>/dev/null
        fi
    else
        # Append to log file if valid, otherwise just execute
        if [[ -n "$log_file" ]]; then
            _log_and_execute >>"$log_file" 2>&1
        else
            _log_and_execute 2>/dev/null
        fi
    fi

    # 2.3.8 Working Directory Restoration
    if ! cd "$original_cwd" 2>/dev/null; then
        zf::debug "⚠️  Warning: Could not restore original directory: $original_cwd"
        return 1
    fi

    return 0
}

# 2.4 Execute the deferred wrapper in background (truly deferred)
# Temporarily disabled for performance 040-testing
# if [[ "${(%):-%x}" == *"03-macos-defaults-deferred.zsh" ]]; then
#     # Run in background to avoid blocking shell startup
#     {
#         # Small delay to ensure shell is fully loaded
#         sleep 1
#         _deferred_macos_defaults
#     } &
#     disown
# fi
