#!/usr/bin/env zsh
# Tool Configuration - POST-PLUGIN PHASE
# Comprehensive tool-specific configuration from refactored zsh setup
# This file consolidates development tool environments and configurations

[[ "$ZSH_DEBUG" == "1" ]] && {
        zf::debug "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
    zf::debug "# [tool-configs] Setting up development tool configurations"
}

## [tools.bun] - JavaScript runtime and package manager
{
    zf::debug "# [tools.bun]"

    export BUN_INSTALL="${BUN_INSTALL:-${XDG_DATA_HOME:-$HOME/.local/share}/bun}"
    _path_prepend "${BUN_INSTALL}/bin"
}

## [tools.deno] - JavaScript/TypeScript runtime
{
    zf::debug "# [tools.deno]"

    export DENO_INSTALL="${XDG_DATA_HOME:-${HOME}/.local/share}/deno"
    mkdir -p "${DENO_INSTALL}/bin" 2>/dev/null
    _path_prepend "${DENO_INSTALL}/bin"
}

## [tools.dotnet] - .NET development platform
{
    zf::debug "# [tools.dotnet]"

    export DOTNET_CLI_FORCE_UTF8_ENCODING="true"
    export DOTNET_CLI_HOME="${DOTNET_CLI_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/dotnet}"
    export DOTNET_CLI_TELEMETRY_OPTOUT="true"
    export DOTNET_ROOT="${DOTNET_ROOT:-/usr/local/share/dotnet}"
    export DOTNET_SYSTEM_CONSOLE_ALLOW_ANSI_COLOR_REDIRECTION="true"

    _path_prepend "${DOTNET_CLI_HOME}/tools"
}

## [tools.golang] - Go programming language
{
    zf::debug "# [tools.golang]"

    export GOPATH="${XDG_DATA_HOME:-${HOME}/.local/share}/go"
    export GOROOT="${HOMEBREW_PREFIX}/opt/go/libexec"
    _path_prepend "${GOPATH}/bin"
}

## [tools.rust] - Rust programming language
{
    zf::debug "# [tools.rust]"

    export RUSTUP_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/rustup"
    export CARGO_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/cargo"
    export CARGO_TARGET_DIR="${CARGO_HOME}/target"
    export RUSTUP_LOCATION="${CARGO_HOME}/bin/rustup"
    _path_prepend "${CARGO_HOME}/bin"
}

## [tools.gem] - Ruby gem system
{
    zf::debug "# [tools.gem]"

    export GEM_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/gem/ruby/3.3.0"
    export GEM_PATH="${GEM_HOME}/bin"
    _path_prepend "${GEM_HOME}/bin"
}

## [tools.pnpm] - Node.js package manager
{
    zf::debug "# [tools.pnpm]"

    export PNPM_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/pnpm"
    _path_prepend "$PNPM_HOME"
}

## [tools.nvm] - Node.js version manager
# DISABLED: Now handled by pre-plugin configuration + Oh My Zsh NVM plugin
# See: ~/.zshrc.pre-plugins.d/20_23-nvm-config.zsh
# And: zgenom ohmyzsh plugins/nvm in ~/.zshrc.add-plugins.d/010-add-plugins.zsh
# {
#     zf::debug "# [tools.nvm]"
#
#     export NVM_AUTO_USE=true
#     export NVM_LAZY_LOAD=true
#     export NVM_COMPLETION=true
#
#     # Custom NVM directory detection
#     if [[ -d "${HOME}/Library/Application Support/Herd/config/nvm" ]]; then
#         export NVM_DIR="${HOME}/Library/Application Support/Herd/config/nvm"
#     elif [[ -d "${HOMEBREW_PREFIX}/opt/nvm" ]]; then
#         export NVM_DIR="${HOMEBREW_PREFIX}/opt/nvm"
#     elif [[ -d "${HOME}/.nvm" ]]; then
#         export NVM_DIR="${HOME}/.nvm"
#     fi
#
#     # Lazy load nvm for faster startup
#     [[ -d "$NVM_DIR" ]] && {
#         nvm() {
#             unfunction nvm
#             [[ -s "$NVM_DIR/nvm.sh" ]] && builtin source "$NVM_DIR/nvm.sh"
#             [[ -s "$NVM_DIR/bash_completion" ]] && builtin source "$NVM_DIR/bash_completion"
#             nvm "$@"
#         }
#     }
# }

## [tools.fzf] - Fuzzy finder
{
    zf::debug "# [tools.fzf]"

    export FZF_BASE="${HOMEBREW_PREFIX}/opt/fzf"
    export FZF_COMPLETION_TRIGGER='**'
    export FZF_TMUX_HEIGHT=40%
    export FZF_TMUX=1
    export LESSOPEN='| lessfilter-fzf %s'

    # Default commands with fd if available
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND='fd --type f --hidden --follow --exclude .git'
    fi

    # Enhanced options with bat integration
    export FZF_DEFAULT_OPTS='--ansi --bind=ctrl-j:down,ctrl-k:up,ctrl-h:preview-up,ctrl-l:preview-down --border --color --cycle --height 40% --ignore-case --layout=reverse --multi --nth=2 --preview="bat --color=always --line-range :500 --style=grid,header,numbers {}" --preview-window=right:60%:wrap --prompt="Q> " --wrap'

    if command -v bat >/dev/null 2>&1; then
        export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range=:500 {}'"
        export FZF_ALT_C_OPTS='--preview-window=right:60%:wrap'
    fi

    export FZF_CTRL_R_OPTS="--sort --exact"
}

