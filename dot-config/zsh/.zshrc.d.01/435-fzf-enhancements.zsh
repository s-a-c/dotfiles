#!/usr/bin/env zsh
# Filename: 435-fzf-enhancements.zsh
# Purpose:  Advanced FZF integration with previews, custom keybindings, and enhanced fuzzy finding (P4.3)
# Phase:    Post-plugin (.zshrc.d/)
# Requires: 270-productivity-fzf.zsh (FZF must be loaded first)
# Toggles:  ZF_DISABLE_FZF_ENHANCEMENTS

if [[ "${ZF_DISABLE_FZF_ENHANCEMENTS:-0}" == 1 ]]; then
    return 0
fi

# Ensure FZF is available
if ! command -v fzf >/dev/null 2>&1; then
    return 0
fi

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# ==============================================================================
# Enhanced FZF Configuration
# ==============================================================================

# Enhanced default options with better UI
export FZF_DEFAULT_OPTS="
--height=80%
--border=rounded
--layout=reverse
--info=inline
--prompt='🔍 '
--pointer='▶'
--marker='✓'
--color=fg:#e0e0e0,bg:#1e1e1e,hl:#569cd6
--color=fg+:#ffffff,bg+:#2d2d2d,hl+:#4ec9b0
--color=info:#d4d4d4,prompt:#569cd6,pointer:#4ec9b0
--color=marker:#4ec9b0,spinner:#569cd6,header:#608b4e
--bind='ctrl-/:toggle-preview'
--bind='ctrl-a:select-all'
--bind='ctrl-d:deselect-all'
--bind='ctrl-t:toggle-all'
--preview-window='right:50%:wrap'
"

# ==============================================================================
# Enhanced FZF Functions
# ==============================================================================

# fzf with file preview (using bat if available, cat otherwise)
fzf-file-preview() {
    local preview_cmd
    if command -v bat >/dev/null 2>&1; then
        preview_cmd="bat --color=always --style=numbers,changes --line-range=:500 {}"
    else
        preview_cmd="cat {}"
    fi
    
    fzf --preview="$preview_cmd" \
        --preview-window='right:60%:wrap' \
        --header='Files with preview (Ctrl-/: toggle preview)' \
        "$@"
}

# Git branch switcher with diff preview
fzf-git-branch() {
    local branch
    branch=$(git branch -a --color=always | \
        grep -v '/HEAD\s' | \
        sort | \
        fzf --ansi \
            --height=50% \
            --preview="git log --oneline --color=always --decorate {1} | head -50" \
            --preview-window='right:50%:wrap' \
            --header='Select branch (Ctrl-/: toggle preview)' | \
        sed 's/^[* ]*//; s#^remotes/origin/##')
    
    if [[ -n "$branch" ]]; then
        git checkout "$branch"
    fi
}

# Process killer with resource usage preview
fzf-kill-process() {
    local pid
    pid=$(ps -ef | sed 1d | fzf --multi \
        --header='Select process to kill (Tab: multi-select)' \
        --preview='echo "PID: {2}"; echo "User: {1}"; echo "Command: {8..}"; ps -p {2} -o pid,ppid,pgid,%cpu,%mem,etime,command' \
        --preview-window='down:40%:wrap' | \
        awk '{print $2}')
    
    if [[ -n "$pid" ]]; then
        echo "Killing process(es): $pid"
        kill -9 $pid
    fi
}

# Enhanced directory navigation with file listing preview
fzf-cd() {
    local dir
    dir=$(find . -type d -not -path '*/\.*' 2>/dev/null | \
        fzf --preview='ls -lah --color=always {} 2>/dev/null | head -50' \
            --preview-window='right:50%:wrap' \
            --header='Select directory (Ctrl-/: toggle preview)')
    
    if [[ -n "$dir" ]]; then
        cd "$dir" || return 1
    fi
}

