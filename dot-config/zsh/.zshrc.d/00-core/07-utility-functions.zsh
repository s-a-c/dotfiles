# Enhanced Utility Functions - POST-PLUGIN PHASE
# Comprehensive utility functions from refactored zsh configuration
# This file consolidates useful functions for daily development work

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
    echo "# [utility-functions] Loading enhanced utility functions" >&2
}

## [functions.path-management] - Enhanced PATH manipulation
{
    # Enhanced path manipulation functions with validation
    _path_append() {
        local dir="$1"
        [[ -z "$dir" ]] && return 1
        if [[ -d "$dir" ]] && [[ ":$PATH:" != *":$dir:"* ]]; then
            PATH="${PATH:+"$PATH:"}$dir"
        fi
    }

    _path_prepend() {
        local dir="$1"
        [[ -z "$dir" ]] && return 1
        if [[ -d "$dir" ]] && [[ ":$PATH:" != *":$dir:"* ]]; then
            PATH="$dir${PATH:+":$PATH"}"
        fi
    }

    _path_remove() {
        local dir="$1"
        [[ -z "$dir" ]] && return 1
        PATH=$(echo ":$PATH:" | sed "s|:$dir:|:|g" | sed 's/^://;s/:$//')
    }

    # Show PATH in readable format
    path() {
        echo "$PATH" | tr ':' '\n' | nl
    }

    # Clean duplicate PATH entries
    path_dedupe() {
        local new_path=""
        local dir
        IFS=':' read -ra ADDR <<< "$PATH"
        for dir in "${ADDR[@]}"; do
            if [[ -n "$dir" ]] && [[ ":$new_path:" != *":$dir:"* ]]; then
                new_path="${new_path:+"$new_path:"}$dir"
            fi
        done
        export PATH="$new_path"
        echo "PATH deduplicated: $(echo "$PATH" | tr ':' '\n' | wc -l) entries"
    }
}

