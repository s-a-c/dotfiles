
[[ -n "$ZSH_DEBUG" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
    # Add this check to detect errant file creation:
    if [[ -f "${ZDOTDIR:-$HOME}/2" ]] || [[ -f "${ZDOTDIR:-$HOME}/3" ]]; then
        echo "Warning: Numbered files detected - check for redirection typos" >&2
    fi
}

# [splash_screen]
{
    if [[ -n "${commands[lolcat]}" ]]; then
        [[ -n "${commands[colorscript]}" ]] && colorscript random | lolcat
    else
        [[ -n "${commands[colorscript]}" ]] && colorscript random
    fi
    [[ -n "${commands[fastfetch]}" ]] && fastfetch
}
