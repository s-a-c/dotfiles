##
## This file is sourced by zsh upon start-up. It should contain commands to set
## up aliases, functions, options, key bindings, etc.
##

# vim: ft=zsh sw=2 ts=2 et nu rnu ai si



export HISTDUP=erase
export HISTFILE="$ZDOTDIR/.zsh_history"         ## History filepath
export HISTSIZE=1000000                         ## Maximum events for internal history
export HISTTIMEFORMAT='%F %T %z %a %V '
export SAVEHIST=1100000                         ## Maximum events in history file


## [builtins] ## {{{
## [builtins.colors]
autoload -U colors && colors ## Load Colors
## [builtins.keybindings]
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region
## [builtins.smarturls]
autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic
## }}}  ## [builtins]


## [plugins]  ## {{{
## [plugins.zsh-abbr]   ## {{{
# export ZSH_ABBR_COMPLETION=1
# export ZSH_ABBR_PROMPT=1
# export ZSH_ABBR_PROMPT_COLOR="cyan"
# export ZSH_ABBR_PROMPT_SYMBOL="⚡"
## Configuration
##   The following variables may be set:
##   • ABBR_AUTOLOAD Should `abbr load` run before every `abbr` command? (0 or 1, default 1)
##   • ABBR_DEFAULT_BINDINGS Use the default key bindings? (0 or 1, default 1)
##   • ABBR_DEBUG Print debugging logs? (0 or 1, default 0)
##   • ABBR_DRY_RUN Behave as if `--dry-run` was passed? (0 or 1, default 0)
##   • ABBR_FORCE Behave as if `--force` was passed? (0 or 1, default 0)
##   • ABBR_QUIET Behave as if `--quiet` was passed? (0 or 1, default 0)
##   • ABBR_USER_ABBREVIATIONS_FILE File abbreviations are stored in (default ${HOME}/.config/zsh/abbreviations)
##   • NO_COLOR If `NO_COLOR` is set, color output is disabled. See https://no-color.org/.
export ABBR_AUTOLOAD=1
export ABBR_DEFAULT_BINDINGS=1
export ABBR_DEBUG=0
export ABBR_DRY_RUN=0
export ABBR_FORCE=0
typeset -gA ABBR_GLOBAL_USER_ABBREVIATIONS
export ABBR_GLOBAL_USER_ABBREVIATIONS=()
export ABBR_QUIET=1
export ABBR_QUIETER=1
typeset -gA ABBR_REGULAR_USER_ABBREVIATIONS
export ABBR_REGULAR_USER_ABBREVIATIONS=()
export ABBR_TMPDIR="${XDG_RUNTIME_DIR}/zsh-abbr"
rm -fr "${ABBR_TMPDIR}"
mkdir -p "${ABBR_TMPDIR}"
export ABBR_USER_ABBREVIATIONS_FILE="${XDG_CONFIG_HOME}/zsh-abbr/user-abbreviations"
rm -f "${ABBR_USER_ABBREVIATIONS_FILE}"
unset NO_COLOR

# .zshrc

bindkey " "  abbr-expand
bindkey "^E" abbr-expand
bindkey "^A" abbr-expand-and-insert

bindkey -M viins " " abbr-expand-and-insert
bindkey -M viins "^ " magic-space
bindkey -M viins "^M" abbr-expand-and-accept
## }}}  ## [plugins.zsh-abbr]

## [plugins.alias-tips]
#export ZSH_PLUGINS_ALIAS_TIPS_REVEAL_EXCLUDES=(_ ll vi)
export ZSH_PLUGINS_ALIAS_TIPS_REVEAL_TEXT="Alias tip: "
export ZSH_PLUGINS_ALIAS_TIPS_REVEAL=1

## [plugins.zsh-async]
export ASYNC_PROMPT="async> "
export ASYNC_SHOW_ON_COMMAND=1
export ASYNC_SHOW_PID=1
export ASYNC_SHOW_TIME=1
export ASYNC_SHOW_WAIT=1

## [plugins.zsh-autopair]
typeset -gA AUTOPAIR_PAIRS
AUTOPAIR_PAIRS+=("<" ">")

## [plugins.zsh-autosuggestions]
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"
export ZSH_AUTOSUGGEST_USE_ASYNC=1

## [plugins.zsh-autosuggestions-abbreviations-strategy]
ZSH_AUTOSUGGEST_STRATEGY=( abbreviations $ZSH_AUTOSUGGEST_STRATEGY )

## [plugins.brew] ## {{{
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

[[ -d "${HOMEBREW_PREFIX}/share/zsh/site-functions" ]] && {
    fpath+=("${HOMEBREW_PREFIX}/share/zsh/site-functions")
    #_field_append FPATH "${HOMEBREW_PREFIX}/share/zsh/site-functions"
    export FPATH="$FPATH:${HOMEBREW_PREFIX}/share/zsh/site-functions"
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
    ## By default, brew does not add any of LLVM’s binaries to your $PATH and you will need to
    ## symlink it to a place where it is able to be found.
    ## You can symlink it to /usr/local/bin by doing ln -s $(brew --prefix llvm)/bin/wasm-ld /usr/local/bin/wasm-ld.
    ##
    ## Alternatively, you can add the entire $(brew --prefix llvm)/bin to your $PATH, but brew does not recommend it.

    #_field_prepend PATH "${HOMEBREW_PREFIX}/sbin"
    _path_prepend "${HOMEBREW_PREFIX}/sbin"
    #_field_prepend PATH "${HOMEBREW_PREFIX}/bin"
    _path_prepend "${HOMEBREW_PREFIX}/bin"
}
## }}}  ## [plugins.brew]

