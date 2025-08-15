## #!/opt/homebrew/bin/zsh

##
## This file is sourced by zsh upon start-up. It should contain commands to set
## up aliases, functions, options, key bindings, etc.
##

# vim: ft=zsh sw=4 ts=4 et nu rnu ai si

[[ -n "$ZSH_DEBUG" ]] && printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2

## [pre-plugins]
{
    [[ -n "$ZSH_DEBUG" ]] && echo "# [pre-plugins]" >&2
    export HISTDUP=erase
    export HISTFILE="$ZDOTDIR/.zsh_history"         ## History filepath
    export HISTSIZE=1000000                         ## Maximum events for internal history
    export HISTTIMEFORMAT='%F %T %z %a %V '
    export SAVEHIST=1100000                         ## Maximum events in history file
}

## [compinit] - Improved version
{
    [[ -n "$ZSH_DEBUG" ]] && echo "# [compinit]" >&2

    # Check if we're in ZSH
    if [[ -z "$ZSH_VERSION" ]]; then
        echo "Warning: compinit setup requires ZSH" >&2
        return 1
    fi

    # Prevent multiple initialization
    if [[ -n "$_COMPINIT_LOADED" ]]; then
        [[ -n "$ZSH_DEBUG" ]] && echo "# compinit already loaded" >&2
        return 0
    fi

    ## Cache Completion Loading:
    # Add to .zshrc before plugin loading
    export SKIP_GLOBAL_COMPINIT=1  # Skip system compinit

    # Load compinit with improved error handling
    if ! autoload -Uz compinit; then
        echo "Error: Failed to load compinit" >&2
        return 1
    fi

    # Single, robust compinit call with proper error handling
    if [[ -n "$COMPINIT_INSECURE" ]]; then
        compinit -C -d "${ZDOTDIR:-$HOME}/.zcompdump" 2>/dev/null || {
            echo "compinit -C failed, trying secure mode" >&2
            compinit -d "${ZDOTDIR:-$HOME}/.zcompdump"
        }
    else
        compinit -d "${ZDOTDIR:-$HOME}/.zcompdump" 2>/dev/null || {
            echo "compinit failed, attempting recovery" >&2
            rm -f "${ZDOTDIR:-$HOME}/.zcompdump"*
            compinit -d "${ZDOTDIR:-$HOME}/.zcompdump"
        }
    fi

    # Mark as loaded
    export _COMPINIT_LOADED=1

    [[ -n "$ZSH_DEBUG" ]] && echo "# compinit initialization complete" >&2
}

## [builtins]
{
    [[ -n "$ZSH_DEBUG" ]] && echo "# [builtins]" >&2
    ## [builtins.colors]
    autoload -U colors && colors ## Load Colors

    ## [builtins.bindkey]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [builtins.bindkey]" >&2
        bindkey -e
        bindkey '^p' history-search-backward
        bindkey '^n' history-search-forward
        bindkey '^[w' kill-region

        bindkey "^[[3~" delete-char

        ## Complete Configuration Block (Choose Based on Your Mode)
        ## For Emacs Mode Users:
        # Windows/Linux style Home and End keys - Emacs Mode
        bindkey -M emacs "^[[H"    beginning-of-line    # Home
        bindkey -M emacs "^[[F"    end-of-line          # End
        bindkey -M emacs "^[[1~"   beginning-of-line    # Home (alternative)
        bindkey -M emacs "^[[4~"   end-of-line          # End (alternative)
        bindkey -M emacs "^[[7~"   beginning-of-line    # Home (some terminals)
        bindkey -M emacs "^[[8~"   end-of-line          # End (some terminals)
        bindkey -M emacs "^[OH"    beginning-of-line    # Home (xterm app mode)
        bindkey -M emacs "^[OF"    end-of-line          # End (xterm app mode)
        # With modifiers
        bindkey -M emacs "^[[1;5H" beginning-of-buffer-or-history  # Ctrl+Home
        bindkey -M emacs "^[[1;5F" end-of-buffer-or-history        # Ctrl+End
        bindkey -M emacs "^[[1;2H" vi-beginning-of-line            # Shift+Home
        bindkey -M emacs "^[[1;2F" vi-end-of-line                  # Shift+End
        bindkey -M emacs "^[[1;3H" beginning-of-line               # Alt+Home
        bindkey -M emacs "^[[1;3F" end-of-line                     # Alt+End#

        ## For Vi Mode Users:
        # Windows/Linux style Home and End keys - Vi Insert Mode
        bindkey -M viins "^[[H"    beginning-of-line    # Home
        bindkey -M viins "^[[F"    end-of-line          # End
        bindkey -M viins "^[[1~"   beginning-of-line    # Home (alternative)
        bindkey -M viins "^[[4~"   end-of-line          # End (alternative)
        bindkey -M viins "^[[7~"   beginning-of-line    # Home (some terminals)
        bindkey -M viins "^[[8~"   end-of-line          # End (some terminals)
        bindkey -M viins "^[OH"    beginning-of-line    # Home (xterm app mode)
        bindkey -M viins "^[OF"    end-of-line          # End (xterm app mode)
        # With modifiers
        bindkey -M viins "^[[1;5H" beginning-of-buffer-or-history  # Ctrl+Home
        bindkey -M viins "^[[1;5F" end-of-buffer-or-history        # Ctrl+End
        bindkey -M viins "^[[1;2H" vi-beginning-of-line            # Shift+Home
        bindkey -M viins "^[[1;2F" vi-end-of-line                  # Shift+End
        bindkey -M viins "^[[1;3H" beginning-of-line               # Alt+Home
        bindkey -M viins "^[[1;3F" end-of-line                     # Alt+End
    }

    ## [builtins.smarturls]
    autoload -Uz url-quote-magic
    zle -N self-insert url-quote-magic
}

