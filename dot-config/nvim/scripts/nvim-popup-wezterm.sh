#!/bin/bash

# Neovim Spotlight-style popup using WezTerm
# Usage: ./nvim-popup-wezterm.sh [file]

# Check if wezterm is available
if ! command -v wezterm &> /dev/null; then
    echo "WezTerm is required. Install with: brew install wezterm"
    exit 1
fi

# Configuration
COLUMNS=100
LINES=30

# Create temporary wezterm config
TEMP_CONFIG=$(mktemp).lua
cat > "$TEMP_CONFIG" << 'EOF'
local wezterm = require 'wezterm'

return {
  -- Window configuration
  initial_cols = 100,
  initial_rows = 30,
  window_decorations = "RESIZE",
  window_background_opacity = 0.95,
  macos_window_background_blur = 20,
  
  -- Font configuration
  font_size = 14.0,
  
  -- Color scheme (Tokyo Night)
  colors = {
    foreground = '#c0caf5',
    background = '#1a1b26',
    cursor_bg = '#c0caf5',
    cursor_fg = '#1a1b26',
    cursor_border = '#c0caf5',
    selection_fg = '#c0caf5',
    selection_bg = '#33467C',
    scrollbar_thumb = '#292e42',
    split = '#7aa2f7',
  },
  
  -- Disable tabs for cleaner look
  enable_tab_bar = false,
  
  -- Window padding
  window_padding = {
    left = 10,
    right = 10,
    top = 10,
    bottom = 10,
  },
  
  -- Disable bell
  audible_bell = "Disabled",
  
  -- Window positioning
  window_close_confirmation = "NeverPrompt",
}
EOF

# Launch wezterm with popup configuration
wezterm \
    --config-file "$TEMP_CONFIG" \
    start \
    --class nvim-popup \
    -- nvim "$@" &

# Get the PID and center the window
WEZTERM_PID=$!
sleep 0.5

# Use AppleScript to center and focus the window
osascript << EOF
tell application "System Events"
    repeat with proc in application processes
        if name of proc is "wezterm-gui" then
            tell proc
                set frontWindow to front window
                set screenSize to size of (first desktop)
                set windowSize to size of frontWindow
                set newX to (item 1 of screenSize - item 1 of windowSize) / 2
                set newY to (item 2 of screenSize - item 2 of windowSize) / 2
                set position of frontWindow to {newX, newY}
                set frontmost to true
            end tell
            exit repeat
        end if
    end repeat
end tell
EOF

# Wait for wezterm to finish, then clean up
wait $WEZTERM_PID
rm "$TEMP_CONFIG"
