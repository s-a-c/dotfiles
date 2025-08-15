##
## This file is sourced by zsh upon start-up. It should contain commands to set
## up aliases, functions, options, key bindings, etc.
##

# vim: ft=zsh sw=4 ts=4 et nu rnu ai si

[[ -n "$ZSH_DEBUG" ]] && printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2

## [_path]
{
    [[ -n "$ZSH_DEBUG" ]] && echo "# [_path]" >&2

    ## [path.golang]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [path.golang]" >&2
        export GOPATH=$HOME/go
        export GOROOT=/opt/homebrew/opt/go/libexec
        _path_prepend "$GOROOT/bin"
        _path_prepend "$GOPATH/bin"
    }

    ## [my_path]
    {
        [[ -n "$ZSH_DEBUG" ]] && echo "# [my_path]" >&2

        _path_prepend \
            "/sbin" \
            "/bin" \
            "/usr/sbin" \
            "/usr/bin" \
            "/usr/local/sbin" \
            "/usr/local/bin" \
            "/nix/var/nix/profiles/default/bin" \
            "/run/current-system/sw/bin" \
            "/opt/local/sbin" \
            "/opt/local/bin" \
            "/home/linuxbrew/.linuxbrew/sbin" \
            "/home/linuxbrew/.linuxbrew/bin" \
            "$ZDOTDIR/.linuxbrew/sbin" \
            "$ZDOTDIR/.linuxbrew/bin" \
            "/opt/homebrew/sbin" \
            "/opt/homebrew/bin" \
            "/opt/homebrew/opt/go/libexec/bin" \
            "$GOROOT/bin" \
            "$GOPATH/bin" \
            "/Applications/Xcode.app/Contents/Developer/usr/bin" \
            "/Applications/Herd.app/Contents/Resources" \
            "$ZDOTDIR/src/gocode/bin" \
            "$ZDOTDIR/gocode" \
            "$ZDOTDIR/bin" \
            "$ZDOTDIR/.rbenv/bin" \
            "$ZDOTDIR/.cargo/bin" \
            "$ZDOTDIR/.cabal/bin" \
            "$HOME/.nix-profile/sbin" \
            "$HOME/.nix-profile/bin" \
            "$HOME/Library/Application Support/Herd" \
            "$HOME/Library/Application Support/Herd/bin" \
            "$HOME/.turso" \
            "$HOME/.local/share/bob" \
            "$HOME/.local/sbin" \
            "$HOME/.local/bin" \
            "$HOME/sbin" \
            "$HOME/bin"

        [[ -n "$ZSH_DEBUG" ]] && {
            local _dir
            local IFS=':'
            for _dir in ${PATH}; do
                [[ -n "$_dir" ]] && echo "${_dir}" >&2
            done
        }
    }
}
