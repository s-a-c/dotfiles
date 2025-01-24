##
## This file is sourced by zsh upon start-up. It should contain commands to set
## up aliases, functions, options, key bindings, etc.
##

# vim: ft=zsh sw=4 ts=4 et nu rnu ai si

echo ""
echo "# ++++++++++++++++++++++++++++++++++++++++++++++"
echo "# ++++++++++++++++++++++++++++++++++++++++++++++"
echo "# 005-path.zsh"
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
    "/opt/local/bin" \
    "/opt/local/sbin" \
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
    "/home/linuxbrew/.linuxbrew/sbin" \
    "/home/linuxbrew/.linuxbrew/bin" \
    "/opt/homebrew/sbin" \
    "/opt/homebrew/bin" \
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
