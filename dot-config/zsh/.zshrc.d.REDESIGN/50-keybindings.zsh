#!/usr/bin/env zsh
# 50-keybindings.zsh - post-plugin keybinding normalization (REDESIGN)
# Ensures essential cursor/navigation keys are bound even if a plugin or theme resets map.
# AI-authored augmentation per AGENT.md (checksum pending)

# Only run in interactive shells
[[ -o interactive ]] || return 0

# Prefer emacs keymap unless user explicitly set vi mode earlier
if [[ ${KEYMAP:-} != vicmd && ${ZSH_FORCE_VI_MODE:-0} != 1 ]]; then
  bindkey -e
fi

# Right arrow fallback: ensure \e[C forwards a char
# Some terminals may send ^[[C, which is \e[ followed by C
bindkey '\e[C' forward-char 2>/dev/null || true

# Defensive: if autosuggest widget shadowed right arrow, rebind explicit mapping
if bindkey | command grep -q '\\e\[C'; then
  # Confirm binding exists; if not set to forward-char
  current=$(bindkey | grep '\\e\[C' | awk '{print $2}')
  if [[ "$current" != 'forward-char' ]]; then
    bindkey '\e[C' forward-char
  fi
fi

# Optional: left/right word movement if not already
# Optional meta+arrow word movement can emit patterns that confuse tools aliasing grep to ripgrep.
# Enable only if user opts in via ZSH_ENABLE_DOUBLE_ESC_ARROWS=1
if [[ ${ZSH_ENABLE_DOUBLE_ESC_ARROWS:-0} == 1 ]]; then
  if ! bindkey | command grep -q '\\e\\e[C'; then bindkey '\e\e[C' forward-word 2>/dev/null || true; fi
  if ! bindkey | command grep -q '\\e\\e[D'; then bindkey '\e\e[D' backward-word 2>/dev/null || true; fi
fi

# Sentinel for testing
export ZSH_KEYBINDINGS_NORMALIZED=1

# Watchdog: ensure right arrow remains bound to forward-char (some plugins may rebind later)
_zqs__keybinding_watchdog() {
  # Only run in interactive shells with zle available
  [[ -o interactive ]] || return 0
  # Ensure Delete (forward delete) key sequences map to delete-char
  # Common sequences: ESC [ 3 ~ (xterm), variants with modifiers, sometimes send 7F or ^[[P
  local del_seq
  for del_seq in '\e[3~' '\e[3;2~' '\e[3;5~' '\e[3;3~'; do
    if ! bindkey | command grep -q "${del_seq//\\/\\\\}"; then
      bindkey "$del_seq" delete-char 2>/dev/null || true
    fi
  done
  # Backspace robustness: ensure ^? mapped to backward-delete-char (do not clobber if user customized)
  if ! bindkey | command grep -q '\^\?'; then
    bindkey '^?' backward-delete-char 2>/dev/null || true
  fi
  if bindkey | command grep -q '\\e\[C'; then
    local cur
    cur=$(bindkey | command grep '\\e\[C' | awk '{print $2}' | tail -1)
    if [[ "$cur" != 'forward-char' ]]; then
      bindkey '\e[C' forward-char 2>/dev/null || true
      [[ ${ZSH_DEBUG:-0} == 1 && -n ${ZSH_DEBUG_LOG:-} ]] && print -r -- "[KEYBIND] Restored right arrow to forward-char (was $cur)" >>"$ZSH_DEBUG_LOG" 2>/dev/null || true
    fi
  else
    bindkey '\e[C' forward-char 2>/dev/null || true
  fi
  # Ensure Home/End sequences present
  local seq
  for seq in '\e[H' '\eOH' '\e[1~'; do
    if ! bindkey | command grep -Fq "$seq"; then
      bindkey "$seq" beginning-of-line 2>/dev/null || true
    fi
  done
  for seq in '\e[F' '\eOF' '\e[4~'; do
    if ! bindkey | command grep -Fq "$seq"; then
      bindkey "$seq" end-of-line 2>/dev/null || true
    fi
  done
}
if (( ! ${precmd_functions[(I)_zqs__keybinding_watchdog]} )); then
  precmd_functions+=( _zqs__keybinding_watchdog )
fi
