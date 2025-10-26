#!/usr/bin/env zsh
# ==============================================================================
# Force Emacs Mode Keybindings - Final Override
# ==============================================================================
# This file ensures that emacs mode is active and arrow keys work correctly.
# It's loaded late (990-prefix) to override any plugin that might set vi mode.
# Updated with document-aware navigation for optimal multiline behavior.

# Force emacs mode
bindkey -e                            # ←  Set emacs mode
bindkey -A emacs main                 # ←  Set main keymap to emacs
zmodload zsh/terminfo 2>/dev/null || true

# Ensure arrow keys work in emacs mode - bind to emacs keymap explicitly
# UPDATED: Use multiline-aware widgets for proper cursor behavior
bindkey -M emacs '^[[D' backward-char              # Left arrow
bindkey -M emacs '^[[C' forward-char               # Right arrow
bindkey -M emacs '^[[A' up-line-or-history         # Up arrow (multiline-aware)
bindkey -M emacs '^[[B' down-line-or-history       # Down arrow (multiline-aware)

# Alternative sequences (application mode) - UPDATED
bindkey -M emacs '^[OD' backward-char              # Left arrow (app mode)
bindkey -M emacs '^[OC' forward-char               # Right arrow (app mode)
bindkey -M emacs '^[OA' up-line-or-history         # Up arrow (app mode)
bindkey -M emacs '^[OB' down-line-or-history       # Down arrow (app mode)

# Also bind in the main keymap (in case emacs isn't the main) - UPDATED
bindkey '^[[D' backward-char
bindkey '^[[C' forward-char
bindkey '^[[A' up-line-or-history                 # Up arrow (multiline-aware)
bindkey '^[[B' down-line-or-history               # Down arrow (multiline-aware)

bindkey '^[OD' backward-char
bindkey '^[OC' forward-char
bindkey '^[OA' up-line-or-history                 # Up arrow (app mode)
bindkey '^[OB' down-line-or-history               # Down arrow (app mode)

# Basic emacs keybindings
bindkey -M emacs '^B' backward-char
bindkey -M emacs '^F' forward-char
bindkey -M emacs '^A' beginning-of-line
bindkey -M emacs '^E' end-of-line

# Home/End/Delete/Backspace — terminfo-driven with common fallbacks
# Terminfo-aware bindings (if available)
if (( ${+terminfo[khome]} )); then
    bindkey -M emacs "${terminfo[khome]}" beginning-of-line
    bindkey "${terminfo[khome]}" beginning-of-line
fi
if (( ${+terminfo[kend]} )); then
    bindkey -M emacs "${terminfo[kend]}" end-of-line
    bindkey "${terminfo[kend]}" end-of-line
fi
if (( ${+terminfo[kdch1]} )); then
    bindkey -M emacs "${terminfo[kdch1]}" delete-char
    bindkey "${terminfo[kdch1]}" delete-char
fi
if (( ${+terminfo[kbs]} )); then
    bindkey -M emacs "${terminfo[kbs]}" backward-delete-char
    bindkey "${terminfo[kbs]}" backward-delete-char
fi

