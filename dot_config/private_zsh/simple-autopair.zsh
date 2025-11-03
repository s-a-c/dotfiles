#!/usr/bin/env zsh
# Simple Working Autopair Implementation
# This bypasses the buggy hlissner/zsh-autopair plugin

echo "🔧 Installing Simple Autopair Implementation"
echo "==========================================="

# Remove conflicting widgets
for widget in autopair-insert autopair-close autopair-delete autopair-delete-word; do
    [[ -n "${widgets[$widget]:-}" ]] && zle -D "$widget" 2>/dev/null
done

# Define autopair configuration
typeset -gA SIMPLE_AUTOPAIR_PAIRS
SIMPLE_AUTOPAIR_PAIRS=(
    $'(' $')'
    $'[' $']'
    $'{' $'}'
    $'"' $'"'
    $"'" $"'"
    $'`' $'`'
)

# Get the matching pair character
simple-autopair-get-pair() {
    local char="$1"
    echo "${SIMPLE_AUTOPAIR_PAIRS[$char]:-}"
}

# Insert widget - handles opening characters
simple-autopair-insert() {
    local char="$KEYS"
    local pair="$(simple-autopair-get-pair "$char")"
    
    if [[ -n "$pair" ]]; then
        # Check if we should skip (cursor is right after the same character)
        if [[ "$char" == "$pair" && "${RBUFFER[1]}" == "$char" ]]; then
            # Skip over the existing character
            zle forward-char
        else
            # Insert the pair
            LBUFFER+="$char"
            RBUFFER="$pair$RBUFFER"
        fi
    else
        # Not a special character, just insert normally
        zle self-insert
    fi
}

# Close widget - handles closing characters  
simple-autopair-close() {
    local char="$KEYS"
    
    # Check if the next character is what we're typing
    if [[ "${RBUFFER[1]}" == "$char" ]]; then
        # Skip over it
        zle forward-char
    else
        # Insert normally
        zle self-insert
    fi
}

# Delete widget - handles backspace between pairs
simple-autopair-delete() {
    local left_char="${LBUFFER[-1]:-}"
    local right_char="${RBUFFER[1]:-}"
    local expected_pair="$(simple-autopair-get-pair "$left_char")"
    
    if [[ -n "$expected_pair" && "$right_char" == "$expected_pair" ]]; then
        # Delete both characters
        RBUFFER="${RBUFFER[2,-1]}"
    fi
    
    # Always do the normal backspace
    zle backward-delete-char
}

# Register the widgets
zle -N simple-autopair-insert
zle -N simple-autopair-close  
zle -N simple-autopair-delete

# Bind opening characters
bindkey '(' simple-autopair-insert
bindkey '[' simple-autopair-insert
bindkey '{' simple-autopair-insert
bindkey '"' simple-autopair-insert
bindkey "'" simple-autopair-insert
bindkey '`' simple-autopair-insert

# Bind closing characters
bindkey ')' simple-autopair-close
bindkey ']' simple-autopair-close
bindkey '}' simple-autopair-close

# Bind backspace
bindkey '^?' simple-autopair-delete
bindkey '^H' simple-autopair-delete

echo "✅ Simple autopair implementation installed"
echo
echo "📋 Configured pairs:"
for key in "${(@k)SIMPLE_AUTOPAIR_PAIRS}"; do
    echo "  $key → ${SIMPLE_AUTOPAIR_PAIRS[$key]}"
done

echo
echo "🧪 Test the autopair functionality:"
echo "  • Type opening characters: ( [ { \" ' \`"
echo "  • Use backspace between paired characters" 
echo "  • Type closing characters when next to them"

echo
echo "🔍 Widget status:"
for widget in simple-autopair-insert simple-autopair-close simple-autopair-delete; do
    if [[ -n "${widgets[$widget]:-}" ]]; then
        echo "  $widget: ✅ registered"
    else
        echo "  $widget: ❌ missing"
    fi
done