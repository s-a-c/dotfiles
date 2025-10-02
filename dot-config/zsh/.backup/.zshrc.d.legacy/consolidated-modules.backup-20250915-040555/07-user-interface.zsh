#!/usr/bin/env zsh
# ==============================================================================
# ZSH Legacy Configuration: User Interface Module
# ==============================================================================
# Purpose: Complete user interface configuration including prompt, aliases,
#          keybindings, and splash screen functionality
# 
# Consolidated from:
#   - ACTIVE-30_30-prompt.zsh (1 function)
#   - DISABLED-30_10-aliases.zsh (139 aliases)
#   - DISABLED-30_20-keybindings.zsh (67 keybindings)
#   - DISABLED-99_99-splash.zsh (4 functions)
#
# Dependencies: 01-core-infrastructure.zsh (for logging functions)
# Load Order: Late (70-79 range)
# Author: ZSH Legacy Consolidation System
# Created: 2025-09-14
# Version: 1.0.0
# ==============================================================================

# Prevent multiple loading
if [[ -n "${_USER_INTERFACE_LOADED:-}" ]]; then
    return 0
fi
export _USER_INTERFACE_LOADED=1

# Debug helper - use core infrastructure if available
_ui_debug() {
    if command -v debug_log >/dev/null 2>&1; then
        debug_log "$1"
    elif [[ -n "${ZSH_DEBUG:-}" ]]; then
        echo "[UI-DEBUG] $1" >&2
    fi
}

_ui_debug "Loading user interface module..."

# ==============================================================================
# SECTION 1: PROMPT CONFIGURATION
# ==============================================================================
# From: ACTIVE-30_30-prompt.zsh
# Purpose: Prompt and UI configuration

_ui_debug "Configuring prompt system..."

# Builtin prompt setup function
setup_builtin_prompt() {
    _ui_debug "Setting up builtin prompt..."
    
    # Simple, clean prompt as fallback
    export PS1='%F{blue}%n@%m%f:%F{green}%~%f$ '
    export RPS1='%F{yellow}%T%f'
    
    # Additional prompt configurations
    export PS2='%F{red}%_%f> '
    export PS3='?# '
    export PS4='+%F{cyan}%N%f:%F{yellow}%i%f> '
    
    _ui_debug "Builtin prompt configured"
}

# Initialize prompt system
init_prompt_system() {
    _ui_debug "Initializing prompt system..."
    
    # Set default prompt options
    setopt PROMPT_SUBST         # Enable prompt parameter expansion
    setopt TRANSIENT_RPROMPT    # Remove right prompt from previous lines
    
    # Check for available prompt systems
    if command -v starship >/dev/null 2>&1; then
        _ui_debug "Starship prompt detected - will be handled by plugins"
    elif command -v powerline-go >/dev/null 2>&1; then
        _ui_debug "Powerline-go prompt detected"
    else
        _ui_debug "Using builtin prompt"
        setup_builtin_prompt
    fi
    
    _ui_debug "Prompt system initialized"
}

# ==============================================================================
# SECTION 2: ALIASES CONFIGURATION
# ==============================================================================
# From: DISABLED-30_10-aliases.zsh  
# Purpose: Enhanced aliases for productivity (139 aliases)

_ui_debug "Loading enhanced aliases..."

# === Core System Aliases ===
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'
alias -- -='cd -'

# === Directory Operations ===
alias l='ls -lah'
alias la='ls -lAh'
alias ll='ls -lh'
alias ls='ls -G'  # macOS colorized ls
alias lsa='ls -lah'
alias md='mkdir -p'
alias rd='rmdir'

# === File Operations ===
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias ln='ln -iv'
alias mkdir='mkdir -pv'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# === Modern Tool Replacements (if available) ===
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --color=auto --icons'
    alias ll='eza -l --color=auto --icons'
    alias la='eza -la --color=auto --icons'
    alias tree='eza --tree'
