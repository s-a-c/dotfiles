#!/usr/bin/env zsh
# Comprehensive test for all keybindings in zsh configuration
# Tests emacs mode, backspace, delete, home, end, arrows, and page up/down

set -euo pipefail

# Colors for output
typeset -gr RED=$'\033[0;31m'
typeset -gr GREEN=$'\033[0;32m'
typeset -gr YELLOW=$'\033[1;33m'
typeset -gr NC=$'\033[0m'

# Test results
typeset -a failures
typeset -a passes

cd "$(dirname "$0")/.."
export ZDOTDIR="$PWD"

# Only run if we're in an interactive shell with full config loaded
if [[ ! -o interactive ]]; then
  print -P "${RED}Error: This test must be run in an interactive zsh session${NC}"
  print -P "${YELLOW}Run: zsh -i tests/test_all_keybindings.zsh${NC}"
  exit 1
fi

print -P "${YELLOW}Testing zsh keybindings...${NC}"

# Helper function to check binding
check_binding() {
  local seq="$1"
  local target="$2"
  local description="$3"

  if bindkey | grep -F "${seq}" | grep -q "${target}"; then
    passes+=("✓ $description")
  else
    failures+=("✗ $description (${seq} → ${target})")
  fi
}

# Test emacs mode keybindings
print -P "${YELLOW}Testing emacs mode basic bindings...${NC}"
check_binding "^A" "beginning-of-line" "Ctrl+A → beginning of line"
check_binding "^E" "end-of-line" "Ctrl+E → end of line"
check_binding "^B" "backward-char" "Ctrl+B → backward char"
check_binding "^F" "forward-char" "Ctrl+F → forward char"
check_binding "^P" "up-line-or-history" "Ctrl+P → up line/history"
check_binding "^N" "down-line-or-history" "Ctrl+N → down line/history"

# Test backspace
print -P "${YELLOW}Testing backspace/delete...${NC}"
check_binding "^?" "backward-delete-char" "Backspace (^?) → backward delete"
check_binding "^H" "backward-delete-char" "Ctrl+H → backward delete"
check_binding "^[[3~" "delete-char" "Delete (^[[3~) → forward delete"

# Test Home key variations
print -P "${YELLOW}Testing Home key variations...${NC}"
check_binding "^[[H" "beginning-of-line" "Home (^[[H) → beginning of line"
check_binding "^[OH" "beginning-of-line" "Home (^[OH) → beginning of line"
check_binding "^[[1~" "beginning-of-line" "Home (^[[1~) → beginning of line"
check_binding "^[7~" "beginning-of-line" "Home (^[7~) → beginning of line"

# Test End key variations
print -P "${YELLOW}Testing End key variations...${NC}"
check_binding "^[[F" "end-of-line" "End (^[[F) → end of line"
check_binding "^[OF" "end-of-line" "End (^[OF) → end of line"
check_binding "^[[4~" "end-of-line" "End (^[[4~) → end of line"
check_binding "^[8~" "end-of-line" "End (^[8~) → end of line"

# Test arrow keys
print -P "${YELLOW}Testing arrow keys...${NC}"
check_binding "^[[A" "up-history" "Up arrow (^[[A) → up history"
check_binding "^[[B" "down-history" "Down arrow (^[[B) → down history"
check_binding "^[[C" "forward-char" "Right arrow (^[[C) → forward char"
check_binding "^[[D" "backward-char" "Left arrow (^[[D) → backward char"

# Test application mode arrow keys
print -P "${YELLOW}Testing application mode arrow keys...${NC}"
check_binding "^[OA" "up-history" "Up arrow app mode (^[OA) → up history"
check_binding "^[OB" "down-history" "Down arrow app mode (^[OB) → down history"
check_binding "^[OC" "forward-char" "Right arrow app mode (^[OC) → forward char"
check_binding "^[OD" "backward-char" "Left arrow app mode (^[OD) → backward char"

# Test page up/down
print -P "${YELLOW}Testing Page Up/Down...${NC}"
check_binding "^[[5~" "beginning-of-history" "Page Up (^[[5~) → beginning of history"
check_binding "^[[6~" "end-of-history" "Page Down (^[[6~) → end of history"
check_binding "^[5~" "beginning-of-history" "Page Up (^[5~) → beginning of history"
check_binding "^[6~" "end-of-history" "Page Down (^[6~) → end of history"

# Check if we're in emacs mode
print -P "${YELLOW}Checking keymap mode...${NC}"
if [[ $KEYMAP == emacs ]]; then
  passes+=("✓ Keymap is set to emacs mode")
else
  failures+=("✗ Keymap is not in emacs mode (current: $KEYMAP)")
fi

# Print results
print
print -P "${GREEN}=== PASSED TESTS ===${NC}"
for pass in "${passes[@]}"; do
  print -P "${GREEN}$pass${NC}"
done

if ((${#failures[@]} > 0)); then
  print
  print -P "${RED}=== FAILED TESTS ===${NC}"
  for fail in "${failures[@]}"; do
    print -P "${RED}$fail${NC}"
  done
  print
  print -P "${RED}Total failures: ${#failures[@]}${NC}"
  exit 1
else
  print
  print -P "${GREEN}All keybinding tests passed! ✅${NC}"
  print -P "${GREEN}Total passed: ${#passes[@]}${NC}"
fi
