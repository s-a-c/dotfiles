#!/usr/bin/env zsh
# Disable ZQS auto-update system to prevent infinite loops
# This prevents the _check-for-zsh-quickstart-update function from running
unset QUICKSTART_KIT_REFRESH_IN_DAYS

# Also disable the problematic colorscript that's causing errors
if [[ -f "/usr/local/bin/colorscript" ]]; then
    alias colorscript='echo "colorscript disabled due to PATH issues"'
fi
