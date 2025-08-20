# Minimal completion initialization
if command -v compinit >/dev/null 2>&1; then
    autoload -Uz compinit
    compinit -d ~/.config/zsh/.zcompdump 2>/dev/null || true
fi
