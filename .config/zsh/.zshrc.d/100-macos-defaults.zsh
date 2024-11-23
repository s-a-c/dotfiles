if [[ "$(uname)" == "Darwin" ]]; then
    defaults read >| "${ZDOTDIR}/saved_macos_defaults.plist"
fi
