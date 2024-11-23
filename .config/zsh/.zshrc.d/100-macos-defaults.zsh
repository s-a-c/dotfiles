if [[ "$(uname)" == "Darwin" ]]; then
    defaults read >| "${ZDDOTDIR}/saved_macos_defaults.plist"
fi
