#!/bin/bash

# Neovim Spotlight-style popup using Kitty terminal
# Usage: ./nvim-popup.sh [file]

# Check if kitty is available
if ! command -v kitty &> /dev/null; then
    echo "Kitty terminal is required. Install with: brew install kitty"
    exit 1
fi

# Configuration
WINDOW_WIDTH="80c"   # 80 columns
WINDOW_HEIGHT="24r"  # 24 rows
OPACITY="0.95"

# Create a temporary kitty config for the popup
TEMP_CONFIG=$(mktemp)
cat > "$TEMP_CONFIG" << EOF
# Popup window configuration
background_opacity $OPACITY
window_padding_width 10
font_size 14.0
cursor_blink_interval 0
enable_audio_bell no
window_border_width 1pt
active_border_color #7aa2f7
inactive_border_color #414868
bell_border_color #e0af68
EOF

# Launch kitty with popup-like appearance
kitty \
    --config="$TEMP_CONFIG" \
    --class="nvim-popup" \
    --title="Neovim" \
    --override="remember_window_size=no" \
    --override="initial_window_width=$WINDOW_WIDTH" \
    --override="initial_window_height=$WINDOW_HEIGHT" \
    --override="placement_strategy=center" \
    nvim "$@"

# Clean up
rm "$TEMP_CONFIG"
