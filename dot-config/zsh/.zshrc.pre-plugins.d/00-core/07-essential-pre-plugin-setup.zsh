# Essential Pre-Plugin Setup - PRE-PLUGIN PHASE
# CONSOLIDATED FROM: 060-pre-plugins.zsh + 070-zstyle.zsh (essential parts) + 090-compinit.zsh (basic parts)
# Critical setup that MUST happen before plugins load but after core system setup

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
    echo "# [essential-pre-plugin] Critical pre-plugin setup and environment preparation" >&2
}

## [essential-pre-plugin.history] - History configuration before plugins
# MERGED FROM: 060-pre-plugins.zsh
# Essential history setup that plugins depend on

export HISTDUP=erase
export HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
export HISTSIZE=1000000
export HISTTIMEFORMAT='%F %T %z %a %V '
export SAVEHIST=1100000

## [essential-pre-plugin.builtins] - Core zsh functionality
# MERGED FROM: 060-pre-plugins.zsh
# Essential builtins that must be loaded before plugins

# Load colors
autoload -U colors && colors

# Essential key bindings (basic set needed before plugins)
bindkey -e  # Emacs mode
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region
bindkey "^[[3~" delete-char

# Windows/Linux style Home and End keys - Emacs Mode
bindkey -M emacs "^[[H"    beginning-of-line    # Home
bindkey -M emacs "^[[F"    end-of-line          # End
bindkey -M emacs "^[[1~"   beginning-of-line    # Home (alternative)
bindkey -M emacs "^[[4~"   end-of-line          # End (alternative)
bindkey -M emacs "^[[7~"   beginning-of-line    # Home (some terminals)
bindkey -M emacs "^[[8~"   end-of-line          # End (some terminals)
bindkey -M emacs "^[OH"    beginning-of-line    # Home (xterm app mode)
bindkey -M emacs "^[OF"    end-of-line          # End (xterm app mode)

# With modifiers - Emacs Mode
bindkey -M emacs "^[[1;5H" beginning-of-buffer-or-history  # Ctrl+Home
bindkey -M emacs "^[[1;5F" end-of-buffer-or-history        # Ctrl+End
bindkey -M emacs "^[[1;2H" vi-beginning-of-line            # Shift+Home
bindkey -M emacs "^[[1;2F" vi-end-of-line                  # Shift+End
bindkey -M emacs "^[[1;3H" beginning-of-line               # Alt+Home
bindkey -M emacs "^[[1;3F" end-of-line                     # Alt+End

# Vi Insert Mode key bindings for compatibility
bindkey -M viins "^[[H"    beginning-of-line    # Home
bindkey -M viins "^[[F"    end-of-line          # End
bindkey -M viins "^[[1~"   beginning-of-line    # Home (alternative)
bindkey -M viins "^[[4~"   end-of-line          # End (alternative)
bindkey -M viins "^[[7~"   beginning-of-line    # Home (some terminals)
bindkey -M viins "^[[8~"   end-of-line          # End (some terminals)
bindkey -M viins "^[OH"    beginning-of-line    # Home (xterm app mode)
bindkey -M viins "^[OF"    end-of-line          # End (xterm app mode)

# With modifiers - Vi Insert Mode
bindkey -M viins "^[[1;5H" beginning-of-buffer-or-history  # Ctrl+Home
bindkey -M viins "^[[1;5F" end-of-buffer-or-history        # Ctrl+End
bindkey -M viins "^[[1;2H" vi-beginning-of-line            # Shift+Home
bindkey -M viins "^[[1;2F" vi-end-of-line                  # Shift+End
bindkey -M viins "^[[1;3H" beginning-of-line               # Alt+Home
bindkey -M viins "^[[1;3F" end-of-line                     # Alt+End

# Arrow keys (basic - plugins will enhance these)
bindkey -M emacs "^[[A"    up-line-or-history        # Up
bindkey -M emacs "^[[B"    down-line-or-history      # Down
bindkey -M emacs "^[[C"    forward-char               # Right
bindkey -M emacs "^[[D"    backward-char              # Left

# Additional useful bindings
bindkey -M emacs "^[[5~"   beginning-of-buffer-or-history   # Page Up
bindkey -M emacs "^[[6~"   end-of-buffer-or-history         # Page Down
bindkey -M emacs "^[[2~"   overwrite-mode                   # Insert

# Smart URLs
autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic

## [essential-pre-plugin.plugin-prep] - Plugin environment preparation
# MERGED FROM: 060-pre-plugins.zsh
# Essential setup that plugins expect to be available

# Create essential temporary directories that plugins might need
export ABBR_TMPDIR="${XDG_RUNTIME_DIR:-/tmp}/zsh-abbr"
mkdir -p "${ABBR_TMPDIR}" 2>/dev/null

# Essential widget placeholders to prevent syntax highlighting warnings
# These will be properly redefined by plugins after they load
abbr-expand() { zle .self-insert }
zle -N abbr-expand 2>/dev/null || true

# Prepare plugin environment variables
export DISABLE_AUTO_UPDATE=true         # Disable OMZ auto-updates (use zgenom)
export DISABLE_UPDATE_PROMPT=true       # No update prompts during startup
export ZSH_DISABLE_COMPFIX=true        # Skip permission checks for speed

## [essential-pre-plugin.homebrew] - Homebrew integration
# MERGED FROM: 060-pre-plugins.zsh
# Essential Homebrew setup needed before plugins load

