#!/usr/bin/env zsh
# ==============================================================================
# Fix Plugin Helper Function Guards
# ==============================================================================
# Purpose: Add defensive guard for zf::add_segment to all plugin files
# Part of: Phase 1, Task 1.2 - Configuration Stability Testing Fix
# Created: 2025-10-07
#
# Note: zf::debug is already defined in .zshenv (always available)
#       zf::add_segment is defined in .zshrc.pre-plugins.d/030-segment-management.zsh
#       but may not be available during zgenom save
# ==============================================================================

emulate -L zsh
setopt ERR_RETURN NO_UNSET PIPE_FAIL

ZDOTDIR="${ZDOTDIR:-${HOME}/.config/zsh}"
PLUGIN_DIR="${ZDOTDIR}/.zshrc.add-plugins.d"

# Guard block to add at the top of each file (after the header comments)
# Only need to guard zf::add_segment since zf::debug is in .zshenv
GUARD_BLOCK='
# Defensive guard for zf::add_segment (may not be available during zgenom save)
typeset -f zf::add_segment >/dev/null 2>&1 || zf::add_segment() { : }
'

echo "Adding defensive guards to plugin files..."
echo ""

for file in "${PLUGIN_DIR}"/*.zsh; do
  if [[ ! -f "$file" ]]; then
    continue
  fi

  filename=$(basename "$file")

  # Check if guards already exist
  if grep -q "typeset -f zf::add_segment" "$file" 2>/dev/null; then
    echo "  ✓ $filename - guards already present"
    continue
  fi

  # Find the line number after the header comments (after RESTART_REQUIRED line)
  insert_line=$(grep -n "^# RESTART_REQUIRED:" "$file" | cut -d: -f1)

  if [[ -z "$insert_line" ]]; then
    echo "  ⚠ $filename - no RESTART_REQUIRED marker found, skipping"
    continue
  fi

  # Insert after the RESTART_REQUIRED line
  insert_line=$((insert_line + 1))

  # Create backup
  cp "$file" "${file}.backup"

  # Insert the guard block
  {
    head -n "$insert_line" "$file"
    echo "$GUARD_BLOCK"
    tail -n +$((insert_line + 1)) "$file"
  } > "${file}.new"

  # Replace original with new file
  mv "${file}.new" "$file"

  echo "  ✓ $filename - guards added at line $insert_line"
done

echo ""
echo "Done! Backup files created with .backup extension"
echo ""
echo "Next steps:"
echo "  1. Review the changes: git diff .zshrc.add-plugins.d/"
echo "  2. Clean caches: find . -name '*.zwc' -delete && find . -name '.zcompdump*' -delete"
echo "  3. Test: zgenom reset && zgenom save"
echo "  4. Verify: zgenom list | wc -l"
echo "  5. If successful, remove backups: rm .zshrc.add-plugins.d/*.backup"
echo ""