## [plugins]
{
    [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins]" >&2

    ## [plugins.zsh-abbr]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.zsh-abbr]" >&2

        ## [plugins.zsh-abbr.environment]
        {
            [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.zsh-abbr.environment]" >&2

            export ABBR_AUTOLOAD=1                    # Auto-load abbreviations on startup
            export ABBR_DEFAULT_BINDINGS=1            # Enable default key bindings
            export ABBR_DEBUG=0                       # Disable debug output (set to 1 for debugging)
            export ABBR_DRY_RUN=0                     # Disable dry-run mode
            export ABBR_FORCE=0                       # Don't force operations without confirmation
            export ABBR_QUIET=1                       # Enable quiet mode (less verbose output)
            export ABBR_QUIETER=1                     # Enable quieter mode (minimal output)

            # Storage and temporary files
            export ABBR_TMPDIR="${XDG_RUNTIME_DIR:-/tmp}/zsh-abbr"
            mkdir -p "${ABBR_TMPDIR}"

            # Advanced configuration
            export ABBR_PRECMD_LOGS=0                 # Disable precmd logging
            export ABBR_SET_EXPANSION_CURSOR=1        # Enable cursor positioning after expansion
            export ABBR_SET_LINE_CURSOR=1             # Set cursor position in line

            # Color output (set NO_COLOR to disable colors)
            unset NO_COLOR
        }

        ## [plugins.zsh-abbr.widgets]   ## Pre-register widgets to prevent syntax highlighting warnings
        {
            [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.zsh-abbr.widgets]" >&2

            # Create placeholder widgets that will be properly defined by zsh-abbr later
            # shellcheck disable=SC1073
            abbr-expand() { zle .self-insert }
            abbr-expand-and-space() { zle .self-insert }
            abbr-expand-and-accept() { zle .self-insert }
            abbr-expand-and-insert() { zle .self-insert }

            zle -N abbr-expand
            zle -N abbr-expand-and-space
            zle -N abbr-expand-and-accept
            zle -N abbr-expand-and-insert
        }
    }

    ## [plugins.zsh-alias-tips]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.zsh-alias-tips]" >&2

        export ZSH_PLUGINS_ALIAS_TIPS_REVEAL=1
        #export ZSH_PLUGINS_ALIAS_TIPS_REVEAL_EXCLUDES=(_ ll vi)
        export ZSH_PLUGINS_ALIAS_TIPS_REVEAL_TEXT="Alias tip: "
    }

    ## [plugins.zsh-async]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.zsh-async]" >&2

        export ASYNC_PROMPT="async> "
        export ASYNC_SHOW_ON_COMMAND=1
        export ASYNC_SHOW_PID=1
        export ASYNC_SHOW_TIME=1
        export ASYNC_SHOW_WAIT=1
    }

    ## [plugins.zsh-autopair]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.zsh-autopair]" >&2

        typeset -gA AUTOPAIR_PAIRS
        AUTOPAIR_PAIRS+=("<" ">")
    }

    ## [plugins.zsh-autosuggestions]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.zsh-autosuggestions]" >&2

        export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"
        export ZSH_AUTOSUGGEST_USE_ASYNC=1

        ## [plugins.zsh-autosuggestions-abbreviations-strategy]
        ZSH_AUTOSUGGEST_STRATEGY=( abbreviations $ZSH_AUTOSUGGEST_STRATEGY )
    }

    ## [plugins.zsh-defer]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.zsh-defer]" >&2

        export ZSH_DEFER_PROMPT="defer> "
        export ZSH_DEFER_SHOW_ON_COMMAND=1
        export ZSH_DEFER_SHOW_PID=1
        export ZSH_DEFER_SHOW_TIME=1
        export ZSH_DEFER_SHOW_WAIT=1

        # Defer non-critical commands for faster startup
        zsh-defer -c 'autoload -U compinit; compinit' 2>/dev/null || autoload -U compinit; compinit
    }

    ## [plugins.zsh-navigation-tools]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.zsh-navigation-tools]" >&2

        # Navigation tools configuration
        export ZNT_HISTORY_ACTIVE_TEXT="reverse"
        export ZNT_HISTORY_NLIST_COLORING_PATTERN="*"
        export ZNT_BUFFER_ACTIVE_TEXT="reverse"

        # Key bindings
        zle -N znt-history-widget
        bindkey '^R' znt-history-widget 2>/dev/null || true
    }

    ## [plugins.brew]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.brew]" >&2

        if [[ ! -n "${commands[brew]}" ]]; then
            #if (( ! $+commands[brew] )); then
            if [[ -n "${BREW_LOCATION}" ]]; then
                if [[ ! -x "${BREW_LOCATION}" ]]; then
                    echo "[zshrc] ${BREW_LOCATION} is not executable"
                    return
                fi
            elif [[ -x /opt/homebrew/bin/brew ]]; then
                BREW_LOCATION="/opt/homebrew/bin/brew"
            elif [[ -x /usr/local/bin/brew ]]; then
                BREW_LOCATION="/usr/local/bin/brew"
            elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
                BREW_LOCATION="/home/linuxbrew/.linuxbrew/bin/brew"
            elif [[ -x "${HOME}/.linuxbrew/bin/brew" ]]; then
                BREW_LOCATION="${HOME}/.linuxbrew/bin/brew"
            else
                return
            fi

            ## Only add Homebrew installation to PATH, MANPATH, and INFOPATH if brew is
            ## not already on the path, to prevent duplicate entries. This aligns with
            ## the behavior of the brew installer.sh post-install steps.
            eval "$(brew shellenv)"
            unset BREW_LOCATION
        fi
        eval "$(brew shellenv)"

        [[ -z "${HOMEBREW_PREFIX}" ]] && {
            ## Maintain compatability with potential custom user profiles, where we had
            ## previously relied on always sourcing shellenv. OMZ plugins should not rely
            ## on this to be defined due to out of order processing.
            export HOMEBREW_PREFIX="$(brew --prefix)"
        }
        export HOMEBREW_AUTO_UPDATE_SECS="86400"

        # Remove or disable Nix's zsh function path from your config
        # In your zsh configuration, ensure you're using Homebrew's completions:
        [[ -d "${HOMEBREW_PREFIX}/share/zsh/site-functions" ]] && {
            # Remove any existing Homebrew site-functions from fpath to avoid duplicates
            fpath=(${fpath:#${HOMEBREW_PREFIX}/share/zsh/site-functions})

            # Explicitly place Homebrew functions at the FRONT of fpath array
            fpath=("${HOMEBREW_PREFIX}/share/zsh/site-functions" ${fpath[@]})

            # Export FPATH with Homebrew at the front for any tools that use FPATH directly
            export FPATH="${HOMEBREW_PREFIX}/share/zsh/site-functions:${FPATH}"

            # Initialize completion system with Homebrew functions prioritized
            autoload -Uz compinit
            compinit
        }

        function brews() {
            local formulae="$(brew leaves | xargs brew deps --installed --for-each)"
            local casks="$(brew list --cask 2>/dev/null)"

            local lightblue="$(tput setaf 4)"
            local bold="$(tput bold)"
            local off="$(tput sgr0)"

            echo "${lightblue}==>${off} ${bold}Formulae${off}"
            echo "${formulae}" | sed "s/^\(.*\):\(.*\)$/\1${lightblue}\2${off}/"
            echo "\n${lightblue}==>${off} ${bold}Casks${off}\n${casks}"
        }

        [[ -n "${HOMEBREW_PREFIX}" ]] && {
            ## A note on WASM and LLVM binaries #
            ## In order to compile for WASM, Odin calls out to wasm-ld for linking.
            ## This requires it to be available through your $PATH.
            ## By default, brew does not add any of LLVM's binaries to your $PATH and you will need to
            ## symlink it to a place where it is able to be found.
            ## You can symlink it to /usr/local/bin by doing ln -s $(brew --prefix llvm)/bin/wasm-ld /usr/local/bin/wasm-ld.
            ##
            ## Alternatively, you can add the entire $(brew --prefix llvm)/bin to your $PATH, but brew does not recommend it.

            #_field_prepend PATH "${HOMEBREW_PREFIX}/sbin"
            _path_prepend "${HOMEBREW_PREFIX}/sbin"
            #_field_prepend PATH "${HOMEBREW_PREFIX}/bin"
            _path_prepend "${HOMEBREW_PREFIX}/bin"
        }
    }

    ## [plugins.bullet-train]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.bullet-train]" >&2

        # Bullet train configuration
        export BULLETTRAIN_PROMPT_CHAR="$"
        export BULLETTRAIN_PROMPT_ORDER=(
            time
            status
            custom
            context
            dir
            screen
            perl
            ruby
            virtualenv
            nvm
            aws
            go
            rust
            elixir
            git
            hg
            cmd_exec_time
            # context
            # dir
            # git
            # status
            # time
            # vi-mode
            # exec_time
        )
    }

    ## [plugins.bun]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.bun]" >&2

        export BUN_INSTALL=${BUN_INSTALL:="${XDG_DATA_HOME}/bun"}
        _path_prepend "${BUN_INSTALL}/bin"
    }

    ## [plugins.carapace]   ## Carapace completion system
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.carapace]" >&2

        # Carapace configuration
        export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
        zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
    }

    ## [plugins.colorize]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.colorize]" >&2

        # Colorize configuration
        export ZSH_COLORIZE_CHROMA_FORMATTER="terminal256"
        export ZSH_COLORIZE_STYLE="perldoc"
        export ZSH_COLORIZE_TOOL="chroma"
    }

    ## [plugins.composer]
    _path_prepend "${XDG_CONFIG_HOME}/composer/vendor/bin"

    ## [plugins.deno]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.deno]" >&2

        export DENO_INSTALL="${XDG_DATA_HOME}/deno"
        mkdir -p "${DENO_INSTALL}/bin"
        _path_prepend "${DENO_INSTALL}/bin"
    }

    ## [plugins.desk]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.desk]" >&2

        export DESK_TEMPLATES_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/desk"
        export DESK_DESKDIR="${XDG_DATA_HOME:-${HOME}/.local/share}/desk"
        export DESK_DESKSET_DIR="${DESK_DESKDIR}"  # Backwards compatible
    }

