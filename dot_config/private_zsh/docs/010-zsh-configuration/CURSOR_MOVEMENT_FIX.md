# ZSH Cursor Movement Fix Documentation

## Problem Description
Left arrow key cursor movement was erratic - the cursor would only go back so far and then skip up to the prompt line.

## Root Cause
The shell was operating in **VI mode** instead of Emacs mode:
- Main keymap was aliased to `viins` (VI insert mode)
- Arrow keys were bound to `vi-backward-char` and `vi-forward-char`
- VI mode has different cursor movement behavior that can be restrictive

## Solution Applied
Created `~/.config/zsh/.zshrc.d.00/999-force-emacs-mode.zsh` which:
1. Forces emacs mode with `bindkey -e`
2. Explicitly binds arrow keys to proper functions in emacs keymap
3. Provides fallback bindings for various terminal escape sequences
4. Exports `KEYMAP=emacs` environment variable
5. Loads last (999- prefix) to override any plugin settings

## How to Apply the Fix
```bash
# Reload your shell configuration
source ~/.zshrc

# Or open a new terminal window
```

## Verification Commands
```bash
# Check if emacs mode is active (should show "bindkey -A emacs main")
bindkey -lL | grep main

# Check KEYMAP variable (should output "emacs")
echo $KEYMAP

# Check arrow key bindings (should show "backward-char", not "vi-backward-char")
bindkey | grep '^\"\^\\[\\[D\"'

# Full diagnostic
zsh -c 'bindkey -lL; echo ""; bindkey | grep -E "(\\^\[\[D|\\^\[\[C)"'
```

## Expected Behavior After Fix
- LEFT ARROW: Moves cursor left through entire command line
- RIGHT ARROW: Moves cursor right through entire command line  
- UP ARROW: Navigate command history
- DOWN ARROW: Navigate command history
- Ctrl+A: Jump to beginning of line
- Ctrl+E: Jump to end of line
- Ctrl+B: Move backward one character
- Ctrl+F: Move forward one character

## Alternative Solutions (if needed)

### Option 1: Disable the fix and use VI mode properly
If you actually want VI mode, remove or rename the fix file:
```bash
mv ~/.config/zsh/.zshrc.d.00/999-force-emacs-mode.zsh{,.disabled}
```

Then learn VI mode keybindings:
- In insert mode: Arrow keys should work
- Press ESC to enter command mode
- In command mode: h/l for left/right, 0/$ for line start/end

### Option 2: Find and disable the VI mode plugin
```bash
# Search for the culprit
grep -r "bindkey -v\|vi-mode" ~/.config/zsh --include="*.zsh" ! -path "*/.backup/*"
```

### Option 3: Set in .zshenv (earlier override)
Add to `~/.zshenv`:
```zsh
export KEYMAP=emacs
```

## Files Modified
- Created: `~/.config/zsh/.zshrc.d.00/999-force-emacs-mode.zsh`
- Modified: `~/.config/zsh/.zshrc.d.00/540-user-interface.zsh` (added arrow key bindings)

## Rollback Instructions
To revert if needed:
```bash
rm ~/.config/zsh/.zshrc.d.00/999-force-emacs-mode.zsh
source ~/.zshrc
```

## Additional Notes
- The fix uses `999-` prefix to ensure it loads last, after all plugins
- Both standard (`^[[X`) and application mode (`^[OX`) escape sequences are bound
- macOS-specific modifier key combinations are included (Option/Cmd + arrows)
- The fix works even if zgenom/oh-my-zsh plugins try to set VI mode

## Testing
A test was performed and confirmed:
- ✅ Emacs mode activated
- ✅ Arrow keys correctly bound to backward-char/forward-char
- ✅ KEYMAP variable set to "emacs"
- ✅ Main keymap aliased to emacs

Date Fixed: 2025-10-14
