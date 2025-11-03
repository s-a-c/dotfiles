#!/usr/bin/env bash
set -euo pipefail

echo "Testing parameter error fixes..."

cd /Users/s-a-c/.config/zsh

echo "=== Running ZSH startup test ==="
timeout 15s bash -c 'ZDOTDIR="$PWD" zsh -i -c "
    echo \"PARAMETER CHECKS:\"
    echo \"widgets defined: $(( ${+widgets} ))\"
    echo \"parameters defined: $(( ${+parameters} ))\" 
    echo \"functions defined: $(( ${+functions} ))\"
    echo \"RPS2 defined: $(( ${+RPS2} ))\"
    echo \"RUBY_AUTO_VERSION defined: $(( ${+RUBY_AUTO_VERSION} ))\"
    echo \"Startup successful\"
    exit
"' 2>&1 | tee startup_test.log

echo ""
echo "=== Checking for parameter errors ==="
if grep -q "parameter not set" startup_test.log; then
    echo "❌ Still have parameter errors:"
    grep "parameter not set" startup_test.log | sed 's/^/    /'
else
    echo "✅ No parameter not set errors found"
fi

echo ""
echo "=== Checking for widget errors ==="
if grep -q "widgets\[.*\]: parameter not set" startup_test.log; then
    echo "❌ Still have widget errors:"
    grep "widgets\[.*\]: parameter not set" startup_test.log | sed 's/^/    /'
else
    echo "✅ No widget parameter errors found"
fi

echo ""
echo "=== Summary ==="
error_count=$(grep -c "parameter not set" startup_test.log || echo 0)
echo "Total 'parameter not set' errors: $error_count"

if [[ $error_count -eq 0 ]]; then
    echo "🎉 All parameter errors fixed!"
else
    echo "⚠️  Still have $error_count parameter errors to fix"
fi

# Clean up
rm -f startup_test.log
