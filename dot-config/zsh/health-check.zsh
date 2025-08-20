## #!/usr/bin/env zsh
# Zsh Configuration Health Check

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
    # Add this check to detect errant file creation:
    if [[ -f "${ZDOTDIR:-$HOME}/2" ]] || [[ -f "${ZDOTDIR:-$HOME}/3" ]]; then
        echo "Warning: Numbered files detected - check for redirection typos" >&2
    fi
}

echo "🔍 Zsh Configuration Health Check"
echo "================================"

# Check syntax of main files
for file in ~/.config/zsh/{.zshenv,.zshrc} ~/.config/zsh/.zshrc.d/*.zsh; do
    if [[ -f "$file" ]]; then
        if zsh -n "$file" 2>/dev/null; then
            echo "✅ $file - Syntax OK"
        else
            echo "❌ $file - Syntax Error"
        fi
    fi
done

# Check for exposed credentials
if grep -r "sk-" ~/.config/zsh/ --exclude-dir=.env 2>/dev/null; then
    echo "⚠️  Possible exposed API keys found!"
else
    echo "✅ No exposed API keys detected"
fi

# Check PATH sanity
if echo $PATH | grep -q "/usr/bin"; then
    echo "✅ System PATH includes /usr/bin"
else
    echo "❌ System PATH missing /usr/bin"
fi

# Check zgenom setup
if [[ -n "$ZGEN_DIR" && -d "$ZGEN_DIR" ]]; then
    echo "✅ zgenom directory exists: $ZGEN_DIR"
else
    echo "⚠️  zgenom directory not found"
fi

# Check startup time
startup_time=$(time zsh -i -c exit 2>&1 | grep real | awk '{print $2}')
echo "⏱️  Startup time: $startup_time"

echo "
💡 Recommendations:
- Run 'zsh health-check.zsh' monthly
- Keep startup time under 2 seconds
- Update plugins quarterly: 'zgenom update'
- Backup config before major changes
"
