#!/usr/bin/env zsh
# 90-zqs-quickstart-compat.zsh
# ZSH Quickstart Kit compatibility module
# 
# PURPOSE:
#   Provides essential ZQS functions that were missing from the redesigned configuration.
#   This restores the quickstart kit functionality for update checking and management.
#
# FUNCTIONS PROVIDED:
#   - _check-for-zsh-quickstart-update
#   - _update-zsh-quickstart
#   - _load-lastupdate-from-file
#   - zqs (command interface)
#
# GUARDS:
#   - Only loads if QUICKSTART_KIT_REFRESH_IN_DAYS is set
#   - Respects existing function definitions (no override)
#

# Only load if quickstart functionality is desired
if [[ -z "${QUICKSTART_KIT_REFRESH_IN_DAYS:-}" ]]; then
    return 0
fi

# Guard against multiple loading
if [[ -n "${_ZQS_COMPAT_LOADED:-}" ]]; then
    return 0
fi
_ZQS_COMPAT_LOADED=1

# =============================================================================
# Helper Functions
# =============================================================================

_load-lastupdate-from-file() {
    local now=$(date +%s)
    if [[ -f "${1}" ]]; then
        local last_update=$(cat "${1}")
    else
        local last_update=0
    fi
    local interval="$(expr ${now} - ${last_update})"
    echo "${interval}"
}

_update-zsh-quickstart() {
    local _zshrc_loc="$ZDOTDIR/.zshrc"
    if [[ ! -L "${_zshrc_loc}" ]]; then
        zsh_debug_echo ".zshrc is not a symlink, skipping zsh-quickstart-kit update"
    else
        local _link_loc=${_zshrc_loc:A}
        if [[ "${_link_loc/${HOME}}" == "${_link_loc}" ]]; then
            pushd $(dirname "${HOME}/${_zshrc_loc:A}")
        else
            pushd $(dirname ${_link_loc})
        fi
        
        local gitroot=$(git rev-parse --show-toplevel 2>/dev/null)
        if [[ -n "$gitroot" && -f "${gitroot}/.gitignore" ]]; then
            if [[ $(grep -c zsh-quickstart-kit "${gitroot}/.gitignore" 2>/dev/null || echo 0) -ne 0 ]]; then
                # Cope with switch from master to main
                local zqs_current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
                git fetch 2>/dev/null || true
                
                # Determine the repo default branch and switch to it unless we're in testing mode
                local zqs_default_branch="$(git remote show origin 2>/dev/null | grep 'HEAD branch' | awk '{print $3}' || echo 'main')"
                
                if [[ "$zqs_current_branch" == 'master' ]]; then
                    zsh_debug_echo "The ZSH Quickstart Kit has switched default branches to $zqs_default_branch"
                    zsh_debug_echo "Changing branches in your local checkout from $zqs_current_branch to $zqs_default_branch"
                    git checkout "$zqs_default_branch" 2>/dev/null || true
                fi
                
                if [[ "$zqs_current_branch" != "$zqs_default_branch" ]]; then
                    zsh_debug_echo "Using $zqs_current_branch instead of $zqs_default_branch"
                fi
                
                zsh_debug_echo "---- updating $zqs_current_branch ----"
                git pull 2>/dev/null || true
                date +%s >! "$ZDOTDIR/.zsh-quickstart-last-update"
                
                unset zqs_default_branch
                unset zqs_current_branch
            fi
        else
            zsh_debug_echo 'No quickstart marker found, is your quickstart directory a valid git checkout?'
        fi
        popd
    fi
}

_check-for-zsh-quickstart-update() {
    local day_seconds=$(expr 24 \* 60 \* 60)
    local refresh_seconds=$(expr "${day_seconds}" \* "${QUICKSTART_KIT_REFRESH_IN_DAYS}")
    local last_quickstart_update=$(_load-lastupdate-from-file "$ZDOTDIR/.zsh-quickstart-last-update")

    if [ ${last_quickstart_update} -gt ${refresh_seconds} ]; then
        zsh_debug_echo "It has been $(expr ${last_quickstart_update} / ${day_seconds}) days since your zsh quickstart kit was updated"
        zsh_debug_echo "Checking for zsh-quickstart-kit updates..."
        _update-zsh-quickstart
    fi
}

# =============================================================================
# ZQS Command Interface (Basic)
# =============================================================================

function zqs() {
    case "$1" in
        'check-for-updates')
            _check-for-zsh-quickstart-update
            ;;
        'selfupdate')
            _update-zsh-quickstart
            ;;
        'update')
            _update-zsh-quickstart
            if command -v zgenom >/dev/null 2>&1; then
                zgenom update
            fi
            ;;
        'update-plugins')
            if command -v zgenom >/dev/null 2>&1; then
                zgenom update
            else
                zsh_debug_echo "zgenom not available for plugin updates"
            fi
            ;;
        'cleanup')
            if command -v zgenom >/dev/null 2>&1; then
                zgenom clean
            else
                zsh_debug_echo "zgenom not available for cleanup"
            fi
            ;;
        *)
            zsh_debug_echo "zqs: basic quickstart compatibility interface"
            zsh_debug_echo "Available commands:"
            zsh_debug_echo "  check-for-updates - Check for quickstart updates"
            zsh_debug_echo "  selfupdate - Update quickstart kit"
            zsh_debug_echo "  update - Update quickstart kit and plugins"
            zsh_debug_echo "  update-plugins - Update plugins only"
            zsh_debug_echo "  cleanup - Clean unused plugins"
            ;;
    esac
}

