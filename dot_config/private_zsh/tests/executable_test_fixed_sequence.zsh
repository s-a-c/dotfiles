#!/usr/bin/env zsh
# test_fixed_sequence.zsh - Test the corrected execution sequence
# Verifies that splash screen runs before first prompt to prevent cursor issues

set -euo pipefail

# Colors
typeset -gr RED=$'\033[0;31m'
typeset -gr GREEN=$'\033[0;32m'
typeset -gr YELLOW=$'\033[1;33m'
typeset -gr BLUE=$'\033[0;34m'
typeset -gr NC=$'\033[0m'

print -P "${BLUE}=== Testing Fixed Execution Sequence ===${NC}"
print

# Test 1: Verify load order
print -P "${YELLOW}Test 1: Checking load order...${NC}"
print -P "User interface should load at 395 (before prompt setup)"

if [[ -f "${ZDOTDIR:-$HOME}/.zshrc.d/395-user-interface.zsh" ]]; then
  print -P "${GREEN}✓ User interface positioned at 395${NC}"
else
  print -P "${RED}✗ User interface not found at 395${NC}"
fi

if [[ -f "${ZDOTDIR:-$HOME}/.zshrc.d/540-prompt-starship.zsh" ]]; then
  print -P "${GREEN}✓ Starship prompt loads at 540 (after UI)${NC}"
else
  print -P "${RED}✗ Starship prompt not found at 540${NC}"
fi
print

# Test 2: Check if splash runs immediately
print -P "${YELLOW}Test 2: Splash screen execution timing${NC}"
print -P "The splash should run immediately, not via precmd hook"

# Check if the precmd hook is registered
if add-zsh-hook -L precmd 2>/dev/null | grep -q "show_startup_splash_precmd"; then
  print -P "${RED}✗ Splash still using precmd hook (bad)${NC}"
else
  print -P "${GREEN}✓ Splash not using precmd hook (good)${NC}"
fi
print

# Test 3: Verify cursor positioning with test line
print -P "${YELLOW}Test 3: Cursor positioning test${NC}"
print -P "${RED}Paste this line and test cursor movement:${NC}"
print -P "${BLUE}ai/tools/apply-doc-standards/apply-doc-standards ai/AI-GUIDELINES/Documentation/000-index.md${NC}"
print
print -P "${YELLOW}Expected behavior:${NC}"
print -P "• Splash screen should appear BEFORE first prompt"
print -P "• Press Home/Ctrl-A should reach the very first character"
print -P "• No cursor positioning issues on long wrapped lines"
print

# Test 4: Show current sequence
print -P "${YELLOW}Test 4: Current execution sequence${NC}"
print -P "${BLUE}Fixed sequence:${NC}"
print -P "1. System login messages"
print -P "2. ZSH options (400)"
print -P "3. User interface/splash (395) ← ${GREEN}MOVED EARLIER${NC}"
print -P "4. Starship prompt setup (540)"
print -P "5. Cursor positioning fixes (541)"
print -P "6. First prompt appears"
print -P "7. ${GREEN}No more output after prompt${NC}"
print

print -P "${GREEN}=== Expected Result ===${NC}"
print -P "${YELLOW}With the fixed sequence, cursor positioning should work correctly${NC}"
print -P "${YELLOW}because all startup output happens BEFORE the first prompt.${NC}"
print
print -P "${BLUE}If cursor issues persist, run: fix-starship-cursor${NC}"
