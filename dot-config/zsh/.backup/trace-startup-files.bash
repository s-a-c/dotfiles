#!/usr/bin/env bash
set -euo pipefail

echo "Tracing actual ZSH startup files..."
cd /Users/s-a-c/dotfiles/dot-config/zsh

echo "=== ZSH Startup File Trace ==="
timeout 10s bash -c 'ZDOTDIR="$PWD" zsh -x -i -c "exit" 2>&1' | \
    grep -E "(\+[^+].*source|\+[^+].*\\.)" | \
    grep -v "zsh/parameter" | \
    sed 's/^+[^+]*//' | \
    head -30 > startup_trace.log 2>/dev/null || echo "Trace completed with timeout"

echo "Files actually sourced during startup:"
if [[ -f startup_trace.log ]]; then
    cat startup_trace.log | head -20
    echo ""
    echo "Total files traced: $(wc -l < startup_trace.log)"
else
    echo "No trace file generated"
fi

echo ""
echo "=== Checking parameter errors location ==="
timeout 15s bash -c 'ZDOTDIR="$PWD" zsh -i -c "exit" 2>&1' | \
    grep "parameter not set" | \
    head -5 > param_errors.log 2>/dev/null || echo "Parameter error check completed"

if [[ -f param_errors.log && -s param_errors.log ]]; then
    echo "Parameter errors found:"
    cat param_errors.log
else
    echo "No parameter errors found in current test"
fi

echo ""
echo "=== Checking if .zshenv changes are loaded ==="
timeout 10s bash -c 'ZDOTDIR="$PWD" zsh -i -c "
    echo \"RPS2 status: \${+RPS2}\"
    echo \"RUBY_AUTO_VERSION status: \${+RUBY_AUTO_VERSION}\"
    echo \"widgets array status: \${+widgets}\"
    exit
" 2>&1' | grep -E "(RPS2|RUBY_AUTO_VERSION|widgets)" > var_status.log 2>/dev/null || echo "Variable check completed"

if [[ -f var_status.log ]]; then
    echo "Variable initialization status:"
    cat var_status.log
fi

# Cleanup
rm -f startup_trace.log param_errors.log var_status.log

echo ""
echo "=== Key module loading pattern ==="
timeout 10s bash -c 'ZDOTDIR="$PWD" zsh -i -c "exit" 2>&1' | \
    grep -E "(\[pre-plugin\]|\[PATH-SAFETY\]|widgets|parameter not set)" | \
    head -10