## [functions.filesystem] - File and directory operations
{
    # Make directory and change to it
    mkcd() {
        if [[ $# -ne 1 ]]; then
            echo "Usage: mkcd <directory>"
            return 1
        fi
        mkdir -p "$1" && cd "$1"
    }

    # Create backup of file with timestamp
    backup() {
        if [[ -z "$1" ]]; then
            echo "Usage: backup <file>"
            return 1
        fi
        if [[ ! -e "$1" ]]; then
            echo "Error: '$1' does not exist"
            return 1
        fi
        local backup_name="$1.bak.$(date +%Y%m%d_%H%M%S)"
        cp "$1" "$backup_name"
        echo "Backup created: $backup_name"
    }

    # Extract various archive formats
    extract() {
        if [[ -z "$1" ]]; then
            echo "Usage: extract <archive>"
            return 1
        fi

        if [[ ! -f "$1" ]]; then
            echo "Error: '$1' is not a valid file"
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
            *)           echo "Error: '$1' cannot be extracted via extract()" ;;
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
        echo "System Information:"
        echo "==================="
        echo "Hostname: $(hostname)"
        echo "OS: $(uname -sr)"
        echo "Kernel: $(uname -r)"
        echo "Shell: $SHELL"
        echo "Terminal: $TERM"
        echo "User: $USER"
        echo "Date: $(date)"
        echo "Uptime: $(uptime)"
        echo "Current Directory: $(pwd)"
        echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
        echo "Memory Usage: $(free -h 2>/dev/null || vm_stat | head -4)"
        echo "Disk Usage: $(df -h . | tail -1)"
    }

    # Get IP addresses
#    myip() {
#        echo "Local IP addresses:"
#        if command -v ip >/dev/null 2>&1; then
#            ip addr show 2>/dev/null | grep -Po 'inet \K[\d.]+'
#        elif command -v ifconfig >/dev/null 2>&1; then
#            ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*'
#        fi
#        echo
#        echo "External IP address:"
#        curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "Unable to fetch external IP"
#        echo
#    }

    # System resource usage
    usage() {
        echo "System Resource Usage:"
        echo "======================"
        echo "CPU Usage:"
        top -l 1 -n 0 | grep "CPU usage" 2>/dev/null || echo "CPU info not available"
        echo
        echo "Memory Usage:"
        free -h 2>/dev/null || vm_stat | head -10
        echo
        echo "Disk Usage:"
        df -h | head -10
        echo
        echo "Top Processes by CPU:"
        ps aux | sort -k3 -rn | head -5
    }
}

## [functions.process] - Process management utilities
{
    # Search for processes
    psgrep() {
        if [[ -z "$1" ]]; then
            echo "Usage: psgrep <process_name>"
            return 1
        fi
        ps aux | grep -v grep | grep -i "$1"
    }

    # Kill processes by name with confirmation
    kill9() {
        if [[ -z "$1" ]]; then
            echo "Usage: kill9 <process_name>"
            return 1
        fi

        local pids=$(pgrep -f "$1")
        if [[ -z "$pids" ]]; then
            echo "No processes found matching: $1"
            return 1
        fi

        echo "Found processes:"
        ps -p $pids -o pid,ppid,user,command
        echo
        read "confirm?Kill these processes? (y/N): "
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            pkill -9 -f "$1"
            echo "Processes killed."
        else
            echo "Cancelled."
        fi
    }

    # Show listening ports
    ports() {
        if command -v netstat >/dev/null 2>&1; then
            netstat -tuln | grep LISTEN
        elif command -v ss >/dev/null 2>&1; then
            ss -tuln | grep LISTEN
        else
            lsof -i -P -n | grep LISTEN
        fi
    }
}

## [functions.development] - Development utilities
{
    # Start simple HTTP server
    serve() {
        local port="${1:-8000}"
        echo "Starting HTTP server on port $port..."
        echo "Open: http://localhost:$port"

        if command -v python3 >/dev/null 2>&1; then
            python3 -m http.server "$port"
        elif command -v python2 >/dev/null 2>&1; then
            python2 -m SimpleHTTPServer "$port"
        elif command -v node >/dev/null 2>&1; then
            npx http-server -p "$port"
        else
            echo "Error: No suitable HTTP server found (python/node)"
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
            echo "Usage: newproject <project_name> [template]"
            return 1
        fi

        local project_name="$1"
        local template="${2:-basic}"

        mkdir -p "$project_name"
        cd "$project_name"

        case "$template" in
            "node"|"js")
                npm init -y
                echo "node_modules/\n.env\n*.log" > .gitignore
                ;;
            "python"|"py")
                python3 -m venv venv
                echo "venv/\n__pycache__/\n*.pyc\n.env" > .gitignore
                touch requirements.txt
                ;;
            "rust")
                cargo init .
                ;;
            *)
                touch README.md
                echo ".DS_Store\n*.log\n.env" > .gitignore
                ;;
        esac

        git init
        echo "Project '$project_name' created with template '$template'"
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
        echo "This will clean all untracked files and reset changes."
        read "confirm?Continue? (y/N): "
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            git clean -fd
            git checkout -- .
            echo "Working directory cleaned."
        else
            echo "Cancelled."
        fi
    }

    # Quick git commit with message
    gcommit() {
        if [[ -z "$1" ]]; then
            echo "Usage: gcommit <message>"
            return 1
        fi
        git add .
        git commit -m "$1"
    }

    # Git branch cleanup
    gbclean() {
        echo "Cleaning up merged branches..."
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

        echo "${lightblue}==>${off} ${bold}Formulae${off}"
        echo "${formulae}" | sed "s/^\(.*\):\(.*\)$/\1${lightblue}\2${off}/"
        echo "\n${lightblue}==>${off} ${bold}Casks${off}\n${casks}"
    }

    # Homebrew maintenance
    brewup() {
        echo "Updating Homebrew..."
        brew update
        echo "Upgrading packages..."
        brew upgrade
        echo "Cleaning up..."
        brew cleanup
        echo "Running doctor..."
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
            echo "Usage: qr <text>"
            return 1
        fi
        echo "$1" | curl -F-=\<- qrenco.de
    }

    # Timer function
    timer() {
        local seconds="${1:-60}"
        echo "Timer set for $seconds seconds..."
        sleep "$seconds"
        echo "⏰ Time's up!"
        if command -v osascript >/dev/null 2>&1; then
            osascript -e 'display notification "Timer finished!" with title "Shell Timer"'
        fi
    }

    # History search with grep
    hgrep() {
        if [[ -z "$1" ]]; then
            echo "Usage: hgrep <pattern>"
            return 1
        fi
        history | grep -i "$1"
    }

    # Environment variable search
    envgrep() {
        if [[ -z "$1" ]]; then
            echo "Usage: envgrep <pattern>"
            return 1
        fi
        printenv | grep -i "$1"
    }
}

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [utility-functions] ✅ Enhanced utility functions loaded" >&2
