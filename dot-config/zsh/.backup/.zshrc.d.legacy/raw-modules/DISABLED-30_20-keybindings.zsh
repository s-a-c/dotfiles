#!/usr/bin/env zsh
# Keybindings Configuration - Essential keyboard shortcuts
# This file configures key bindings for optimal productivity
# Load time target: <20ms

[[ "$ZSH_DEBUG" == "1" ]] && {
        zf::debug "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
}

# History search (works with history-substring-search plugin if loaded)
if command -v history-substring-search-up >/dev/null 2>&1; then
    bindkey '^[[A' history-substring-search-up      # Up arrow
    bindkey '^[[B' history-substring-search-down    # Down arrow
    bindkey '^P' history-substring-search-up        # Ctrl+P
    bindkey '^N' history-substring-search-down      # Ctrl+N
else
    # Fallback to standard history search
    bindkey '^[[A' up-line-or-history
    bindkey '^[[B' down-line-or-history
    bindkey '^P' up-line-or-history
    bindkey '^N' down-line-or-history
fi

# FZF keybindings (only if FZF is available)
if command -v fzf >/dev/null 2>&1; then
    bindkey '^T' fzf-file-widget           # Ctrl+T for file selection
    bindkey '^R' fzf-history-widget        # Ctrl+R for history search
    bindkey '\ec' fzf-cd-widget            # Alt+C for directory navigation
fi

# Enhanced editing keybindings
bindkey '^A' beginning-of-line             # Ctrl+A
bindkey '^E' end-of-line                   # Ctrl+E
bindkey '^K' kill-line                     # Ctrl+K
bindkey '^U' kill-whole-line               # Ctrl+U
bindkey '^W' backward-kill-word            # Ctrl+W
bindkey '^Y' yank                          # Ctrl+Y
bindkey '^_' undo                          # Ctrl+_

# Word navigation
bindkey '^[[1;5C' forward-word             # Ctrl+Right
bindkey '^[[1;5D' backward-word            # Ctrl+Left
bindkey '^[[H' beginning-of-line           # Home
bindkey '^[[F' end-of-line                 # End

# Use Emacs-style keybindings (more common and expected)
bindkey -e

# History search with arrow keys
bindkey '^[[A' history-search-backward  # Up arrow
bindkey '^[[B' history-search-forward   # Down arrow
bindkey '^P' history-search-backward    # Ctrl-P
bindkey '^N' history-search-forward     # Ctrl-N

# Line editing shortcuts
bindkey '^A' beginning-of-line          # Ctrl-A
bindkey '^E' end-of-line                # Ctrl-E
bindkey '^K' kill-line                  # Ctrl-K
bindkey '^U' kill-whole-line            # Ctrl-U
bindkey '^W' backward-kill-word         # Ctrl-W
bindkey '^[w' kill-region               # Alt-W

# Word navigation
bindkey '^[f' forward-word              # Alt-F
bindkey '^[b' backward-word             # Alt-B
bindkey '^[[1;5C' forward-word          # Ctrl-Right
bindkey '^[[1;5D' backward-word         # Ctrl-Left

# Home and End keys (various terminal sequences)
bindkey '^[[H' beginning-of-line        # Home
bindkey '^[[F' end-of-line              # End
bindkey '^[[1~' beginning-of-line       # Home (alternative)
bindkey '^[[4~' end-of-line             # End (alternative)
bindkey '^[[7~' beginning-of-line       # Home (some terminals)
bindkey '^[[8~' end-of-line             # End (some terminals)
bindkey '^[OH' beginning-of-line        # Home (xterm app mode)
bindkey '^[OF' end-of-line              # End (xterm app mode)

# Delete keys
bindkey '^[[3~' delete-char             # Delete
bindkey '^[d' kill-word                 # Alt-D
bindkey '^H' backward-delete-char       # Backspace
bindkey '^?' backward-delete-char       # Backspace (alternative)

