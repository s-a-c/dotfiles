#!/usr/bin/env zsh
# Simple test to reproduce and verify the cursor positioning issue

# Test the exact scenario you described
print -P "%F{yellow}=== Cursor Position Test ===%f"
print -P "%F{red}Paste this line and test cursor movement:%f"
print -P "%F{blue}ai/tools/apply-doc-standards/apply-doc-standards ai/AI-GUIDELINES/Documentation/000-index.md%f"
print
print -P "%F{yellow}Instructions:%f"
print -P "1. Paste the line above"
print -P "2. Try to move cursor to the beginning with Home or Ctrl+A"
print -P "3. Note where the cursor stops (should be at first 'a')"
print -P "4. If it stops early, run: fix-starship-cursor"
print -P "5. Test again"
print
print -P "%F{green}Current terminal width: $COLUMNS%f"
print -P "%F{green}Test line length: 79 characters%f"