## [plugins.diff-so-fancy]
{
    [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.diff-so-fancy]" >&2

    #export GIT_PAGER='diff-so-fancy | less --tabs=4 -RFX'

    ## Configure git to use diff-so-fancy for all diff output:
    git config --global core.pager "diff-so-fancy | less --tabs=4 -RF"
    git config --global interactive.diffFilter "diff-so-fancy --patch"

    ## Improved colors for the highlighted bits
    ## The default Git colors are not optimal. The colors used for the screenshot above were:
    git config --global color.ui true

    git config --global color.diff-highlight.oldNormal    "red bold"
    git config --global color.diff-highlight.oldHighlight "red bold 52"
    git config --global color.diff-highlight.newNormal    "green bold"
    git config --global color.diff-highlight.newHighlight "green bold 22"

    git config --global color.diff.meta       "11"
    git config --global color.diff.frag       "magenta bold"
    git config --global color.diff.func       "146 bold"
    git config --global color.diff.commit     "yellow bold"
    git config --global color.diff.old        "red bold"
    git config --global color.diff.new        "green bold"
    git config --global color.diff.whitespace "red reverse"
}

    ## [plugins.direnv]
    eval "$(direnv hook zsh)" 2>/dev/null || true

    ## [plugins.docker]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.docker]" >&2

        export DOCKER_CONFIG="${XDG_CONFIG_HOME}/docker"
        zstyle ':completion:*:*:docker:*' option-stacking yes
        zstyle ':completion:*:*:docker-*:*' option-stacking yes

        #_path_prepend "${HOME}/.docker/bin"
    }

    ## [plugins.dotnet]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.dotnet]" >&2

        export DOTNET_CLI_FORCE_UTF8_ENCODING="true"
        export DOTNET_CLI_HOME="${DOTNET_CLI_HOME:="${XDG_DATA_HOME}/dotnet"}"
        export DOTNET_CLI_TELEMETRY_OPTOUT="true"
        export DOTNET_ROOT="${DOTNET_ROOT:=/usr/local/share/dotnet}"
        export DOTNET_SYSTEM_CONSOLE_ALLOW_ANSI_COLOR_REDIRECTION="true"

        _path_prepend "${DOTNET_CLI_HOME}/tools"
    }

    ## [plugins.emacs]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.emacs]" >&2

        # Emacs configuration
        export EMACS_HOME="${XDG_CONFIG_HOME}/emacs"
        export EMACS_SERVER_NAME="emacs-server"

        _path_prepend ${XDG_CONFIG_HOME}/emacs/bin
    }

    ## [plugins.enhancd]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.enhancd]" >&2

        # enhancd configuration
        export ENHANCD_COMMAND='cd'
        export ENHANCD_DOT_ARG='..'
        export ENHANCD_DOT_SHOW_FULLPATH=1
        export ENHANCD_DOT_SHOW_HIDDEN=1
        export ENHANCD_FILTER="fzf --height 40%:fzy"
        export ENHANCD_HYPHEN_ARG='-'
        export ENHANCD_USE_ABBREV="${ENHANCD_USE_ABBREV:-true}"
    }

    ## [plugins.evalcache]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.evalcache]" >&2

        export ZSH_EVALCACHE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/zsh-evalcache"
    }

    ## [plugins.fast-syntax-highlighting]
    {
        # Load custom theme if available
        typeset -gxA FAST_HIGHLIGHT_STYLES
        FAST_HIGHLIGHT_STYLES[command]='fg=green,bold'
        FAST_HIGHLIGHT_STYLES[path]='fg=blue,bold'
        FAST_HIGHLIGHT_STYLES[variable]='fg=cyan'

        export FAST_WORK_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/fsh"

        # Configure highlighting options
        typeset -gxA FAST_HIGHLIGHT
        FAST_HIGHLIGHT[chroma-docker]=1
        FAST_HIGHLIGHT[chroma-git]=1
        FAST_HIGHLIGHT[chroma-man]=1
        FAST_HIGHLIGHT[chroma-ssh]=1
        # Configure to ignore unknown widgets and suppress messages
        FAST_HIGHLIGHT[no_theme_messages]=1
        FAST_HIGHLIGHT[no_unknown_widget_warning]=1
        FAST_HIGHLIGHT[use_brackets]=1
    }

    ## [plugins.forgit]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.forgit]" >&2

        export FORGIT_NO_ALIASES="1"
        export FORGIT_LOG_GRAPH_ENABLE="true"
        export FORGIT_COPY_CMD="pbcopy"
    }

    ## [plugins.fzf]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.fzf]" >&2

        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
        export FZF_ALT_C_OPTS='--preview-window=right:60%:wrap'
        export FZF_BASE="${XDG_DATA_HOME}/fzf"
        export FZF_COMPLETION_TRIGGER='**'
        export FZF_CTRL_T_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_OPTS='--preview-window=right:60%:wrap'
        #export FZF_DEFAULT_COMMAND='rg --files  --hidden --iglob="!.git" --line-number'
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_DEFAULT_OPTS='--ansi --bind=ctrl-j:down,ctrl-k:up,ctrl-h:preview-up,ctrl-l:preview-down --border --color --cycle --height 40% --ignore-case --layout=reverse --multi --nth=2 --preview="bat --color=always --line-range :500 --style=grid,header,numbers {}" --preview-window=right:60%:wrap --prompt="Q> " --wrap'
        export FZF_PATH="${XDG_DATA_HOME}/fzf"
        export FZF_TMUX_HEIGHT=40%
        export FZF_TMUX_OPTS='--ansi --border --color --cycle --height 40% --ignore-case --layout=reverse --multi --nth=2 --preview="bat --color=always --line-range :500 --style=grid,header,numbers {}" --preview-window=right:60%:wrap --prompt="Q> " --wrap'
        export FZF_TMUX=1
        export LESSOPEN='| lessfilter-fzf %s'

        # fzf configuration for better integration
        export FZF_BASE="${HOMEBREW_PREFIX}/opt/fzf"
        export FZF_CTRL_R_OPTS="--sort --exact"

        # Use fd for file search if available
        if command -v fd >/dev/null 2>&1; then
            export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
            export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
        fi

        # Better preview with bat if available
        if command -v bat >/dev/null 2>&1; then
            export FZF_CTRL_T_OPTS="$FZF_CTRL_T_OPTS --preview 'bat --color=always --line-range=:500 {}'"
        fi
    }

    ## [plugins.gem]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.gem]" >&2

        # Ruby gem configuration
        export GEM_HOME="${XDG_DATA_HOME}/gem/ruby/3.3.0"
        export GEM_PATH="${GEM_HOME}/bin"

        _path_prepend "${GEM_HOME}/bin"
    }

    ## [plugins.gh]
    export GH_CONFIG_DIR="${XDG_CONFIG_HOME}/gh"

    ## [plugins.git]
    {
        # Git plugin configuration
        export GIT_AUTHOR_NAME="$(git config --get user.name 2>/dev/null || echo 'Unknown')"
        export GIT_AUTHOR_EMAIL="$(git config --get user.email 2>/dev/null || echo 'unknown@example.com')"
        export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
        export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
    }

    ## [plugins.globalias]
    {
        # Global alias expansion configuration
        GLOBALIAS_FILTER_VALUES=(
            ls
            ll
            la
            cd
            git
        )
    }

    ## [plugins.golang]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.golang]" >&2

        # Golang configuration
        export GOPATH="${XDG_DATA_HOME}/go"
        export GOROOT="${HOMEBREW_PREFIX}/opt/go/libexec"
        _path_prepend "${GOPATH}/bin"
    }

    ## [plugins.gpg-agent]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.gpg-agent]" >&2

        # GPG agent configuration
        export GPG_AGENT_INFO_FILE="${XDG_RUNTIME_DIR}/gpg-agent-info"
        eval "$(ssh-agent)"
    }

    ## [plugins.nvm]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.nvm]" >&2

        # Configure NVM for faster loading
        export NVM_AUTO_USE=true
        export NVM_LAZY_LOAD=true
        export NVM_COMPLETION=true

        # Custom NVM directory if different from default
        if [[ -d "${HOME}/Library/Application Support/Herd/config/nvm" ]]; then
            export NVM_DIR="${HOME}/Library/Application Support/Herd/config/nvm"
        elif [[ -d "${HOMEBREW_PREFIX}/opt/nvm" ]]; then
            export NVM_DIR="${HOMEBREW_PREFIX}/opt/nvm"
        elif [[ -d "${HOME}/.nvm" ]]; then
            export NVM_DIR="${HOME}/.nvm"
        fi

        zstyle ':omz:plugins:nvm' lazy yes
        zstyle ':omz:plugins:nvm' lazy-cmd eslint prettier typescript
        zstyle ':omz:plugins:nvm' autoload yes
    }

    ## [plugins.perl]
    export PERLBREW_ROOT="${XDG_DATA_HOME}/perl5/perlbrew"

    ## [plugins.pip]
    export PIPENV_VENV_IN_PROJECT=1


    ## [plugins.powerlevel10k]
    export POWERLEVEL9K_MODE='nerdfont-complete'
    export POWERLEVEL9K_DISABLE_HOT_RELOAD=false

    ## [plugins.rust]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.rust]" >&2

        # Rust configuration
        export RUSTUP_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/rustup"
        export CARGO_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/cargo"
        export CARGO_TARGET_DIR="${CARGO_HOME}/target"
        export RUSTUP_LOCATION="${CARGO_HOME}/bin/rustup"
        _path_prepend "${CARGO_HOME}/bin"
    }

    ## [plugins.screen]
    export SCREENRC="${XDG_CONFIG_HOME}/screen/screenrc"

    ## [plugins.ssh-agent]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.ssh-agent]" >&2
        # SSH agent configuration
        export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.sock"
        export SSH_AGENT_PID="${XDG_RUNTIME_DIR}/ssh-agent.pid"

        eval "$(ssh-agent)"
        zstyle :omz:plugins:ssh-agent agent-forwarding yes
        zstyle :omz:plugins:ssh-agent autoload yes
        zstyle :omz:plugins:ssh-agent identities ~/.ssh/id_ed25519
        zstyle :omz:plugins:ssh-agent lazy yes
        zstyle :omz:plugins:ssh-agent quiet yes
        zstyle :omz:plugins:ssh-agent ssh-add-args --apple-load-keychain --apple-use-keychain
    }

    ## [plugins.starship]
    {
        # Starship prompt configuration
        export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-${HOME}/.config}/starship.toml"
        export STARSHIP_CACHE="${XDG_CACHE_HOME:-${HOME}/.cache}/starship"

        export ZSH_THEME="jonathan"
    }

    ## [plugins.thefuck]
    {
        # thefuck configuration
        export THEFUCK_REQUIRE_CONFIRMATION=false
        export THEFUCK_WAIT_COMMAND=10
        export THEFUCK_NO_COLORS=false
    }

    ## [plugins.vi-mode]
    {
        # Vi mode configuration
        export VI_MODE_SET_CURSOR=true
        export VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
        export VI_MODE_CURSOR_NORMAL=6  # Steady bar
        export VI_MODE_CURSOR_VISUAL=2  # Block
        export VI_MODE_CURSOR_INSERT=6  # Steady bar
        export VI_MODE_CURSOR_OPPEND=0  # Blinking block
    }

    ## [plugins.you-should-use]
    {
        # you-should-use plugin configuration
        export YSU_HARDCORE=1
        export YSU_MESSAGE_POSITION="after"
        export YSU_MESSAGE_FORMAT="$(tput setaf 1)Hey! I found this %alias_type for %command: %alias$(tput sgr0)"
        export YSU_IGNORE_ALIASES=(
            g
            ll
            la
            please
        )
    }

    ## [plugins.zoxide]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.zoxide]" >&2

        export _ZO_DATA_DIR="${XDG_DATA_HOME}/zoxide"
        export _ZO_ECHO=1
        export _ZO_RESOLVE_SYMLINKS=1
    }
}