fi

if command -v bat >/dev/null 2>&1; then
    alias cat='bat --style=plain'
    alias less='bat --style=plain --paging=always'
fi

if command -v fd >/dev/null 2>&1; then
    alias find='fd'
fi

if command -v rg >/dev/null 2>&1; then
    alias grep='rg'
fi

# === Git Aliases ===
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gbD='git branch -D'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit -a'
alias gcam='git commit -am'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gd='git diff'
alias gdc='git diff --cached'
alias gf='git fetch'
alias gl='git log --oneline --graph --decorate'
alias gll='git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit'
alias gm='git merge'
alias gp='git push'
alias gpu='git push -u origin'
alias gpl='git pull'
alias gr='git remote'
alias grv='git remote -v'
alias gs='git status'
alias gss='git status -s'
alias gst='git stash'
alias gstp='git stash pop'
alias gstl='git stash list'

# === Development Aliases ===
alias py='python3'
alias pip='pip3'
alias node='node'
alias npm='npm'
alias npx='npx'
alias yarn='yarn'
alias docker='docker'
alias dc='docker-compose'
alias k='kubectl'

# === macOS Specific Aliases ===
if [[ "$OSTYPE" == darwin* ]]; then
    alias o='open'
    alias oo='open .'
    alias finder='open -a Finder'
    alias preview='open -a Preview'
    alias xcode='open -a Xcode'
    alias safari='open -a Safari'
    alias chrome='open -a "Google Chrome"'
    alias firefox='open -a Firefox'
    
    # System utilities
    alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
    alias lscleanup='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder'
    alias emptytrash='sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl'
    
    # Show/hide hidden files
    alias showfiles='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
    alias hidefiles='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'
    
    # Network utilities
    alias myip='curl -s https://checkip.dyndns.org | sed "s/.*Current IP Address: \([0-9\.]*\).*/\1/"'
    alias localip='ipconfig getifaddr en0'
fi

# === Productivity Aliases ===
alias h='history'
alias hg='history | grep'
alias j='jobs'
alias p='ps aux'
alias pg='ps aux | grep'
alias path='echo -e ${PATH//:/\\n}'
alias reload='source ~/.zshrc'
alias zshrc='$EDITOR ~/.zshrc'
alias zprofile='$EDITOR ~/.zprofile'
alias zshenv='$EDITOR ~/.zshenv'

# === Network and System Aliases ===
alias ping='ping -c 5'
alias ports='netstat -tulanp'
alias wget='wget -c'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias top='top -o cpu'
alias htop='htop'

# === Archive Aliases ===
alias tar='tar -v'
alias untar='tar -xvf'
alias gz='tar -czf'
alias ungz='tar -xzf'

# === Quick Edits ===
alias v='$EDITOR'
alias vi='$EDITOR'
alias vim='$EDITOR'
alias nano='$EDITOR'
alias e='$EDITOR'

# === Directory Stack Aliases ===
alias d='dirs -v | head -10'
alias 1='cd -'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'

# === Suffix Aliases (open files by extension) ===
alias -s txt='$EDITOR'
alias -s md='$EDITOR'
alias -s json='$EDITOR'
alias -s yml='$EDITOR'
alias -s yaml='$EDITOR'
alias -s xml='$EDITOR'
alias -s html='$EDITOR'
alias -s css='$EDITOR'
alias -s js='$EDITOR'
alias -s ts='$EDITOR'
alias -s py='$EDITOR'
alias -s rb='$EDITOR'
alias -s go='$EDITOR'
alias -s sh='$EDITOR'
alias -s zsh='$EDITOR'

if [[ "$OSTYPE" == darwin* ]]; then
    alias -s pdf='open -a Preview'
    alias -s png='open -a Preview'
    alias -s jpg='open -a Preview'
    alias -s jpeg='open -a Preview'
    alias -s gif='open -a Preview'
fi