## [tools.docker] - Container platform
{
    zf::debug "# [tools.docker]"

    export DOCKER_CONFIG="${XDG_CONFIG_HOME:-${HOME}/.config}/docker"
}

## [tools.git] - Version control
# LAZY LOADED: Now handled by ~/.config/zsh/.zshrc.pre-plugins.d/05-lazy-git-config.zsh
# Git configuration is cached and loaded only when:
# 1. git commit/log/show/config commands are used
# 2. Cache is refreshed hourly or manually with git-refresh-config
{
    zf::debug "# [tools.git] Lazy loading with caching enabled (see 05-lazy-git-config.zsh)"
}

## [tools.gpg] - Encryption/signing
{
    zf::debug "# [tools.gpg]"

    export GPG_AGENT_INFO_FILE="${XDG_RUNTIME_DIR:-/tmp}/gpg-agent-info"

    # DISABLED: Don't launch ssh-agent here as it's handled by the main SSH configuration
    # and could cause password prompts during startup
    # eval "$(ssh-agent)" 2>/dev/null || true
}

## [tools.emacs] - Text editor
{
    zf::debug "# [tools.emacs]"

    export EMACS_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}/emacs"
    export EMACS_SERVER_NAME="emacs-server"
    _path_prepend "${XDG_CONFIG_HOME:-${HOME}/.config}/emacs/bin"
}

## [tools.screen] - Terminal multiplexer
{
    zf::debug "# [tools.screen]"
    export SCREENRC="${XDG_CONFIG_HOME:-${HOME}/.config}/screen/screenrc"
}

## [tools.desk] - Workspace management
{
    zf::debug "# [tools.desk]"

    export DESK_TEMPLATES_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/desk"
    export DESK_DESKDIR="${XDG_DATA_HOME:-${HOME}/.local/share}/desk"
    export DESK_DESKSET_DIR="${DESK_DESKDIR}"
}

## [tools.console-ninja] - Browser debugging
{
    zf::debug "# [tools.console-ninja]"
    _path_prepend "${HOME}/.console-ninja/.bin"
}

## [tools.lmstudio] - Local language models
{
    zf::debug "# [tools.lmstudio]"
    _path_append "${HOME}/.lmstudio/bin"
}

## [tools.herd] - PHP development environment
{
    zf::debug "# [tools.herd]"

    export HERD_APP="/Applications/Herd.app"
    export HERD_TOOLS_HOME="${HOME}/Library/Application Support/Herd"
    export HERD_TOOLS_BIN="${HERD_TOOLS_HOME}/bin"
    export HERD_TOOLS_CONFIG="${HERD_TOOLS_HOME}/config"

    # PHP version-specific configurations
    export HERD_PHP_82_INI_SCAN_DIR="${HERD_TOOLS_CONFIG}/php/82/"
    export HERD_PHP_83_INI_SCAN_DIR="${HERD_TOOLS_CONFIG}/php/83/"
    export HERD_PHP_84_INI_SCAN_DIR="${HERD_TOOLS_CONFIG}/php/84/"
    export HERD_PHP_85_INI_SCAN_DIR="${HERD_TOOLS_CONFIG}/php/85/"

    _path_prepend "${HERD_TOOLS_BIN}" "${HERD_TOOLS_HOME}"
}

## [tools.composer] - PHP package manager
{
    zf::debug "# [tools.composer]"
    _path_prepend "${XDG_CONFIG_HOME:-${HOME}/.config}/composer/vendor/bin"
}

## [tools.pip] - Python package manager
{
    zf::debug "# [tools.pip]"
    export PIPENV_VENV_IN_PROJECT=1
}

## [tools.perl] - Perl programming language
{
    zf::debug "# [tools.perl]"
    export PERLBREW_ROOT="${XDG_DATA_HOME:-${HOME}/.local/share}/perl5/perlbrew"
}

## [tools.gh] - GitHub CLI
{
    zf::debug "# [tools.gh]"
    export GH_CONFIG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/gh"
}

## [tools.direnv] - Environment variable management
# LAZY LOADED: Now handled by ~/.config/zsh/.zshrc.pre-plugins.d/04-lazy-direnv.zsh
# direnv hook is loaded only when:
# 1. direnv command is used explicitly
# 2. .envrc file is detected in current directory
# 3. chpwd hook detects .envrc in new directory
{
    zf::debug "# [tools.direnv] Lazy loading enabled (see 04-lazy-direnv.zsh)"
}

zf::debug "# [tool-configs] ✅ Development tool configurations applied"
