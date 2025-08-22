#!/opt/homebrew/bin/zsh
#=============================================================================
# File: 03-macos-defaults-deferred.zsh
# Purpose: 2.1 Deferred execution wrapper for macOS defaults configuration
# Dependencies: macOS (Darwin), ~/bin/macos-defaults-setup.zsh
# Author: Configuration management system
# Last Modified: 2025-08-20
#=============================================================================

# Load source/execute detection utils if present (optional)
{
    DETECTION_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00-core/01-source-execute-detection.zsh"
    if [ -r "$DETECTION_SCRIPT" ]; then
        export ZSH_SOURCE_EXECUTE_TESTING=false
        source "$DETECTION_SCRIPT"
    fi
}

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
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

    # 2.3.2 Configuration paths
    local config_base="/Users/s-a-c/.config/zsh"
    local setup_script="$config_base/bin/macos-defaults-setup.zsh"
    local marker_file="$config_base/.macos-defaults-last-run"
    local log_date=$(date -u +%Y-%m-%d)
    local log_time=$(date -u +%H-%M-%S)
    local log_dir="$config_base/logs/$log_date"
    local log_file="$log_dir/deferred-macos-defaults_$log_time.log"

    # 2.3.3 Setup logging directory
    mkdir -p "$log_dir"

    # 2.3.4 Setup comprehensive logging (both STDOUT and STDERR)
    {
        echo "=============================================================================="
        echo "Deferred macOS Defaults Wrapper Execution"
        echo "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "Log file: $log_file"
        echo "=============================================================================="
        echo ""

        # 2.3.5 Check if setup script exists
        if [[ ! -x "$setup_script" ]]; then
            echo "❌ Setup script not found or not executable: $setup_script" >&2
            return 1
        fi

        # 2.3.6 Determine if defaults need to be run
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
                local marker_timestamp=$(stat -f %m "$marker_file" 2>/dev/null || echo "0")
                local current_timestamp=$(date +%s)
                local time_diff=$((current_timestamp - marker_timestamp))
                local hours_diff=$((time_diff / 3600))

                if [[ $hours_diff -gt 24 ]]; then
                    needs_run=true
                    run_reason="More than 24 hours since last run ($hours_diff hours)"
                fi
            fi
        fi

        # 2.3.7 Execute or skip based on needs
        if [[ "$needs_run" == "true" ]]; then
            echo "🔄 Running macOS defaults setup - $run_reason"
            echo ""

            # Execute the setup script
            if "$setup_script"; then
                # Update marker file on successful completion
                echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$marker_file"
                echo ""
                echo "✅ macOS defaults setup completed successfully"
                echo "📄 Marker file updated: $marker_file"
            else
                local exit_code=$?
                echo ""
                echo "❌ macOS defaults setup failed with exit code: $exit_code"
                return 1
            fi
        else
            echo "⏭️  Skipping macOS defaults setup - already up to date"
            echo "📄 Last run: $(cat "$marker_file" 2>/dev/null || echo "Unknown")"
        fi

        echo ""
        echo "=============================================================================="
        echo "Deferred macOS defaults wrapper completed at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "=============================================================================="

    } 2>&1 | tee -a "$log_file"

    # 2.3.8 Working Directory Restoration
    if ! cd "$original_cwd" 2>/dev/null; then
        echo "⚠️  Warning: Could not restore original directory: $original_cwd" >&2
        return 1
    fi

    return 0
}

# 2.4 Execute the deferred wrapper in background (truly deferred)
# Temporarily disabled for performance testing
# if [[ "${(%):-%x}" == *"03-macos-defaults-deferred.zsh" ]]; then
#     # Run in background to avoid blocking shell startup
#     {
#         # Small delay to ensure shell is fully loaded
#         sleep 1
#         _deferred_macos_defaults
#     } &
#     disown
# fi