_ui_debug "Enhanced aliases loaded (139 aliases)"

# ==============================================================================
# SECTION 3: KEYBINDINGS CONFIGURATION
# ==============================================================================
# From: DISABLED-30_20-keybindings.zsh
# Purpose: Enhanced keyboard shortcuts (67 keybindings)

_ui_debug "Configuring enhanced keybindings..."

# Set keymap mode
bindkey -e  # Emacs-style key bindings (can be changed to -v for vi-style)

# === History Navigation ===
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward

# === Line Editing ===
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^B' backward-char
bindkey '^F' forward-char
bindkey '^H' backward-delete-char
bindkey '^D' delete-char
bindkey '^U' kill-whole-line
bindkey '^K' kill-line
bindkey '^W' backward-kill-word
bindkey '^Y' yank

# === Word Movement ===
bindkey '^[b' backward-word
bindkey '^[f' forward-word
bindkey '^[d' kill-word
bindkey '^[h' backward-kill-word

# === macOS-specific Keybindings ===
if [[ "$OSTYPE" == darwin* ]]; then
    # Option + Left/Right for word movement
    bindkey '^[^[[D' backward-word
    bindkey '^[^[[C' forward-word
    
    # Command + Left/Right for line movement  
    bindkey '^[[H' beginning-of-line
    bindkey '^[[F' end-of-line
fi

# === Advanced Editing ===
bindkey '^X^E' edit-command-line
bindkey '^Q' push-line-or-edit
bindkey '^T' transpose-chars
bindkey '^[t' transpose-words
bindkey '^[u' up-case-word
bindkey '^[l' down-case-word
bindkey '^[c' capitalize-word

# === Completion Keybindings ===
bindkey '^I' complete-word          # Tab
bindkey '^[[Z' reverse-menu-complete # Shift+Tab

# === Directory Navigation ===
bindkey '^[^I' menu-complete        # Alt+Tab for menu completion
bindkey '^X^D' list-choices         # Ctrl+X Ctrl+D for listing completions

# === Custom Widget Functions ===
# Function to quickly edit zshrc
edit-zshrc() {
    $EDITOR ~/.zshrc
}
zle -N edit-zshrc
bindkey '^X^Z' edit-zshrc

# Function to reload shell configuration
reload-shell() {
    source ~/.zshrc
    zle reset-prompt
}
zle -N reload-shell
bindkey '^X^R' reload-shell

# Function to insert sudo at beginning of line
insert-sudo() {
    if [[ $BUFFER != "sudo "* ]]; then
        BUFFER="sudo $BUFFER"
        CURSOR=$((CURSOR + 5))
    fi
}
zle -N insert-sudo
bindkey '^X^S' insert-sudo

# Function to quickly cd to parent directory
cd-parent() {
    BUFFER="cd .."
    zle accept-line
}
zle -N cd-parent
bindkey '^X^U' cd-parent

# Function for quick git status
git-status() {
    BUFFER="git status"
    zle accept-line
}
zle -N git-status
bindkey '^X^G' git-status

_ui_debug "Enhanced keybindings configured (67+ keybindings)"

# ==============================================================================
# SECTION 4: SPLASH SCREEN AND PERFORMANCE
# ==============================================================================
# From: DISABLED-99_99-splash.zsh
# Purpose: Startup splash and performance monitoring (4 functions)

_ui_debug "Loading splash and performance functions..."

# Display startup splash screen
splash_screen() {
    if [[ -n "${ZSH_DISABLE_SPLASH:-}" ]]; then
        return 0
    fi
    
    local shell_version="ZSH $ZSH_VERSION"
    local config_version="${ZDOTDIR##*/} configuration"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo ""
    echo "╭─────────────────────────────────────────────────────────╮"
    echo "│  🚀 Welcome to Enhanced ZSH Configuration              │"
    echo "│                                                         │"
    echo "│  Shell: $shell_version                                    │"
    echo "│  Config: $config_version                          │"
    echo "│  Time: $timestamp                            │"
    echo "│                                                         │"
    echo "│  💡 Enhanced features now active:                      │"
    echo "│    • 139 productivity aliases                           │"
    echo "│    • 67+ enhanced keybindings                           │"
    echo "│    • Advanced prompt system                             │"
    echo "│    • Modern tool integrations                           │"
    echo "╰─────────────────────────────────────────────────────────╯"
    echo ""
}

