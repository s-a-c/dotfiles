#!/usr/bin/env zsh
# Test script for 07-simple-autopair.zsh module

echo "🧪 Testing Autopair Module Integration"
echo "====================================="

# Test if the module loaded properly
if [[ -n "$ZSH_AUTOPAIR_MODULE_LOADED" ]]; then
    echo "✅ Module loaded: ZSH_AUTOPAIR_MODULE_LOADED = $ZSH_AUTOPAIR_MODULE_LOADED"
else
    echo "❌ Module not loaded: ZSH_AUTOPAIR_MODULE_LOADED not set"
fi

# Test if SIMPLE_AUTOPAIR_PAIRS is defined
if [[ -n "${SIMPLE_AUTOPAIR_PAIRS+x}" ]]; then
    echo "✅ Configuration loaded: ${#SIMPLE_AUTOPAIR_PAIRS[@]} pairs defined"
    echo "   Pairs: ${(@k)SIMPLE_AUTOPAIR_PAIRS} → ${(@v)SIMPLE_AUTOPAIR_PAIRS}"
else
    echo "❌ Configuration missing: SIMPLE_AUTOPAIR_PAIRS not defined"
fi

# Test if widgets are registered
echo
echo "🔍 Widget Registration Status:"
autopair_widgets=(simple-autopair-insert simple-autopair-close simple-autopair-delete)
for widget in "${autopair_widgets[@]}"; do
    if [[ -n "${widgets[$widget]:-}" ]]; then
        echo "  $widget: ✅ registered as ${widgets[$widget]}"
    else
        echo "  $widget: ❌ not registered"
    fi
done

# Test if functions are available
echo
echo "🔍 Function Availability:"
if [[ -n "${functions[simple-autopair-get-pair]:-}" ]]; then
    echo "  simple-autopair-get-pair: ✅ available"
    
    # Test the function with some pairs
    echo "    Testing function:"
    echo "      '(' → '$(simple-autopair-get-pair '(')'"
    echo "      '[' → '$(simple-autopair-get-pair '[')'"
    echo "      '<' → '$(simple-autopair-get-pair '<')'"
    echo "      '\"' → '$(simple-autopair-get-pair '"')'"
else
    echo "  simple-autopair-get-pair: ❌ missing"
fi

# Test key bindings
echo
echo "🔍 Key Binding Status:"
test_keys=('(' '[' '{' '<' '"' "'" '`' ')' ']' '}' '>' '^?' '^H')
for key in "${test_keys[@]}"; do
    binding=$(bindkey "$key" 2>/dev/null | cut -d' ' -f2-)
    if [[ "$binding" == simple-autopair-* ]]; then
        echo "  $key: ✅ bound to $binding"
    elif [[ "$key" == '^?' || "$key" == '^H' ]] && [[ "$binding" == simple-autopair-delete ]]; then
        echo "  $key: ✅ bound to $binding"
    else
        echo "  $key: ⚠️  bound to $binding (not autopair)"
    fi
done

# Check for conflicts with old autopair plugin
echo
echo "🔍 Conflict Detection:"
old_widgets=(autopair-insert autopair-close autopair-delete autopair-delete-word)
conflicts_found=0
for widget in "${old_widgets[@]}"; do
    if [[ -n "${widgets[$widget]:-}" ]]; then
        echo "  $widget: ⚠️  still registered (potential conflict)"
        conflicts_found=1
    fi
done

if [[ $conflicts_found -eq 0 ]]; then
    echo "  ✅ No conflicts detected with old autopair widgets"
fi

# Test angle brackets specifically
echo
echo "🔍 Angle Bracket Support:"
if [[ "${SIMPLE_AUTOPAIR_PAIRS['<']}" == ">" ]]; then
    echo "  ✅ Angle brackets configured: < → >"
    
    # Check bindings
    left_binding=$(bindkey '<' 2>/dev/null | cut -d' ' -f2-)
    right_binding=$(bindkey '>' 2>/dev/null | cut -d' ' -f2-)
    
    if [[ "$left_binding" == "simple-autopair-insert" ]]; then
        echo "  ✅ '<' correctly bound to simple-autopair-insert"
    else
        echo "  ❌ '<' bound to $left_binding instead of simple-autopair-insert"
    fi
    
    if [[ "$right_binding" == "simple-autopair-close" ]]; then
        echo "  ✅ '>' correctly bound to simple-autopair-close"
    else
        echo "  ❌ '>' bound to $right_binding instead of simple-autopair-close"
    fi
else
    echo "  ❌ Angle brackets not configured properly"
fi

echo
echo "🧪 Manual Testing Instructions:"
echo "  1. Type '<' - should auto-close with '>'"
echo "  2. Type inside angle brackets: <test> "
echo "  3. Use backspace between < and > - should delete both"
echo "  4. Type '>' when positioned before '>' - should skip over"
echo "  5. Test all other pairs: () [] {} \"\" '' \`\`"

echo
if [[ -n "$ZSH_AUTOPAIR_MODULE_LOADED" && -n "${SIMPLE_AUTOPAIR_PAIRS+x}" ]]; then
    echo "🎉 Autopair module integration test PASSED"
    exit 0
else
    echo "💥 Autopair module integration test FAILED"
    exit 1
fi