#!/opt/homebrew/bin/zsh
# ==============================================================================
# ZSH Configuration: Quick Consistency Test
# ==============================================================================
# Purpose: Quick test to validate 100% consistency achievement
# ==============================================================================

echo "========================================================"
echo "Quick Consistency Validation"
echo "========================================================"

ZSHRC_DIR="${ZDOTDIR:-$HOME/.config/zsh}"
ISSUES=0

# Test 1: Check for double-hash comments (should be fixed)
echo "Test 1: Checking for double-hash comments..."
DOUBLE_HASH=$(find "$ZSHRC_DIR/.zshrc.d/00-core" -name "*.zsh" -exec grep -l "^##[^#]" {} \; 2>/dev/null | wc -l)
if [[ $DOUBLE_HASH -eq 0 ]]; then
        zsh_debug_echo "✅ No double-hash comments found"
else
        zsh_debug_echo "❌ Found $DOUBLE_HASH files with double-hash comments"
    ISSUES=$((ISSUES + 1))
fi

# Test 2: Check shebang consistency
echo "Test 2: Checking shebang consistency..."
WRONG_SHEBANG=$(find "$ZSHRC_DIR/.zshrc.d/00-core" -name "*.zsh" -exec head -1 {} \; | grep -v "#!/opt/homebrew/bin/zsh" | wc -l)
if [[ $WRONG_SHEBANG -eq 0 ]]; then
        zsh_debug_echo "✅ All shebangs are consistent"
else
        zsh_debug_echo "❌ Found $WRONG_SHEBANG inconsistent shebangs"
    ISSUES=$((ISSUES + 1))
fi

# Test 3: Check for function keyword usage
echo "Test 3: Checking function declarations..."
FUNCTION_KEYWORD=$(find "$ZSHRC_DIR/.zshrc.d/00-core" -name "*.zsh" -exec grep -l "^function [a-zA-Z_]" {} \; 2>/dev/null | wc -l)
if [[ $FUNCTION_KEYWORD -eq 0 ]]; then
        zsh_debug_echo "✅ No 'function' keyword usage found"
else
        zsh_debug_echo "❌ Found $FUNCTION_KEYWORD files using 'function' keyword"
    ISSUES=$((ISSUES + 1))
fi

# Test 4: Check for tab characters
echo "Test 4: Checking for tab characters..."
TAB_FILES=$(find "$ZSHRC_DIR/.zshrc.d/00-core" -name "*.zsh" -exec grep -l $'\t' {} \; 2>/dev/null | wc -l)
if [[ $TAB_FILES -eq 0 ]]; then
        zsh_debug_echo "✅ No tab characters found"
else
        zsh_debug_echo "❌ Found $TAB_FILES files with tab characters"
    ISSUES=$((ISSUES + 1))
fi

# Calculate consistency score
TOTAL_TESTS=4
PASSED_TESTS=$((TOTAL_TESTS - ISSUES))
CONSISTENCY_SCORE=$((PASSED_TESTS * 100 / TOTAL_TESTS))

echo ""
echo "========================================================"
echo "Consistency Results"
echo "========================================================"
echo "Tests passed: $PASSED_TESTS/$TOTAL_TESTS"
echo "Consistency Score: ${CONSISTENCY_SCORE}%"

if [[ $CONSISTENCY_SCORE -eq 100 ]]; then
        zsh_debug_echo "🏆 PERFECT: 100% consistency achieved!"
elif [[ $CONSISTENCY_SCORE -ge 95 ]]; then
        zsh_debug_echo "🥇 EXCELLENT: ${CONSISTENCY_SCORE}% consistency achieved!"
elif [[ $CONSISTENCY_SCORE -ge 90 ]]; then
        zsh_debug_echo "🥈 VERY GOOD: ${CONSISTENCY_SCORE}% consistency achieved!"
else
        zsh_debug_echo "⚠️ NEEDS IMPROVEMENT: ${CONSISTENCY_SCORE}% consistency"
fi

exit $ISSUES
