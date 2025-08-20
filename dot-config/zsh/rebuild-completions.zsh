#!/usr/bin/env zsh
# Safe completion rebuild function

rebuild_completions() {
    echo "🔄 Rebuilding completions safely..."
    
    # Remove old cache
    rm -f ~/.config/zsh/.zcompdump* ~/.zcompdump* 2>/dev/null
    
    # Rebuild with proper error handling
    if command -v compinit >/dev/null 2>&1; then
        autoload -Uz compinit
        compinit -d ~/.config/zsh/.zcompdump
        echo "✅ Completions rebuilt successfully"
    else
        echo "⚠️  compinit not available"
    fi
}

# Auto-run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    rebuild_completions
fi