## [plugins.bullet-train] ## {{{
export BULLETTRAIN_PROMPT_ORDER=(
    context
    dir
    git
    status
    time
    vi-mode
    exec_time
    exit_code
    char
)
export BULLETTRAIN_CHAR_SYMBOL="❯"
export BULLETTRAIN_CHAR_SUFFIX=" "
export BULLETTRAIN_DIR_CONTEXT_SHOW=true
export BULLETTRAIN_GIT_COLORIZE_DIRTY=true
export BULLETTRAIN_STATUS_EXIT_SHOW=true
export BULLETTRAIN_TIME_12HR=false
export BULLETTRAIN_CUSTOM_MSG="¡There is no such thing as a free lunch!"
## }}}  ## [plugins.bullet-train]

## [plugins.bun]
export BUN_INSTALL=${BUN_INSTALL:="${XDG_DATA_HOME}/bun"}
#_field_prepend PATH "${BUN_INSTALL}/bin"
_path_prepend "${BUN_INSTALL}/bin"

## [plugins.colorize]
#export ZSH_COLORIZE_STYLE="rainbow_dash"
export ZSH_COLORIZE_STYLE="colorful"

## [plugins.composer]
## [plugins.cpanm]

## [plugins.zsh-defer]
export ZSH_DEFER_PROMPT="defer> "
export ZSH_DEFER_SHOW_ON_COMMAND=1
export ZSH_DEFER_SHOW_PID=1
export ZSH_DEFER_SHOW_TIME=1
export ZSH_DEFER_SHOW_WAIT=1

## [plugins.deno]

## [plugins.diff-so-fancy]  ## {{{
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
## }}}  ## [plugins.diff-so-fancy]

## [plugins.direnv]

## [plugins.docker]
export DOCKER_CONFIG="${XDG_CONFIG_HOME}/docker"
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes

## [plugins.dotnet] ## {{{
export DOTNET_CLI_FORCE_UTF8_ENCODING="true"
export DOTNET_CLI_HOME="${DOTNET_CLI_HOME:="${XDG_DATA_HOME}/dotnet"}"
export DOTNET_CLI_TELEMETRY_OPTOUT="true"
export DOTNET_ROOT="${DOTNET_ROOT:=/usr/local/share/dotnet}"
export DOTNET_SYSTEM_CONSOLE_ALLOW_ANSI_COLOR_REDIRECTION="true"
_path_prepend "${DOTNET_CLI_HOME}/tools"

## [plugins.emacs]
## Start emacs server
#alias emacs="$(which emacsclient) -c -a '$(which emacs) --daemon ' &"
_path_prepend ${XDG_CONFIG_HOME}/emacs/bin

## [plugins.enhancd]
export ENHANCD_FILTER="fzf --height 40%:fzy"
export ENHANCD_USE_ABBREV="${ENHANCD_USE_ABBREV:-true}"

## [plugins.eza]  ## {{{
export EZA_CONFIG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/eza"
zstyle ':omz:plugins:eza' 'dirs-first' yes
zstyle ':omz:plugins:eza' 'git-status' yes
zstyle ':omz:plugins:eza' 'header' yes
zstyle ':omz:plugins:eza' 'hyperlink' yes
zstyle ':omz:plugins:eza' 'icons' yes
## }}}  ## [plugins.eza]

## [plugins.fast-syntax-highlighting]
typeset -gA FAST_HIGHLIGHT
export FAST_HIGHLIGHT[use_brackets]=1

## [plugins.fzf]
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
## }}}  ## [plugins.fzf]

## [plugins.gem]
export GEM_HOME="${XDG_DATA_HOME}/gem/ruby/3.3.0"
export GEM_PATH="${GEM_HOME}/bin"
_path_prepend "${GEM_HOME}/bin"

## [plugins.gh]
export GH_CONFIG_DIR="${XDG_CONFIG_HOME}/gh"

## [plugins.git]

## [plugins.golang]
export GOPATH="${XDG_DATA_HOME}/go"
export GOROOT="${HOMEBREW_PREFIX}/opt/go/libexec"
_path_prepend "${GOPATH}/bin"

## [plugins.gpg-agent]  ## {{{
export GPG_AGENT_INFO_FILE="${XDG_RUNTIME_DIR}/gpg-agent-info"
eval "$(ssh-agent)"
## }}}  ## [plugins.gpg-agent]

## [plugins.isodate]
export ISO_DATE_FORMAT="%Y-%m-%d %H:%M:%S %Z %a %V"

## [plugins.iterm2]
export ITERM2_CONFIG="${XDG_CONFIG_HOME}/iterm2"
export ITERM2_PROFILES="${XDG_CONFIG_HOME}/iterm2/profiles"
zstyle :omz:plugins:iterm2 shell-integration yes


