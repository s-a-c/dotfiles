#!/usr/bin/env zsh
# ==============================================================================
# Force Emacs Mode Keybindings - Final Override
# ==============================================================================
# This file ensures that emacs mode is active and arrow keys work correctly.
# It's loaded late (990-prefix) to override any plugin that might set vi mode.

# Force emacs mode
bindkey -e
zmodload zsh/terminfo 2>/dev/null || true

# Ensure arrow keys work in emacs mode - bind to emacs keymap explicitly
bindkey -M emacs '^[[D' backward-char # Left arrow
bindkey -M emacs '^[[C' forward-char  # Right arrow
bindkey -M emacs '^[[A' up-history    # Up arrow
bindkey -M emacs '^[[B' down-history  # Down arrow

# Alternative sequences (application mode)
bindkey -M emacs '^[OD' backward-char # Left arrow (app mode)
bindkey -M emacs '^[OC' forward-char  # Right arrow (app mode)
bindkey -M emacs '^[OA' up-history    # Up arrow (app mode)
bindkey -M emacs '^[OB' down-history  # Down arrow (app mode)

# Also bind in the main keymap (in case emacs isn't the main)
bindkey '^[[D' backward-char
bindkey '^[[C' forward-char
bindkey '^[[A' up-history
bindkey '^[[B' down-history

bindkey '^[OD' backward-char
bindkey '^[OC' forward-char
bindkey '^[OA' up-history
bindkey '^[OB' down-history

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
bindkey '^[8~' end-of-line

# Delete key
bindkey -M emacs '^[[3~' delete-char
bindkey '^[[3~' delete-char

# Page Up/Down keys
bindkey -M emacs '^[[5~' beginning-of-history  # Page Up
bindkey -M emacs '^[[6~' end-of-history        # Page Down
bindkey '^[[5~' beginning-of-history           # Page Up
bindkey '^[[6~' end-of-history                 # Page Down

# Alternative Page Up/Down sequences
bindkey -M emacs '^[5~' beginning-of-history   # Page Up (alt)
bindkey -M emacs '^[6~' end-of-history         # Page Down (alt)
bindkey '^[5~' beginning-of-history            # Page Up (alt)
bindkey '^[6~' end-of-history                  # Page Down (alt)

# Backspace key (both DEL and BS)
bindkey -M emacs '^?' backward-delete-char
bindkey -M emacs '^H' backward-delete-char
bindkey '^?' backward-delete-char
bindkey '^H' backward-delete-char

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

  print -r -- ""
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


# Export KEYMAP to indicate emacs mode
export KEYMAP=emacs

# Debug output (only if ZSH_DEBUG is enabled)
if [[ ${ZSH_DEBUG:-0} == 1 ]]; then
    echo "[990-force-emacs-mode] Emacs mode enforced, arrow keys configured"
fi
