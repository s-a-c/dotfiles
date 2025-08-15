# Fixed Post-Plugin Configuration
# This file is sourced after plugins are loaded
# Contains aliases, functions, options, key bindings, and tool integrations

# Set file type and editor options for this file
# vim: ft=zsh sw=4 ts=4 et nu rnu ai si

[[ -n "$ZSH_DEBUG" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
    # Add this check to detect errant file creation:
    if [[ -f "${ZDOTDIR:-$HOME}/2" ]] || [[ -f "${ZDOTDIR:-$HOME}/3" ]]; then
        echo "Warning: Numbered files detected - check for redirection typos" >&2
    fi
}

# Add Composer global vendor/bin to PATH if Composer is available
{
    [[ -n "$ZSH_DEBUG" ]] && echo "# [composer]" >&2

    if command -v composer >/dev/null 2>&1; then
        composer_home="$(composer config --global home 2>/dev/null)"
        if [[ -n "$composer_home" && -d "$composer_home/vendor/bin" ]]; then
            _path_prepend "$composer_home/vendor/bin"
        fi
        unset composer_home
    fi
}

# Platform-specific configurations
{
    [[ -n "$ZSH_DEBUG" ]] && echo "# [platform]" >&2
    case "$(uname -s)" in
    Darwin)
        # macOS-specific settings
        defaults write -g NSWindowShouldDragOnGesture -bool true 2>/dev/null || true
        defaults write NSGlobalDomain AppleHighlightColor -string "0.615686 0.823529 0.454902" 2>/dev/null || true
        ;;
    Linux)
        # Linux-specific setup if needed
        ;;
    MINGW32_NT*|MINGW64_NT*)
        # Windows setup if needed
        ;;
    esac
}

