#!/usr/bin/env zsh

echo "=== Testing load-shell-fragments behavior ==="

# Source the load-shell-fragments function from .zshrc
source /Users/s-a-c/dotfiles/dot-config/zsh/.zshrc

BASEDIR="${ZDOTDIR:-$HOME}/.config/zsh"

echo -e "\n1. What load-shell-fragments sees in .zshrc.pre-plugins.d:"
ls -la "$BASEDIR/.zshrc.pre-plugins.d/"

echo -e "\n2. Files that should be loaded (recursive):"
find "$BASEDIR/.zshrc.pre-plugins.d/" -name "*.zsh" | sort

echo -e "\n3. What load-shell-fragments actually loads (non-recursive):"
for item in $(/bin/ls -A "$BASEDIR/.zshrc.pre-plugins.d/")
do
    if [ -r "$BASEDIR/.zshrc.pre-plugins.d/$item" ]; then
            zf::debug "Would load: $item"
    else
            zf::debug "Cannot read: $item"
    fi
done

echo -e "\n4. Same test for .zshrc.d:"
echo "Directory contents:"
ls -la "$BASEDIR/.zshrc.d/"

echo -e "\nFiles that should be loaded (recursive):"
find "$BASEDIR/.zshrc.d/" -name "*.zsh" | sort

echo -e "\nWhat load-shell-fragments actually loads:"
for item in $(/bin/ls -A "$BASEDIR/.zshrc.d/")
do
    if [ -r "$BASEDIR/.zshrc.d/$item" ]; then
            zf::debug "Would load: $item"
    else
            zf::debug "Cannot read: $item"
    fi
done
