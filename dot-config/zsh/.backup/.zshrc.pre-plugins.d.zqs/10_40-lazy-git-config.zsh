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
# File: 05-lazy-git-config.zsh
# Purpose: 2.2.3 Lazy loading wrapper for git configuration with caching
# Dependencies: git (if available)
# Author: Configuration management system
# Last Modified: 2025-08-20
#=============================================================================

[[ "$ZSH_DEBUG" == "1" ]] && {
    zf::debug "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
}

# 2.2.3 git configuration lazy loading and caching - USES SAFE GIT FROM .zshenv
# Use _lazy_git_wrapper (alias for safe_git) from .zshenv which prioritizes /opt/homebrew/bin/git

if command -v _lazy_git_wrapper >/dev/null 2>&1; then
    local git_cmd="_lazy_git_wrapper"

    # 2.2.3.1 Working Directory Management - Save current working directory
    local original_cwd="$(pwd)"

    # 2.2.3.2 Configuration and logging setup
    local config_base="$ZDOTDIR"
    local cache_dir="$config_base/.cache"
    local git_cache_file="$cache_dir/git-config-cache"
    local log_date=$(safe_date +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d 2>/dev/null || zf::debug "unknown")
    local log_time=$(safe_date +%H-%M-%S 2>/dev/null || date +%H-%M-%S 2>/dev/null || zf::debug "unknown")
    local log_dir="$config_base/logs/$log_date"
    local log_file="$log_dir/lazy-git-config_$log_time.log"

    # 2.2.3.3 Setup cache and logging directories
    safe_mkdir -p "$cache_dir" "$log_dir"

    # 2.2.3.4 Initialize lazy loading state
    typeset -g _GIT_CONFIG_LOADED=0

    # 2.2.3.5 Simple Git configuration caching function
    _cache_git_config() {
        # Skip if already loaded
        [[ $_GIT_CONFIG_LOADED -eq 1 ]] && return 0

        # Verify git is still available before proceeding
        if ! command -v _lazy_git_wrapper >/dev/null 2>&1; then
            zf::debug "# Git not available, skipping config cache"
            return 1
        fi

        # Simple cache check - 1 hour TTL
        local cache_ttl=3600 # 1 hour in seconds
        local needs_refresh=true

        if [[ -f "$git_cache_file" ]]; then
            local cache_age=$(($(date +%s) - $(stat -f %m "$git_cache_file" 2>/dev/null || zf::debug 0)))
            if [[ $cache_age -lt $cache_ttl ]]; then
                needs_refresh=false
                zf::debug "# Using cached git config (${cache_age}s old)"
            fi
        fi

        if [[ "$needs_refresh" == "true" ]]; then
            zf::debug "# Refreshing git configuration cache..."

            # Get git configuration values using safe git command
            local git_name git_email
            git_name=$(_lazy_git_wrapper config --get user.name 2>/dev/null || zf::debug 'Unknown')
            git_email=$(_lazy_git_wrapper config --get user.email 2>/dev/null || zf::debug 'unknown@example.com')

            # Write to cache file
            safe_mkdir -p "$(safe_dirname "$git_cache_file")"
            cat >"$git_cache_file" <<EOF
# Git configuration cache - generated $(safe_date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || zf::debug "unknown")
export GIT_AUTHOR_NAME='$git_name'
export GIT_AUTHOR_EMAIL='$git_email'
export GIT_COMMITTER_NAME='$git_name'
export GIT_COMMITTER_EMAIL='$git_email'
EOF
            zf::debug "# Git config cached: $git_name <$git_email>"
        fi

        # Source the cache file
        if [[ -f "$git_cache_file" ]]; then
            source "$git_cache_file"
            _GIT_CONFIG_LOADED=1
            zf::debug "# Git configuration loaded from cache"
        else
            zf::debug "# Failed to load git configuration"
            return 1
        fi

        return 0
    }

    # 2.2.3.5.1 Initialize cache immediately for performance testing and immediate availability
    _cache_git_config 2>/dev/null || true

    # 2.2.3.6 Lazy git wrapper functions (for common git commands that need config)
    _lazy_git_wrapper_with_config() {
        local cmd="$1"
        shift

        # Load git config on first use
        _cache_git_config || return 1

        # Call the real git command using safe wrapper
        _lazy_git_wrapper "$cmd" "$@"
    }

    # 2.2.3.7 Override common git commands that benefit from cached config
    git() {
        case "$1" in
        commit | log | show | config)
            _lazy_git_wrapper_with_config "$@"
            ;;
        *)
            _lazy_git_wrapper "$@"
            ;;
        esac
    }

    # 2.2.3.8 Function to manually refresh git config cache
    git-refresh-config() {
        [[ -f "$git_cache_file" ]] && rm "$git_cache_file"
        _GIT_CONFIG_LOADED=0
        _cache_git_config
    }

    # 2.2.3.9 Working Directory Restoration
    if ! cd "$original_cwd" 2>/dev/null; then
        zf::debug "⚠️  Warning: Could not restore original directory: $original_cwd"
    fi

    zf::debug "# [lazy-git-config] Lazy git configuration wrapper initialized with safe git: $git_cmd"
else
    zf::debug "# [lazy-git-config] git not found, skipping"
fi
