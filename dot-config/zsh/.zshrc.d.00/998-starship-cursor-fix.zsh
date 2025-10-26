
#!/usr/bin/env zsh
# ==============================================================================
# 998-starship-cursor-fix.zsh — Final Starship cursor positioning fixes
# ==============================================================================
# Purpose: Apply comprehensive cursor positioning fixes for Starship prompt
# Runs at the very end of initialization to override any conflicting bindings
# ==============================================================================

# Only run in interactive shells with Starship available
if [[ ! -o interactive ]] || ! command -v starship >/dev/null 2>&1; then
  return 0
fi

# Enhanced cursor positioning widgets for complex Starship prompts
beginning-of-line-starship() {
  local original_cursor=$CURSOR

  # Try standard behavior first
  zle beginning-of-line

  # If cursor didn't move to position 0, force it and reset
  if [[ $CURSOR -gt 0 ]]; then
    CURSOR=0
    zle reset-prompt
  fi
}

end-of-line-starship() {
  local original_cursor=$CURSOR
  local buffer_length=${#BUFFER}

  # Try standard behavior first
  zle end-of-line

  # If cursor didn't reach the end, force it and reset
  if [[ $CURSOR -lt $buffer_length ]]; then
    CURSOR=$buffer_length
    zle reset-prompt
  fi
}

# Create the ZLE widgets
zle -N beginning-of-line-starship
zle -N end-of-line-starship

# Override keybindings to use our enhanced widgets
bindkey '^A' beginning-of-line-starship
bindkey '^E' end-of-line-starship

# Home key bindings
if (( ${+terminfo[khome]} )); then
  bindkey "${terminfo[khome]}" beginning-of-line-starship
fi
bindkey '^[[H' beginning-of-line-starship
bindkey '^[[1~' beginning-of-line-starship
bindkey '^[OH' beginning-of-line-starship

# End key bindings
if (( ${+terminfo[kend]} )); then
  bindkey "${terminfo[kend]}" end-of-line-starship
fi
bindkey '^[[F' end-of-line-starship
bindkey '^[[4~' end-of-line-starship
bindkey '^[OF' end-of-line-starship

# Ensure proper prompt options
setopt PROMPT_SP
unsetopt PROMPT_CR

# Test function to verify the fix
test-starship-cursor() {
  local test_cmd="ai/tools/apply-doc-standards/apply-doc-standards ai/AI-GUIDELINES/Documentation/000-index.md && echo 'Testing cursor positioning with long command line'"

  print -P "%F{yellow}=== Starship Cursor Test ===%f"
  print -P "%F{blue}Test command (${#test_cmd} chars):%f"
  print -P "%F{cyan}$test_cmd%f"
  print -P "%F{white}Instructions:%f"
  print -P "%F{white}1. This command is now in your buffer%f"
  print -P "%F{white}2. Press Home/Ctrl+A - should go to beginning%f"
  print -P "%F{white}3. Press End/Ctrl+E - should go to end%f"
  print -P "%F{white}4. Test backspace and arrow keys%f"

  # Load test command into buffer
  BUFFER="$test_cmd"
  CURSOR=${#BUFFER}
  zle reset-prompt
}

# Create test widget
zle -N test-starship-cursor

# Manual fix function
fix-starship-cursor() {
  print -P "%F{green}Applying Starship cursor fixes...%f"

  # Rebind keys to ensure they override any conflicting bindings
  bindkey '^A' beginning-of-line-starship
  bindkey '^E' end-of-line-starship

  if (( ${+terminfo[khome]} )); then
    bindkey "${terminfo[khome]}" beginning-of-line-starship
  fi
  if (( ${+terminfo[kend]} )); then
    bindkey "${terminfo[kend]}" end-of-line-starship
  fi

  bindkey '^[[H' beginning-of-line-starship
  bindkey '^[[F' end-of-line-starship

  print -P "%F{green}✓ Fixes applied. Test with Alt+X test-starship-cursor%f"
}

# Create fix widget
zle -N fix-starship-cursor

# Bind Alt+X to test function
bindkey '\ex' test-starship-cursor

# Auto-apply for complex prompts
if [[ -o interactive ]]; then
  local starship_prompt
  starship_prompt="$(starship prompt 2>/dev/null || echo '')"

  if [[ -n "$starship_prompt" ]]; then
    local escape_count
    escape_count=$(echo -E "$starship_prompt" | grep -o $'\e\[[0-9;]*m' | wc -l 2>/dev/null || echo 0)

    # Auto-apply if prompt has many escape sequences
    if ((escape_count > 15)); then
      # Bind the enhanced widgets
      bindkey '^A' beginning-of-line-starship 2>/dev/null || true
      bindkey '^E' end-of-line-starship 2>/dev/null || true
    fi
  fi
fi

# Success message for debug mode
if [[ ${ZSH_DEBUG:-0} == 1 ]]; then
  print -P "%F{green}[starship-cursor-fix] Loaded - press Alt+X to test%f"
fi