# Page Up/Down for history
bindkey '^[[5~' history-search-backward # Page Up
bindkey '^[[6~' history-search-forward  # Page Down

# Undo/Redo
bindkey '^_' undo                       # Ctrl-_
bindkey '^[_' redo                      # Alt-_

# Quick directory navigation
bindkey -s '^[1' 'cd ..\n'              # Alt-1: cd ..
bindkey -s '^[2' 'cd ../..\n'           # Alt-2: cd ../..
bindkey -s '^[3' 'cd ../../..\n'        # Alt-3: cd ../../..

# Quick commands
bindkey -s '^[l' 'ls -la\n'             # Alt-L: ls -la
bindkey -s '^[g' 'git status\n'         # Alt-G: git status

# Terminal management
bindkey '^L' clear-screen               # Ctrl-L: clear screen
bindkey '^Z' push-line-or-edit          # Ctrl-Z: push current line

# Command line editing
bindkey '^X^E' edit-command-line        # Ctrl-X Ctrl-E: edit in $EDITOR

# Accept suggestions (for zsh-autosuggestions)
bindkey '^[[C' forward-char             # Right arrow (accept suggestion)
bindkey '^[^[[C' forward-word           # Alt-Right (accept word)

# History expansion
bindkey ' ' magic-space                 # Space: expand history

# Smart URLs (auto-quote URLs)
autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic

## [ui-customization.keybindings] - Enhanced keybindings after plugins load

# History search (works with history-substring-search plugin if loaded)
if command -v history-substring-search-up >/dev/null 2>&1; then
    bindkey '^[[A' history-substring-search-up      # Up arrow
    bindkey '^[[B' history-substring-search-down    # Down arrow
    bindkey '^P' history-substring-search-up        # Ctrl+P
    bindkey '^N' history-substring-search-down      # Ctrl+N
else
    bindkey '^[[A' up-line-or-history
    bindkey '^[[B' down-line-or-history
    bindkey '^P' up-line-or-history
    bindkey '^N' down-line-or-history
fi

# FZF keybindings (only if FZF is available)
if command -v fzf >/dev/null 2>&1; then
    bindkey '^T' fzf-file-widget           # Ctrl+T for file selection
    bindkey '^R' fzf-history-widget        # Ctrl+R for history search
    bindkey '\ec' fzf-cd-widget            # Alt+C for directory navigation
fi

# Enhanced editing keybindings
bindkey '^A' beginning-of-line             # Ctrl+A
bindkey '^E' end-of-line                   # Ctrl+E
bindkey '^K' kill-line                     # Ctrl+K
bindkey '^U' kill-whole-line               # Ctrl+U
bindkey '^W' backward-kill-word            # Ctrl+W
bindkey '^Y' yank                          # Ctrl+Y

# Word navigation
bindkey '^[[1;5C' forward-word             # Ctrl+Right
bindkey '^[[1;5D' backward-word            # Ctrl+Left
bindkey '^[[H' beginning-of-line           # Home
bindkey '^[[F' end-of-line                 # End

# Custom widgets for enhanced functionality
# Quick edit current command line
edit-command-line() {
    local EDITOR="${EDITOR:-vim}"
    local tmpfile=$(mktemp)
    zf::debug "$BUFFER" > "$tmpfile"
    $EDITOR "$tmpfile" < /dev/tty > /dev/tty
    BUFFER="$(cat "$tmpfile")"
    rm -f "$tmpfile"
    CURSOR=$#BUFFER
}
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Insert sudo at beginning of line
insert-sudo() {
    if [[ $BUFFER != "sudo "* ]]; then
        BUFFER="sudo $BUFFER"
        CURSOR=$#BUFFER
    fi
}
zle -N insert-sudo
bindkey '^[s' insert-sudo               # Alt-S: insert sudo

# Quick file operations
bindkey -s '^[.' '...\n'                # Alt-.: cd ../../..
bindkey -s '^[h' 'cd ~\n'               # Alt-H: cd home

zf::debug "# [30-ui] Keybindings configured"
