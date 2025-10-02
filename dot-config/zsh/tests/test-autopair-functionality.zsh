#!/usr/bin/env zsh
# Test Autopair Functionality

echo "🧪 Testing Autopair Functionality"
echo "================================="

# Test 1: Check widget bindings
echo "🔍 Current key bindings for autopair keys:"
bindkey | grep -E "autopair|\"|\(|\[|\{|\`" | head -10

echo
echo "🔍 Widget status:"
for widget in autopair-insert autopair-close autopair-delete autopair-delete-word; do
    if [[ -n "${widgets[$widget]:-}" ]]; then
        echo "  $widget: ✅ registered as ${widgets[$widget]}"
    else
        echo "  $widget: ❌ not registered"
    fi
done

echo
echo "🔍 Function availability:"
for func in _ap-get-pair _ap-can-pair _ap-can-skip; do
    if [[ -n "${functions[$func]:-}" ]]; then
        echo "  $func: ✅ available"
    else
        echo "  $func: ❌ missing"
    fi
done

echo
echo "🔍 AUTOPAIR parameters:"
echo "  AUTOPAIR_PAIRS keys: ${(k)AUTOPAIR_PAIRS}"
echo "  AUTOPAIR_LBOUNDS keys: ${(k)AUTOPAIR_LBOUNDS}"

echo
echo "🧪 Manual test instructions:"
echo "Try typing the following in your shell:"
echo "  1. Type a quote: \"    (should auto-close)"
echo "  2. Type brackets: [   (should auto-close)"
echo "  3. Type braces: {     (should auto-close)"
echo "  4. Use backspace between pairs (should delete both)"

echo
echo "🔧 If autopair still has issues, the error might be in the plugin itself."
echo "    The '_ap-get-pair:1: 1: parameter not set' suggests a bug in the autopair plugin."