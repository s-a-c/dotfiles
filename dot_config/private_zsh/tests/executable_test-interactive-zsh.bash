#!/opt/homebrew/bin/bash
# test-interactive-zsh.bash - Test interactive ZSH behavior

echo "=== INTERACTIVE ZSH TEST ==="
echo "Running from bash (PID: $$)"
echo "Testing interactive ZSH startup..."
echo

# Test 1: Check if ZSH starts interactively from bash
echo "Test 1: Manual interactive ZSH launch"
echo "About to run: ZDOTDIR=/Users/s-a-c/.config/zsh zsh -i"
echo "This should show your ZSH prompt. Type 'exit' to return to bash."
echo "Press Enter to continue..."
read -r

echo "Launching interactive ZSH..."
ZDOTDIR="${HOME}/.config/zsh" zsh -i

echo
echo "=== BACK IN BASH ==="
echo "Exit code from ZSH: $?"
echo

# Test 2: Quick ZSH version info
echo "Test 2: ZSH version and info"
ZDOTDIR="${HOME}/.config/zsh" zsh -c 'echo "ZSH Version: $ZSH_VERSION"; echo "ZDOTDIR: $ZDOTDIR"; echo "Shell: $0"'

echo
echo "=== WARP CONFIGURATION INFO ==="
echo "To fix Warp, you need to:"
echo "1. Open Warp Settings (Cmd+,)"
echo "2. Go to 'Features' -> 'Session'"
echo "3. Find 'Startup shell for new sessions'"
echo "4. Change from 'zsh' to '/opt/homebrew/bin/bash'"
echo
echo "Or set a custom shell path to '/opt/homebrew/bin/bash'"
echo
echo "This will make Warp use bash as the startup shell."
echo "Then you can manually run 'zsh -i' when you want ZSH."
