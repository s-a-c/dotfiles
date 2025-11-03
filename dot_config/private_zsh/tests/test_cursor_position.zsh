```#!/usr/bin/env zsh
# Diagnostic tool for cursor positioning issues with long lines
# Tests various scenarios to identify where cursor positioning goes wrong

set -euo pipefail

# Colors
typeset -gr RED=$'\033[0;31m'
typeset -gr GREEN=$'\033[0;32m'
typeset -gr YELLOW=$'\033[1;33m'
typeset -gr BLUE=$'\033[0;34m'
typeset -gr NC=$'\033[0m'

print -P "${BLUE}=== Cursor Position Diagnostic Tool ===${NC}"
print

# Get current terminal info
print -P "${YELLOW}Terminal Information:${NC}"
print -P "Columns: ${GREEN}$COLUMNS${NC}"
print -P "Lines: ${GREEN}$LINES${NC}"
print -P "Keymap: ${GREEN}$KEYMAP${NC}"
print

# Test 1: Simple prompt
print -P "${YELLOW}Test 1: Simple prompt (no escape sequences)${NC}"
PS1="$ "
print -P "Type: ${BLUE}echo 'very long command that should wrap and test cursor positioning by going beyond the terminal width and see if we can move cursor properly'${NC}"
print -P "Then try moving cursor to beginning with Home/Ctrl-A"
print -P "Expected: Should reach the very first character"
read -k1 -s "Press any key to continue..."
print
print

# Test 2: Current Starship prompt
print -P "${YELLOW}Test 2: Current Starship prompt${NC}"
print -P "Current prompt length: ${GREEN}$(echo '$(starship prompt)' | wc -c)${NC} characters"
print -P "Type: ${BLUE}echo 'another very long command to test cursor positioning with the current complex starship prompt that has many escape sequences'${NC}"
print -P "Then try moving cursor to beginning with Home/Ctrl-A"
print -P "Expected: Should reach the very first character, but may stop early"
read -k1 -s "Press any key to continue..."
print
print

# Test 3: Minimal prompt
print -P "${YELLOW}Test 3: Minimal prompt${NC}"
PS1="%# "
print -P "Type: ${BLUE}echo 'testing with minimal prompt to see if cursor positioning works correctly'${NC}"
print -P "Then try moving cursor to beginning with Home/Ctrl-A"
print -P "Expected: Should work correctly"
read -k1 -s "Press any key to continue..."
print
print

# Test 4: Check prompt escape sequences
print -P "${YELLOW}Test 4: Analyzing prompt escape sequences${NC}"
local starship_prompt
starship_prompt="$(starship prompt)"
print -P "Raw prompt bytes: ${GREEN}${#starship_prompt}${NC}"
print -P "Visible characters: ${GREEN}$(echo -E "$starship_prompt" | sed 's/\x1b\[[0-9;]*m//g' | wc -c)${NC}"
print -P "Escape sequences: ${GREEN}$(echo -E "$starship_prompt" | grep -o $'\x1b\[[0-9;]*m' | wc -l)${NC}"

# Show escape sequences
print -P "${BLUE}Escape sequences found:${NC}"
echo -E "$starship_prompt" | grep -o $'\x1b\[[0-9;]*m' | head -10 | while read -r seq; do
  print -P "  ${RED}${seq}${NC}"
done
print

# Test 5: ZLE widgets check
print -P "${YELLOW}Test 5: ZLE widget analysis${NC}"
print -P "Widgets that might affect cursor positioning:"
zle -l | grep -E '(beginning|end|line|cursor)' | while read -r widget; do
  print -P "  ${GREEN}${widget}${NC}"
done
print

# Test 6: ZSH options that affect prompting
print -P "${YELLOW}Test 6: ZSH options related to prompting${NC}"
setopt | grep -E '(prompt|zle|transient|brace)' | while read -r opt; do
  print -P "  ${GREEN}${opt}${NC}"
done
print

# Test 7: Create a problematic test case
print -P "${YELLOW}Test 7: Reproducing the issue${NC}"
print -P "${RED}Paste this exact line and test cursor movement:${NC}"
print -P "${BLUE}ai/tools/apply-doc-standards/apply-doc-standards ai/AI-GUIDELINES/Documentation/000-index.md${NC}"
print -P "Length: ${GREEN}79${NC} characters"
print -P "With your 74-column terminal, this should wrap"
print -P "Try moving cursor to the beginning - where does it stop?"
read -k1 -s "Press any key when done testing..."
print
print

# Recommendations
print -P "${GREEN}=== Recommendations ===${NC}"
print -P "${YELLOW}1. If issue occurs with complex prompts but not simple ones:${NC}"
print -P "   The prompt has non-printing escape sequences without proper %{%} wrappers"
print
print -P "${YELLOW}2. If issue occurs even with simple prompts:${NC}"
print -P "   Terminal or zsh configuration issue"
print
print -P "${YELLOW}3. Common fixes:${NC}"
print -P "   - Add 'unsetopt PROMPT_CR' to .zshrc"
print -P "   - Add 'setopt PROMPT_SP' to .zshrc"
print -P "   - Use 'unsetopt PROMPT_SUBST' if using command substitution"
print -P "   - Ensure Starship prompt uses proper escape sequence handling"
print
print -P "${YELLOW}4. Test with different terminal widths${NC}"
print -P "   Resize terminal and test if issue persists"
print
print -P "${BLUE}Run this script with: zsh test_cursor_position.zsh${NC}"
