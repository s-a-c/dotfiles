#!/opt/homebrew/bin/zsh
# Load source/execute detection utils if present (optional)
{
    DETECTION_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00_01-source-execute-detection.zsh"
    if [ -r "$DETECTION_SCRIPT" ]; then
        export ZSH_SOURCE_EXECUTE_TESTING=false
        source "$DETECTION_SCRIPT"
    fi
}
#=============================================================================
# File: 04-lazy-direnv.zsh
# Purpose: 2.2.1 Lazy loading wrapper for direnv hook initialization
# Dependencies: direnv (if available)
# Author: Configuration management system
# Last Modified: 2025-08-23
#=============================================================================

[[ "$ZSH_DEBUG" == "1" ]] && {
        zsh_debug_echo "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
}

if command -v direnv >/dev/null 2>&1; then
  _lazy_direnv_bootstrap() {
    # Working Directory Management - Save current working directory
    local original_cwd="$(pwd)"

    # Resolve config base from ZDOTDIR or XDG defaults
    local config_base="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"

    # Robust date values with fallbacks
    local log_date log_time
    log_date="$(date -u +%Y-%m-%d 2>/dev/null || printf 'unknown-date')"
    log_time="$(date -u +%H-%M-%S 2>/dev/null || printf '%(%s)T' -1 2>/dev/null || printf 'unknown-time')"

    # Compute log dir/file with fallbacks
    local log_dir log_file
    log_dir="$config_base/logs/$log_date"
    mkdir -p "$log_dir" 2>/dev/null || true
    if [[ ! -d "$log_dir" ]]; then
      log_dir="${TMPDIR:-/tmp}/zsh-logs-${USER:-user}/$log_date"
      mkdir -p "$log_dir" 2>/dev/null || true
    fi
    [[ -d "$log_dir" ]] || log_dir="${TMPDIR:-/tmp}"

    log_file="$log_dir/lazy-direnv_${log_time}.log"
    # Validate log_file usability; if invalid, disable logging to file
    if [[ -z "$log_file" || ! -d "$log_dir" ]]; then
      log_file=""
    fi

    # Initialize lazy loading state
    typeset -g _DIRENV_HOOKED="${_DIRENV_HOOKED:-0}"

    _init_direnv_hook() {
      [[ $_DIRENV_HOOKED -eq 1 ]] && return 0

      if [[ -n "$log_file" && "$ZSH_DEBUG" == "1" && -d "$log_dir" && -w "$log_dir" ]]; then
        # Extra validation to prevent empty tee calls
        if [[ "$log_file" != "" && "$log_file" != "/" && "$log_file" =~ .*/.* ]]; then
          {
            zsh_debug_echo "=============================================================================="
            zsh_debug_echo "Lazy Direnv Hook Initialization"
            zsh_debug_echo "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
            zsh_debug_echo "Triggered by: ${funcstack[2]:-unknown}"
            zsh_debug_echo "=============================================================================="
            zsh_debug_echo ""
            if eval "$(command direnv hook zsh)" 2>/dev/null; then
              _DIRENV_HOOKED=1
              zsh_debug_echo "✅ direnv hook initialized successfully"
            else
              zsh_debug_echo "❌ direnv hook initialization failed"
              return 1
            fi
            zsh_debug_echo ""
            zsh_debug_echo "=============================================================================="
            zsh_debug_echo "Lazy direnv hook initialization completed at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
            zsh_debug_echo "=============================================================================="
          } 2>&1 | tee -a "$log_file"
        else
          # Fallback: silent execution if log file is invalid
          if eval "$(command direnv hook zsh)" 2>/dev/null; then
            _DIRENV_HOOKED=1
          else
            return 1
          fi
        fi
      else
        # Append minimal logs when path is valid, otherwise stay quiet
        if [[ -n "$log_file" ]]; then
          {
            zsh_debug_echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] initializing direnv hook"
          } >>"$log_file" 2>&1
        fi
        if eval "$(command direnv hook zsh)" 2>/dev/null; then
          _DIRENV_HOOKED=1
        else
          return 1
        fi
      fi
      return 0
    }

    # Lazy wrapper for direnv
    direnv() {
      _init_direnv_hook || return 1
      unfunction direnv 2>/dev/null
      command direnv "$@"
    }

    # Hook into directory changes to trigger direnv when needed
    _lazy_direnv_chpwd() {
      if [[ -f ".envrc" && $_DIRENV_HOOKED -eq 0 ]]; then
        zsh_debug_echo "# Lazy loading direnv due to .envrc presence"
        _init_direnv_hook
      fi
    }

    autoload -U add-zsh-hook
    add-zsh-hook chpwd _lazy_direnv_chpwd
    _lazy_direnv_chpwd

    cd -q "$original_cwd" 2>/dev/null || {
      zsh_debug_echo "Warning: Could not restore original directory: $original_cwd"
      return 1
    }
    zsh_debug_echo "# [lazy-direnv] Lazy direnv wrapper initialized"
  }
  _lazy_direnv_bootstrap
else
  zsh_debug_echo "# [lazy-direnv] direnv not found, skipping"
fi
