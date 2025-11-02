#!/usr/bin/env zsh
# Filename: 490-keybindings.zsh
# Purpose:  Ensures a consistent and powerful keybinding experience by forcing Emacs mode and applying fixes for modern terminals and complex prompts like Starship. This script is loaded late to override any conflicting settings from plugins. Features: - Forces `emacs` keymap to be active. - Binds arrow keys, Home, End, Delete, and Page Up/Down to multiline-aware ZLE widgets for correct cursor behavior. - Includes enhanced cursor positioning widgets (`beginning-of-line-starship`, `end-of-line-starship`) to fix issues with Starship's prompt. - Provides diagnostic ZLE widgets (`_zle_diag_keyseq`, `_zle_bindkey_suggest`) for debugging key escape sequences. --- Force Emacs Mode ---
# Phase:    Post-plugin (.zshrc.d/)

# --- Force Emacs Mode ---
bindkey -e
bindkey -A emacs main
export KEYMAP=emacs

# --- Starship Cursor Fix Widgets ---
beginning-of-line-starship() {
  zle beginning-of-line
  if [[ $CURSOR -gt 0 ]]; then
    CURSOR=0
    zle reset-prompt
  fi
}
zle -N beginning-of-line-starship

end-of-line-starship() {
  zle end-of-line
  if [[ $CURSOR -lt ${#BUFFER} ]]; then
    CURSOR=${#BUFFER}
    zle reset-prompt
  fi
}
zle -N end-of-line-starship

# --- Core Bindings (using fixed widgets) ---
bindkey '^A' beginning-of-line-starship
bindkey '^E' end-of-line-starship
bindkey '^B' backward-char
bindkey '^F' forward-char
bindkey '^P' up-line-or-history
bindkey '^N' down-line-or-history
bindkey '^D' delete-char-or-list
bindkey '^H' backward-delete-char
bindkey '^?' backward-delete-char

# --- Arrow and Navigation Keys ---
zmodload zsh/terminfo 2>/dev/null || true
bindkey "${terminfo[kcuu1]}" up-line-or-history
bindkey "${terminfo[kcud1]}" down-line-or-history
bindkey "${terminfo[kcub1]}" backward-char
bindkey "${terminfo[kcuf1]}" forward-char
bindkey "${terminfo[khome]}" beginning-of-line-starship
bindkey "${terminfo[kend]}" end-of-line-starship
bindkey "${terminfo[kdch1]}" delete-char
bindkey "${terminfo[kpp]}" beginning-of-buffer-or-history # Page Up
bindkey "${terminfo[knp]}" end-of-buffer-or-history     # Page Down

# --- Fallback sequences for common terminals ---
# Arrows
bindkey '^[[A' up-line-or-history; bindkey '^[OA' up-line-or-history
bindkey '^[[B' down-line-or-history; bindkey '^[OB' down-line-or-history
bindkey '^[[D' backward-char; bindkey '^[OD' backward-char
bindkey '^[[C' forward-char; bindkey '^[OC' forward-char
# Home/End
bindkey '^[[H' beginning-of-line-starship; bindkey '^[OH' beginning-of-line-starship
bindkey '^[[1~' beginning-of-line-starship; bindkey '^[7~' beginning-of-line-starship
bindkey '^[[F' end-of-line-starship; bindkey '^[OF' end-of-line-starship
bindkey '^[[4~' end-of-line-starship; bindkey '^[8~' end-of-line-starship
# Delete
bindkey '^[[3~' delete-char
# Page Up/Down
bindkey '^[[5~' beginning-of-buffer-or-history
bindkey '^[[6~' end-of-buffer-or-history

# --- Diagnostic Widgets ---
_zle_diag_keyseq() {
  local key seq; read -k key; seq="$key"; read -k -t 0.03 key && seq+="$key"
  print -r -- "[ZLE keyseq] Captured: ${(q)seq}"
  zle -M "Captured: ${(q)seq}"
}
zle -N _zle_diag_keyseq
bindkey '^X^K' _zle_diag_keyseq

# --- Help Function ---
keybinds-help() {
  echo "--- Core Emacs Keybindings ---"
  echo "^A        : Beginning of line (Starship-aware)"
  echo "^E        : End of line (Starship-aware)"
  echo "^B        : Backward one character"
  echo "^F        : Forward one character"
  echo "^P        : Previous line (or history)"
  echo "^N        : Next line (or history)"
  echo "^D        : Delete character (or list completions)"
  echo "^H, ^?    : Backward delete character (backspace)"
  echo ""
  echo "--- Arrow & Navigation Keys ---"
  echo "↑         : Previous line (or history)"
  echo "↓         : Next line (or history)"
  echo "←         : Backward one character"
  echo "→         : Forward one character"
  echo "Home      : Beginning of line (Starship-aware)"
  echo "End       : End of line (Starship-aware)"
  echo "Delete    : Delete character under cursor"
  echo "Page Up   : Beginning of buffer or history"
  echo "Page Down : End of buffer or history"
  echo ""
  echo "--- Diagnostic Tools ---"
  echo "^X^K      : Capture and display key sequence (for debugging)"
  echo ""
  echo "--- Notes ---"
  echo "• All keybindings use Emacs mode (not Vi mode)"
  echo "• Cursor positioning widgets are Starship-prompt aware"
  echo "• Arrow/navigation keys work across multiple terminals"
}

# --- Welcome Message ---
if [[ -z "${_ZF_KEYBINDINGS_NOTIFIED:-}" ]]; then
  echo "⌨️  Emacs keybindings active. Type 'keybinds-help' for a full list."
  export _ZF_KEYBINDINGS_NOTIFIED=1
fi

typeset -f zf::debug >/dev/null 2>&1 && zf::debug "# [keys] Emacs keybindings enforced with Starship cursor fix"
return 0
