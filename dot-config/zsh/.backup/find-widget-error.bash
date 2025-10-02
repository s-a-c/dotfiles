#!/usr/bin/env bash
set -euo pipefail

echo "Finding the exact source of widgets parameter error..."
cd /Users/s-a-c/dotfiles/dot-config/zsh

echo "=== Checking Starship cache file ==="
if [[ -f .zsh-evalcache/init-starship-*.sh ]]; then
    echo "Starship cache files found:"
    ls -la .zsh-evalcache/init-starship-*.sh | head -3
    echo ""
    
    echo "Looking for widgets[zle-keymap-select] in starship cache:"
    grep -n "widgets\[zle-keymap-select\]" .zsh-evalcache/init-starship-*.sh || echo "Not found in starship cache"
    
    echo ""
    echo "Checking line 67 in starship cache:"
    for file in .zsh-evalcache/init-starship-*.sh; do
        if [[ -f "$file" ]]; then
            echo "File: $file"
            sed -n '65,70p' "$file" | cat -n
            echo ""
        fi
    done
fi

echo "=== Looking for the exact (eval) source ==="
timeout 10s bash -c 'ZDOTDIR="$PWD" zsh -x -i -c "exit" 2>&1' | \
    grep -B5 -A5 "widgets\[zle-keymap-select\]" | \
    head -15 > widget_error_context.log 2>/dev/null || echo "Context search completed"

if [[ -f widget_error_context.log && -s widget_error_context.log ]]; then
    echo "Error context from trace:"
    cat widget_error_context.log
else
    echo "No detailed context found"
fi

echo ""
echo "=== Checking if this is happening before or after .zshenv ==="
timeout 10s bash -c 'ZDOTDIR="$PWD" zsh -i -c "
    echo \"Checking timing - widgets status: \${+widgets}\"
    echo \"Checking timing - widgets type: \$(typeset -p widgets 2>/dev/null || echo NOT_SET)\"
    exit
" 2>&1' | grep -E "(widgets|Checking timing)"

# Cleanup
rm -f widget_error_context.log