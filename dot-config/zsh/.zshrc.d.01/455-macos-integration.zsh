#!/usr/bin/env zsh
# Filename: 455-macos-integration.zsh
# Purpose:  Deep macOS integration including Spotlight, Finder, Quick Look,
#           and Notification Center for enhanced native platform experience
# Phase:    Post-plugin (.zshrc.d/)
# Requires: 420-terminal-integration.zsh
# Toggles:  ZF_DISABLE_MACOS_INTEGRATION

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# Skip if not on macOS or disabled
if [[ "$(uname -s)" != "Darwin" ]] || [[ "${ZF_DISABLE_MACOS_INTEGRATION:-0}" == 1 ]]; then
    return 0
fi

# ==============================================================================
# Spotlight Integration
# ==============================================================================

# Search Spotlight from command line
spotlight() {
    local query="$*"
    
    if [[ -z "$query" ]]; then
        echo "Usage: spotlight <search query>"
        return 1
    fi
    
    mdfind "$query"
}

# Search Spotlight with result count limit
spotlight-find() {
    local query="$1"
    local limit="${2:-10}"
    
    if [[ -z "$query" ]]; then
        echo "Usage: spotlight-find <query> [limit]"
        return 1
    fi
    
    mdfind "$query" | head -n "$limit"
}

# Search Spotlight in specific directory
spotlight-here() {
    local query="$*"
    local current_dir="$PWD"
    
    if [[ -z "$query" ]]; then
        echo "Usage: spotlight-here <search query>"
        return 1
    fi
    
    mdfind -onlyin "$current_dir" "$query"
}

# ==============================================================================
# Quick Look Integration
# ==============================================================================

# Quick Look file preview
ql() {
    local file="$1"
    
    if [[ -z "$file" ]]; then
        echo "Usage: ql <file>"
        return 1
    fi
    
    if [[ ! -e "$file" ]]; then
        echo "Error: File not found: $file"
        return 1
    fi
    
    qlmanage -p "$file" &>/dev/null &
}

# Quick Look with FZF integration
ql-fzf() {
    local file
    
    if command -v fzf >/dev/null 2>&1; then
        file=$(find . -type f -not -path '*/\.*' 2>/dev/null | fzf --preview='qlmanage -t {} -s 512 -o /tmp 2>/dev/null && cat /tmp/*.png 2>/dev/null || file {}')
        
        if [[ -n "$file" ]]; then
            ql "$file"
        fi
    else
        echo "Error: fzf not installed"
        return 1
    fi
}

# ==============================================================================
# Finder Integration
# ==============================================================================

# Open current directory in Finder
finder() {
    local target="${1:-.}"
    open "$target"
}

# Get Finder's current directory
finder-pwd() {
    osascript -e 'tell application "Finder"
        if (count of Finder windows) > 0 then
            get POSIX path of (target of front window as text)
        else
            get POSIX path of (desktop as alias)
        end if
    end tell' 2>/dev/null
}

# Change shell to Finder's current directory
cdf() {
    local finder_path="$(finder-pwd)"
    
    if [[ -n "$finder_path" ]]; then
        cd "$finder_path" || return 1
        echo "Changed to Finder directory: $finder_path"
    else
        echo "Error: Could not get Finder's current directory"
        return 1
    fi
}

# Sync Finder to current shell directory
sync-finder() {
    osascript -e "tell application \"Finder\"
        set target of front window to (POSIX file \"$PWD\" as alias)
    end tell" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Finder synced to: $PWD"
    else
        # If no Finder window, open new one
        open "$PWD"
        echo "✅ Opened Finder at: $PWD"
    fi
}

# Show file in Finder
show-in-finder() {
    local target="${1:-.}"
    
    if [[ ! -e "$target" ]]; then
        echo "Error: File or directory not found: $target"
        return 1
    fi
    
    open -R "$target"
}

# ==============================================================================
# Notification Center Integration
# ==============================================================================

# Send notification to Notification Center
notify() {
    local title="${1:-Terminal Notification}"
    local message="${2:-Command completed}"
    local sound="${3:-}"
    
    local cmd="osascript -e 'display notification \"$message\" with title \"$title\""
    
    if [[ -n "$sound" ]]; then
        cmd="${cmd} sound name \"${sound}\""
    fi
    
    cmd="${cmd}'"
    
    eval "$cmd"
}

# Notify when long-running command completes
notify-done() {
    local exit_code=$?
    local cmd_time="${1:-unknown}"
    
    if [[ $exit_code -eq 0 ]]; then
        notify "✅ Command Succeeded" "Completed in ${cmd_time}" "Glass"
    else
        notify "❌ Command Failed" "Exit code: $exit_code" "Basso"
    fi
    
    return $exit_code
}

# ==============================================================================
# Clipboard Integration
# ==============================================================================

# Copy to clipboard
clip() {
    if [[ -t 0 ]]; then
        # From argument
        echo -n "$*" | pbcopy
        echo "✅ Copied to clipboard: $*"
    else
        # From pipe
        pbcopy
        echo "✅ Piped content copied to clipboard"
    fi
}

# Paste from clipboard
paste() {
    pbpaste
}

# Copy current directory path
cpwd() {
    echo -n "$PWD" | pbcopy
    echo "✅ Copied to clipboard: $PWD"
}

# ==============================================================================
# macOS Defaults & System Integration
# ==============================================================================

# Show/hide hidden files in Finder
toggle-hidden-files() {
    local current=$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null || echo "false")
    
    if [[ "$current" == "true" ]] || [[ "$current" == "YES" ]]; then
        defaults write com.apple.finder AppleShowAllFiles -bool false
        echo "Hidden files: disabled"
    else
        defaults write com.apple.finder AppleShowAllFiles -bool true
        echo "Hidden files: enabled"
    fi
    
    killall Finder
}