# Command history with usage stats
fzf-history-enhanced() {
    local cmd
    cmd=$(fc -l 1 | \
        sort -k2 | \
        uniq -c | \
        sort -rn | \
        fzf --tac \
            --height=80% \
            --preview='echo "Usage count: {1}"; echo ""; echo "Command:"; echo "{2..}" | fold -w 80' \
            --preview-window='down:30%:wrap' \
            --header='Command history with usage stats' | \
        sed 's/^[^0-9]*[0-9]*[^0-9]*//')
    
    if [[ -n "$cmd" ]]; then
        print -z "$cmd"
    fi
}

# Git file selector with diff preview
fzf-git-files() {
    local file
    file=$(git ls-files 2>/dev/null | \
        fzf --preview='git diff --color=always {} 2>/dev/null || cat {}' \
            --preview-window='right:60%:wrap' \
            --header='Git files with diff preview')
    
    if [[ -n "$file" ]]; then
        ${EDITOR:-nvim} "$file"
    fi
}

# Environment variable browser
fzf-env() {
    local var
    var=$(env | sort | \
        fzf --preview='echo "Value: {}"' \
            --preview-window='down:30%:wrap' \
            --header='Environment variables' | \
        cut -d= -f1)
    
    if [[ -n "$var" ]]; then
        echo "$var=${(P)var}"
    fi
}

# ==============================================================================
# Key Bindings
# ==============================================================================

# Enhanced file finder (Ctrl-Alt-F)
bindkey -s '^[^F' 'fzf-file-preview\n'

# Git branch switcher (Ctrl-G then B)
bindkey -s '^GB' 'fzf-git-branch\n'

# Process killer (Ctrl-Alt-K)
bindkey -s '^[^K' 'fzf-kill-process\n'

# Enhanced directory navigation (Ctrl-Alt-D)
bindkey -s '^[^D' 'fzf-cd\n'

# Enhanced history (Ctrl-Alt-R)
bindkey -s '^[^R' 'fzf-history-enhanced\n'

# Git file selector (Ctrl-G then F)
bindkey -s '^GF' 'fzf-git-files\n'

# Environment variable browser (Ctrl-Alt-E)
bindkey -s '^[^E' 'fzf-env\n'

# ==============================================================================
# Help Function
# ==============================================================================

fzf-help() {
    cat <<'EOF'
🔍 Enhanced FZF Integration

File Operations:
  Ctrl-Alt-F        : File finder with bat/cat preview
  Ctrl-T            : Standard FZF file finder (from base FZF)
  
Directory Navigation:
  Ctrl-Alt-D        : Directory browser with ls preview
  Ctrl-Alt-C        : Standard FZF cd (from base FZF)
  
Git Operations:
  Ctrl-G B          : Git branch switcher with log preview
  Ctrl-G F          : Git file selector with diff preview
  
History:
  Ctrl-Alt-R        : Enhanced history with usage stats
  Ctrl-R            : Standard FZF history (from base FZF)
  
System:
  Ctrl-Alt-K        : Process killer with resource preview
  Ctrl-Alt-E        : Environment variable browser
  
Preview Controls (in FZF):
  Ctrl-/            : Toggle preview pane
  Ctrl-A            : Select all
  Ctrl-D            : Deselect all
  Ctrl-T            : Toggle all
  Tab               : Multi-select (mark items)

Functions:
  fzf-file-preview  : File finder with preview
  fzf-git-branch    : Git branch switcher
  fzf-kill-process  : Process killer
  fzf-cd            : Directory browser
  fzf-history-enhanced : Command history browser
  fzf-git-files     : Git file selector
  fzf-env           : Environment variable browser
  fzf-help          : This help message

Toggles:
  ZF_DISABLE_FZF_ENHANCEMENTS=1  : Disable all enhancements

Note: Install 'bat' for syntax-highlighted file previews:
  brew install bat
EOF
}

# Welcome message
if [[ -z "${_ZF_FZF_ENHANCEMENTS_NOTIFIED:-}" ]]; then
    echo "🔍 Enhanced FZF features active. Type 'fzf-help' for keybindings."
    export _ZF_FZF_ENHANCEMENTS_NOTIFIED=1
fi

zf::debug "# [fzf-enhancements] Advanced FZF integration loaded"

return 0

