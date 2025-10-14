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
<<<<<<< HEAD
        zf::debug "  $i. $(basename "$old_file") → $new_name"
=======
        zsh_debug_echo "  $i. $(basename "$old_file") → $new_name"
>>>>>>> origin/develop
done

echo ""
echo "Continue? (y/N): "
read -r confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
<<<<<<< HEAD
        zf::debug "❌ Operation cancelled"
=======
        zsh_debug_echo "❌ Operation cancelled"
>>>>>>> origin/develop
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

<<<<<<< HEAD
        zf::debug -n "  $i. $(basename "$old_file") → $new_name... "

    if [[ ! -f "$old_file" ]]; then
            zf::debug "❌ Source file not found"
=======
        zsh_debug_echo -n "  $i. $(basename "$old_file") → $new_name... "

    if [[ ! -f "$old_file" ]]; then
            zsh_debug_echo "❌ Source file not found"
>>>>>>> origin/develop
        ((error_count++))
        continue
    fi

    if [[ -f "$new_path" ]]; then
<<<<<<< HEAD
            zf::debug "⚠️  Target exists, skipping"
=======
            zsh_debug_echo "⚠️  Target exists, skipping"
>>>>>>> origin/develop
        continue
    fi

    if mv "$old_file" "$new_path"; then
<<<<<<< HEAD
            zf::debug "✅"
        ((success_count++))
    else
            zf::debug "❌ Failed"
        ((error_count++))
            zf::debug "    Error details: mv '$old_file' '$new_path'"
=======
            zsh_debug_echo "✅"
        ((success_count++))
    else
            zsh_debug_echo "❌ Failed"
        ((error_count++))
            zsh_debug_echo "    Error details: mv '$old_file' '$new_path'"
>>>>>>> origin/develop
    fi
done

echo ""
echo "📊 Summary:"
echo "  ✅ Successfully renamed: $success_count files"
echo "  ❌ Failed to rename: $error_count files"

if [[ $success_count -gt 0 ]]; then
<<<<<<< HEAD
        zf::debug ""
        zf::debug "📁 New fix scripts:"
    for new_name in "${new_names[@]}"; do
        local new_path="$ZSHRC_D_DIR/$new_name"
        if [[ -f "$new_path" ]]; then
                zf::debug "  📄 $new_name"
=======
        zsh_debug_echo ""
        zsh_debug_echo "📁 New fix scripts:"
    for new_name in "${new_names[@]}"; do
        local new_path="$ZSHRC_D_DIR/$new_name"
        if [[ -f "$new_path" ]]; then
                zsh_debug_echo "  📄 $new_name"
>>>>>>> origin/develop
        fi
    done
fi

if [[ $error_count -eq 0 ]]; then
<<<<<<< HEAD
        zf::debug ""
        zf::debug "🎉 All fix scripts successfully renamed with ___nn prefixes!"
else
        zf::debug ""
        zf::debug "⚠️  Some operations failed. Check the errors above."
=======
        zsh_debug_echo ""
        zsh_debug_echo "🎉 All fix scripts successfully renamed with ___nn prefixes!"
else
        zsh_debug_echo ""
        zsh_debug_echo "⚠️  Some operations failed. Check the errors above."
>>>>>>> origin/develop
    exit 1
fi