# Show file path in Finder title
show-path-in-finder() {
    defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
    killall Finder
    echo "✅ Finder will show full path in title"
}

# ==============================================================================
# Application Integration
# ==============================================================================

# Open in default application
openx() {
    local file="$1"
    
    if [[ -z "$file" ]]; then
        echo "Usage: openx <file>"
        return 1
    fi
    
    open "$file"
}

# Open with specific application
open-with() {
    local app="$1"
    local file="$2"
    
    if [[ -z "$app" ]] || [[ -z "$file" ]]; then
        echo "Usage: open-with <application> <file>"
        return 1
    fi
    
    open -a "$app" "$file"
}

# ==============================================================================
# System Information
# ==============================================================================

# Show macOS version
macos-version() {
    sw_vers
}

# Show system info summary
macos-info() {
    cat <<EOF
🍎 macOS System Information

Version: $(sw_vers -productVersion)
Build: $(sw_vers -buildVersion)
Architecture: $(uname -m)
Hostname: $(hostname)
User: $USER
Shell: $SHELL ($ZSH_VERSION)
Terminal: ${TERM_PROGRAM:-Unknown}

Disk Usage:
$(df -h / | tail -1 | awk '{print "  " $1 ": " $3 " used / " $2 " total (" $5 " full)"}')

Memory:
$(vm_stat | head -4)
EOF
}

# ==============================================================================
# Help Function
# ==============================================================================

macos-help() {
    cat <<'EOF'
🍎 macOS Deep Integration

Spotlight Search:
  spotlight <query>           : Search Spotlight
  spotlight-find <query> [n]  : Find with result limit
  spotlight-here <query>      : Search in current directory

Quick Look:
  ql <file>                   : Preview file in Quick Look
  ql-fzf                      : FZF file selector with Quick Look

Finder:
  finder [path]               : Open in Finder
  finder-pwd                  : Get Finder's current directory
  cdf                         : Change to Finder's directory
  sync-finder                 : Sync Finder to shell directory
  show-in-finder <file>       : Reveal file in Finder

Notifications:
  notify <title> <msg> [sound]: Send notification
  notify-done                 : Notify when command completes

Clipboard:
  clip [text]                 : Copy to clipboard (or from pipe)
  paste                       : Paste from clipboard
  cpwd                        : Copy current directory path

System:
  toggle-hidden-files         : Show/hide hidden files in Finder
  show-path-in-finder         : Show full path in Finder title
  macos-version               : Show macOS version
  macos-info                  : System information summary

Aliases:
  openx <file>                : Open in default app
  open-with <app> <file>      : Open with specific app

Toggle:
  ZF_DISABLE_MACOS_INTEGRATION=1  : Disable all macOS features

Note: Some features require macOS 10.15+ (Catalina)
EOF
}

# Mark functions readonly (wrapped to prevent function definition output)
(
  readonly -f spotlight 2>/dev/null || true
  readonly -f spotlight-find 2>/dev/null || true
  readonly -f spotlight-here 2>/dev/null || true
  readonly -f ql 2>/dev/null || true
  readonly -f ql-fzf 2>/dev/null || true
  readonly -f finder 2>/dev/null || true
  readonly -f finder-pwd 2>/dev/null || true
  readonly -f cdf 2>/dev/null || true
  readonly -f sync-finder 2>/dev/null || true
  readonly -f show-in-finder 2>/dev/null || true
  readonly -f notify 2>/dev/null || true
  readonly -f notify-done 2>/dev/null || true
  readonly -f clip 2>/dev/null || true
  readonly -f cpwd 2>/dev/null || true
  readonly -f toggle-hidden-files 2>/dev/null || true
  readonly -f show-path-in-finder 2>/dev/null || true
  readonly -f macos-version 2>/dev/null || true
  readonly -f macos-info 2>/dev/null || true
  readonly -f openx 2>/dev/null || true
  readonly -f open-with 2>/dev/null || true
  readonly -f macos-help 2>/dev/null || true
) >/dev/null 2>&1

# Welcome message
if [[ -z "${_ZF_MACOS_NOTIFIED:-}" ]]; then
    echo "🍎 macOS integration active. Type 'macos-help' for native features."
    export _ZF_MACOS_NOTIFIED=1
fi

zf::debug "# [macos] macOS deep integration loaded"

return 0

