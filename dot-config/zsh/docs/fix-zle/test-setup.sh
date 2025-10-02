#!/bin/bash
# Test Setup Script - Run this first to prepare bisection testing
# Execute: bash docs/fix-zle/test-setup.sh

echo "=== ZLE FIX - TEST SETUP ==="
echo "Working directory: $(pwd)"
echo "Current shell: $0"
echo "SHELL variable: $SHELL"
echo ""

echo "1. Creating bisection infrastructure..."
if cp .zshenv.full.backup .zshenv.full.bisect 2>/dev/null; then
    echo "✅ Created .zshenv.full.bisect from backup"
else
    echo "❌ Failed to create .zshenv.full.bisect"
    exit 1
fi

echo ""
echo "2. Checking current .zshenv status..."
if [ -L .zshenv ]; then
    echo "✅ .zshenv is a symlink pointing to: $(readlink .zshenv)"
else
    echo "❌ .zshenv is not a symlink"
    ls -la .zshenv
fi

echo ""
echo "3. Verifying test files exist..."
for file in .zshenv.minimal.complete .zshrc.minimal .zshenv.full.backup .zshenv.full.bisect; do
    if [ -f "$file" ]; then
        echo "✅ $file exists ($(wc -l < "$file") lines)"
    else
        echo "❌ $file missing"
    fi
done

echo ""
echo "4. Creating test result directory..."
mkdir -p docs/fix-zle/results
echo "✅ Results directory ready"

echo ""
echo "=== SETUP COMPLETE ==="
echo "Next: Run bash docs/fix-zle/test-baseline.sh"
