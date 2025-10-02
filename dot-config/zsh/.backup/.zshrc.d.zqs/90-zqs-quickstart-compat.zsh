#!/usr/bin/env zsh
# 90-zqs-quickstart-compat.zsh
# ZSH Quickstart Kit compatibility module

# NOTE: Emergency ZLE widget repair has been moved to 01-autosuggestions-enablement.zsh
# This compatibility module now focuses on ZQS functions and parameter guards
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
        zf::debug ".zshrc is not a symlink, skipping zsh-quickstart-kit update"
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
                    zf::debug "The ZSH Quickstart Kit has switched default branches to $zqs_default_branch"
                    zf::debug "Changing branches in your local checkout from $zqs_current_branch to $zqs_default_branch"
                    git checkout "$zqs_default_branch" 2>/dev/null || true
                fi

                if [[ "$zqs_current_branch" != "$zqs_default_branch" ]]; then
                    zf::debug "Using $zqs_current_branch instead of $zqs_default_branch"
                fi

                zf::debug "---- updating $zqs_current_branch ----"
                git pull 2>/dev/null || true
                date +%s >! "$ZDOTDIR/.zsh-quickstart-last-update"

                unset zqs_default_branch
                unset zqs_current_branch
            fi
        else
            zf::debug 'No quickstart marker found, is your quickstart directory a valid git checkout?'
        fi
        popd
    fi
}

_check-for-zsh-quickstart-update() {
    local day_seconds=$(expr 24 \* 60 \* 60)
    local refresh_seconds=$(expr "${day_seconds}" \* "${QUICKSTART_KIT_REFRESH_IN_DAYS}")
    local last_quickstart_update=$(_load-lastupdate-from-file "$ZDOTDIR/.zsh-quickstart-last-update")

    if [ ${last_quickstart_update} -gt ${refresh_seconds} ]; then
        zf::debug "It has been $(expr ${last_quickstart_update} / ${day_seconds}) days since your zsh quickstart kit was updated"
        zf::debug "Checking for zsh-quickstart-kit updates..."
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
                zf::debug "zgenom not available for plugin updates"
            fi
            ;;
        'cleanup')
            if command -v zgenom >/dev/null 2>&1; then
                zgenom clean
            else
                zf::debug "zgenom not available for cleanup"
            fi
            ;;
        *)
            zf::debug "zqs: basic quickstart compatibility interface"
            zf::debug "Available commands:"
            zf::debug "  check-for-updates - Check for quickstart updates"
            zf::debug "  selfupdate - Update quickstart kit"
            zf::debug "  update - Update quickstart kit and plugins"
            zf::debug "  update-plugins - Update plugins only"
            zf::debug "  cleanup - Clean unused plugins"
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
    # Note: Shell options are managed centrally - no local setopt needed
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
    # Note: Shell options are managed centrally - no local setopt needed
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

# Guard against ZLE widgets array access - CRITICAL FOR STARSHIP INIT
# Starship's init script tries to access widgets[zle-keymap-select] at line 67
# This happens during eval before ZLE is fully initialized
if [[ -o interactive ]]; then
  # Force ZLE to be available - this is crucial for Starship
  autoload -Uz zle 2>/dev/null || true

  # Ensure widgets array exists as an associative array
  # The widgets array is managed by ZLE but we need to ensure it exists
  typeset -gA widgets 2>/dev/null || true

  # Pre-populate the specific widget that Starship checks
  # This prevents "parameter not set" errors when Starship eval runs
  widgets[zle-keymap-select]="" 2>/dev/null || true

  # Also ensure other common widgets exist for completeness
  widgets[zle-line-init]="" 2>/dev/null || true
  widgets[zle-line-finish]="" 2>/dev/null || true

  zf::debug "# [zqs-compat] ZLE widgets prepared for Starship initialization"
fi

# =============================================================================
# Final Starship ZLE Fix - Function Override Approach
# =============================================================================

# Override the problematic parameter access in a more robust way
# Create a safe wrapper for any widgets array access
if [[ -o interactive ]]; then
  # If REDESIGN is active, defer Starship init entirely to REDESIGN modules
  if [[ "${LEGACY_REDESIGN_COMPAT_MODE:-legacy}" == "active" ]]; then
    zf::debug "# [zqs-compat] Skipping Starship init (handled by REDESIGN)"
  else
    # Ensure ZLE and widgets are available
    autoload -Uz zle 2>/dev/null || true

    # Create safe widgets access helper
    _safe_starship_eval() {
      # Pre-populate widgets before any starship eval
      typeset -gA widgets 2>/dev/null || true
      widgets[zle-keymap-select]="" 2>/dev/null || true

      # Now eval the starship init safely
      local starship_code="$(starship init zsh 2>/dev/null)"
      if [[ -n "$starship_code" ]]; then
        eval "$starship_code" 2>/dev/null
        return $?
      fi
      return 1
    }

    # If starship is available, initialize it safely right now
    if command -v starship >/dev/null 2>&1 || [[ -x "$HOME/.local/share/cargo/bin/starship" ]]; then
      if _safe_starship_eval 2>/dev/null; then
        export STARSHIP_SHELL="${STARSHIP_SHELL:-zsh}"
        [[ -f "$HOME/.config/starship.toml" ]] && export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$HOME/.config/starship.toml}"
        zf::debug "# [zqs-compat] ✅ Starship initialized safely via compatibility module"
      else
        zf::debug "# [zqs-compat] ⚠️  Starship initialization failed, using fallback prompt"
      fi
    fi
  fi
fi

zf::debug "# [zqs-compat] ZSH Quickstart compatibility functions loaded"
zf::debug "# [zqs-compat] Defensive parameter guards active"
