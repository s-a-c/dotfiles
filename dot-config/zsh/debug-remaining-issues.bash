#!/usr/bin/env bash
set -euo pipefail

echo "Investigating remaining ZSH startup issues..."
cd /Users/s-a-c/dotfiles/dot-config/zsh

echo "=== 1. Checking zgenom init.zsh permissions ==="
if [[ -f .zqs-zgenom/init.zsh ]]; then
    ls -la .zqs-zgenom/init.zsh
    echo "First few lines of init.zsh:"
    head -5 .zqs-zgenom/init.zsh 2>/dev/null || echo "Cannot read file"
else
    echo "init.zsh does not exist"
fi

echo ""
echo "=== 2. Checking for 'command not found: --' source ==="
timeout 10s bash -c 'ZDOTDIR="$PWD" zsh -x -i -c "exit" 2>&1' | \
    grep -B3 -A3 "command not found.*--" | \
    head -10 > command_error.log 2>/dev/null || echo "Error search completed"

if [[ -f command_error.log && -s command_error.log ]]; then
    echo "Found command not found error context:"
    cat command_error.log
else
    echo "No command not found errors found in trace"
fi

echo ""
echo "=== 3. Checking if starship is actually loading ==="
timeout 10s bash -c 'ZDOTDIR="$PWD" zsh -x -i -c "exit" 2>&1' | \
    grep -E "(starship|STARSHIP)" | \
    head -5 > starship_trace.log 2>/dev/null || echo "Starship trace completed"

if [[ -f starship_trace.log && -s starship_trace.log ]]; then
    echo "Starship loading detected:"
    cat starship_trace.log
else
    echo "No starship loading detected in trace"
fi

echo ""
echo "=== 4. Testing zgenom status ==="
timeout 5s bash -c 'ZDOTDIR="$PWD" zsh -i -c "
    echo \"zgenom available: \$(command -v zgenom >/dev/null && echo yes || echo no)\"
    if command -v zgenom >/dev/null; then
        zgenom list 2>/dev/null | head -3 || echo \"zgenom list failed\"
    fi
    exit
" 2>/dev/null' || echo "zgenom test failed"

echo ""
echo "=== 5. Checking if 09-external-integrations actually loads starship ==="
timeout 10s bash -c 'ZDOTDIR="$PWD" zsh -x -i -c "exit" 2>&1' | \
    grep -E "(09-external-integrations|setup_starship_prompt)" | \
    head -5 > ext_integrations.log 2>/dev/null || echo "External integrations check completed"

if [[ -f ext_integrations.log && -s ext_integrations.log ]]; then
    echo "External integrations module activity:"
    cat ext_integrations.log
else
    echo "No external integrations activity detected"
fi

# Cleanup
rm -f command_error.log starship_trace.log ext_integrations.log