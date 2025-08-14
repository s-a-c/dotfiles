#!/bin/bash

# Neovim Spotlight-style popup using Alacritty terminal
# Usage: ./nvim-popup-alacritty.sh [file]

# Check if alacritty is available
if ! command -v alacritty &> /dev/null; then
    echo "Alacritty terminal is required. Install with: brew install alacritty"
    exit 1
fi

# Configuration
COLUMNS=100
LINES=30

# Create temporary alacritty config
TEMP_CONFIG=$(mktemp).yml
cat > "$TEMP_CONFIG" << EOF
window:
  dimensions:
    columns: $COLUMNS
    lines: $LINES
  position:
    x: 0
    y: 0
  padding:
    x: 10
    y: 10
  opacity: 0.95
  decorations: buttonless
  startup_mode: Windowed
  title: Neovim
  class:
    instance: nvim-popup
    general: nvim-popup

font:
  size: 14.0

colors:
  primary:
    background: '#1a1b26'
    foreground: '#c0caf5'
  cursor:
    cursor: '#c0caf5'
    text: '#1a1b26'

bell:
  animation: EaseOutExpo
  duration: 0
EOF

# Launch alacritty with popup configuration
alacritty \
    --config-file "$TEMP_CONFIG" \
    --command nvim "$@" &

# Get the PID and center the window
ALACRITTY_PID=$!
sleep 0.5

# Use AppleScript to center the window (macOS specific)
osascript << EOF
tell application "System Events"
    set frontApp to name of first application process whose frontmost is true
    if frontApp is "Alacritty" then
        tell process "Alacritty"
            set frontWindow to front window
            set screenSize to size of (first desktop)
            set windowSize to size of frontWindow
            set newX to (item 1 of screenSize - item 1 of windowSize) / 2
            set newY to (item 2 of screenSize - item 2 of windowSize) / 2
            set position of frontWindow to {newX, newY}
        end tell
    end if
end tell
EOF

# Wait for alacritty to finish, then clean up
wait $ALACRITTY_PID
rm "$TEMP_CONFIG"
