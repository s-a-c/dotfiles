
[[ "$ZSH_DEBUG" == "1" ]] && {
<<<<<<< HEAD
        zf::debug "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
    # Add this check to detect errant file creation:
    if [[ -f "${ZDOTDIR:-$HOME}/2" ]] || [[ -f "${ZDOTDIR:-$HOME}/3" ]]; then
            zf::debug "Warning: Numbered files detected - check for redirection typos"
=======
        zsh_debug_echo "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
    # Add this check to detect errant file creation:
    if [[ -f "${ZDOTDIR:-$HOME}/2" ]] || [[ -f "${ZDOTDIR:-$HOME}/3" ]]; then
            zsh_debug_echo "Warning: Numbered files detected - check for redirection typos"
>>>>>>> origin/develop
    fi
}

[[ "$(uname)" == "Darwin" ]] && {
    # Note: macOS defaults configuration moved to deferred execution system
    # See: ~/.config/zsh/.zshrc.pre-plugins.d/03-macos-defaults-deferred.zsh
    # And: ~/.config/zsh/bin/macos-defaults-setup.zsh

    # Only keep the defaults read for comparison/backup purposes (fast operation)
    defaults read >| "${ZDOTDIR}/saved_macos_defaults.plist"
}
