#!/usr/bin/env zsh
# Filename: 420-terminal-integration.zsh
# Purpose:  Unified terminal emulator and multiplexer integration
#           Supports: Warp, WezTerm, Ghostty, Kitty, iTerm2, VSCode/Cursor (emulators)
#                     tmux, zellij (multiplexers)
# Phase:    Post-plugin (.zshrc.d/)
# Toggles:  ZF_DISABLE_MULTIPLEXER, ZF_TMUX_AUTO_ATTACH, ZF_ZELLIJ_AUTO_ATTACH

[[ -n ${_ZF_TERMINAL_INTEGRATION_DONE:-} ]] && return 0
_ZF_TERMINAL_INTEGRATION_DONE=1

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# ==============================================================================
# Terminal Emulator Integration
# ==============================================================================

case "${TERM_PROGRAM:-}" in
  WarpTerminal)
    export WARP_IS_LOCAL_SHELL_SESSION=1
    zf::debug "# [term] Warp integration enabled"
    ;;
  WezTerm)
    export WEZTERM_SHELL_INTEGRATION=1
    zf::debug "# [term] WezTerm integration enabled"
    ;;
  ghostty)
    export GHOSTTY_SHELL_INTEGRATION=1
    if [[ -n ${GHOSTTY_RESOURCES_DIR:-} && -f "${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration" ]]; then
      source "${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration" 2>/dev/null || true
      zf::debug "# [term] Ghostty integration script sourced"
    else
      zf::debug "# [term] Ghostty integration enabled"
    fi
    ;;
  vscode)
    # VSCode/Cursor handles its own shell integration automatically via VSCODE_INJECTION
    # We don't need to source it manually - it's already active by the time we get here
    # We just need to clean up the side effects (PATH corruption, broken functions)

    # CRITICAL: VSCode shell integration corrupts PATH by prepending extension directories
    # (.console-ninja/.bin, .lmstudio/bin, etc.) Re-fix PATH after VSCode integration runs
    export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH}"

    # Ensure vendor env-tracking arrays exist (missing definitions cause math errors)
    if ! typeset -f __zf_vscode_env_guard >/dev/null 2>&1; then
      __zf_vscode_env_guard() {
        if [[ ${__vsc_use_aa:-0} -eq 1 ]]; then
          typeset -gA vsc_aa_env
        fi
        typeset -ga __vsc_env_keys
        typeset -ga __vsc_env_values
      }
    fi

    # Ensure add-zsh-hook is loaded before using it
    autoload -Uz add-zsh-hook 2>/dev/null || true

    # Register guard function if add-zsh-hook is available
    if typeset -f add-zsh-hook >/dev/null 2>&1; then
      add-zsh-hook precmd __zf_vscode_env_guard
      precmd_functions=(__zf_vscode_env_guard ${precmd_functions:#__zf_vscode_env_guard})
    else
      # Fallback: directly add to precmd_functions if add-zsh-hook unavailable
      precmd_functions=(__zf_vscode_env_guard ${precmd_functions:#__zf_vscode_env_guard})
    fi

    zf::debug "# [term] VS Code/Cursor integration active (auto-loaded), PATH fixed"
    ;;
  iTerm.app)
    if [[ -f "${HOME}/.iterm2_shell_integration.zsh" ]]; then
      source "${HOME}/.iterm2_shell_integration.zsh" || true
      zf::debug "# [term] iTerm2 integration script sourced"
    fi
    ;;
esac

if [[ "${TERM:-}" == "xterm-kitty" ]]; then
  export KITTY_SHELL_INTEGRATION=enabled
  zf::debug "# [term] Kitty integration enabled"
fi

# ==============================================================================
# Terminal Multiplexer Integration (tmux, zellij)
# ==============================================================================

# Skip multiplexer integration if disabled
if [[ "${ZF_DISABLE_MULTIPLEXER:-0}" == 1 ]]; then
    zf::debug "# [mux] Multiplexer integration disabled"
    return 0
fi

# ------------------------------------------------------------------------------
# TMUX Integration
# ------------------------------------------------------------------------------

if command -v tmux >/dev/null 2>&1; then

    # Function to list tmux sessions with details
    tmux-sessions() {
        if ! tmux list-sessions 2>/dev/null; then
            echo "No active tmux sessions"
            return 1
        fi
    }

    # Function to create or attach to named session
    tmux-attach() {
        local session_name="${1:-default}"

        if tmux has-session -t "$session_name" 2>/dev/null; then
            tmux attach-session -t "$session_name"
        else
            tmux new-session -s "$session_name"
        fi
    }

    # Function to create session with 3-pane workspace layout
    tmux-workspace() {
        local workspace_name="${1:-workspace}"

        if tmux has-session -t "$workspace_name" 2>/dev/null; then
            echo "Session '$workspace_name' already exists. Attaching..."
            tmux attach-session -t "$workspace_name"
            return 0
        fi

        # Create new session with 3-pane layout
        tmux new-session -d -s "$workspace_name" -n "main"

        # Split horizontally (editor on top, terminal on bottom)
        tmux split-window -v -t "$workspace_name:main" -p 30

        # Split the bottom pane vertically (two terminal panes)
        tmux split-window -h -t "$workspace_name:main.1"

        # Focus top pane (editor)
        tmux select-pane -t "$workspace_name:main.0"

        # Attach to session
        tmux attach-session -t "$workspace_name"
    }

    # Function to kill session
    tmux-kill() {
        local session_name="$1"

        if [[ -z "$session_name" ]]; then
            echo "Usage: tmux-kill <session-name>"
            echo "Available sessions:"
            tmux list-sessions 2>/dev/null || echo "  (none)"
            return 1
        fi

        tmux kill-session -t "$session_name"
    }

    # Auto-attach to tmux on SSH connections (optional)
    if [[ -n "$SSH_CONNECTION" ]] && [[ "${ZF_TMUX_AUTO_ATTACH:-0}" == 1 ]] && [[ -z "$TMUX" ]]; then
        tmux-attach "ssh-${USER}"
    fi

    # Enhanced tmux aliases
    alias tl='tmux list-sessions'
    alias ta='tmux-attach'
    alias tn='tmux new-session -s'
    alias tk='tmux-kill'
    alias tw='tmux-workspace'
    alias td='tmux detach'

    zf::debug "# [mux] tmux integration loaded"
fi

# ------------------------------------------------------------------------------
# Zellij Integration
# ------------------------------------------------------------------------------

if command -v zellij >/dev/null 2>&1; then

    # Function to list zellij sessions
    zellij-sessions() {
        zellij list-sessions 2>/dev/null || echo "No active zellij sessions"
    }

    # Function to attach or create session
    zellij-attach() {
        local session_name="${1:-default}"

        if zellij list-sessions 2>/dev/null | grep -q "^${session_name}\$"; then
            zellij attach "$session_name"
        else
            zellij -s "$session_name"
        fi
    }

    # Function to create development workspace
    zellij-workspace() {
        local workspace_name="${1:-workspace}"

        # Create new session with layout
        zellij -s "$workspace_name" -l compact
    }

    # Function to kill session
    zellij-kill() {
        local session_name="$1"

        if [[ -z "$session_name" ]]; then
            echo "Usage: zellij-kill <session-name>"
            echo "Available sessions:"
            zellij list-sessions 2>/dev/null || echo "  (none)"
            return 1
        fi

        zellij delete-session "$session_name"
    }

    # Auto-attach to zellij on SSH connections (optional)
    if [[ -n "$SSH_CONNECTION" ]] && [[ "${ZF_ZELLIJ_AUTO_ATTACH:-0}" == 1 ]] && [[ -z "$ZELLIJ" ]]; then
        zellij-attach "ssh-${USER}"
    fi

    # Enhanced zellij aliases
    alias zl='zellij-sessions'
    alias za='zellij-attach'
    alias zn='zellij -s'
    alias zk='zellij-kill'
    alias zw='zellij-workspace'
    alias zd='zellij action detach'

    zf::debug "# [mux] zellij integration loaded"
fi

# ------------------------------------------------------------------------------
# Common Multiplexer Functions
# ------------------------------------------------------------------------------

# Detect if running inside any multiplexer
zf::in_multiplexer() {
    [[ -n "$TMUX" ]] || [[ -n "$ZELLIJ" ]] || [[ -n "$ZELLIJ_SESSION_NAME" ]]
}

# Get current multiplexer name
zf::multiplexer_name() {
    if [[ -n "$TMUX" ]]; then
        echo "tmux"
    elif [[ -n "$ZELLIJ" ]] || [[ -n "$ZELLIJ_SESSION_NAME" ]]; then
        echo "zellij"
    else
        echo "none"
    fi
}

# Enhanced pane/window management
if zf::in_multiplexer; then
    local mux_type="$(zf::multiplexer_name)"

    case "$mux_type" in
        tmux)
            export TMUX_ACTIVE=1
            ;;
        zellij)
            export ZELLIJ_ACTIVE=1
            ;;
    esac

    zf::debug "# [mux] Running inside $mux_type"
fi

# ------------------------------------------------------------------------------
# Help Function
# ------------------------------------------------------------------------------

terminal-help() {
    local mux_type="$(zf::multiplexer_name)"

    cat <<EOF
🖥️  Terminal & Multiplexer Integration

Terminal Emulator: ${TERM_PROGRAM:-$TERM}
Multiplexer: ${mux_type}
$(zf::in_multiplexer && echo "✅ Running inside multiplexer" || echo "⚪ No multiplexer active")

TMUX Commands (if installed):
  tl              : List sessions
  ta [name]       : Attach/create session
  tn <name>       : New named session
  tk <name>       : Kill session
  tw [name]       : Create workspace with 3-pane layout
  td              : Detach from session

  tmux-sessions   : List all sessions
  tmux-attach     : Attach to session (creates if doesn't exist)
  tmux-workspace  : Create development workspace layout
  tmux-kill       : Kill named session

Zellij Commands (if installed):
  zl              : List sessions
  za [name]       : Attach/create session
  zn <name>       : New named session
  zk <name>       : Kill session
  zw [name]       : Create workspace with compact layout
  zd              : Detach from session

  zellij-sessions : List all sessions
  zellij-attach   : Attach to session
  zellij-workspace: Create development workspace
  zellij-kill     : Kill named session

Auto-Attach (SSH only):
  ZF_TMUX_AUTO_ATTACH=1    : Auto-attach to tmux on SSH
  ZF_ZELLIJ_AUTO_ATTACH=1  : Auto-attach to zellij on SSH

Toggle:
  ZF_DISABLE_MULTIPLEXER=1 : Disable all multiplexer integration

Tips:
  - Use workspaces for project-based sessions
  - Sessions persist across disconnections
  - Layouts auto-configure editor + terminal panes
EOF
}

# Mark functions readonly (wrapped to prevent function definition output)
(
  readonly -f zf::in_multiplexer 2>/dev/null || true
  readonly -f zf::multiplexer_name 2>/dev/null || true
  readonly -f terminal-help 2>/dev/null || true
) >/dev/null 2>&1

# Welcome message for multiplexer integration
if [[ -z "${_ZF_MULTIPLEXER_NOTIFIED:-}" ]] && (command -v tmux >/dev/null 2>&1 || command -v zellij >/dev/null 2>&1); then
    local available_mux=""
    command -v tmux >/dev/null 2>&1 && available_mux="${available_mux}tmux "
    command -v zellij >/dev/null 2>&1 && available_mux="${available_mux}zellij"

    echo "🖥️  Multiplexer integration active: ${available_mux}. Type 'terminal-help' for commands."
    export _ZF_MULTIPLEXER_NOTIFIED=1
fi

return 0
