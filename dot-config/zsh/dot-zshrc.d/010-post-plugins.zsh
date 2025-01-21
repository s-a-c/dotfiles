##
## This file is sourced by zsh upon start-up. It should contain commands to set
## up aliases, functions, options, key bindings, etc.
##

# vim: ft=zsh sw=4 ts=4 et nu rnu ai si

echo ""
echo "# ++++++++++++++++++++++++++++++++++++++++++++++"
echo "# ++++++++++++++++++++++++++++++++++++++++++++++"
echo "# 010-post-plugins.zsh"
echo "# ++++++++++++++++++++++++++++++++++++++++++++++"
echo "# ++++++++++++++++++++++++++++++++++++++++++++++"
echo ""

## [_path]    ## {{{
## [_path.remove] ## {{{
function _path_remove() {
    for ARG in "$@"; do
        while [[ ":$PATH:" == *":$ARG:"* ]]; do
            ## Delete path by parts so we can never accidentally remove sub paths
            [[ "$PATH" == "$ARG" ]] && PATH=""
            PATH=${PATH//":$ARG:"/":"} ## delete any instances in the middle
            PATH=${PATH/#"$ARG:"/}     ## delete any instance at the beginning
            PATH=${PATH/%":$ARG"/}     ## delete any instance in the at the end
            export PATH
        done
    done
}
## }}}    ## [_path.remove]

## [_path.append] ## {{{
function _path_append() {
    for ARG in "$@"; do
        _path_remove "$ARG"
        [[ -d "$ARG" ]] && export PATH="${PATH:+"$PATH:"}$ARG"
    done
}
## }}}    ## [_path.append]

## [_path.prepend]    ## {{{
function _path_prepend() {
    for ARG in "$@"; do
        _path_remove "$ARG"
        [[ -d "$ARG" ]] && export PATH="$ARG${PATH:+":$PATH"}"
    done
}
## }}}    ## [_path.prepend]

## [my_path]
_path_append \
    "/home/linuxbrew/.linuxbrew/bin" \
    "/home/linuxbrew/.linuxbrew/sbin" \
    "/opt/local/bin" \
    "/opt/local/sbin" \
    "/opt/homebrew/bin" \
    "/opt/homebrew/sbin" \
    "/run/current-system/sw/bin" \
    "/nix/var/nix/profiles/default/bin" \
    "/usr/local/bin" \
    "/usr/local/sbin" \
    "/usr/bin" \
    "/usr/sbin" \
    "/bin" \
    "/sbin"

_path_prepend \
    "/Applications/Xcode.app/Contents/Developer/usr/bin" \
    "/Applications/Herd.app/Contents/Resources" \
    "$ZDOTDIR/src/gocode/bin" \
    "$ZDOTDIR/gocode" \
    "$ZDOTDIR/bin" \
    "$ZDOTDIR/.rbenv/bin" \
    "$ZDOTDIR/.linuxbrew/sbin" \
    "$ZDOTDIR/.linuxbrew/bin" \
    "$ZDOTDIR/.cargo/bin" \
    "$ZDOTDIR/.cabal/bin" \
    "$HOME/.nix-profile/sbin" \
    "$HOME/.nix-profile/bin" \
    "$HOME/Library/Application Support/Herd" \
    "$HOME/Library/Application Support/Herd/bin" \
    "$HOME/.turso" \
    "$HOME/sbin" \
    "$HOME/bin" \
    "$HOME/.local/sbin" \
    "$HOME/.local/bin"

# Prevent duplicate entries in PATH and FPATH
typeset -xU PATH path FPATH fpath

# for _dir in `echo "${PATH}" | tr ':' '\n'`; do
#     echo "${_dir}"
# done

#_field_prepend PATH "/run/current-system/sw/bin"
#_field_prepend PATH "${HOME}/.local/bin"
#_field_prepend PATH "${HOME}/.local/sbin"
#_field_prepend PATH "${HOME}/bin"
#_field_prepend PATH "${HOME}/sbin"
## }}}    ## [_path]

# [[ -n "${commands[composer]}" ]] && export COMPOSER_BIN_DIR="$(composer config --global home)/vendor/bin" && _path_prepend $COMPOSER_BIN_DIR

export EDITOR=$commands[nvim]
export VISUAL=$commands[cursor]

if [[ "$(uname)" == "Darwin" ]]; then
    defaults write -g NSWindowShouldDragOnGesture -bool true
    defaults write NSGlobalDomain AppleHighlightColor -string "0.615686 0.823529 0.454902"
    :
elif [[ "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
    ## Do something under GNU/Linux platform
    :
elif [[ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]]; then
    ## Do something under 32 bits Windows NT platform
    :
elif [[ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]]; then
    ## Do something under 64 bits Windows NT platform
    :
fi

## [plugins]  ## {{{
## [plugins.zsh-abbr@v6]
#builtin source "$ZGEN_DIR/olets/zsh-abbr/v6/zsh-abbr.plugin.zsh"

## [plugins.fast-syntax-highlighting]
[[ -n "${commands[fast - syntax - highlighting]}" ]] && {
    fast-theme q-jmnemonic
}

## [plugins.ssh]
#ssh-add ${HOME}/.ssh/id_ed25519
ssh-add -q --apple-load-keychain --apple-use-keychain ~/.ssh/id_ed25519

## [plugins.starship]
[[ -n "${commands[starship]}" ]] && eval "$(starship init zsh)"

## [plugins.zoxide]
[[ -n "${commands[zoxide]}" ]] && eval "$(zoxide init zsh --hook pwd)"

## }}}  ## [plugins]

## [carapace]    ## Carapace shell integration for Zsh. This must be at the top of your zshrc!
[[ -n "${commands[carapace]}" ]] && {
    export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense' # optional
    zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
    builtin source <(carapace _carapace)
}

## [rio]
[[ -n "${commands[rio]}" ]] && {
    export RIO_CONFIG="${XDG_CONFIG_HOME}/rio/config"
    export RIO_CACHE="${XDG_CACHE_HOME}/rio"
    if ! infocmp rio &>/dev/null; then
        tempfile=$(mktemp) &&
            curl -o ${tempfile} https://raw.githubusercontent.com/raphamorim/rio/main/misc/rio.terminfo &&
            sudo tic -xe rio ${tempfile} &&
            rm ${tempfile}
    fi
}

## [wezterm]
[[ -n "${commands[wezterm]}" ]] && {
    if ! infocmp wezterm &>/dev/null; then
        tempfile=$(mktemp) &&
            curl -o ${tempfile} https://raw.githubusercontent.com/wez/wezterm/main/termwiz/data/wezterm.terminfo &&
            sudo tic -xe wezterm ${tempfile} &&
            rm ${tempfile}
    fi
}

## [my_fpath]
[[ -d "${XDG_DATA_HOME}/zsh/functions" ]] && {
    fpath+=("${XDG_DATA_HOME}/zsh/functions")
    #_field_append FPATH "$XDG_DATA_HOME/zsh/functions"
    export FPATH="${FPATH}:${XDG_DATA_HOME}/zsh/functions"
}

# Prevent duplicate entries in PATH and FPATH
typeset -U PATH path FPATH fpath

# rm -f "${ZDOTDIR:-${HOME:?No ZDOTDIR or HOME}}/.zcompdump" \
#     && rm -f "${ZSH_COMPDUMP}" \
#     && compinit -d "${ZSH_COMPDUMP}"

## [update-all]
#[[ -s "$XDG_CONFIG_HOME/zsh/update-all.zsh" ]] && source "$XDG_CONFIG_HOME/zsh/update-all.zsh"