# =============================================================================
# Auto-update Integration
# =============================================================================

# The main .zshrc will call _check-for-zsh-quickstart-update if it exists,
# so no additional setup needed here. This module just provides the function.

# =============================================================================
# Additional ZQS Compatibility Functions (restore missing functions)
# =============================================================================

# Select Powerlevel10k prompt (records intent; default remains Starship until user invokes this)
if ! typeset -f zsh-quickstart-select-powerlevel10k >/dev/null 2>&1; then
  zsh-quickstart-select-powerlevel10k() {
    emulate -L zsh
    setopt no_unset
    local zd="${ZDOTDIR:-$HOME}"
    print -r -- "[zqs] Selecting Powerlevel10k prompt (persisting choice)..."
    rm -f "$zd/.zqs-prompt-starship" 2>/dev/null || true
    touch "$zd/.zqs-prompt-powerlevel10k"
    print -r -- "[zqs] Done. Restart your shell to apply."
  }
fi

# Select Bullet Train prompt (records intent; placeholder for future loader)
if ! typeset -f zsh-quickstart-select-bullet-train >/dev/null 2>&1; then
  zsh-quickstart-select-bullet-train() {
    emulate -L zsh
    setopt no_unset
    local zd="${ZDOTDIR:-$HOME}"
    print -r -- "[zqs] Selecting Bullet Train prompt (persisting choice)..."
    rm -f "$zd/.zqs-prompt-starship" 2>/dev/null || true
    touch "$zd/.zqs-prompt-bullet-train"
    print -r -- "[zqs] Done. Restart your shell to apply."
  }
fi

# Help summary
if ! typeset -f zqs-help >/dev/null 2>&1; then
  zqs-help() {
    emulate -L zsh
    cat <<'EOF'
ZSH Quickstart Kit compatibility commands:
  - zsh-quickstart-select-powerlevel10k  # select P10k (restart shell to apply)
  - zsh-quickstart-select-bullet-train   # select Bullet Train (restart shell to apply)
  - _check-for-zsh-quickstart-update     # check for upstream updates
  - _update-zsh-quickstart               # update repo and plugins
  - zqs                                  # main command interface

Docs:
  - docs/redesignv2/REFERENCE.md
  - docs/redesignv2/IMPLEMENTATION.md
  - /Users/s-a-c/dotfiles/dot-config/zsh/WARP.md
EOF
  }
fi

# =============================================================================
# Defensive Parameter Guards (fix unset parameter errors)
# =============================================================================

# Guard against P10K variable references when using Starship
# These may be checked by P10K configs or plugins even when Starship is active
[[ -z "${POWERLEVEL9K_PROMPT_ADD_NEWLINE:-}" ]] && export POWERLEVEL9K_PROMPT_ADD_NEWLINE=false
[[ -z "${POWERLEVEL9K_MODE:-}" ]] && export POWERLEVEL9K_MODE=""
[[ -z "${POWERLEVEL9K_INSTANT_PROMPT:-}" ]] && export POWERLEVEL9K_INSTANT_PROMPT=quiet

# Guard against Emacs-related variables checked by Oh-My-Zsh termsupport
# Warp terminal integrations may reference these
[[ -z "${INSIDE_EMACS:-}" ]] && export INSIDE_EMACS=""
[[ -z "${EMACS:-}" ]] && export EMACS=""

# Additional Warp-specific guards if needed
[[ -z "${WARP_HONOR_PS1:-}" ]] && export WARP_HONOR_PS1="${WARP_HONOR_PS1:-1}"

# Guard against warp_title function calls (may be referenced by Warp terminal integrations)
# Create a safe no-op function if it doesn't exist
if ! typeset -f warp_title >/dev/null 2>&1; then
  warp_title() {
    # Safe no-op implementation for warp_title if not defined by Warp terminal
    # Check that INSIDE_EMACS is defined to avoid parameter not set errors
    [[ -n "${INSIDE_EMACS:-}" && "$INSIDE_EMACS" != "vterm" ]] && return
    # Optionally set terminal title using standard escape sequences if not in Emacs
    return 0
  }
fi

# Guard against ZLE widgets array access when ZLE is not fully initialized
# This can happen during rapid prompt evaluation or when widgets are not yet loaded
if [[ -o interactive ]] && [[ -n "${ZLE_VERSION:-}" ]]; then
  # Ensure widgets array exists as an associative array
  if [[ -z "${widgets:-}" ]]; then
    typeset -gA widgets
  fi
  
  # Ensure common widgets have default values to prevent parameter not set errors
  [[ -z "${widgets[zle-keymap-select]:-}" ]] && widgets[zle-keymap-select]="user:_zle_keymap_select_placeholder"
  [[ -z "${widgets[zle-line-init]:-}" ]] && widgets[zle-line-init]="user:_zle_line_init_placeholder"
  [[ -z "${widgets[zle-line-finish]:-}" ]] && widgets[zle-line-finish]="user:_zle_line_finish_placeholder"
fi

zsh_debug_echo "# [zqs-compat] ZSH Quickstart compatibility functions loaded"
zsh_debug_echo "# [zqs-compat] Defensive parameter guards active"
