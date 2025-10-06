#!/usr/bin/env zsh
# 120-SIMPLE-AUTOPAIR.ZSH (inlined from legacy 30-simple-autopair.zsh)
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}
# DISABLED - Using hlissner/zsh-autopair plugin instead
return 0
[[ -n "$PERF_SEGMENT_LOG" ]] && echo "$(date '+%H:%M:%S.%3N') [SEGMENT:START] simple-autopair" >> "$PERF_SEGMENT_LOG"
if [[ ! -o interactive ]]; then
	[[ -n "$PERF_SEGMENT_LOG" ]] && echo "$(date '+%H:%M:%S.%3N') [SEGMENT:SKIP] simple-autopair (non-interactive)" >> "$PERF_SEGMENT_LOG"
	return 0
fi

# Ensure ZLE is loaded before defining widgets
if ! zmodload -i zsh/zle 2>/dev/null; then
	[[ -n "$PERF_SEGMENT_LOG" ]] && echo "$(date '+%H:%M:%S.%3N') [SEGMENT:SKIP] simple-autopair (no ZLE)" >> "$PERF_SEGMENT_LOG"
	return 0
fi
for widget in autopair-insert autopair-close autopair-delete autopair-delete-word; do [[ -n "${widgets[$widget]:-}" ]] && zle -D "$widget" 2>/dev/null; done
typeset -gA SIMPLE_AUTOPAIR_PAIRS; SIMPLE_AUTOPAIR_PAIRS=( '(' ')' '[' ']' '{' '}' '<' '>' '"' '"' "'" "'" '`' '`' )
export SIMPLE_AUTOPAIR_PAIRS
simple-autopair-get-pair() {
    local char="$1"
    echo "${SIMPLE_AUTOPAIR_PAIRS[$char]:-}"
}
# Define autopair functions in global scope with explicit export
simple-autopair-insert() {
    local char="${KEYS:-}" pair
    [[ -n "$char" ]] || return 0
    pair="$(simple-autopair-get-pair "$char")"
    if [[ -n "$pair" ]]; then
        if [[ "$char" == "$pair" && "${RBUFFER[1]}" == "$char" ]]; then
            zle forward-char
        else
            LBUFFER+="$char"
            RBUFFER="$pair$RBUFFER"
        fi
    else
        zle self-insert
    fi
}

simple-autopair-close() {
    local char="${KEYS:-}"
    [[ -n "$char" ]] || return 0
    if [[ "${RBUFFER[1]}" == "$char" ]]; then
        zle forward-char
    else
        zle self-insert
    fi
}

simple-autopair-delete() {
    local left_char="${LBUFFER[-1]:-}" right_char="${RBUFFER[1]:-}" expected_pair="$(simple-autopair-get-pair "$left_char")"
    [[ -n "$expected_pair" && "$right_char" == "$expected_pair" ]] && RBUFFER="${RBUFFER[2,-1]}"
    zle backward-delete-char
}

# Ensure functions are available in global scope
typeset -f simple-autopair-insert simple-autopair-close simple-autopair-delete >/dev/null 2>&1
# Register widgets with error handling
if [[ -o interactive ]] && zmodload -i zsh/zle 2>/dev/null; then
  # Register widgets
  local insert_ok=0 close_ok=0 delete_ok=0

  # Test function availability first
  if typeset -f simple-autopair-insert >/dev/null 2>&1; then
    if zle -N simple-autopair-insert; then
      insert_ok=1
      # Bind opening characters immediately after successful registration
      bindkey '(' simple-autopair-insert 2>/dev/null || true
      bindkey '[' simple-autopair-insert 2>/dev/null || true
      bindkey '{' simple-autopair-insert 2>/dev/null || true
      bindkey '<' simple-autopair-insert 2>/dev/null || true
      bindkey '"' simple-autopair-insert 2>/dev/null || true
      bindkey "'" simple-autopair-insert 2>/dev/null || true
      bindkey '`' simple-autopair-insert 2>/dev/null || true
      [[ -n "$DEBUG_ZSH_REDESIGN" ]] && echo "[AUTOPAIR] Successfully registered simple-autopair-insert"
    else
      [[ -n "$DEBUG_ZSH_REDESIGN" ]] && echo "[AUTOPAIR] Failed to register simple-autopair-insert widget"
    fi
  else
    [[ -n "$DEBUG_ZSH_REDESIGN" ]] && echo "[AUTOPAIR] Function simple-autopair-insert not found"
  fi

  if zle -N simple-autopair-close 2>/dev/null; then
    close_ok=1
    # Bind closing characters immediately after successful registration
    bindkey ')' simple-autopair-close 2>/dev/null || true
    bindkey ']' simple-autopair-close 2>/dev/null || true
    bindkey '}' simple-autopair-close 2>/dev/null || true
    bindkey '>' simple-autopair-close 2>/dev/null || true
  fi

  if zle -N simple-autopair-delete 2>/dev/null; then
    delete_ok=1
    # Bind delete keys immediately after successful registration
    bindkey '^?' simple-autopair-delete 2>/dev/null || true
    bindkey '^H' simple-autopair-delete 2>/dev/null || true
  fi

  [[ -n "$DEBUG_ZSH_REDESIGN" ]] && echo "[AUTOPAIR] Widget registration: insert=$insert_ok close=$close_ok delete=$delete_ok"
fi
[[ -n "$DEBUG_ZSH_REDESIGN" ]] && {
  echo "[AUTOPAIR] Simple autopair implementation loaded"
  echo "[AUTOPAIR] Configured pairs: ${(@k)SIMPLE_AUTOPAIR_PAIRS}"
  echo "[AUTOPAIR] Widgets registered: simple-autopair-{insert,close,delete}"
  echo "[AUTOPAIR] Widget check - insert: ${widgets[simple-autopair-insert]:-MISSING}"
  echo "[AUTOPAIR] Widget check - close: ${widgets[simple-autopair-close]:-MISSING}"
  echo "[AUTOPAIR] Widget check - delete: ${widgets[simple-autopair-delete]:-MISSING}"
  echo "[AUTOPAIR] Key bindings test: type '(' to test autopair"
}
[[ -n "$PERF_SEGMENT_LOG" ]] && echo "$(date '+%H:%M:%S.%3N') [SEGMENT:END] simple-autopair" >> "$PERF_SEGMENT_LOG"
typeset -g ZSH_AUTOPAIR_MODULE_LOADED=1
return 0
