#!/usr/bin/env zsh
# Filename: 445-terminal-multiplexer.zsh
# Purpose:  Enhanced terminal multiplexer integration (tmux, zellij)
#           Provides session management, window/pane navigation, and persistence
# Phase:    Post-plugin (.zshrc.d/)
# Requires: 420-terminal-integration.zsh
# Toggles:  ZF_DISABLE_MULTIPLEXER, ZF_TMUX_AUTO_ATTACH, ZF_ZELLIJ_AUTO_ATTACH

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# Skip if disabled
if [[ "${ZF_DISABLE_MULTIPLEXER:-0}" == 1 ]]; then
    return 0
fi

# ==============================================================================
# TMUX Integration
# ==============================================================================

if command -v tmux >/dev/null 2>&1; then

    # --- Enhanced tmux session management ---
    
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

    # Function to create session with layout
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

# ==============================================================================
# Zellij Integration
# ==============================================================================

if command -v zellij >/dev/null 2>&1; then

    # --- Enhanced zellij session management ---
    
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

# ==============================================================================
# Common Multiplexer Functions
# ==============================================================================

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
            # Enhanced tmux keybindings (if tmux.conf allows)
            export TMUX_ACTIVE=1
            ;;
        zellij)
            # Enhanced zellij integration
            export ZELLIJ_ACTIVE=1
            ;;
    esac
    
    zf::debug "# [mux] Running inside $mux_type"
fi

# ==============================================================================
# Help Function
# ==============================================================================

multiplexer-help() {
    local mux_type="$(zf::multiplexer_name)"
    
    cat <<EOF
🖥️  Terminal Multiplexer Integration

Current: ${mux_type}
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

# Mark functions readonly
readonly -f zf::in_multiplexer 2>/dev/null || true
readonly -f zf::multiplexer_name 2>/dev/null || true
readonly -f multiplexer-help 2>/dev/null || true

# Welcome message
if [[ -z "${_ZF_MULTIPLEXER_NOTIFIED:-}" ]] && (command -v tmux >/dev/null 2>&1 || command -v zellij >/dev/null 2>&1); then
    local available_mux=""
    command -v tmux >/dev/null 2>&1 && available_mux="${available_mux}tmux "
    command -v zellij >/dev/null 2>&1 && available_mux="${available_mux}zellij"
    
    echo "🖥️  Multiplexer integration active: ${available_mux}. Type 'multiplexer-help' for commands."
    export _ZF_MULTIPLEXER_NOTIFIED=1
fi

zf::debug "# [mux] Terminal multiplexer integration loaded"

return 0

