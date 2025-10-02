#!/usr/bin/env zsh
# Emergency Autopair Fix Script - CORRECTED QUOTING
# Run this in your shell: source fix-autopair-emergency-corrected.zsh

echo "🚨 Emergency Autopair Fix Script (CORRECTED)"
echo "=============================================="

# Check if we're in ZSH
if [[ -z "$ZSH_VERSION" ]]; then
    echo "❌ This script must be run in ZSH"
    return 1 2>/dev/null || exit 1
fi

echo "✅ Running in ZSH $ZSH_VERSION"

# Check autopair parameters
echo
echo "🔍 Checking autopair parameters..."
if [[ -n "${AUTOPAIR_PAIRS+x}" ]]; then
    echo "✅ AUTOPAIR_PAIRS: defined (${#AUTOPAIR_PAIRS[@]} pairs)"
else
    echo "❌ AUTOPAIR_PAIRS: missing"
    echo "🔧 Initializing autopair parameters..."
    
    typeset -gA AUTOPAIR_PAIRS
    AUTOPAIR_PAIRS=($'`' $'`' $'\'' $'\'' $'"' $'"' $'{' $'}' $'[' $']' $'(' $')' $' ' $' ')
    
    typeset -gA AUTOPAIR_LBOUNDS
    AUTOPAIR_LBOUNDS=(all $'[.:/\\!]')
    AUTOPAIR_LBOUNDS+=(quotes $'[]})a-zA-Z0-9]')
    AUTOPAIR_LBOUNDS+=(spaces $'[^{([]')
    AUTOPAIR_LBOUNDS+=(braces $'')
    AUTOPAIR_LBOUNDS+=($'`' $'`')
    AUTOPAIR_LBOUNDS+=($'"' $'"')
    AUTOPAIR_LBOUNDS+=($'\'' $'\'')
    
    typeset -gA AUTOPAIR_RBOUNDS
    AUTOPAIR_RBOUNDS=(all $'[[{(<,.:?/%$!a-zA-Z0-9]')
    AUTOPAIR_RBOUNDS+=(quotes $'[a-zA-Z0-9]')
    AUTOPAIR_RBOUNDS+=(spaces $'[^]})]')
    AUTOPAIR_RBOUNDS+=(braces $'')
    
    export AUTOPAIR_INHIBIT_INIT=$''
    export AUTOPAIR_BETWEEN_WHITESPACE=$''
    
    echo "✅ Autopair parameters initialized"
fi

# Check autopair functions
echo
echo "🔍 Checking autopair functions..."
autopair_functions=(autopair-init autopair-insert autopair-close autopair-delete autopair-delete-word)
missing_functions=()

for func in "${autopair_functions[@]}"; do
    if [[ -z "${functions[$func]:-}" ]]; then
        missing_functions+=($func)
    fi
done

