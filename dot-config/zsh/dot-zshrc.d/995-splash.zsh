typeset -U PATH

## [splash_screen]  ## {{{
if [[ -n "${commands[lolcat]}" ]]; then
    [[ -n "${commands[colorscript]}" ]] && colorscript random | lolcat
else
    [[ -n "${commands[colorscript]}" ]] && colorscript random
fi
[[ -n "${commands[fastfetch]}" ]] && fastfetch
## }}}  ## [splash_screen]
