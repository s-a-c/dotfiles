#!/usr/bin/env bash

echo "=== Active ZSH Script Verification ==="
echo "Repository: $(pwd)"
echo "Current shell: $0"
echo ""

# Check which post-plugin directory is active
echo "🔍 Checking active post-plugin directory..."
ZDOTDIR="$PWD" timeout 10s zsh -i -c '
    if [[ $ZSH_ENABLE_POSTPLUGIN_REDESIGN == 1 ]]; then
        echo "✅ Post-plugin REDESIGN is ENABLED"
        echo "Active directory: .zshrc.d.REDESIGN/"
        if [[ -d "$ZDOTDIR/.zshrc.d.REDESIGN" ]]; then
            echo "📁 Contents of .zshrc.d.REDESIGN/:"
            ls -la "$ZDOTDIR/.zshrc.d.REDESIGN/"
        fi
    else
        echo "⚠️  Post-plugin REDESIGN is DISABLED" 
        echo "Active directory: .zshrc.d/"
        if [[ -d "$ZDOTDIR/.zshrc.d" ]]; then
            echo "📁 Contents of .zshrc.d/:"
            ls -la "$ZDOTDIR/.zshrc.d/"
        fi
    fi
    exit
' 2>&1

echo ""
echo "🔍 Checking for Starship configuration..."
ZDOTDIR="$PWD" timeout 10s zsh -i -c '
    echo "=== Starship Detection ==="
    echo "Starship command: $(command -v starship || echo "NOT FOUND")"
    echo "STARSHIP_SHELL: ${STARSHIP_SHELL:-"NOT SET"}"
    echo "STARSHIP_CONFIG: ${STARSHIP_CONFIG:-"NOT SET"}"
    
    # Check which files contain starship init
    if [[ $ZSH_ENABLE_POSTPLUGIN_REDESIGN == 1 ]]; then
        echo "Checking REDESIGN directory for starship:"
        if [[ -d "$ZDOTDIR/.zshrc.d.REDESIGN" ]]; then
            grep -l "starship" "$ZDOTDIR/.zshrc.d.REDESIGN/"* 2>/dev/null || echo "No starship references found"
        fi
    else
        echo "Checking legacy directory for starship:"
        if [[ -d "$ZDOTDIR/.zshrc.d" ]]; then
            grep -l "starship" "$ZDOTDIR/.zshrc.d/"* 2>/dev/null || echo "No starship references found"
        fi
    fi
    exit
' 2>&1

echo ""
echo "🔍 Checking for missing original functions..."
echo "Comparing zsh-quickstart-kit/.zshrc with current .zshrc..."

# Check for key functions that should exist
echo ""
echo "📝 Function presence check:"

functions_to_check=(
    "load-shell-fragments"
    "_zqs-get-setting" 
    "_zqs-set-setting"
    "_zqs-trigger-init-rebuild"
    "zsh-quickstart-select-powerlevel10k"
    "zsh-quickstart-select-bullet-train"
    "_update-zsh-quickstart"
    "_check-for-zsh-quickstart-update"
    "zqs"
    "zqs-help"
)

for func in "${functions_to_check[@]}"; do
    if grep -q "^function $func\|^$func()" .zshrc; then
        echo "✅ $func - Present in .zshrc"
    elif grep -q "^function $func\|^$func()" zsh-quickstart-kit/zsh/.zshrc; then
        echo "❌ $func - Missing from .zshrc (exists in quickstart)"
    else
        echo "❓ $func - Not found in either file"
    fi
done

echo ""
echo "=== Verification Complete ==="