## [plugins.kitty] ## {{{
[[ -n "${commands[kitty]}" ]] && {
    export KITTY_CONFIG_DIRECTORY="${XDG_CONFIG_HOME}/kitty"
    export KITTY_THEME="base16-ocean"

    if [[ "$(uname)" == "Darwin" ]]; then
        ## Do something under Mac OS X platform
        export KITTY_INSTALLATION_DIR="/Applications/kitty.app/Contents/MacOS"
        if test -n "${KITTY_INSTALLATION_DIR}" -a -e "${KITTY_INSTALLATION_DIR}/../Resources/kitty/shell-integration/zsh/kitty.zsh"; then
            builtin source "${KITTY_INSTALLATION_DIR}/../Resources/kitty/shell-integration/zsh/kitty.zsh"
        fi
        :
    elif [[ "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
        ## Do something under GNU/Linux platform
        if test -n "${KITTY_INSTALLATION_DIR}" -a -e "${KITTY_INSTALLATION_DIR}/shell-integration/zsh/kitty.zsh"; then
            builtin source "${KITTY_INSTALLATION_DIR}/shell-integration/zsh/kitty.zsh"
        fi
        :
      elif [[ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]]; then
        ## Do something under 32 bits Windows NT platform
        :
    elif [[ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]]; then
        ## Do something under 64 bits Windows NT platform
        :
    fi
}
## }}}  ## [plugins.kitty]

## [plugins.laravel]
export LARAVEL_CONFIG="${XDG_CONFIG_HOME}/laravel"


## [plugins.nvm]  ## {{{
## Herd injected NVM configuration
export NVM_DIR="${HOME}/Library/Application Support/Herd/config/nvm"

zstyle ':omz:plugins:nvm' lazy yes
zstyle ':omz:plugins:nvm' lazy-cmd eslint prettier typescript
zstyle ':omz:plugins:nvm' autoload yes
## [plugins.nvm]  ## }}}

## [plugins.perl]
export PERLBREW_ROOT="${XDG_DATA_HOME}/perl5/perlbrew"

## [plugins.pip]
export PIPENV_VENV_IN_PROJECT=1


## [plugins.powerlevel10k]
export POWERLEVEL9K_MODE='nerdfont-complete'
export POWERLEVEL9K_DISABLE_HOT_RELOAD=false

## [plugins.rust] ## {{{
export RUSTUP_HOME=${RUSTUP_HOME:="${XDG_DATA_HOME}/rustup"}
export CARGO_HOME=${CARGO_HOME:="${XDG_DATA_HOME}/cargo"}
export CARGO_TARGET_DIR="${CARGO_HOME}/target"
_path_prepend "${CARGO_HOME}/bin"
## [plugins.rust.rustup]  ## {{{
[[ -n "${commands[rustup]}" ]] && {
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

    ## configure rust environment
    [[ -s "$CARGO_HOME/env" ]] && source "$CARGO_HOME/env"
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
    [[ -z "${commands[frum]}" ]]            && cargo install frum
    [[ -z "${commands[macchina]}" ]]        && cargo install macchina
    [[ -z "${commands[rust-analyzer]}" ]]   && rustup component add rust-analyzer
    [[ -z "${commands[starship]}" ]]        && cargo install starship --locked
}
## }}}  ## [plugins.rust.rustup]
## }}}  ## [plugins.rust]

## [plugins.screen]
export SCREENRC="${XDG_CONFIG_HOME}/screen/screenrc"

## [plugins.ssh-agent]  ## {{{
eval "$(ssh-agent)"
zstyle :omz:plugins:ssh-agent agent-forwarding yes
zstyle :omz:plugins:ssh-agent autoload yes
zstyle :omz:plugins:ssh-agent identities ~/.ssh/id_ed25519
zstyle :omz:plugins:ssh-agent lazy yes
zstyle :omz:plugins:ssh-agent quiet yes
zstyle :omz:plugins:ssh-agent ssh-add-args --apple-load-keychain --apple-use-keychain
## }}}  ## [plugins.ssh-agent]

## [plugins.starship]
export STARSHIP_CONFIG=${XDG_CONFIG_HOME}/starship/starship.toml
export ZSH_THEME="jonathan"

## [plugins.zoxide]
export _ZO_DATA_DIR="${XDG_DATA_HOME}/zoxide"
export _ZO_ECHO=1
export _ZO_RESOLVE_SYMLINKS=1
## }}}  ## [plugins]


## [atuin]  ## {{{
# [[ -n "${commands[atuin]}" ]] && {
    typeset -Ag ATUIN
    typeset -gx ATUIN[HOME_DIR]="${XDG_DATA_HOME:-${HOME}/.local/share}/atuin"
    typeset -gx ATUIN[BIN_DIR]="${XDG_DATA_HOME:-${HOME}/.local/share}/atuin/bin"
    typeset -gx ATUIN_HOME=${ATUIN[HOME_DIR]}
    atuin daemon
    #_field_prepend PATH "${ATUIN[BIN_DIR]}"
    _path_prepend "${ATUIN[BIN_DIR]}"
    [[ -s "${ATUIN[BIN_DIR]}/env" ]] && builtin source "${ATUIN[BIN_DIR]}/env"
    $(atuin init zsh) >| "${ZDOTDIR}/saved_atuin_init.zsh"
    eval $(atuin init zsh) || source "${ZDOTDIR}/saved_atuin_init.zsh" || {
        echo "[zshrc] atuin init failed"
        return
    }
# }
## }}}  ## [atuin]

## [avfs]  ## {{{
## AVFS is a system, which enables all programs to look inside archived or compressed files,
## or access remote files without recompiling the programs or changing the kernel.
## At the moment it supports floppies, tar and gzip files, zip, bzip2, ar and rar files,
## ftp sessions, http, webdav, rsh/rcp, ssh/scp.
## Quite a few other handlers are implemented with the Midnight Commander's external FS.
[ -n "${commands[mountavfs]}" ] && mountavfs
## }}}  ## [avfs]

## [bat]  ## {{{
[[ -n "${commands[bat]}" ]] && {
    bat cache --build
    #export BAT_THEME='Visual Studio Dark+'
    export BAT_THEME='modus-vivendi'
    ## If you want to preview the different themes on a custom file,
    ##   you can use the following command (you need fzf for this):
    #bat --list-themes | fzf --preview="bat --theme={} --color=always /path/to/file"
}
## }}}  ## [bat]

## [console-ninja]
export CONSOLE_NINJA_CONFIG="${XDG_CONFIG_HOME}/console-ninja"


## [dircolors]  ## {{{
## + enable color support of ls and also add handy aliases
[[ -n "${commands[dircolors]}" ]] && {
    [[ -s ~/.dircolors ]] && eval "$(dircolors --sh ~/.dircolors)" || eval "$(dircolors --sh)"
}

## [dircolors.256dark]  ## {{{
## The following is a list of the 256 colors for your reference.
## 0-15: 16 basic colors
## 16-231: 6*6*6=216 colors: 16 + 36*r + 6*g + b (0 <= r, g, b <= 5)
## 232-255: grayscale from black to white in 24 steps
##
## 0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15
## 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31
## 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47
## 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63
## 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79
## 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95
## 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110
## 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125
## 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140
## 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155
## 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170
## 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185
## 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200
## 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215
## 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230
## 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245
## 246 247 248 249 250 251 252 253 254 255
##
## 0: black
## 1: red
## 2: green
## 3: yellow
## 4: blue
## 5: magenta
## 6: cyan
## 7: white
##
## 8: bright black
## 9: bright red
## 10: bright green
## 11: bright yellow
## 12: bright blue
## 13: bright magenta
## 14: bright cyan
## 15: bright white
##
## 16: dark grey
## 17: light red
## 18: light green
## 19: light yellow
## 20: light blue
## 21: light magenta
## 22: light cyan
## 23: light white
##
## 24: dark red
## 25: dark green
## 26: dark yellow
## 27: dark blue
## 28: dark magenta
## 29: dark cyan
## 30: dark white
## }}}  ## [dircolors.256dark]
## }}}  ## [dircolors]

## [dirstack] ## {{{
# # - - - - - - - - - - - - - - - - - - - -
# # cdr, persistent cd
# # - - - - - - - - - - - - - - - - - - - -
DIRSTACKFILE="$ZSH_CACHE_DIR/dirs"

## Make `DIRSTACKFILE` If It 'S Not There.
if [[ ! -a $DIRSTACKFILE ]]; then
    mkdir -p ${DIRSTACKFILE[0,-5]}
    touch ${DIRSTACKFILE}
fi

[[ -f "$DIRSTACKFILE" ]] && [[ $#dirstack -eq 0 ]] && dirstack=( ${(f)"$(< $DIRSTACKFILE)"} )

chpwd() {
    print -l ${PWD} ${(u)dirstack} >>${DIRSTACKFILE}
    local d="$(sort -u ${DIRSTACKFILE} 2> /dev/null)"
    echo "${d}" > ${DIRSTACKFILE}
}

DIRSTACKSIZE=40

autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs
## }}}  ## [dirstack]

## [elixir_mix]
export MIX_XDG=true

## [erlang_rebar3]
export REBAR_PROFILE="term"             # force a base profile
# export HEX_CDN="https://..."            # change the Hex endpoint for a private one
export QUIET=1                          # only display errors
export DEBUG=1                          # show debug output
                                        # "QUIET=1 DEBUG=1" displays both errors and warnings
export DIAGNOSTIC=1                     # show maintainers output
export REBAR_COLOR="low"                # reduces amount of color in output if supported
export REBAR_CACHE_DIR                  # override where Rebar3 stores cache data
export REBAR_GLOBAL_CONFIG_DIR          # override where Rebar3 stores config data
export REBAR_BASE_DIR                   # override where Rebar3 stores build output
export REBAR_CONFIG="rebar3.config"     # changes the name of rebar.config files
export REBAR_GIT_CLONE_OPTIONS=""       #  pass additional options to all git clone operations
                                        #  for example, a cache across project can be set up
                                        # with "--reference ~/.cache/repos.reference"
# export http_proxy                       # standard proxy ENV variable is respected
# export https_proxy                      #  standard proxy ENV variable is respected
# export TERM                             # standard terminal definition value. TERM=dumb disables color

## [frum]
export FRUM_DIR="${XDG_DATA_HOME}/frum"


## [ghcup]
[[ -n "${commands[ghcup]}" ]] && {
    export BOOTSTRAP_HASKELL_CABAL_XDG=${BOOTSTRAP_HASKELL_CABAL_XDG:="true"}
    export GHCUP_USE_XDG_DIRS=${GHCUP_USE_XDG_DIRS:="true"}
    export STACK_XDG=${STACK_XDG:="true"}
    [[ -s "${XDG_DATA_HOME}/ghcup/env" ]] && source "${XDG_DATA_HOME}/ghcup/env"
}
## }}}  ## [ghcup]

## [ghostty]    ## Ghostty shell integration for Zsh. This must be at the top of your zshrc!
[[ -n "${GHOSTTY_RESOURCES_DIR}" ]] && builtin source "${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration"

## [github]
export GITHUB_CONFIG_DIR="${XDG_CONFIG_HOME}/github"
(( ! ${fpath[(I)/usr/local/share/zsh/site-functions]} )) && {
    FPATH="/usr/local/share/zsh/site-functions:${FPATH}"
}

## [go] ## {{{
[[ -n "${commands[go]}" ]] && {
    export GOENV=${GOENV:="${XDG_CONFIG_HOME}/go"}
    export GOPATH=${GOPATH:="${XDG_DATA_HOME}/go"}

    export GOBIN=${GOBIN:="${GOPATH}/bin"}

    # + Custom go binaries are installed in $GOPATH/bin.
    _path_append "${GOPATH}/bin"

    [[ ! -f "${GOPATH}/bin/gofumpt" ]] && go install mvdan.cc/gofumpt@latest
    [[ ! -f "${GOPATH}/bin/golangci-lint" ]] && go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
    [[ ! -f "${GOPATH}/bin/revive" ]] && go install github.com/mgechev/revive@latest
}
## }}}  ## [go]

## [gpg]
#[[ -n "${commands[gpg]}" ]] export GNUPGHOME=${GNUPGHOME:="${XDG_DATA_HOME}/gnupg"}

## [gpgconf]
[[ -n "${commands[gpgconf]}" ]] && export GPG_TTY=$(tty)

## [guile] ## {{{
# [[ -n "${commands[guile]}" ]] && {
#     export GUILE_LOAD_PATH="$(brew --prefix)/share/guile/site/3.0"
#     export GUILE_LOAD_COMPILED_PATH="$(brew --prefix)/lib/guile/3.0/site-ccache"
#     export GUILE_SYSTEM_EXTENSIONS_PATH="$(brew --prefix)/lib/guile/3.0/extensions"
#     export GUILE_LOAD_PATH="${GUILE_LOAD_PATH}:${GUILE_SYSTEM_EXTENSIONS_PATH}"
#     export GUILE_LOAD_PATH="${GUILE_LOAD_PATH}:${GUILE_LOAD_COMPILED_PATH}"
#     export GUILE_LOAD_PATH="${GUILE_LOAD_PATH}:${XDG_DATA_HOME}/guile"
#     export GUILE_LOAD_PATH="${GUILE_LOAD_PATH}:${XDG_DATA_HOME}/guile/site"
#     export GUILE_LOAD_PATH="${GUILE_LOAD_PATH}:${XDG_DATA_HOME}/guile/site-ccache"
#     export GUILE_LOAD_PATH="${GUILE_LOAD_PATH}:${XDG_DATA_HOME}/guile/site-extensions"
#     export GUILE_LOAD_PATH="${GUILE_LOAD_PATH}:${XDG_DATA_HOME}/guile/site-compiled"
#     export GUILE_TLS_CERTIFICATE_DIRECTORY="$(brew --prefix)/etc/gnutls/"
# }
## }}}  ## [guile]

## [gum] ## {{{
## + Uses values configured through environment variables above but can still be overridden with flags.
## + https://github.com/charmbracelet/gum
[[ -n "${commands[gum]}" ]] && {
    export GUM_INPUT_CURSOR_FOREGROUND="#FF0"
    export GUM_INPUT_PROMPT_FOREGROUND="#0FF"
    export GUM_INPUT_PLACEHOLDER="What's up?"
    export GUM_INPUT_PROMPT="* "
    export GUM_INPUT_WIDTH=80
}
## }}}  ## [gum]

## [julia]  ## {{{
[[ -n "${commands[julia]}" ]] && {
    export JULIAUP_DEPOT_PATH=${JULIAUP_DEPOT_PATH:="${XDG_DATA_HOME}/julia"}
    export JULIA_DEPOT_PATH=${JULIA_DEPOT_PATH:="${XDG_DATA_HOME}/julia"}
    export JULIA_LOAD_PATH=${JULIA_LOAD_PATH:="${XDG_DATA_HOME}/julia"}
    export JULIA_PKG_SERVER=${JULIA_PKG_SERVER:="https://mirrors.sjtug.sjtu.edu.cn/julia"}
    export JULIA_HISTORY=${JULIA_HISTORY:="${XDG_DATA_HOME}/julia/julia_history.jl"}
    export JULIA_NUM_THREADS=${JULIA_NUM_THREADS:="4"}
    export JULIA_EDITOR=${JULIA_EDITOR:="nvim"}
    export JULIA_VIM=${JULIA_VIM:="nvim"}
    export JULIA_VIM_INIT=${JULIA_VIM_INIT:="startinsert"}
    export JULIA_VIM_ARGS=${JULIA_VIM_ARGS:="--nofork"}
    export JULIA_VIM_COLOR=${JULIA_VIM_COLOR:="dark"}
    export JULIA_VIM_THEME=${JULIA_VIM_THEME:="base16-ocean"}
    export JULIA_VIM_FONT=${JULIA_VIM_FONT:="OpenDyslexicM Nerd Font"}
    export JULIA_VIM_FONT_SIZE=${JULIA_VIM_FONT_SIZE:="12"}
    export JULIA_VIM_FONT_WEIGHT=${JULIA_VIM_FONT_WEIGHT:="normal"}
    export JULIA_VIM_FONT_STYLE=${JULIA_VIM_FONT_STYLE:="normal"}
    export JULIA_VIM_FONT_LIGATURES=${JULIA_VIM_FONT_LIGATURES:="true"}
    export JULIA_VIM_FONT_ANTIALIAS=${JULIA_VIM_FONT_ANTIALIAS:="true"}
    export JULIA_VIM_FONT_AUTOHINT=${JULIA_VIM_FONT_AUTOHINT:="true"}
    export JULIA_VIM_FONT_HINTING=${JULIA_VIM_FONT_HINTING:="full"}
    export JULIA_VIM_FONT_HINT_STYLE=${JULIA_VIM_FONT_HINT_STYLE:="hintslight"}
    export JULIA_VIM_FONT_SUBPIXEL=${JULIA_VIM_FONT_SUBPIXEL:="rgb"}
    export JULIA_VIM_FONT_VERTICAL_LIGATURES=${JULIA_VIM_FONT_VERTICAL_LIGATURES:="true"}
    export JULIA_VIM_FONT_HORIZONTAL_LIGATURES=${JULIA_VIM_FONT_HORIZONTAL_LIGATURES:="true"}
    export JULIA_VIM_FONT_VARIABLES=${JULIA_VIM_FONT_VARIABLES:="true"}
    ## [juliaup]  ## {{{
    [[ ! -s "${XDG_CONFIG_HOME}/julialang/autocomplete/juliaup.zsh" ]] && {
        mkdir -p "${XDG_CONFIG_HOME}/julialang/autocomplete"
        juliaup completions zsh >> "${XDG_CONFIG_HOME}/julialang/autocomplete/juliaup.zsh"
    }
    builtin source "${XDG_CONFIG_HOME}/julialang/autocomplete/juliaup.zsh"
    ## }}}  ## [juliaup]
}
## }}}  ## [julia]

## [jupyter]
[[ -n "${commands[jupyter]}" ]] && export JUPYTER_CONFIG_DIR="${XDG_CONFIG_HOME}/jupyter"

## [lesspipe]
## make less more friendly for non-text input files, see lesspipe(1)
[[ -n ${commands[lesspipe.sh]} ]] && export LESSOPEN=' | lesspipe.sh %s'

## [luarocks] ## {{{
[[ -n "${commands[luarocks]}" ]] && {
    export LUA_PATH="$LUA_PATH;${XDG_DATA_HOME}/lua/?.lua"
    export LUA_CPATH="$LUA_CPATH;${XDG_DATA_HOME}/lua/?.so"
    export LUAROCKS_CONFIG=${LUAROCKS_CONFIG:="${XDG_CONFIG_HOME}/luarocks/config-5.4.lua"}
    export LUAROCKS_HOME_TREE=${LUAROCKS_HOME_TREE:="${XDG_DATA_HOME}/luarocks"}
    # Luarocks bin path
    [[ -d "$LUAROCKS_HOME_TREE/bin" ]] || [[ $(mkdir -p $LUAROCKS_HOME_TREE/bin) ]] && _path_prepend "$LUAROCKS_HOME_TREE/bin"
}
## }}}  ## [luarocks]

## [nvim] ## {{{
[[ -n "${commands[nvim]}" ]] && {
    ## [nvim.bob]  ## {{{
    ## Bob Neovim version manager configuration
    export BOB_CONFIG=${XDG_CONFIG_HOME}/bob/config.json
    [[ -n "${commands[bob]}" ]] && {
        ## Bob neovim path
        [[ -d ${XDG_DATA_HOME}/bob/nvim-bin ]] && _path_prepend "${XDG_DATA_HOME}/bob/nvim-bin"
        bob use stable
        bob sync
        bob update --all
    }
    ## }}}  ## [nvim.bob]

    ## [nvim.lazyman]  ## {{{
    ## git clone https://github.com/doctorfree/nvim-lazyman ${XDG_CONFIG_HOME}/nvim-Lazyman
    [[ -n "${commands[lazyman]}" ]] && {
        ## Lazyman Neovim configuration
        ## Source the Lazyman shell initialization for aliases and nvims selector
        [[ -s ${XDG_CONFIG_HOME}/nvim-Lazyman/.lazymanrc ]] && source ${XDG_CONFIG_HOME}/nvim-Lazyman/.lazymanrc
        ## Source the Lazyman .nvimsbind for nvims key binding
        [[ -r ${XDG_CONFIG_HOME}/nvim-Lazyman/.nvimsbind ]] && source ${XDG_CONFIG_HOME}/nvim-Lazyman/.nvimsbind

        ## To easily switch between lazyman installed Neovim configurations,
        ## shell aliases and the 'nvims' and 'neovides' commands have been created.

        ## Aliases like the following are defined in ~/.config/nvim-Lazyman/.lazymanrc
        # alias lmvim="source ${XDG_DATA_HOME}/nvim-Lazyman/bin/activate && NVIM_APPNAME=nvim-Lazyman ${commands[lazyman]}"
    }
}
## }}}  ## [nvim.lazyman]
## }}}  ## [nvim]

## [opam] ## {{{
[[ -n "${commands[opam]}" ]] && {
    export OPAMROOT=${OPAMROOT:="${XDG_DATA_HOME}/opam"}
    export OPAMSWITCH=${OPAMSWITCH:="default"}
    _path_prepend "${OPAMROOT}/$OPAMSWITCH/bin"
}

## [ocaml] ## {{{
#[[ -n "${commands=ocaml}" ]] && {
    export OCAMLRUNPARAM="b"
    export OCAML_TOPLEVEL_PATH="${XDG_DATA_HOME}/ocaml"
    export OCAML_TOPLEVEL_HISTORY="${XDG_DATA_HOME}/ocaml/toplevel-history"
    export OPAMROOT="${XDG_DATA_HOME}/opam"
#}

## [ocaml.dune] ##
[[ -n "${commands[dune]}" ]] && export DUNE_CACHE="$XDG_CACHE_HOME/dune"

## [ocaml.opam] ## {{{
[[ -n "${commands[opam]}" ]] && {
    ## opam configuration
    ## - shell completion
    ## - environment setup
    ## - opam aliases
    [[ -s "${OPAMROOT}/opam-init/init.zsh" ]] && source "${OPAMROOT}/opam-init/init.zsh" > /dev/null 2>&1
    [[ -s "${OPAMROOT}/opam-init/opam-switch.sh" ]] && source "${OPAMROOT}/opam-init/opam-switch.sh" > /dev/null 2>&1
    [[ -s "${OPAMROOT}/opam-init/opam-aliases.sh" ]] && source "${OPAMROOT}/opam-init/opam-aliases.sh" > /dev/null 2>&1

    export OPAM_SWITCH_PREFIX="${OPAMROOT}/default"
    #export OCAML_TOPLEVEL_PATH="$OPAM_SWITCH_PREFIX/lib/toplevel"
    #export CAML_LD_LIBRARY_PATH="$OPAM_SWITCH_PREFIX/lib/stublibs:$OPAM_SWITCH_PREFIX/lib/ocaml/stublibs:$OPAM_SWITCH_PREFIX/lib/ocaml"

    typeset -agx _OPAM_SWITCH_DEFAULT=(core core_bench dune js_of_ocaml js_of_ocaml-ppx merlin ocaml-lsp-server ocamlformat ocp-indent odoc opam-client opam-installer tuareg user-setup utop)
    typeset -agx _OPAM_SWITCH_JANESTREET=(async base base_quickcheck bonsai core core_unix dune incr_dom incremental patdiff ppx_jane)
    typeset -agx _OPAM_SWITCH_OCSIGEN=(logs-async ocsigen-start ocsipersist-pgsql-config ocsipersist-sqlite-config pgx_lwt riot)
    typeset -agx _OPAM_SWITCH_REASON=(dune melange reason reason-react reason-react-ppx)
    _OPAM_SWITCH_REASON+=(${_OPAM_SWITCH_JANESTREET})
    _OPAM_SWITCH_OCSIGEN+=(${_OPAM_SWITCH_JANESTREET})

    unset _OPAM_SWITCH && typeset -Agx _OPAM_SWITCH
    typeset -gx _OPAM_SWITCH[reason]=${_OPAM_SWITCH_REASON}
    typeset -gx _OPAM_SWITCH[ocsigen]=${_OPAM_SWITCH_OCSIGEN}
    typeset -gx _OPAM_SWITCH[janestreet]=${_OPAM_SWITCH_JANESTREET}
    typeset -gx _OPAM_SWITCH[default]=${_OPAM_SWITCH_DEFAULT}

    function opam_switches() {
        for switch in $(opam switch list -s); do
            echo "\n<><> opam install --switch $switch \"$@\" <><><><><><><><>\n"
            opam install --switch ${switch} "$@"
        done
    }

    ## [ocaml.opam.ENVIRONMENT]  ## {{{
    # Opam makes use of the environment variables listed here. Boolean variables should be set to "0", "no", "false" or the empty string to disable, "1", "yes" or "true" to enable.
    export OPAMALLPARENS=true # surround all filters with parenthesis.
    # OPAMASSUMEDEPEXTS see option ‘--assume-depexts'.
    # OPAMAUTOREMOVE see remove option ‘--auto-remove'.
    # OPAMBESTEFFORT see option ‘--best-effort'.
    # OPAMBESTEFFORTPREFIXCRITERIA sets the string that must be prepended to the criteria when the ‘--best-effort' option is set, and is expected to maximise the ‘opam-query' property in the solution.
    # OPAMBUILDDOC Removed in 2.1.
    # OPAMBUILDTEST Removed in 2.1.
    # OPAMCLI see option ‘--cli'.
    export OPAMCOLOR=always # when set to always or never, sets a default value for the ‘--color' option.
    # OPAMCONFIRMLEVEL see option ‘--confirm-level‘. OPAMCONFIRMLEVEL has priority over OPAMYES and OPAMNO.
    # OPAMCRITERIA specifies user preferences for dependency solving. The default value depends on the solver version, use ‘config report' to know the current setting. See also option --criteria.
    # OPAMCUDFFILE save the cudf graph to file-actions-explicit.dot.
    # OPAMCUDFTRIM controls the filtering of unrelated packages during CUDF preprocessing.
    # OPAMCURL can be used to select a given 'curl' program. See OPAMFETCH for more options.
    # OPAMDEBUG see options ‘--debug' and ‘--debug-level'.
    # OPAMDEBUGSECTIONS if set, limits debug messages to the space-separated list of sections. Sections can optionally have a specific debug level (for example, CLIENT:2 or CLIENT CUDF:2), but otherwise use ‘--debug-level'.
    # OPAMDIGDEPTH defines how aggressive the lookup for conflicts during CUDF preprocessing is.
    # OPAMDOWNLOADJOBS sets the maximum number of simultaneous downloads.
    # OPAMDROPWORKINGDIR overrides packages previously updated with --working-dir on update. Without this variable set, opam would keep them unchanged unless explicitly named on the command-line.
    # OPAMDRYRUN see option ‘--dry-run'.
    # OPAMEDITOR sets the editor to use for opam file editing, overrides $EDITOR and $VISUAL.
    # OPAMERRLOGLEN sets the number of log lines printed when a sub-process fails. 0 to print all.
    # OPAMEXTERNALSOLVER see option ‘--solver'.
    # OPAMFAKE see option ‘--fake'.
    # OPAMFETCH specifies how to download files: either ‘wget', ‘curl' or a custom command where variables %{url}%, %{out}%, %{retry}%, %{compress}% and %{checksum}% will be replaced. Overrides the 'download-command' value from the main config file.
    # OPAMFIXUPCRITERIA same as OPAMUPGRADECRITERIA, but specific to fixup and reinstall.
    # OPAMIGNORECONSTRAINTS see install option ‘--ignore-constraints-on'.
    # OPAMIGNOREPINDEPENDS see option ‘--ignore-pin-depends'.
    # OPAMINPLACEBUILD see option ‘--inplace-build'.
    # OPAMJOBS sets the maximum number of parallel workers to run.
    # OPAMJSON log json output to the given file (use character ‘%' to index the files).
    # OPAMKEEPBUILDDIR see install option ‘--keep-build-dir'.
    # OPAMKEEPLOGS tells opam to not remove some temporary command logs and some backups. This skips some finalisers and may also help to get more reliable backtraces.
    # OPAMLOCKED combination of ‘--locked' and ‘--lock-suffix' options.
    # OPAMLOGS logdir sets log directory, default is a temporary directory in /tmp
    # OPAMMAKECMD set the system make command to use.
    # OPAMMERGEOUT merge process outputs, stderr on stdout.
    # OPAMNO answer no to any question asked, see options ‘--no‘ and ‘--confirm-level‘. OPAMNO is ignored if either OPAMCONFIRMLEVEL or OPAMYES is set.
    # OPAMNOAGGREGATE with ‘opam admin check', don't aggregate packages.
    # OPAMNOASPCUD Deprecated.
    # OPAMNOAUTOUPGRADE disables automatic internal upgrade of repositories in an earlier format to the current one, on 'update' or 'init'.
    # OPAMNOCHECKSUMS enables option --no-checksums when available.
    # OPAMNODEPEXTS disables system dependencies handling, see option ‘--no-depexts'.
    # OPAMNOENVNOTICE Internal.
    # OPAMNOSELFUPGRADE see option ‘--no-self-upgrade'
    # OPAMPINKINDAUTO sets whether version control systems should be detected when pinning to a local path. Enabled by default since 1.3.0.
    # OPAMPRECISETRACKING fine grain tracking of directories.
    # OPAMPREPRO set this to false to disable CUDF preprocessing. Less efficient, but might help debugging solver issue.
    # OPAMREPOSITORYTARRING internally store the repositories as tar.gz files. This can be much faster on filesystems that don't cope well with scanning large trees but have good caching in /tmp. However this is slower in the general case.
    # OPAMREQUIRECHECKSUMS Enables option ‘--require-checksums' when available (e.g. for ‘opam install').
    # OPAMRETRIES sets the number of tries before failing downloads.
    # OPAMREUSEBUILDDIR see option ‘--reuse-build-dir'.
    # OPAMROOT see option ‘--root'. This is automatically set by ‘opam env --root=DIR --set-root'.
    # OPAMROOTISOK don't complain when running as root.
    # OPAMSAFE see option ‘--safe'.
    # OPAMSHOW see option ‘--show'.
    # OPAMSKIPUPDATE see option ‘--skip-updates'.
    # OPAMSKIPVERSIONCHECKS bypasses some version checks. Unsafe, for compatibility testing only.
    # OPAMSOLVERALLOWSUBOPTIMAL (default ‘true') allows some solvers to still return a solution when they reach timeout; while the solution remains assured to be consistent, there is no guarantee in this case that it fits the expected optimisation criteria. If ‘true', opam willcontinue with a warning, if ‘false' a timeout is an error. Currently only the builtin-z3 backend handles this degraded case.
    # OPAMSOLVERTIMEOUT change the time allowance of the solver. Default is 60.0, set to 0 for unlimited. Note that all solvers may not support this option.
    export OPAMSTATS=false # display stats at the end of command. # true _may_ be useful for debugging but _can_ disturb batch processing.
    export OPAMSTATUSLINE=always # display a dynamic status line showing what's currently going on on the terminal. (one of one of always, never or auto)
    # OPAMSTRICT fail on inconsistencies (file reading, switch import, etc.).
    # OPAMSWITCH see option ‘--switch'. Automatically set by ‘opam env --switch=SWITCH --set-switch'.
    # OPAMUNLOCKBASE see install option ‘--unlock-base'.
    # OPAMUPGRADECRITERIA specifies user preferences for dependency solving when performing an upgrade. Overrides OPAMCRITERIA in upgrades if both are set. See also option --criteria.
    # OPAMUSEINTERNALSOLVER see option ‘--use-internal-solver'.
    # OPAMUSEOPENSSL Removed in 2.2.
    export OPAMUTF8=always # use UTF8 characters in output (one of one of always, never or auto). By default ‘auto', which is determined from the locale).
    # OPAMUTF8MSGS use extended UTF8 characters (camels) in opam messages. Implies OPAMUTF8. This is set by default on macOS only.
    # OPAMVALIDATIONHOOK if set, uses the ‘%{hook%}' command to validate an opam repository update.
    # OPAMVERBOSE see option ‘--verbose'.
    # OPAMVERBOSEON see option --verbose-on
    # OPAMVERSIONLAGPOWER do not use.
    # OPAMWITHDEVSETUP see install option ‘--with-dev-setup'.
    # OPAMWITHDOC see install option ‘--with-doc'.
    # OPAMWITHTEST see install option ‘--with-test.
    # OPAMWORKINGDIR see option ‘--working-dir'.
    # OPAMYES see options ‘--yes' and ‘--confirm-level‘. OPAMYES has priority over OPAMNO and is ignored if OPAMCONFIRMLEVEL is set.
    # OPAMVAR_var overrides the contents of the variable var when substituting ‘%{var}%‘ strings in ‘opam‘ files.
    # OPAMVAR_package_var overrides the contents of the variable package:var when substituting ‘%{package:var}%‘ strings in ‘opam‘ files.
    ## }}}  ## [ocaml.opam.ENVIRONMENT]

    [[ -r ${OPAMROOT}/opam-init/init.sh ]] && source ${OPAMROOT}/opam-init/init.sh >/dev/null 2>/dev/null || true

    #opam switch ocsigen && eval $(opam env --switch=ocsigen --set-switch)
}
## }}}  ## [ocaml.opam]
## }}}  ## [ocaml]

## [ruby]   ## {{{
## [ruby.chruby]
[[ -n "${commands[chruby-exec]}" ]] && {
    builtin source "$(brew --prefix)/opt/chruby/share/chruby/chruby.sh"
    builtin source "$(brew --prefix)/opt/chruby/share/chruby/auto.sh"
    RUBIES+=("${XDG_DATA_HOME}/rubies/*")
}

## [ruby.frum]
eval "$(frum init)"
## }}}  ## [ruby]

## [vivid]
if [[ -n "${commands[vivid]}" ]]; then
    export LS_COLORS="$(vivid --color-mode 24-bit generate catppuccin-mocha)"
    function _vivid_themes() {
        for theme in $(vivid themes); do
            echo "Theme: ${theme}"
            LS_COLORS=$(vivid generate ${theme})
            \ls
            echo
        done
    }
fi


## [herd] ## {{{
## Herd injected PHP 8.4 configuration.
export HERD_PHP_84_INI_SCAN_DIR="${HOME}/Library/Application Support/Herd/config/php/84/"

## Herd injected PHP 8.3 configuration.
export HERD_PHP_83_INI_SCAN_DIR="${HOME}/Library/Application Support/Herd/config/php/83/"

## Herd injected PHP 8.2 configuration.
export HERD_PHP_82_INI_SCAN_DIR="${HOME}/Library/Application Support/Herd/config/php/82/"

## Herd injected PHP binary.
export PATH="${HOME}/Library/Application Support/Herd/bin/":$PATH

## [herd.nvm]
## Herd injected NVM configuration
export NVM_DIR="${HOME}/Library/Application Support/Herd/config/nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && builtin source "$NVM_DIR/nvm.sh" --no-use # This loads nvm
zstyle ':omz:plugins:nvm' lazy yes
zstyle ':omz:plugins:nvm' lazy-cmd nvm node npm pnpm yarn corepack eslint prettier typescript
zstyle ':omz:plugins:nvm' autoload yes
zstyle ':omz:plugins:nvm' silent-autoload yes

## [herd.nvm]  ## }}}

[[ -f "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh" ]] && builtin source "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh"
## }}}  ## [herd]

