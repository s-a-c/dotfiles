#!/bin/bash

# Neovim Spotlight-style launcher
# Usage: ./nvim-spotlight.sh [file]

# Configuration
WINDOW_WIDTH=1000
WINDOW_HEIGHT=600
TRANSPARENCY=0.95

# Get screen dimensions for centering
SCREEN_WIDTH=$(system_profiler SPDisplaysDataType | grep Resolution | awk '{print $2}' | head -1)
SCREEN_HEIGHT=$(system_profiler SPDisplaysDataType | grep Resolution | awk '{print $4}' | head -1)

# Calculate center position
POS_X=$(( (SCREEN_WIDTH - WINDOW_WIDTH) / 2 ))
POS_Y=$(( (SCREEN_HEIGHT - WINDOW_HEIGHT) / 2 ))

# Launch Neovide with spotlight-like appearance
neovide \
    --geometry=${WINDOW_WIDTH}x${WINDOW_HEIGHT}+${POS_X}+${POS_Y} \
    --transparency=${TRANSPARENCY} \
    --no-tabs \
    --maximized=false \
    --frame=none \
    "$@"
