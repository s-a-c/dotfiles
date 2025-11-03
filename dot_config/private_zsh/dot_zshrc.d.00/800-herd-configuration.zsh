# Herd Configuration
# Integration with Herd PHP development environment

# Only load Herd configuration if the application exists
if [[ -d "/Applications/Herd.app" ]]; then
  # PHP 8.4 configuration
  export HERD_PHP_84_INI_SCAN_DIR="${HOME}/Library/Application Support/Herd/config/php/84/"

  # PHP 8.5 configuration
  export HERD_PHP_85_INI_SCAN_DIR="${HOME}/Library/Application Support/Herd/config/php/85/"

  # NVM configuration
  export NVM_DIR="${HOME}/Library/Application Support/Herd/config/nvm"
  [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh" # This loads nvm

  # Source Herd shell configuration
  [[ -f "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh" ]] &&
    builtin source "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh"

  # Add Herd bin to PATH
  export PATH="${HOME}/Library/Application Support/Herd/bin/":$PATH
fi

# Console-ninja configuration (independent of Herd check)
[[ -d ~/.console-ninja/.bin ]] && PATH=~/.console-ninja/.bin:$PATH
