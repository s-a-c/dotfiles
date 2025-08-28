#!/usr/bin/env zsh
# Enhanced Utility Functions - POST-PLUGIN PHASE
# Comprehensive utility functions from refactored zsh configuration
# This file consolidates useful functions for daily development work

[[ "$ZSH_DEBUG" == "1" ]] && {
        zsh_debug_echo "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
    zsh_debug_echo "# [utility-functions] Loading enhanced utility functions"
}

## [functions.path-display] - PATH visualization (non-duplicate utilities)
{
    # Show PATH in readable format
    show_path() {
            zsh_debug_echo "$PATH" | tr ':' '\n' | nl
    }
}

## [functions.filesystem] - File and directory operations
{
    # Make directory and change to it
    mkcd() {
        if [[ $# -ne 1 ]]; then
            zsh_debug_echo "Usage: mkcd <directory>"
            return 1
        fi
        mkdir -p "$1" && cd "$1"
    }

    # Create backup of file with timestamp
    backup() {
        if [[ -z "$1" ]]; then
            zsh_debug_echo "Usage: backup <file>"
            return 1
        fi
        if [[ ! -e "$1" ]]; then
            zsh_debug_echo "Error: '$1' does not exist"
            return 1
        fi
        local backup_name="$1.bak.$(date +%Y%m%d_%H%M%S)"
        cp "$1" "$backup_name"
        zsh_debug_echo "Backup created: $backup_name"
    }

    # Extract various archive formats
    extract() {
        if [[ -z "$1" ]]; then
            zsh_debug_echo "Usage: extract <archive>"
            return 1
        fi

        if [[ ! -f "$1" ]]; then
            zsh_debug_echo "Error: '$1' is not a valid file"
            return 1
        fi

        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.tar.xz)    tar xJf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *.deb)       ar x "$1"        ;;
            *.tar.Z)     tar xzf "$1"     ;;
            *)           zsh_debug_echo "Error: '$1' cannot be extracted via extract()" ;;
        esac
    }

    # Find files by name pattern
    ff() {
        find . -type f -iname "*$@*" -ls
    }

    # Quick file search with fd/find
    qfind() {
        if command -v fd >/dev/null 2>&1; then
            fd "$@"
        else
            find . -name "*$@*" -type f
        fi
    }
}

## [functions.system] - System information and utilities
{
    # Comprehensive system information
    sysinfo() {
        zsh_debug_echo "System Information:"
        zsh_debug_echo "==================="
        zsh_debug_echo "Hostname: $(hostname)"
        zsh_debug_echo "OS: $(uname -sr)"
        zsh_debug_echo "Kernel: $(uname -r)"
        zsh_debug_echo "Shell: $SHELL"
        zsh_debug_echo "Terminal: $TERM"
        zsh_debug_echo "User: $USER"
        zsh_debug_echo "Date: $(date)"
        zsh_debug_echo "Uptime: $(uptime)"
        zsh_debug_echo "Current Directory: $(pwd)"
        zsh_debug_echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
        zsh_debug_echo "Memory Usage: $(free -h 2>/dev/null || vm_stat | head -4)"
        zsh_debug_echo "Disk Usage: $(df -h . | tail -1)"
    }

    # Get IP addresses
#    myip() {
#        zsh_debug_echo "Local IP addresses:"
#        if command -v ip >/dev/null 2>&1; then
#            ip addr show 2>/dev/null | grep -Po 'inet \K[\d.]+'
#        elif command -v ifconfig >/dev/null 2>&1; then
#            ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*'
#        fi
#        zsh_debug_echo
#        zsh_debug_echo "External IP address:"
#        curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || zsh_debug_echo "Unable to fetch external IP"
#        zsh_debug_echo
#    }

    # System resource usage
    usage() {
        zsh_debug_echo "System Resource Usage:"
        zsh_debug_echo "======================"
        zsh_debug_echo "CPU Usage:"
        top -l 1 -n 0 | grep "CPU usage" 2>/dev/null || zsh_debug_echo "CPU info not available"
        zsh_debug_echo
        zsh_debug_echo "Memory Usage:"
        free -h 2>/dev/null || vm_stat | head -10
        zsh_debug_echo
        zsh_debug_echo "Disk Usage:"
        df -h | head -10
        zsh_debug_echo
        zsh_debug_echo "Top Processes by CPU:"
        ps aux | sort -k3 -rn | head -5
    }
}

## [functions.process] - Process management utilities
{
    # Search for processes
    psgrep() {
        if [[ -z "$1" ]]; then
            zsh_debug_echo "Usage: psgrep <process_name>"
            return 1
        fi
        ps aux | grep -v grep | grep -i "$1"
    }

    # Kill processes by name with confirmation
    kill9() {
        if [[ -z "$1" ]]; then
            zsh_debug_echo "Usage: kill9 <process_name>"
            return 1
        fi

        local pids=$(pgrep -f "$1")
        if [[ -z "$pids" ]]; then
            zsh_debug_echo "No processes found matching: $1"
            return 1
        fi

        zsh_debug_echo "Found processes:"
        ps -p $pids -o pid,ppid,user,command
        zsh_debug_echo
        read "confirm?Kill these processes? (y/N): "
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            pkill -9 -f "$1"
            zsh_debug_echo "Processes killed."
        else
            zsh_debug_echo "Cancelled."
        fi
    }

    # Show listening ports
    show_ports() {
        if command -v netstat >/dev/null 2>&1; then
            netstat -tuln | grep LISTEN
        elif command -v ss >/dev/null 2>&1; then
            ss -tuln | grep LISTEN
        else
            lsof -i -P -n | grep LISTEN
        fi
    }

    # Legacy alias for backward compatibility
    alias ports='show_ports'
}

