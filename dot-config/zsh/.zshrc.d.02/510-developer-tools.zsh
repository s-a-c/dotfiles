#!/usr/bin/env zsh
# Filename: 510-developer-tools.zsh
# Purpose:  Configures environment and PATH for various developer tools, including Laravel Herd, LM Studio, and Console Ninja. Features: - Detects Laravel Herd and sources its specific shell configuration. - Adds Herd's binary directory to the PATH. - Adds LM Studio's binary directory to the PATH if it exists. - Adds Console Ninja's binary directory to the PATH if it exists.
# Phase:    Post-plugin (.zshrc.d/)

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# --- Laravel Herd ---
{
  if [[ -d "/Applications/Herd.app" ]]; then
    # Source Herd's shell configuration if it exists
    local herd_rc="/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh"
    if [[ -f "$herd_rc" ]]; then
      source "$herd_rc"
    fi

    # Add Herd's bin directory to the PATH
    zf::path_prepend "${HOME}/Library/Application Support/Herd/bin/"
    zf::debug "# [dev-tools] Laravel Herd environment"

    # --- Herd PHP INI Configuration ---
    # Dynamically configure INI scan directories for all available PHP versions.
    () {
      # Run in a subshell to keep variables local.

      # Define the base path for Herd's PHP configurations.
      local herd_php_base_path="$HOME/Library/Application Support/Herd/config/php"

      # Ensure the directory exists before proceeding.
      if [[ ! -d "$herd_php_base_path" ]]; then
        zf::debug "# [dev-php] Herd PHP config directory not found at $herd_php_base_path"
        return 0
      fi

      # Declare an associative array (hash) to hold the paths.
      typeset -A herd_php_paths

      # Populate the associative array with PHP version paths.
      # The `(/N)` glob qualifiers:
      #   - `/`: matches only directories.
      #   - `N`: ensures the command doesn't fail if no directories are found (null glob).
      for dir in "$herd_php_base_path"/*(/N); do
        # Get the directory name (e.g., "84") as the key using the `:t` modifier.
        local key=${dir:t}

        # Store the full path.
        herd_php_paths[$key]=$dir
      done

      # Export an environment variable for each found PHP version.
      # The `${(@k)var}` syntax expands to the keys of the associative array.
      for key in "${(@k)herd_php_paths}"; do
        # Construct and export the variable, e.g., HERD_PHP_84_INI_SCAN_DIR.
        # The variable name is constructed dynamically, and the value is quoted to handle spaces.
        export HERD_PHP_${key}_INI_SCAN_DIR="${herd_php_paths[$key]}/"
        zf::debug "# [dev-php] Herd PHP ${key} INI scan dir set"
      done
    }
  fi
}

# --- LM Studio ---
if [[ -d "${HOME}/.lmstudio/bin" ]]; then
  zf::path_prepend "${HOME}/.lmstudio/bin"
  zf::debug "# [dev-tools] LM Studio CLI added to PATH"
fi

# --- Console Ninja ---
if [[ -d "${HOME}/.console-ninja/.bin" ]]; then
  zf::path_prepend "${HOME}/.console-ninja/.bin"
  zf::debug "# [dev-tools] Console Ninja added to PATH"
fi

return 0
