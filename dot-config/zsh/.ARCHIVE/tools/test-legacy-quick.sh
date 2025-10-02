#!/usr/bin/env bash
set -euo pipefail

echo "🔥 QUICK LEGACY MODULE TESTS"
echo "============================"
echo ""

cd /Users/s-a-c/dotfiles/dot-config/zsh

CONSOLIDATED_DIR=".zshrc.d.legacy/consolidated-modules"

echo "Testing each consolidated module individually..."
echo ""

# Test each module
for module in "$CONSOLIDATED_DIR"/*.zsh; do
    if [[ -f "$module" ]]; then
        module_name=$(basename "$module")
        echo "📄 Testing: $module_name"
        
        # Quick syntax check and loading test
        if SHELL=/opt/homebrew/bin/zsh ZDOTDIR="$PWD" /opt/homebrew/bin/zsh -n "$module"; then
            echo "  ✅ Syntax check passed"
            
            # Try loading the module
            if SHELL=/opt/homebrew/bin/zsh ZDOTDIR="$PWD" /opt/homebrew/bin/zsh -df -c "source '$module' >/dev/null 2>&1"; then
                echo "  ✅ Module loads successfully"
            else
                echo "  ❌ Module loading failed"
                echo "  🔍 Testing with debug output:"
                SHELL=/opt/homebrew/bin/zsh ZDOTDIR="$PWD" /opt/homebrew/bin/zsh -df -c "source '$module'" 2>&1 | head -10 | sed 's/^/    /'
            fi
        else
            echo "  ❌ Syntax check failed"
        fi
        echo ""
    fi
done

echo "Quick test completed!"