## [tools]  ## Language and Tool Specific Configurations
{
    [[ -n "$ZSH_DEBUG" ]] && echo "# [tools]" >&2

    ## [tools.augmentcode]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [tools.augmentcode.mcp]" >&2

        # MCP Environment Setup for AugmentCode
        builtin source "${HOME}/.mcp-environment.sh"
    }

    ## [tools.bob]  ## Bob Neovim version manager configuration
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [tools.bob]" >&2

        # Laravel/PHP development - safely remove bob alias if it exists
        if (( ${+aliases[bob]} )); then
            unalias bob
        fi

        export BOB_CONFIG=${XDG_CONFIG_HOME}/bob/config.json
        [[ -n "${commands[bob]}" ]] && {
            # Source bob environment if it exists
            if [[ -f "${XDG_DATA_HOME}/bob/env/env.sh" ]]; then
                builtin source "${XDG_DATA_HOME}/bob/env/env.sh"
            fi
            bob use nightly
            bob sync
            bob update --all
        }
    }

    ## [tools.bun]  ## bun completions
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [tools.bun]" >&2

        [[ -s "${XDG_DATA_HOME}/bun/_bun" ]] && {
            source "${XDG_DATA_HOME}/bun/_bun"
        }
    }

    ## [tools.docker]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [tools.docker]" >&2

        # The following lines have been added by Docker Desktop to enable Docker CLI completions.
        fpath=("${HOME}/.docker/completions" $fpath)
        #autoload -Uz compinit  # DISABLED - handled by main compinit
        #compinit               # DISABLED - handled by main compinit
    }

    ## [tools.gcp]  ## Google Cloud SDK
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [tools.gcp]" >&2

        # The next line updates PATH for the Google Cloud SDK.
        [[ -f "${XDG_DATA_HOME}/google-cloud-sdk/path.zsh.inc" ]] && {
            source "${XDG_DATA_HOME}/google-cloud-sdk/path.zsh.inc"
        };

        # The next line enables shell command completion for gcloud.
        [[ -f "${XDG_DATA_HOME}/google-cloud-sdk/completion.zsh.inc" ]] && {
            source "${XDG_DATA_HOME}/google-cloud-sdk/completion.zsh.inc"
        }
    }

    ## [tools.go]  ## Go language setup
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [tools.go]" >&2

        setup_go_environment() {
            # Set GOPATH if ~/go directory exists
            [[ -d "$HOME/go" ]] && export GOPATH="$HOME/go"

            # Find and set GOROOT
            local go_roots=(
                "/usr/local/opt/go/libexec"
                "/usr/local/opt/go"
                "/usr/local/go"
            )

            for goroot in "${go_roots[@]}"; do
                if [[ -d "$goroot" ]]; then
                    export GOROOT="$goroot"
                    break
                fi
            done

            # Add Go binaries to PATH
            [[ -n "$GOROOT" && -d "$GOROOT/bin" ]] && _path_prepend "$GOROOT/bin"
            [[ -n "$GOPATH" && -d "$GOPATH/bin" ]] && _path_prepend "$GOPATH/bin"
            [[ -d "$HOME/go/bin" ]] && _path_prepend "$HOME/go/bin"
        }
        setup_go_environment

        ## Clean up functions used only during setup
        unset -f setup_go_environment
    }

    ## [tools.herd.shell]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [tools.Herd]" >&2

        # Herd shell integration
        [[ -f "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh" ]] && {
            builtin source "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh"
        }
    }

    ## [tools.homebrew]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [tools.homebrew]" >&2

        [[ -n "${commands[brew]}" ]] && {
            eval "$(brew shellenv)"
        }
    }

    ## [tools.jj]  ## jj version control completion (if available)
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [tools.jj]" >&2

        [[ -n "${commands[jj]}" ]] && {
            builtin source <(COMPLETE=zsh jj) 2>/dev/null || true
        }
    }

    ## [tools.laravel]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [tools.laravel]" >&2

        # Laravel/PHP development - safely remove bob alias if it exists
        if (( ${+aliases[bob]} )); then
            unalias bob
        fi
    }

    ## [tools.lazyman]  ## Lazyman Neovim configuration
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [tools.lazyman]" >&2

        # Source the Lazyman shell initialization for aliases and nvims selector
        # shellcheck source=.config/nvim-Lazyman/.lazymanrc
        [ -f "${XDG_CONFIG_HOME}/nvim-Lazyman/.lazymanrc" ] && builtin source "${XDG_CONFIG_HOME}/nvim-Lazyman/.lazymanrc"

        # Source the Lazyman .nvimsbind for nvims key binding
        # shellcheck source=.config/nvim-Lazyman/.nvimsbind
        [ -f "${XDG_CONFIG_HOME}/nvim-Lazyman/.nvimsbind" ] && builtin source "${XDG_CONFIG_HOME}/nvim-Lazyman/.nvimsbind"
    }

    ## [tools.nvm]  ## Node.js version management (if nvm exists)
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [tools.nvm]" >&2

        [[ -d "$NVM_DIR" ]] && {
            # Load nvm lazily to improve startup time
            nvm() {
                unfunction nvm
                [[ -s "$NVM_DIR/nvm.sh" ]] && builtin source "$NVM_DIR/nvm.sh"
                [[ -s "$NVM_DIR/bash_completion" ]] && builtin source "$NVM_DIR/bash_completion"
                nvm "$@"
            }
        }
    }

    ## [tools.python]   ## Python development tools
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [tools.python]" >&2

        [[ -n "${commands[python3]}" ]] && {
            # Add Python user base to PATH
            python_user_base="$(python3 -m site --user-base 2>/dev/null)/bin"
            [[ -d "$python_user_base" ]] && _path_prepend "$python_user_base"
            unset python_user_base
        }

        [[ -n "${commands[uv]}" ]] && {
            eval "$(uv generate-shell-completion zsh)"
        }

        source "$HOME/.venv/bin/activate"
    }

    ## [tools.rio]  ## Rio terminal configuration
    [[ -n "${commands[rio]}" ]] && {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [tools.rio]" >&2

        export RIO_CACHE="${XDG_CACHE_HOME}/rio"
        export RIO_CONFIG="${XDG_CONFIG_HOME}/rio/config"

        # Install Rio terminfo if not present
        if ! infocmp rio &>/dev/null; then
            {
                tempfile=$(mktemp) &&
                curl -s -o "$tempfile" https://raw.githubusercontent.com/raphamorim/rio/main/misc/rio.terminfo &&
                sudo tic -xe rio "$tempfile" &&
                rm "$tempfile"
            } 2>/dev/null || true
        fi
    }

    ## [tools.rustup]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.rustup]" >&2

        [[ -z "${commands[rustup]}" ]] && {
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
        }

        ## configure rust environment
        [[ -s "$CARGO_HOME/env" ]] && source "$CARGO_HOME/env"

        [[ -n "${commands[rustup]}" ]] && {
            ## Only add Rustup installation to PATH, MANPATH, and INFOPATH if rustup is
            ## not already on the path, to prevent duplicate entries. This aligns with
            ## the behavior of the rustup installer.sh post-install steps.
            eval "$(rustup completions zsh)"
            unset RUSTUP_LOCATION
            [[ ! -n "${commands[rustc]}" ]] && {
                #echo "[zshrc] rustc not found, please install it from https://www.rust-lang.org/tools/install"
                echo "[zshrc] rustc not found, using rustup to install `stable`"
                rustup toolchain install stable
            }
            rustup default stable
            ## + rustup
            ## + avoid https://github.com/rust-analyzer/rust-analyzer/issues/4172
            ##
            ## NOTE: Has to be defined after PATH update to locate .cargo directory.
            [[ -n "${commands[rustc]}" ]] && export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"

            ## - autocomplete
            ## - cargo audit
            ## - cargo clippy
            ## - cargo edit
            ## - cargo fmt
            ## - cargo-nextest
            ## - rust-analyzer
            ## - frum
            ## - starship
            [[ -z "${commands[cargo]}" ]]           && rustup component add cargo
            [[ -z "${commands[cargo-audit]}" ]]     && cargo install cargo-audit --features=fix --locked
            [[ -z "${commands[cargo-clippy]}" ]]    && rustup component add clippy
            [[ -z "${commands[cargo-fmt]}" ]]       && rustup component add rustfmt
            [[ -z "${commands[cargo-nextest]}" ]]   && cargo install cargo-nextest
            [[ -z "${commands[cargo-upgrade]}" ]]   && cargo install cargo-edit
            [[ -z "${commands[deno]}" ]]            && cargo install deno --locked
            [[ -z "${commands[frum]}" ]]            && cargo install frum
            [[ -z "${commands[macchina]}" ]]        && cargo install macchina
            [[ -z "${commands[rnix-lsp]}" ]]        && cargo install rnix-lsp
            [[ -z "${commands[rust-analyzer]}" ]]   && rustup component add rust-analyzer
            [[ -z "${commands[starship]}" ]]        && cargo install starship --locked
        }

        # Rust/Cargo path setup
        [[ -d "$HOME/.cargo/bin" ]] && _path_prepend "$HOME/.cargo/bin"
    }

    ## [tools.sqlite]   ## SQLite configuration (macOS Homebrew)
    [[ "$(uname -s)" == "Darwin" ]] && {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [tools.sqlite]" >&2

        [[ -d "/opt/homebrew/opt/sqlite" ]] && {
            # SQLite is keg-only in Homebrew to avoid conflicts with macOS sqlite
            export SQLITE_ROOT="/opt/homebrew/opt/sqlite"
            _path_prepend "$SQLITE_ROOT/bin"

            # Set library and include paths for compilation
            export LDFLAGS="-L$SQLITE_ROOT/lib ${LDFLAGS}"
            export CPPFLAGS="-I$SQLITE_ROOT/include ${CPPFLAGS}"
            export PKG_CONFIG_PATH="$SQLITE_ROOT/lib/pkgconfig:${PKG_CONFIG_PATH}"
        }
    }

    ## [tools.ssh-agent]
    [[ -n "${commands[ssh-add]}" ]] && {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.ssh-agent]" >&2

        /usr/bin/ssh-add -q --apple-load-keychain --apple-use-keychain 2>/dev/null || true
    }

    ## [tools.starship]
    [[ -n "${commands[starship]}" ]] && {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.starship]" >&2

        eval "$(starship init zsh --print-full-init)" >/dev/null 2>&1
    }

    ## [tools.tldr]
    [[ -n "${commands[tldr]}" ]] && {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [tools.tldr]" >&2

        # tldr integration
        tldr-command-line() {
            # if there is no command typed, use the last command
            [[ -z "$BUFFER" ]] && zle up-history

            # if typed command begins with tldr, do nothing
            [[ "$BUFFER" = tldr\ * ]] && return

            # get command and possible subcommand
            # http://zsh.sourceforge.net/Doc/Release/Expansion.html#Parameter-Expansion-Flags
            local -a args
            args=(${${(Az)BUFFER}[1]} ${${(Az)BUFFER}[2]})

            BUFFER="tldr ${args[1]}"
        }

        zle -N tldr-command-line
        # Defined shortcut keys: [Esc]tldr
        bindkey "\e"tldr tldr-command-line
    }

    ## [tools.turso]]
    _path_prepend "${HOME}/.turso"

    ## [vivid]
    [[ -n "${commands[vivid]}" ]] && {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [tools.vivid]" >&2

        eval "$(vivid init zsh)"
        export LS_COLORS="$(vivid generate tokyonight-moon)"
        function _vivid_themes() {
            for theme in $(vivid themes); do
                echo "Theme: $theme"
                LS_COLORS=$(vivid generate $theme)
                \ls
                echo
            done
        }
    }

    ## [tools.wezterm]
    [[ -n "${commands[wezterm]}" ]] && {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [tools.wezterm]" >&2

        if ! infocmp wezterm &>/dev/null; then
            tempfile=$(mktemp) &&
                curl -o ${tempfile} https://raw.githubusercontent.com/wez/wezterm/main/termwiz/data/wezterm.terminfo &&
                sudo tic -xe wezterm ${tempfile} &&
                rm ${tempfile}
        fi
    }

    ## [tools.zoxide]   ## Zoxide integration (smart cd replacement)
    [[ -n "${commands[zoxide]}" ]] && {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [plugins.zoxide]" >&2

        eval "$(zoxide init zsh --hook pwd)"
    }
}


## Performance optimization: avoid redundant PATH operations
## Export PATH only once at the end
export PATH
