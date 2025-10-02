#!/usr/bin/env zsh
# Post-plugin autosuggestions initialization and safe fallbacks
# - Ensures zsh-autosuggestions widgets are present
# - Avoids "No such widget `autosuggest-suggest'" errors
# - Keeps behavior inert if plugin is absent

# Only in interactive shells
[[ -o interactive ]] || return 0

# Prevent multiple loads
if [[ -n ${_ZQS_AUTOSUGGEST_POST_INIT:-} ]]; then
  return 0
fi
export _ZQS_AUTOSUGGEST_POST_INIT=1

# If plugin functions exist, (re)start it safely
if typeset -f _zsh_autosuggest_start >/dev/null 2>&1; then
  # Respect explicit disable flags if user set them
  if [[ "${ZSH_AUTOSUGGEST_DISABLE:-0}" != "1" && "${DISABLE_AUTO_SUGGESTIONS:-0}" != "1" ]]; then
    # Try to start plugin and bind its widgets
    _zsh_autosuggest_start 2>/dev/null || true
  fi
fi

# Provide minimal no-op fallbacks to prevent broken keymaps referencing these widgets
_autosuggest_noop() { return 0 }

for w in autosuggest-suggest autosuggest-fetch autosuggest-accept autosuggest-clear; do
  if [[ -z "${widgets[$w]:-}" ]]; then
    zle -N "$w" _autosuggest_noop 2>/dev/null || true
  fi
done

# Optional: commonly expected keybinds if plugin provided widgets
if [[ -n "${widgets[autosuggest-accept]:-}" ]]; then
  # Enable Right Arrow to accept suggestion by default
  bindkey '^[[C' autosuggest-accept 2>/dev/null || true
fi

