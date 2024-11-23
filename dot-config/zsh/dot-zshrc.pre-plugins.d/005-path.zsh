
## [_path]    ## {{{
## [_path.remove] ## {{{
function _path_remove() {
    for ARG in "$@"; do
        while [[ ":$PATH:" == *":$ARG:"* ]]; do
            ## Delete path by parts so we can never accidentally remove sub paths
            [[ "$PATH" == "$ARG" ]] && PATH=""
            PATH=${PATH//":$ARG:"/":"}    ## delete any instances in the middle
            PATH=${PATH/#"$ARG:"/}    ## delete any instance at the beginning
            PATH=${PATH/%":$ARG"/}    ## delete any instance in the at the end
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
_path_append ${HOME}/.local/bin \
    ${HOME}/bin \
    ${HOME}/.local/sbin \
    ${HOME}/sbin \
    ${HOME}/.nix-profile/bin \
    ${HOME}/.nix-profile/sbin \
    /opt/homebrew/bin \
    /opt/homebrew/sbin \
    /run/current-system/sw/bin \
    /nix/var/nix/profiles/default/bin \
    /usr/local/bin \
    /usr/bin \
    /usr/sbin \
    /bin \
    /sbin

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