if [[ ${#missing_functions[@]} -gt 0 ]]; then
    echo "❌ Missing autopair functions: ${missing_functions[*]}"
    echo "🔧 Attempting to load autopair plugin manually..."
    
    # Try to source autopair directly
    autopair_plugin_file="$ZDOTDIR/.zqs-zgenom/hlissner/zsh-autopair/___/autopair.zsh"
    if [[ -f "$autopair_plugin_file" ]]; then
        echo "📁 Found autopair plugin file: $autopair_plugin_file"
        source "$autopair_plugin_file"
        echo "✅ Autopair plugin sourced manually"
    else
        echo "❌ Autopair plugin file not found: $autopair_plugin_file"
        echo "🔍 Searching for autopair files..."
        find "$ZDOTDIR/.zqs-zgenom" -name "*autopair*" -type f 2>/dev/null | head -5
    fi
else
    echo "✅ All autopair functions available: ${autopair_functions[*]}"
fi

# Check autopair widgets
echo
echo "🔍 Checking autopair widgets..."
autopair_widgets=(autopair-insert autopair-close autopair-delete autopair-delete-word)
missing_widgets=()

for widget in "${autopair_widgets[@]}"; do
    if [[ -z "${widgets[$widget]:-}" ]]; then
        missing_widgets+=($widget)
    fi
done

if [[ ${#missing_widgets[@]} -gt 0 ]]; then
    echo "❌ Missing autopair widgets: ${missing_widgets[*]}"
    echo "🔧 Attempting to initialize autopair widgets..."
    
    # Try to run autopair-init if function exists
    if [[ -n "${functions[autopair-init]:-}" ]]; then
        echo "🚀 Running autopair-init..."
        autopair-init
        echo "✅ autopair-init completed"
    else
        echo "❌ autopair-init function not available"
        
        # Manual widget creation as last resort
        echo "🔧 Creating autopair widgets manually..."
        
        # Define basic autopair functions if missing
        if [[ -z "${functions[autopair-insert]:-}" ]]; then
            autopair-insert() {
                # Minimal autopair insert function
                local char="$KEYS"
                local pair="${AUTOPAIR_PAIRS[$char]:-}"
                if [[ -n "$pair" ]]; then
                    LBUFFER+="$char"
                    RBUFFER="$pair$RBUFFER"
                else
                    zle self-insert
                fi
            }
        fi
        
        if [[ -z "${functions[autopair-delete]:-}" ]]; then
            autopair-delete() {
                # Minimal autopair delete function
                local lchar="${LBUFFER[-1]:-}"
                local rchar="${AUTOPAIR_PAIRS[$lchar]:-}"
                if [[ -n "$rchar" && "${RBUFFER[1]:-}" == "$rchar" ]]; then
                    RBUFFER="${RBUFFER[2,-1]}"
                fi
                zle backward-delete-char
            }
        fi
        
        # Register widgets
        for widget in autopair-insert autopair-close autopair-delete autopair-delete-word; do
            if [[ -n "${functions[$widget]:-}" ]]; then
                zle -N "$widget" 2>/dev/null || true
            fi
        done
        
        echo "✅ Manual widget registration completed"
    fi
else
    echo "✅ All autopair widgets available: ${autopair_widgets[*]}"
fi

# Final status check
echo
echo "📊 Final Status Check:"
echo "====================="

echo "Autopair Parameters:"
echo "  AUTOPAIR_PAIRS: $([[ -n "${AUTOPAIR_PAIRS+x}" ]] && echo "✅ defined (${#AUTOPAIR_PAIRS[@]} pairs)" || echo "❌ missing")"
echo "  AUTOPAIR_LBOUNDS: $([[ -n "${AUTOPAIR_LBOUNDS+x}" ]] && echo "✅ defined" || echo "❌ missing")"
echo "  AUTOPAIR_RBOUNDS: $([[ -n "${AUTOPAIR_RBOUNDS+x}" ]] && echo "✅ defined" || echo "❌ missing")"

echo
echo "Autopair Functions:"
for func in "${autopair_functions[@]}"; do
    if [[ -n "${functions[$func]:-}" ]]; then
        echo "  $func: ✅ available"
    else
        echo "  $func: ❌ missing"
    fi
done

echo
echo "Autopair Widgets:"
for widget in "${autopair_widgets[@]}"; do
    if [[ -n "${widgets[$widget]:-}" ]]; then
        echo "  $widget: ✅ registered"
    else
        echo "  $widget: ❌ missing"
    fi
done

echo
echo "🧪 Test autopair functionality by typing quotes or brackets"
echo "💡 If issues persist, the problem may be with syntax highlighting plugin conflicts"

# Create a function to manually bind keys if needed
fix-autopair-keybindings() {
    echo "🔧 Manually binding autopair keys..."
    
    # Bind common pairs to autopair-insert if available
    if [[ -n "${widgets[autopair-insert]:-}" ]]; then
        # Use proper escaping for single quotes
        local -a pairs
        pairs=($'(' $')' $'[' $']' $'{' $'}' $'"' $'\'' $'`')
        for pair in "${pairs[@]}"; do
            bindkey "$pair" autopair-insert 2>/dev/null || true
        done
        echo "✅ Autopair key bindings set"
    fi
    
    # Bind backspace to autopair-delete if available
    if [[ -n "${widgets[autopair-delete]:-}" ]]; then
        bindkey "^?" autopair-delete 2>/dev/null || true
        bindkey "^H" autopair-delete 2>/dev/null || true
        echo "✅ Autopair backspace binding set"
    fi
}

echo
echo "🛠️ Available commands:"
echo "  fix-autopair-keybindings  - Manually set autopair key bindings"
echo "  source fix-autopair-emergency-corrected.zsh  - Re-run this script"

echo
echo "✅ Emergency autopair fix completed - quoting issues corrected!"