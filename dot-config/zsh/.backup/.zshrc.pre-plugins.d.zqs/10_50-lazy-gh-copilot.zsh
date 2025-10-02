#!/usr/bin/env zsh
# Load source/execute detection utils if present (optional)
{
    DETECTION_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00_01-source-execute-detection.zsh"
    if [ -r "$DETECTION_SCRIPT" ]; then
        export ZSH_SOURCE_EXECUTE_TESTING=false
        source "$DETECTION_SCRIPT"
    fi
}
#=============================================================================
# File: 06-lazy-gh-copilot.zsh
# Purpose: 2.2.2 Lazy loading wrapper for GitHub Copilot CLI aliases
# Dependencies: gh (GitHub CLI) with copilot extension
# Author: Configuration management system
# Last Modified: 2025-08-23
#=============================================================================

[[ "$ZSH_DEBUG" == "1" ]] && {
    zf::debug "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
}

if command -v gh >/dev/null 2>&1; then
    _lazy_gh_copilot_bootstrap() {
        local original_cwd="$(pwd)"
        local config_base="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"

        local log_date log_time
        log_date="$(date -u +%Y-%m-%d 2>/dev/null || printf 'unknown-date')"
        log_time="$(date -u +%H-%M-%S 2>/dev/null || printf '%(%s)T' -1 2>/dev/null || printf 'unknown-time')"

        local log_dir log_file
        log_dir="$config_base/logs/$log_date"
        mkdir -p "$log_dir" 2>/dev/null || true
        if [[ ! -d "$log_dir" ]]; then
            log_dir="${TMPDIR:-/tmp}/zsh-logs-${USER:-user}/$log_date"
            mkdir -p "$log_dir" 2>/dev/null || true
        fi
        [[ -d "$log_dir" ]] || log_dir="${TMPDIR:-/tmp}"

        log_file="$log_dir/lazy-gh-copilot_${log_time}.log"
        if [[ -z "$log_file" || ! -d "$log_dir" ]]; then
            log_file=""
        fi

        typeset -g _GH_COPILOT_LOADED="${_GH_COPILOT_LOADED:-0}"

        _init_gh_copilot() {
            [[ $_GH_COPILOT_LOADED -eq 1 ]] && return 0

            if ! gh copilot --help >/dev/null 2>&1; then
                zf::debug "# gh copilot extension not available"
                return 1
            fi

            if [[ -n "$log_file" && "$ZSH_DEBUG" == "1" && -d "$log_dir" && -w "$log_dir" ]]; then
                # Extra validation to prevent empty tee calls
                if [[ "$log_file" != "" && "$log_file" != "/" && "$log_file" =~ .*/.* ]]; then
                    {
                        zf::debug "=============================================================================="
                        zf::debug "Lazy GitHub Copilot CLI Initialization"
                        zf::debug "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
                        zf::debug "Triggered by: ${funcstack[2]:-unknown}"
                        zf::debug "=============================================================================="
                        zf::debug ""
                        if eval "$(gh copilot alias -- zsh)" 2>/dev/null; then
                            _GH_COPILOT_LOADED=1
                            zf::debug "✅ GitHub Copilot CLI aliases initialized successfully"
                        else
                            zf::debug "❌ GitHub Copilot CLI aliases initialization failed"
                            return 1
                        fi
                        zf::debug ""
                        zf::debug "=============================================================================="
                        zf::debug "Lazy GitHub Copilot CLI initialization completed at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
                        zf::debug "=============================================================================="
                    } 2>&1 | tee -a "$log_file"
                else
                    # Fallback: silent execution if log file is invalid
                    if eval "$(gh copilot alias -- zsh)" 2>/dev/null; then
                        _GH_COPILOT_LOADED=1
                    else
                        return 1
                    fi
                fi
            else
                if [[ -n "$log_file" ]]; then
                    {
                        zf::debug "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] initializing gh copilot aliases"
                    } >>"$log_file" 2>&1
                fi
                if eval "$(gh copilot alias -- zsh)" 2>/dev/null; then
                    _GH_COPILOT_LOADED=1
                else
                    return 1
                fi
            fi
            return 0
        }

        # Lazy wrappers. After init, call gh copilot directly.
        ghcs() {
            _init_gh_copilot || return 1
            unfunction ghcs 2>/dev/null
            gh copilot suggest "$@"
        }

        ghce() {
            _init_gh_copilot || return 1
            unfunction ghce 2>/dev/null
            gh copilot explain "$@"
        }

        cd -q "$original_cwd" 2>/dev/null || {
            zf::debug "Warning: Could not restore original directory: $original_cwd"
            return 1
        }
        zf::debug "# [lazy-gh-copilot] Lazy GitHub Copilot wrapper initialized"
    }
    _lazy_gh_copilot_bootstrap
else
    zf::debug "# [lazy-gh-copilot] gh CLI not found, skipping"
fi