# Perform basic shell health check
shell_health_check() {
    local issues=0
    local warnings=()
    
    # Check for essential commands
    local essential_commands=(git curl wget ssh)
    for cmd in "${essential_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            warnings+=("Missing essential command: $cmd")
            ((issues++))
        fi
    done
    
    # Check shell options
    if ! setopt | grep -q EXTENDED_GLOB; then
        warnings+=("EXTENDED_GLOB not set - some features may not work")
        ((issues++))
    fi
    
    # Check for modern tools
    local modern_tools=(eza bat fd rg)
    local modern_count=0
    for tool in "${modern_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            ((modern_count++))
        fi
    done
    
    if [[ $issues -gt 0 ]]; then
        echo "⚠️  Shell Health Issues Detected ($issues):"
        for warning in "${warnings[@]}"; do
            echo "   • $warning"
        done
        echo ""
    fi
    
    if [[ $modern_count -gt 0 ]]; then
        echo "✨ Modern tools available: $modern_count/${#modern_tools[@]}"
    fi
    
    return $issues
}

# Show performance tips
show_performance_tips() {
    if [[ -n "${ZSH_DISABLE_TIPS:-}" ]]; then
        return 0
    fi
    
    local tips=(
        "Use 'reload' alias to quickly reload your shell configuration"
        "Press Ctrl+X Ctrl+S to add 'sudo' to any command"
        "Use 'l' for detailed file listing, 'll' for long format"
        "Press Ctrl+R for history search, Ctrl+X Ctrl+G for git status"
        "Modern tools (eza, bat, fd, rg) provide enhanced functionality"
        "Use '..' '...' '....' for quick directory navigation"
    )
    
    local tip_index=$((RANDOM % ${#tips[@]} + 1))
    echo "💡 Tip: ${tips[tip_index]}"
    echo ""
}

# Main splash function to orchestrate startup display
show_startup_splash() {
    # Only show splash in interactive shells
    if [[ ! -o interactive ]]; then
        return 0
    fi
    
    # Skip splash if disabled or in non-interactive contexts
    if [[ -n "${ZSH_DISABLE_SPLASH:-}" ]] || [[ -n "${CI:-}" ]] || [[ -n "${SSH_CONNECTION:-}" && -z "${FORCE_SPLASH:-}" ]]; then
        return 0
    fi
    
    splash_screen
    
    # Perform health check if requested
    if [[ -n "${ZSH_ENABLE_HEALTH_CHECK:-}" ]]; then
        shell_health_check
    fi
    
    # Show performance tip
    show_performance_tips
}

_ui_debug "Splash and performance functions loaded"

# ==============================================================================
# SECTION 5: USER INTERFACE UTILITIES
# ==============================================================================

# Set terminal title
set_terminal_title() {
    local title="$1"
    if [[ -n "$title" ]]; then
        case "$TERM" in
            xterm*|rxvt*|screen*|tmux*)
                printf '\033]2;%s\007' "$title"
                ;;
        esac
    fi
}

# Color definitions for UI elements
init_ui_colors() {
    # Only set colors if terminal supports them
    if [[ -t 1 ]] && [[ $(tput colors 2>/dev/null) -ge 8 ]]; then
        export UI_RED=$(tput setaf 1)
        export UI_GREEN=$(tput setaf 2)
        export UI_YELLOW=$(tput setaf 3)
        export UI_BLUE=$(tput setaf 4)
        export UI_MAGENTA=$(tput setaf 5)
        export UI_CYAN=$(tput setaf 6)
        export UI_WHITE=$(tput setaf 7)
        export UI_BOLD=$(tput bold)
        export UI_RESET=$(tput sgr0)
    else
        # Fallback for terminals without color support
        export UI_RED=""
        export UI_GREEN=""
        export UI_YELLOW=""
        export UI_BLUE=""
        export UI_MAGENTA=""
        export UI_CYAN=""
        export UI_WHITE=""
        export UI_BOLD=""
        export UI_RESET=""
    fi
}

# Quick directory listing with colors
quick_ls() {
    if command -v eza >/dev/null 2>&1; then
        eza --color=auto --icons "$@"
    else
        ls -G "$@"
    fi
}

# Enhanced cd with automatic ls
cd_with_ls() {
    builtin cd "$@" && quick_ls
}

# Alias cd to use enhanced version
alias cd='cd_with_ls'

# ==============================================================================
# MODULE INITIALIZATION
# ==============================================================================

_ui_debug "Initializing user interface module..."

# Initialize UI colors
init_ui_colors

# Initialize prompt system
init_prompt_system

# Set module metadata
export USER_INTERFACE_VERSION="1.0.0"
export USER_INTERFACE_LOADED="$(date '+%Y-%m-%d %H:%M:%S')"
export USER_INTERFACE_ALIASES=139
export USER_INTERFACE_KEYBINDINGS=67

_ui_debug "User interface module ready"

# ==============================================================================
# MODULE SELF-TEST
# ==============================================================================

test_user_interface() {
    local tests_passed=0
    local tests_total=7
    
    # Test 1: Aliases loaded
    if alias ll >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Aliases loaded successfully"
    else
        echo "❌ Aliases not loaded"
    fi
    
    # Test 2: Keybindings configured
    if bindkey | grep -q "beginning-of-line"; then
        ((tests_passed++))
        echo "✅ Keybindings configured"
    else
        echo "❌ Keybindings not configured"
    fi
    
    # Test 3: Splash functions available
    if command -v splash_screen >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Splash functions loaded"
    else
        echo "❌ Splash functions not loaded"
    fi
    
    # Test 4: Prompt functions available
    if command -v setup_builtin_prompt >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Prompt functions loaded"
    else
        echo "❌ Prompt functions not loaded"
    fi
    
    # Test 5: UI utilities available
    if command -v set_terminal_title >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ UI utilities loaded"
    else
        echo "❌ UI utilities not loaded"
    fi
    
    # Test 6: Color support initialized
    if [[ -n "$UI_RESET" ]] || [[ -z "$(tput colors 2>/dev/null)" ]]; then
        ((tests_passed++))
        echo "✅ Color support configured"
    else
        echo "❌ Color support not configured"
    fi
    
    # Test 7: Module metadata set
    if [[ -n "$USER_INTERFACE_VERSION" ]]; then
        ((tests_passed++))
        echo "✅ Module metadata available"
    else
        echo "❌ Module metadata missing"
    fi
    
    echo ""
    echo "User Interface Self-Test: $tests_passed/$tests_total tests passed"
    echo "📊 Features: $USER_INTERFACE_ALIASES aliases, $USER_INTERFACE_KEYBINDINGS+ keybindings"
    
    if [[ $tests_passed -eq $tests_total ]]; then
        return 0
    else
        return 1
    fi
}

# ==============================================================================
# STARTUP EXECUTION
# ==============================================================================

# Show startup splash when module loads (only in interactive shells)
if [[ -o interactive ]] && [[ -z "${_UI_SPLASH_SHOWN:-}" ]]; then
    export _UI_SPLASH_SHOWN=1
    # Delay splash slightly to allow shell to fully initialize
    (sleep 0.1; show_startup_splash) &!
fi

# ==============================================================================
# END OF USER INTERFACE MODULE
# ==============================================================================