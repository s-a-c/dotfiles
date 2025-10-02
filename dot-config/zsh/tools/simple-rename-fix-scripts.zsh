#!/usr/bin/env zsh
# Simple, direct rename script for fix files
# No complex logic - just rename the files directly

set -euo pipefail

ZSHRC_D_DIR="/Users/s-a-c/dotfiles/dot-config/zsh/.zshrc.d"

echo "🔧 Simple Fix Script Renamer"
echo "=================================="

# Find all fix scripts manually
typeset -a files_to_rename
files_to_rename=(
    "$ZSHRC_D_DIR/00_00-comprehensive-startup-fix.zsh"
    "$ZSHRC_D_DIR/00_00-emergency-startup-fix.zsh"
    "$ZSHRC_D_DIR/00_00-startup-loop-prevention.zsh"
    "$ZSHRC_D_DIR/00_01-terminal-environment-fix.zsh"
)

# Target names
typeset -a new_names
new_names=(
    "___01-comprehensive-startup-fix.zsh"
    "___02-emergency-startup-fix.zsh"
    "___03-startup-loop-prevention.zsh"
    "___04-terminal-environment-fix.zsh"
)

echo "Files to rename:"
for ((i=1; i<=${#files_to_rename[@]}; i++)); do
    local old_file="${files_to_rename[i]}"
    local new_name="${new_names[i]}"
        zf::debug "  $i. $(basename "$old_file") → $new_name"
done

echo ""
echo "Continue? (y/N): "
read -r confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        zf::debug "❌ Operation cancelled"
    exit 0
fi

echo ""
echo "🚀 Performing renames..."

success_count=0
error_count=0

for ((i=1; i<=${#files_to_rename[@]}; i++)); do
    old_file="${files_to_rename[i]}"
    new_name="${new_names[i]}"
    new_path="$ZSHRC_D_DIR/$new_name"

        zf::debug -n "  $i. $(basename "$old_file") → $new_name... "

    if [[ ! -f "$old_file" ]]; then
            zf::debug "❌ Source file not found"
        ((error_count++))
        continue
    fi

    if [[ -f "$new_path" ]]; then
            zf::debug "⚠️  Target exists, skipping"
        continue
    fi

    if mv "$old_file" "$new_path"; then
            zf::debug "✅"
        ((success_count++))
    else
            zf::debug "❌ Failed"
        ((error_count++))
            zf::debug "    Error details: mv '$old_file' '$new_path'"
    fi
done

echo ""
echo "📊 Summary:"
echo "  ✅ Successfully renamed: $success_count files"
echo "  ❌ Failed to rename: $error_count files"

if [[ $success_count -gt 0 ]]; then
        zf::debug ""
        zf::debug "📁 New fix scripts:"
    for new_name in "${new_names[@]}"; do
        local new_path="$ZSHRC_D_DIR/$new_name"
        if [[ -f "$new_path" ]]; then
                zf::debug "  📄 $new_name"
        fi
    done
fi

if [[ $error_count -eq 0 ]]; then
        zf::debug ""
        zf::debug "🎉 All fix scripts successfully renamed with ___nn prefixes!"
else
        zf::debug ""
        zf::debug "⚠️  Some operations failed. Check the errors above."
    exit 1
fi
