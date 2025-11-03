#!/usr/bin/env bash
# ==============================================================================
# Fix VSCode Insiders Terminal Integration
# ==============================================================================
# Purpose: Fix VSCode terminal to use zsh and remove invalid fish path
# Issues:
#   1. VSCode launching bash instead of zsh
#   2. Fish shell error with invalid path "opt/homebrew/bin/fish"
# ==============================================================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================================================="
echo "VSCode Insiders Terminal Integration Fix"
echo -e "===================================================================${NC}"
echo ""

# Detect VSCode Insiders settings location
VSCODE_SETTINGS="$HOME/Library/Application Support/Code - Insiders/User/settings.json"

if [[ ! -f "$VSCODE_SETTINGS" ]]; then
  echo -e "${RED}✗ VSCode Insiders settings not found at:${NC}"
  echo "  $VSCODE_SETTINGS"
  echo ""
  echo "Trying VSCode (stable)..."
  VSCODE_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"

  if [[ ! -f "$VSCODE_SETTINGS" ]]; then
    echo -e "${RED}✗ VSCode settings not found either.${NC}"
    echo ""
    echo "Please manually fix VSCode settings:"
    echo "  1. Open VSCode Settings (Cmd+,)"
    echo "  2. Search for 'terminal.integrated.defaultProfile.osx'"
    echo "  3. Set to 'zsh'"
    echo "  4. Search for 'terminal.integrated.profiles.osx'"
    echo "  5. Fix or remove the fish entry"
    exit 1
  fi
fi

echo -e "${GREEN}✓ Found VSCode settings:${NC}"
echo "  $VSCODE_SETTINGS"
echo ""

# Create backup
BACKUP_FILE="${VSCODE_SETTINGS}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$VSCODE_SETTINGS" "$BACKUP_FILE"
echo -e "${GREEN}✓ Created backup:${NC}"
echo "  $BACKUP_FILE"
echo ""

# Check if settings.json is valid JSON
if ! python3 -m json.tool "$VSCODE_SETTINGS" >/dev/null 2>&1; then
  echo -e "${RED}✗ Invalid JSON in settings file!${NC}"
  echo "  Please fix manually or restore from backup"
  exit 1
fi

# Use Python to safely update the JSON
python3 - "$VSCODE_SETTINGS" << 'EOF'
import json
import sys

settings_file = sys.argv[1]

# Read current settings
with open(settings_file, 'r') as f:
    settings = json.load(f)

# Fix terminal settings
settings['terminal.integrated.defaultProfile.osx'] = 'zsh'

# Ensure profiles exist
if 'terminal.integrated.profiles.osx' not in settings:
    settings['terminal.integrated.profiles.osx'] = {}

# Set bash profile
settings['terminal.integrated.profiles.osx']['bash'] = {
    'args': ['-l'],
    'icon': 'terminal-bash',
    'path': '/bin/bash'
}

# Set bash (brew) profile
settings['terminal.integrated.profiles.osx']['bash brew'] = {
    'args': ['-l'],
    'icon': 'terminal-bash',
    'path': '/opt/homebrew/bin/bash'
}

# Set powershell profile
settings['terminal.integrated.profiles.osx']['pwsh'] = {
    'icon': 'terminal-powershell',
    'path': '/usr/local/bin/pwsh'
}

# Set tmux profile
settings['terminal.integrated.profiles.osx']['tmux'] = {
    'icon': 'terminal-tmux',
    'path': '/opt/homebrew/bin/tmux'
}

# Set zsh profile
settings['terminal.integrated.profiles.osx']['zsh'] = {
    'args': ['-l'],
    'icon': 'terminal-bash',
    'path': '/bin/zsh'
}

# Set zsh (brew) profile
settings['terminal.integrated.profiles.osx']['zsh brew'] = {
    'args': ['-l'],
    'icon': 'terminal-bash',
    'path': '/opt/homebrew/bin/zsh'
}

# Fix fish profile if it exists (add leading /)
if 'fish' in settings['terminal.integrated.profiles.osx']:
    fish_profile = settings['terminal.integrated.profiles.osx']['fish']
    if isinstance(fish_profile, dict) and 'path' in fish_profile:
        # Fix path if it's missing leading /
        if fish_profile['path'] == 'opt/homebrew/bin/fish':
            fish_profile['path'] = '/opt/homebrew/bin/fish'
        # Check if fish actually exists
        import os
        if not os.path.exists(fish_profile['path']):
            print(f"  ⚠ Fish shell not found at {fish_profile['path']}, removing profile")
            del settings['terminal.integrated.profiles.osx']['fish']

# Enable shell integration
settings['terminal.integrated.shellIntegration.enabled'] = True
settings['terminal.integrated.inheritEnv'] = True

# Write updated settings
with open(settings_file, 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')  # Add trailing newline

print("✓ Settings updated successfully")
EOF

echo ""
echo -e "${GREEN}==================================================================="
echo "Fix Applied Successfully!"
echo -e "===================================================================${NC}"
echo ""
echo "Changes made:"
echo "  ✓ Set default terminal profile to 'zsh'"
echo "  ✓ Configured zsh profile with /bin/zsh"
echo "  ✓ Configured bash profile with /bin/bash"
echo "  ✓ Fixed or removed invalid fish profile"
echo "  ✓ Enabled shell integration"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Reload VSCode: Cmd+Shift+P → 'Developer: Reload Window'"
echo "  2. Open new terminal: Ctrl+\` or Terminal > New Terminal"
echo "  3. Verify: Run 'echo \$SHELL' (should show /bin/zsh)"
echo ""
echo "If something went wrong, restore from backup:"
echo "  cp \"$BACKUP_FILE\" \"$VSCODE_SETTINGS\""
echo ""
