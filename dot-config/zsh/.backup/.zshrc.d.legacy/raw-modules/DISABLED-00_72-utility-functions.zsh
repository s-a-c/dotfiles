#!/usr/bin/env zsh
# Enhanced Utility Functions - POST-PLUGIN PHASE
# Comprehensive utility functions from refactored zsh configuration
# This file consolidates useful functions for daily development work

[[ "$ZSH_DEBUG" == "1" ]] && {
        zf::debug "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
    zf::debug "# [utility-functions] Loading enhanced utility functions"
}

## [functions.path-display] - PATH visualization (non-duplicate utilities)
{
    # Show PATH in readable format
    show_path() {
            zf::debug "$PATH" | tr ':' '\n' | nl
    }
}

## [functions.filesystem] - File and directory operations
{
    # Make directory and change to it
    mkcd() {
        if [[ $# -ne 1 ]]; then
            zf::debug "Usage: mkcd <directory>"
            return 1
        fi
        mkdir -p "$1" && cd "$1"
    }

    # Create backup of file with timestamp
    backup() {
        if [[ -z "$1" ]]; then
            zf::debug "Usage: backup <file>"
            return 1
        fi
        if [[ ! -e "$1" ]]; then
            zf::debug "Error: '$1' does not exist"
            return 1
        fi
        local backup_name="$1.bak.$(date +%Y%m%d_%H%M%S)"
        cp "$1" "$backup_name"
        zf::debug "Backup created: $backup_name"
    }

    # Extract various archive formats
    extract() {
        if [[ -z "$1" ]]; then
            zf::debug "Usage: extract <archive>"
            return 1
        fi

        if [[ ! -f "$1" ]]; then
            zf::debug "Error: '$1' is not a valid file"
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
            *)           zf::debug "Error: '$1' cannot be extracted via extract()" ;;
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
        zf::debug "System Information:"
        zf::debug "==================="
        zf::debug "Hostname: $(hostname)"
        zf::debug "OS: $(uname -sr)"
        zf::debug "Kernel: $(uname -r)"
        zf::debug "Shell: $SHELL"
        zf::debug "Terminal: $TERM"
        zf::debug "User: $USER"
        zf::debug "Date: $(date)"
        zf::debug "Uptime: $(uptime)"
        zf::debug "Current Directory: $(pwd)"
        zf::debug "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
        zf::debug "Memory Usage: $(free -h 2>/dev/null || vm_stat | head -4)"
        zf::debug "Disk Usage: $(df -h . | tail -1)"
    }

    # Get IP addresses
#    myip() {
#        zf::debug "Local IP addresses:"
#        if command -v ip >/dev/null 2>&1; then
#            ip addr show 2>/dev/null | grep -Po 'inet \K[\d.]+'
#        elif command -v ifconfig >/dev/null 2>&1; then
#            ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*'
#        fi
#        zf::debug
#        zf::debug "External IP address:"
#        curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || zf::debug "Unable to fetch external IP"
#        zf::debug
#    }

    # System resource usage
    usage() {
        zf::debug "System Resource Usage:"
        zf::debug "======================"
        zf::debug "CPU Usage:"
        top -l 1 -n 0 | grep "CPU usage" 2>/dev/null || zf::debug "CPU info not available"
        zf::debug
        zf::debug "Memory Usage:"
        free -h 2>/dev/null || vm_stat | head -10
        zf::debug
        zf::debug "Disk Usage:"
        df -h | head -10
        zf::debug
        zf::debug "Top Processes by CPU:"
        ps aux | sort -k3 -rn | head -5
    }
}

## [functions.process] - Process management utilities
{
    # Search for processes
    psgrep() {
        if [[ -z "$1" ]]; then
            zf::debug "Usage: psgrep <process_name>"
            return 1
        fi
        ps aux | grep -v grep | grep -i "$1"
    }

    # Kill processes by name with confirmation
    kill9() {
        if [[ -z "$1" ]]; then
            zf::debug "Usage: kill9 <process_name>"
            return 1
        fi

        local pids=$(pgrep -f "$1")
        if [[ -z "$pids" ]]; then
            zf::debug "No processes found matching: $1"
            return 1
        fi

        zf::debug "Found processes:"
        ps -p $pids -o pid,ppid,user,command
        zf::debug
        read "confirm?Kill these processes? (y/N): "
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            pkill -9 -f "$1"
            zf::debug "Processes killed."
        else
            zf::debug "Cancelled."
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
        zf::debug "Starting HTTP server on port $port..."
        zf::debug "Open: http://localhost:$port"

        if command -v python3 >/dev/null 2>&1; then
            python3 -m http.server "$port"
        elif command -v python2 >/dev/null 2>&1; then
            python2 -m SimpleHTTPServer "$port"
        elif command -v node >/dev/null 2>&1; then
            npx http-server -p "$port"
        else
            zf::debug "Error: No suitable HTTP server found (python/node)"
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
            zf::debug "Usage: newproject <project_name> [template]"
            return 1
        fi

        local project_name="$1"
        local template="${2:-basic}"

        mkdir -p "$project_name"
        cd "$project_name"

        case "$template" in
            "node"|"js")
                npm init -y
                zf::debug "node_modules/\n.env\n*.log" > .gitignore
                ;;
            "python"|"py")
                python3 -m venv venv
                zf::debug "venv/\n__pycache__/\n*.pyc\n.env" > .gitignore
                touch requirements.txt
                ;;
            "rust")
                cargo init .
                ;;
            *)
                touch README.md
                zf::debug ".DS_Store\n*.log\n.env" > .gitignore
                ;;
        esac

        git init
        zf::debug "Project '$project_name' created with template '$template'"
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
        zf::debug "This will clean all untracked files and reset changes."
        read "confirm?Continue? (y/N): "
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            git clean -fd
            git checkout -- .
            zf::debug "Working directory cleaned."
        else
            zf::debug "Cancelled."
        fi
    }

    # Quick git commit with message
    gcommit() {
        if [[ -z "$1" ]]; then
            zf::debug "Usage: gcommit <message>"
            return 1
        fi
        git add .
        git commit -m "$1"
    }

    # Git branch cleanup
    gbclean() {
        zf::debug "Cleaning up merged branches..."
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

        zf::debug "${lightblue}==>${off} ${bold}Formulae${off}"
        zf::debug "${formulae}" | sed "s/^\(.*\):\(.*\)$/\1${lightblue}\2${off}/"
        zf::debug "\n${lightblue}==>${off} ${bold}Casks${off}\n${casks}"
    }

    # Homebrew maintenance
    brew_maintenance() {
        zf::debug "Updating Homebrew..."
        brew update
        zf::debug "Upgrading packages..."
        brew upgrade
        zf::debug "Cleaning up..."
        brew cleanup
        zf::debug "Running doctor..."
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
            zf::debug "Usage: qr <text>"
            return 1
        fi
        zf::debug "$1" | curl -F-=\<- qrenco.de
    }

    # Timer function
    timer() {
        local seconds="${1:-60}"
        zf::debug "Timer set for $seconds seconds..."
        sleep "$seconds"
        zf::debug "⏰ Time's up!"
        if command -v osascript >/dev/null 2>&1; then
            osascript -e 'display notification "Timer finished!" with title "Shell Timer"'
        fi
    }

    # History search with grep
    hgrep() {
        if [[ -z "$1" ]]; then
            zf::debug "Usage: hgrep <pattern>"
            return 1
        fi
        history | grep -i "$1"
    }

    # Environment variable search
    envgrep() {
        if [[ -z "$1" ]]; then
            zf::debug "Usage: envgrep <pattern>"
            return 1
        fi
        printenv | grep -i "$1"
    }
}

zf::debug "# [utility-functions] ✅ Enhanced utility functions loaded"