if [[ ! -n "${commands[brew]}" ]]; then
    local brew_location=""

    if [[ -n "${BREW_LOCATION}" ]]; then
        if [[ ! -x "${BREW_LOCATION}" ]]; then
            echo "[zshrc] ${BREW_LOCATION} is not executable" >&2
        else
            brew_location="${BREW_LOCATION}"
        fi
    elif [[ -x /opt/homebrew/bin/brew ]]; then
        brew_location="/opt/homebrew/bin/brew"
    elif [[ -x /usr/local/bin/brew ]]; then
        brew_location="/usr/local/bin/brew"
    elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        brew_location="/home/linuxbrew/.linuxbrew/bin/brew"
    elif [[ -x "${HOME}/.linuxbrew/bin/brew" ]]; then
        brew_location="${HOME}/.linuxbrew/bin/brew"
    else
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [homebrew] Homebrew not found, skipping" >&2
    fi

    if [[ -n "$brew_location" ]]; then
        eval "$($brew_location shellenv)"
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# [homebrew] Initialized from $brew_location" >&2
    fi
fi

# Set up Homebrew environment
[[ -z "${HOMEBREW_PREFIX}" ]] && {
    export HOMEBREW_PREFIX="$(brew --prefix 2>/dev/null)"
}
export HOMEBREW_AUTO_UPDATE_SECS="86400"

# Add Homebrew completions to fpath for plugins to use
if [[ -d "${HOMEBREW_PREFIX}/share/zsh/site-functions" ]]; then
    # Remove any existing Homebrew site-functions from fpath to avoid duplicates
    fpath=(${fpath:#${HOMEBREW_PREFIX}/share/zsh/site-functions})
    # Add to beginning of fpath
    fpath=("${HOMEBREW_PREFIX}/share/zsh/site-functions" $fpath)
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [homebrew] Added completions to fpath" >&2
fi

## [essential-pre-plugin.completion-basic] - Basic completion setup
# MERGED FROM: 090-compinit.zsh (essential parts only)
# Basic completion initialization that must happen before plugins

# Ensure completion system directories exist
[[ ! -d "${ZDOTDIR:-$HOME}/.zsh" ]] && mkdir -p "${ZDOTDIR:-$HOME}/.zsh"

# Set up basic completion cache
export ZSH_COMPDUMP="${ZDOTDIR:-$HOME}/.zsh/.zcompdump"

# Basic completion configuration (plugins will enhance this)
zstyle ':completion:*' use-cache true
zstyle ':completion:*' cache-path "${ZDOTDIR:-$HOME}/.zsh/.zcompcache"

# Ensure fpath is unique and properly ordered
typeset -gU fpath

## [essential-pre-plugin.variables] - Essential variable declarations
# Pre-declare variables that plugins will use to avoid global creation warnings

# Plugin-specific variables (pre-declared to avoid warnings)
typeset -ga ZSH_AUTOSUGGEST_STRATEGY
typeset -ga GLOBALIAS_FILTER_VALUES
typeset -g ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE
typeset -g FAST_HIGHLIGHT_MAXLENGTH

# Environment variables that plugins expect
typeset -g BUN_INSTALL="${BUN_INSTALL:-${XDG_DATA_HOME:-$HOME/.local/share}/bun}"
typeset -g DOTNET_CLI_HOME="${DOTNET_CLI_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/dotnet}"
typeset -g DOTNET_ROOT="${DOTNET_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/dotnet}"
typeset -g NVM_SCRIPT_SOURCE="${NVM_SCRIPT_SOURCE:-}"
typeset -g SSH_AGENT_PID="${SSH_AGENT_PID:-}"

## [essential-pre-plugin.autoloads] - Essential autoloads before plugins
# Critical autoloads that must be available before plugin loading

autoload -Uz add-zsh-hook
autoload -Uz vcs_info
autoload -Uz compinit
autoload -Uz bashcompinit

## [essential-pre-plugin.health-check] - Pre-plugin health verification
# Verify essential setup before plugins load

essential_pre_plugin_health_check() {
    local issues=()

    # Check essential commands
    for cmd in brew git; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            issues+=("Missing command: $cmd")
        fi
    done

    # Check essential directories
    for dir in "${ZDOTDIR:-$HOME}/.zsh" "$ABBR_TMPDIR"; do
        if [[ ! -d "$dir" ]]; then
            issues+=("Missing directory: $dir")
        fi
    done

    # Check fpath setup
    if [[ ${#fpath[@]} -lt 3 ]]; then
        issues+=("fpath appears incomplete (${#fpath[@]} entries)")
    fi

    if [[ ${#issues[@]} -gt 0 ]]; then
        echo "⚠️  Pre-plugin setup issues detected:" >&2
        printf '   - %s\n' "${issues[@]}" >&2
        return 1
    else
        [[ "$ZSH_DEBUG" == "1" ]] && echo "✅ Pre-plugin environment verified" >&2
        return 0
    fi
}

# Run health check
essential_pre_plugin_health_check

## [essential-pre-plugin.completion-trigger] - Trigger basic completion initialization
# Initialize basic completion system before plugins add their completions

# Only initialize if not already done
if [[ -z "$_ZSH_BASIC_COMPLETION_INITIALIZED" ]]; then
    # Basic compinit (plugins will enhance)
    compinit -d "$ZSH_COMPDUMP" -C  # -C skips security check for speed

    # Mark as initialized
    export _ZSH_BASIC_COMPLETION_INITIALIZED=1
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [essential-pre-plugin] Basic completion system initialized" >&2
fi

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [essential-pre-plugin] ✅ Essential pre-plugin setup completed successfully" >&2
[[ "$ZSH_DEBUG" == "1" ]] && echo "# [essential-pre-plugin] Environment ready for plugin loading" >&2
