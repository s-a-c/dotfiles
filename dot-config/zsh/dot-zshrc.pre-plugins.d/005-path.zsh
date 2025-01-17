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
unset my_path
typeset -a my_path=( \
    "$HOME/.local/bin" \
    "$HOME/.local/sbin" \
    "$HOME/bin" \
    "$HOME/sbin" \
    "$HOME/.nix-profile/bin" \
    "$HOME/.nix-profile/sbin" \
    "$HOME/.turso" \
    "$ZDOTDIR/.cabal/bin" \
    "$ZDOTDIR/.cargo/bin" \
    "$ZDOTDIR/.linuxbrew/bin" \
    "$ZDOTDIR/.linuxbrew/sbin" \
    "$ZDOTDIR/.rbenv/bin" \
    "$ZDOTDIR/bin" \
    "$ZDOTDIR/gocode" \
    "$ZDOTDIR/src/gocode/bin" \
    "/Applications/Herd.app/Contents/Resources" \
    "/Applications/Xcode.app/Contents/Developer/usr/bin" \
    "/home/linuxbrew/.linuxbrew/bin" \
    "/home/linuxbrew/.linuxbrew/sbin" \
    "/opt/homebrew/bin" \
    "/opt/homebrew/sbin" \
    "/opt/local/bin" \
    "/opt/local/sbin" \
    "/run/current-system/sw/bin" \
    "/nix/var/nix/profiles/default/bin" \
    "/usr/local/bin" \
    "/usr/local/sbin" \
    "/usr/bin" \
    "/usr/sbin" \
    "/bin" \
    "/sbin" \
)
# Prepend my_path to path
path[0,${#my_path[@]}]="${my_path[@]}" "${path[@]}"

# Prevent duplicate entries in PATH and FPATH
typeset -U PATH path FPATH fpath

# for _dir in `echo "${PATH}" | tr ':' '\n'`; do
#     echo "${_dir}"
# done

#_field_prepend PATH "/run/current-system/sw/bin"
#_field_prepend PATH "${HOME}/.local/bin"
#_field_prepend PATH "${HOME}/.local/sbin"
#_field_prepend PATH "${HOME}/bin"
#_field_prepend PATH "${HOME}/sbin"
## }}}    ## [_path]
#