## [tools]
{
    [[ -n "$ZSH_DEBUG" ]] && echo "# [tools]" >&2

    ## [tools.console-ninja]
    _path_prepend "${HOME}/.console-ninja/.bin"

    ## [tools.herd]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [tools.Herd]" >&2

        # Herd configuration
        export HERD_APP="/Applications/Herd.app"
        export HERD_TOOLS_HOME="${HOME}/Library/Application Support/Herd"
        export HERD_TOOLS_BIN="${HERD_HOME}/bin"
        export HERD_TOOLS_CONFIG="${HERD_HOME}/config"

        # Herd injected PHP 8.2 configuration.
        export HERD_PHP_82_INI_SCAN_DIR="${HERD_TOOLS_CONFIG}/php/82/"
        # Herd injected PHP 8.3 configuration.
        export HERD_PHP_83_INI_SCAN_DIR="${HERD_TOOLS_CONFIG}/php/83/"
        # Herd injected PHP 8.4 configuration.
        export HERD_PHP_84_INI_SCAN_DIR="${HERD_TOOLS_CONFIG}/php/84/"
        # Herd injected PHP 8.5 configuration.
        export HERD_PHP_85_INI_SCAN_DIR="${HERD_TOOLS_CONFIG}/php/85/"

        export NVM_DIR="${HERD_TOOLS_CONFIG}/nvm"

        _path_prepend "${HERD_TOOLS_BIN}" "${HERD_TOOLS_HOME}"
    }

    ## [tools.lmstudio]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [tools.lmstudio]" >&2

        # Added by LM Studio CLI (lms)
        _path_append "${HOME}/.lmstudio/bin"
    }

    ## [tools.pnpm]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [tools.pnpm]" >&2

        export PNPM_HOME="${XDG_DATA_HOME}/pnpm"
        _path_prepend "$PNPM_HOME"
    }
}

