# Use ZERO variable if available (set by zgenom), otherwise fallback to $0
local plugin_script="${ZERO:-$0}"
local plugin_dir="${plugin_script:h}"

# Verify the plugin dir contains the expected file
if [[ -f "$plugin_dir/zsh-autosuggestions.zsh" ]]; then
  source "$plugin_dir/zsh-autosuggestions.zsh"
else
  echo "Error: zsh-autosuggestions.zsh not found in $plugin_dir" >&2
fi
