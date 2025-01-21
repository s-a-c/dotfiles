[[ "$(uname)" == "Darwin" ]] && [[ -s "${ZDOTDIR}/saved_macos_defaults.plist" ]] && defaults read >|"${ZDOTDIR}/saved_macos_defaults.plist"
