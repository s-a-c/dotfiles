#!/usr/bin/env zsh
# Fix Autopair Parameters - Complete Configuration

echo "🔧 Fixing Autopair Parameters"
echo "============================="

# Clear existing incomplete parameters
unset AUTOPAIR_PAIRS AUTOPAIR_LBOUNDS AUTOPAIR_RBOUNDS

# Set up AUTOPAIR_PAIRS with all standard pairs
typeset -gA AUTOPAIR_PAIRS
AUTOPAIR_PAIRS=(
    $'(' $')'
    $'[' $']'
    $'{' $'}'
    $'"' $'"'
    $"'" $"'"
    $'`' $'`'
    $' ' $' '
)

# Set up AUTOPAIR_LBOUNDS - left boundary patterns
typeset -gA AUTOPAIR_LBOUNDS
AUTOPAIR_LBOUNDS=(
    all $'[.:/\\!]'
    quotes $'[]})a-zA-Z0-9]'
    spaces $'[^{([]'
    braces $''
    $'`' $'`'
    $'"' $'"'
    $"'" $"'"
    $'(' $''
    $'[' $''
    $'{' $''
    $' ' $'[^{([]'
)

# Set up AUTOPAIR_RBOUNDS - right boundary patterns  
typeset -gA AUTOPAIR_RBOUNDS
AUTOPAIR_RBOUNDS=(
    all $'[[{(<,.:?/%$!a-zA-Z0-9]'
    quotes $'[a-zA-Z0-9]'
    spaces $'[^]})]'
    braces $''
    $'`' $'`'
    $'"' $'"'
    $"'" $"'"
    $')' $'[[{(<,.:?/%$!a-zA-Z0-9]'
    $']' $'[[{(<,.:?/%$!a-zA-Z0-9]'
    $'}' $'[[{(<,.:?/%$!a-zA-Z0-9]'
    $' ' $'[^]})]'
)

# Export control variables
export AUTOPAIR_INHIBIT_INIT=$''
export AUTOPAIR_BETWEEN_WHITESPACE=$''

echo "✅ AUTOPAIR_PAIRS: ${#AUTOPAIR_PAIRS[@]} pairs defined"
echo "✅ AUTOPAIR_LBOUNDS: ${#AUTOPAIR_LBOUNDS[@]} patterns defined"
echo "✅ AUTOPAIR_RBOUNDS: ${#AUTOPAIR_RBOUNDS[@]} patterns defined"

echo
echo "🔍 Parameter verification:"
echo "AUTOPAIR_PAIRS keys: ${(k)AUTOPAIR_PAIRS}"
echo "AUTOPAIR_LBOUNDS keys: ${(k)AUTOPAIR_LBOUNDS}" 
echo "AUTOPAIR_RBOUNDS keys: ${(k)AUTOPAIR_RBOUNDS}"

# Reinitialize autopair with the corrected parameters
if [[ -n "${functions[autopair-init]:-}" ]]; then
    echo
    echo "🚀 Reinitializing autopair with corrected parameters..."
    autopair-init
    echo "✅ Autopair reinitialized"
else
    echo "❌ autopair-init function not available"
fi

echo
echo "🧪 Test autopair now by typing quotes, brackets, or braces"