## [functions]
{
    ## Path manipulation functions
    _path_append() {
        if [[ -d "$1" ]] && [[ ":$PATH:" != *":$1:"* ]]; then
            PATH="${PATH:+"$PATH:"}$1"
        fi
    }

    _path_prepend() {
        if [[ -d "$1" ]] && [[ ":$PATH:" != *":$1:"* ]]; then
            PATH="$1${PATH:+":$PATH"}"
        fi
    }

    _path_remove() {
        PATH=$(echo ":$PATH:" | sed "s|:$1:|:|g" | sed 's/^://;s/:$//')
    }

    ## Utility functions
    mkcd() {
        if [[ $# -ne 1 ]]; then
            echo "Usage: mkcd <directory>"
            return 1
        fi
        mkdir -p "$1" && cd "$1"
    }

    extract() {
        if [[ -z "$1" ]]; then
            echo "Usage: extract <archive>"
            return 1
        fi

        if [[ -f "$1" ]]; then
            case "$1" in
                *.tar.bz2)   tar xjf "$1"     ;;
                *.tar.gz)    tar xzf "$1"     ;;
                *.bz2)       bunzip2 "$1"     ;;
                *.rar)       unrar x "$1"     ;;
                *.gz)        gunzip "$1"      ;;
                *.tar)       tar xf "$1"      ;;
                *.tbz2)      tar xjf "$1"     ;;
                *.tgz)       tar xzf "$1"     ;;
                *.zip)       unzip "$1"       ;;
                *.Z)         uncompress "$1"  ;;
                *.7z)        7z x "$1"        ;;
                *)           echo "'$1' cannot be extracted via extract()" ;;
            esac
        else
            echo "'$1' is not a valid file"
            return 1
        fi
    }

    ## System information
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
    }

    ## Network utilities
    myip() {
        echo "Local IP addresses:"
        ip addr show 2>/dev/null | grep -Po 'inet \K[\d.]+'
        echo
        echo "External IP address:"
        curl -s ifconfig.me
        echo
    }

    ## Process utilities
    psgrep() {
        if [[ -z "$1" ]]; then
            echo "Usage: psgrep <process_name>"
            return 1
        fi
        ps aux | grep -v grep | grep -i "$1"
    }

    kill9() {
        if [[ -z "$1" ]]; then
            echo "Usage: kill9 <process_name>"
            return 1
        fi
        pkill -9 -f "$1"
    }

    ## File utilities
    backup() {
        if [[ -z "$1" ]]; then
            echo "Usage: backup <file>"
            return 1
        fi
        cp "$1"{,.bak.$(date +%Y%m%d_%H%M%S)}
    }

    ## Development utilities
    serve() {
        local port="${1:-8000}"
        if command -v python3 >/dev/null 2>&1; then
            python3 -m http.server "$port"
        elif command -v python2 >/dev/null 2>&1; then
            python2 -m SimpleHTTPServer "$port"
        else
            echo "Python not found"
            return 1
        fi
    }

    # Function to display help using bat with specific formatting
    batHelp() {
        bat --plain --language=help "$@"
    }

    function help() {
        '$@' --help 2>&1 | bathelp
    }

    ## Git utilities
    gitlog() {
        git log --oneline --graph --decorate --all
    }

    gitstatus() {
        git status --short --branch
    }

    gitclean() {
        git clean -fd
        git checkout -- .
    }

    function nvimvenv {
      if [[ -e "$VIRTUAL_ENV" && -f "$VIRTUAL_ENV/bin/activate" ]]; then
        source "$VIRTUAL_ENV/bin/activate"
        command nvim "$@"
        deactivate
      else
        command nvim "$@"
      fi
    }
}