# Fallback sequences for common terminals
# Home -> beginning-of-line (like Ctrl-A)
bindkey -M emacs '^[[H' beginning-of-line
bindkey -M emacs '^[OH' beginning-of-line
bindkey -M emacs '^[[1~' beginning-of-line
bindkey -M emacs '^[7~' beginning-of-line
bindkey '^[[H' beginning-of-line
bindkey '^[OH' beginning-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[7~' beginning-of-line

# End -> end-of-line (like Ctrl-E)
bindkey -M emacs '^[[F' end-of-line
bindkey -M emacs '^[OF' end-of-line
bindkey -M emacs '^[[4~' end-of-line
bindkey -M emacs '^[8~' end-of-line
bindkey '^[[F' end-of-line
bindkey '^[OF' end-of-line
bindkey '^[[4~' end-of-line
bindkey '^[[8~' end-of-line

# Delete key
bindkey -M emacs '^[[3~' delete-char
bindkey '^[[3~' delete-char

# Page Up/Down keys - UPDATED: Use document-aware widgets
bindkey -M emacs '^[[5~' beginning-of-buffer-or-history  # Page Up (smart navigation)
bindkey -M emacs '^[[6~' end-of-buffer-or-history        # Page Down (smart navigation)
bindkey '^[[5~' beginning-of-buffer-or-history           # Page Up (smart navigation)
bindkey '^[[6~' end-of-buffer-or-history                 # Page Down (smart navigation)

# Alternative Page Up/Down sequences - UPDATED: Use document-aware widgets
bindkey -M emacs '^[5~' beginning-of-buffer-or-history   # Page Up (alt, smart navigation)
bindkey -M emacs '^[6~' end-of-buffer-or-history         # Page Down (alt, smart navigation)
bindkey '^[5~' beginning-of-buffer-or-history            # Page Up (alt, smart navigation)
bindkey '^[6~' end-of-buffer-or-history                  # Page Down (alt, smart navigation)

# Additional document navigation widgets for comprehensive coverage
# Ctrl+Page Up/Down for explicit document navigation
bindkey -M emacs '^[[5;5~' beginning-of-buffer-or-history   # Ctrl+Page Up
bindkey -M emacs '^[[6;5~' end-of-buffer-or-history         # Ctrl+Page Down

# Shift+Page Up/Down for explicit document navigation
bindkey -M emacs '^[[5;2~' beginning-of-buffer-or-history   # Shift+Page Up
bindkey -M emacs '^[[6;2~' end-of-buffer-or-history         # Shift+Page Down

# Word movement in emacs mode
bindkey -M emacs '^[B' backward-word
bindkey -M emacs '^[F' forward-word
bindkey -M emacs '^A' beginning-of-line
bindkey -M emacs '^E' end-of-line

# Enhanced word movement for multiline documents
bindkey -M emacs '^[^B' backward-word
bindkey -M emacs '^[^F' forward-word

# Backspace key (both DEL and BS)
bindkey -M emacs '^?' backward-delete-char
bindkey -M emacs '^H' backward-delete-char
bindkey '^?' backward-delete-char
bindkey '^H' backward-delete-char

# Enhanced deletion for multiline documents
bindkey -M emacs '^W' backward-kill-word
bindkey -M emacs '^U' backward-kill-line

# Tab completion handling
bindkey -M emacs '^I' expand-or-complete
bindkey -M emacs '^[^I' reverse-menu-complete

# Escape sequence handling for better multiline editing
bindkey -M emacs '^[[3~' delete-char

# Vi-style movements in emacs mode for muscle memory compatibility
bindkey -M emacs '^[[1;5D' backward-word                # Ctrl+Left
bindkey -M emacs '^[[1;5C' forward-word                 # Ctrl+Right
bindkey -M emacs '^[[1;5A' up-line-or-history           # Ctrl+Up
bindkey -M emacs '^[[1;5B' down-line-or-history         # Ctrl+Down

# Alt+Page movements for enhanced navigation
bindkey -M emacs '^[[5;3~' beginning-of-buffer-or-history   # Alt+Page Up
bindkey -M emacs '^[[6;3~' end-of-buffer-or-history         # Alt+Page Down

# Comprehensive text editing widgets
bindkey -M emacs '^K' kill-line
bindkey -M emacs '^Y' yank
bindkey -M emacs '^T' transpose-chars

# Enhanced multiline text operations
bindkey -M emacs '^X^K' kill-line
bindkey -M emacs '^X^Y' yank
bindkey -M emacs '^X^W' backward-kill-word

# Diagnostic ZLE widget: capture and display key escape sequences
function _zle_diag_keyseq() {
  emulate -L zsh
  local key more seq=""
  local -i max=16
  local -i timeout_ms=${ZSH_KEYSEQ_TIMEOUT_MS:-30}

  zle -M "Press a key (Home/End/Delete etc.) to capture its escape sequence..."
  # Read first byte (blocking)
  read -k key
  seq+="$key"
  # Read subsequent bytes with a short timeout to collect the full sequence
  while read -k -t $(( timeout_ms / 1000.0 )) more; do
    seq+="$more"
    (( ${#seq} >= max )) && break
  done

  # Build caret-notation (e.g., ^[, ^?, etc.) and hex bytes
  local caret=""
  local -a hex=()
  local ch code
  for ((i=1; i<=${#seq}; i++)); do
    ch=${seq[i]}
    code=$(printf "%d" "'$ch")
    if (( code == 27 )); then
      caret+="^["
    elif (( code < 32 )); then
      caret+="^"$(printf "%c" $(( code + 64 )))
    elif (( code == 127 )); then
      caret+="^?"
    else
      caret+="$ch"
    fi
    hex+=($(printf "%02X" "$code"))
  done

  print -r -- ""    # Print a newline
  print -r -- "[ZLE keyseq] length=${#seq} caret=${caret} hex=${(j: :)hex}"
  zle -M "Captured: caret=${caret} hex=${(j: :)hex}"
}
zle -N _zle_diag_keyseq
# Bind diagnostic to Ctrl-X Ctrl-K (works in both emacs and main keymaps)
bindkey -M emacs '^X^K' _zle_diag_keyseq
bindkey '^X^K' _zle_diag_keyseq

# Helper ZLE widget: generate bindkey commands for captured key sequence
function _zle_bindkey_suggest() {
  emulate -L zsh
  local key more seq=""
  local -i max=16
  local -i timeout_ms=${ZSH_KEYSEQ_TIMEOUT_MS:-30}

  zle -M "Press the key to generate bindkey commands..."
  read -k key
  seq+="$key"
  while read -k -t $(( timeout_ms / 1000.0 )) more; do
    seq+="$more"
    (( ${#seq} >= max )) && break
  done

  # Build $'...' escaped sequence for bindkey
  local esc="" ch code
  for ((i=1; i<=${#seq}; i++)); do
    ch=${seq[i]}
    code=$(printf "%d" "'$ch")
    if (( code == 27 )); then
      esc+="\\e"
    elif (( code == 92 )); then
      esc+="\\\\"
    elif (( code == 39 )); then
      esc+="\\'"
    elif (( code >= 32 && code <= 126 )); then
      esc+="$ch"
    else
      esc+="\\x"$(printf "%02X" "$code")
    fi
  done

  print -r -- ""
  print -r -- "[bindkey suggest] Copy-paste one of the lines below and replace <widget> with a ZLE widget (e.g., beginning-of-line, end-of-line, delete-char):"
  print -r -- "bindkey -M emacs \$'$esc' <widget>"
  print -r -- "bindkey \$'$esc' <widget>"
  zle -M "Generated bindkey templates for: \$'$esc'"
}
zle -N _zle_bindkey_suggest
# Bind suggestion helper to Ctrl-X Ctrl-G (both emacs and main keymaps)
bindkey -M emacs '^X^G' _zle_bindkey_suggest
bindkey '^X^G' _zle_bindkey_suggest

# Additional diagnostic: test document navigation widgets
function _zle_test_document_nav() {
  emulate -L zsh
  local test_multiline=$'Line 1\nLine 2\nLine 3\nLine 4'
  LBUFFER=$test_multiline
  RBUFFER=""
  zle -M "Test multiline buffer loaded. Use up/down/page keys to test navigation."
}
zle -N _zle_test_document_nav
bindkey -M emacs '^X^T' _zle_test_document_nav

# Export KEYMAP to indicate emacs mode
export KEYMAP=emacs

# Debug output (only if ZSH_DEBUG is enabled)
if [[ ${ZSH_DEBUG:-0} == 1 ]]; then
    echo "[990-force-emacs-mode] Emacs mode enforced with document-aware navigation"
    echo "[990-force-emacs-mode] Arrow keys: up-line-or-history / down-line-or-history"
    echo "[990-force-emacs-mode] Page keys: beginning-of-buffer-or-history / end-of-buffer-or-history"
    echo "[990-force-emacs-mode] Main keymap set to: emacs"
fi