## [functions.development] - Development utilities
{
    # Start simple HTTP server
    serve() {
        local port="${1:-8000}"
        zsh_debug_echo "Starting HTTP server on port $port..."
        zsh_debug_echo "Open: http://localhost:$port"

        if command -v python3 >/dev/null 2>&1; then
            python3 -m http.server "$port"
        elif command -v python2 >/dev/null 2>&1; then
            python2 -m SimpleHTTPServer "$port"
        elif command -v node >/dev/null 2>&1; then
            npx http-server -p "$port"
        else
            zsh_debug_echo "Error: No suitable HTTP server found (python/node)"
            return 1
        fi
    }

    # Enhanced help function using bat
    help() {
        if command -v bat >/dev/null 2>&1; then
            "$@" --help 2>&1 | bat --plain --language=help
        else
            "$@" --help
        fi
    }

    # Better man pages with colors
    bathelp() {
        if command -v bat >/dev/null 2>&1; then
            bat --plain --language=help "$@"
        else
            cat "$@"
        fi
    }

    # Run nvim with virtual environment if available
    nvimvenv() {
        if [[ -e "$VIRTUAL_ENV" && -f "$VIRTUAL_ENV/bin/activate" ]]; then
            source "$VIRTUAL_ENV/bin/activate"
            command nvim "$@"
            deactivate
        else
            command nvim "$@"
        fi
    }

    # Quick project setup
    newproject() {
        if [[ -z "$1" ]]; then
            zsh_debug_echo "Usage: newproject <project_name> [template]"
            return 1
        fi

        local project_name="$1"
        local template="${2:-basic}"

        mkdir -p "$project_name"
        cd "$project_name"

        case "$template" in
            "node"|"js")
                npm init -y
                zsh_debug_echo "node_modules/\n.env\n*.log" > .gitignore
                ;;
            "python"|"py")
                python3 -m venv venv
                zsh_debug_echo "venv/\n__pycache__/\n*.pyc\n.env" > .gitignore
                touch requirements.txt
                ;;
            "rust")
                cargo init .
                ;;
            *)
                touch README.md
                zsh_debug_echo ".DS_Store\n*.log\n.env" > .gitignore
                ;;
        esac

        git init
        zsh_debug_echo "Project '$project_name' created with template '$template'"
    }
}

## [functions.git] - Git utilities
{
    # Git log with graph
    # Commented out to avoid conflict with alias
    # gitlog() {
    #     git log --oneline --graph --decorate --all "$@"
    # }

    # Git status with short format
    gitstatus() {
        git status --short --branch
    }

    # Clean git working directory
    gitclean() {
        zsh_debug_echo "This will clean all untracked files and reset changes."
        read "confirm?Continue? (y/N): "
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            git clean -fd
            git checkout -- .
            zsh_debug_echo "Working directory cleaned."
        else
            zsh_debug_echo "Cancelled."
        fi
    }

    # Quick git commit with message
    gcommit() {
        if [[ -z "$1" ]]; then
            zsh_debug_echo "Usage: gcommit <message>"
            return 1
        fi
        git add .
        git commit -m "$1"
    }

    # Git branch cleanup
    gbclean() {
        zsh_debug_echo "Cleaning up merged branches..."
        git branch --merged | grep -v "\*\|main\|master\|develop" | xargs -n 1 git branch -d
    }
}

## [functions.homebrew] - Homebrew utilities
{
    # List installed packages with dependencies
    brews() {
        local formulae="$(brew leaves | xargs brew deps --installed --for-each)"
        local casks="$(brew list --cask 2>/dev/null)"

        local lightblue="$(tput setaf 4)"
        local bold="$(tput bold)"
        local off="$(tput sgr0)"

        zsh_debug_echo "${lightblue}==>${off} ${bold}Formulae${off}"
        zsh_debug_echo "${formulae}" | sed "s/^\(.*\):\(.*\)$/\1${lightblue}\2${off}/"
        zsh_debug_echo "\n${lightblue}==>${off} ${bold}Casks${off}\n${casks}"
    }

    # Homebrew maintenance
    brew_maintenance() {
        zsh_debug_echo "Updating Homebrew..."
        brew update
        zsh_debug_echo "Upgrading packages..."
        brew upgrade
        zsh_debug_echo "Cleaning up..."
        brew cleanup
        zsh_debug_echo "Running doctor..."
        brew doctor
    }
}

## [functions.misc] - Miscellaneous utilities
{
    # Weather information
    weather() {
        local location="${1:-}"
        curl -s "wttr.in/${location}?format=3"
    }

    # QR code generation
    qr() {
        if [[ -z "$1" ]]; then
            zsh_debug_echo "Usage: qr <text>"
            return 1
        fi
        zsh_debug_echo "$1" | curl -F-=\<- qrenco.de
    }

    # Timer function
    timer() {
        local seconds="${1:-60}"
        zsh_debug_echo "Timer set for $seconds seconds..."
        sleep "$seconds"
        zsh_debug_echo "⏰ Time's up!"
        if command -v osascript >/dev/null 2>&1; then
            osascript -e 'display notification "Timer finished!" with title "Shell Timer"'
        fi
    }

    # History search with grep
    hgrep() {
        if [[ -z "$1" ]]; then
            zsh_debug_echo "Usage: hgrep <pattern>"
            return 1
        fi
        history | grep -i "$1"
    }

    # Environment variable search
    envgrep() {
        if [[ -z "$1" ]]; then
            zsh_debug_echo "Usage: envgrep <pattern>"
            return 1
        fi
        printenv | grep -i "$1"
    }
}

[[ "$ZSH_DEBUG" == "1" ]] && zsh_debug_echo "# [utility-functions] ✅ Enhanced utility functions loaded"
