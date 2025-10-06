# Emergency Procedures & Current Workarounds

## 🚨 Current Status: Emergency Mode Active

**Emergency configuration is currently active** providing basic ZSH functionality while the main configuration is being debugged.

## 🛠️ Emergency Mode Details

### What's Working
- ✅ **Starship prompt** - Full functionality
- ✅ **ZLE system** - Widget registration working
- ✅ **Basic completion** - Tab completion functional
- ✅ **Command execution** - All standard commands work
- ✅ **History** - Command history available
- ✅ **File operations** - All file system operations
- ✅ **Environment variables** - Proper environment setup

### What's Missing
- ❌ **Advanced plugins** - Syntax highlighting, autosuggestions, etc.
- ❌ **Custom key bindings** - Advanced ZLE widgets
- ❌ **Oh-My-Zsh features** - Plugin ecosystem
- ❌ **Custom aliases/functions** - User-defined shortcuts
- ❌ **Advanced completion** - Plugin-enhanced completions

## 🔄 Mode Management

### Switch to Emergency Mode
```bash
cd ~/dotfiles/dot-config/zsh
./emergency-mode
```

### Restore Normal Mode
```bash
cd ~/dotfiles/dot-config/zsh
./restore-normal-mode
```

### Check Current Mode
```bash
# Emergency mode active if this file exists:
ls -la .zshrc.emergency

# Check which .zshrc is active:
head -5 .zshrc
```

## 📁 Emergency Files

### Core Files
- **`.zshrc.emergency`** - Minimal working configuration
- **`emergency-mode`** - Script to activate emergency mode
- **`restore-normal-mode`** - Script to restore normal configuration
- **`.zshrc.backup.*`** - Timestamped backups of original .zshrc

### Debug Files
- **`.zshenv.local`** - Debug hook for investigation
- **`debug-load-fragments-wrapper`** - Alternative debug approach
- **`docs/fix-zle/`** - Complete investigation documentation

## 🧪 Testing Procedures

### Test Emergency Mode
```bash
# Start new shell and verify:
zsh

# Test ZLE functionality:
test-widget() { echo "ZLE works"; }
zle -N test-widget && echo "✅ ZLE: SUCCESS" || echo "❌ ZLE: FAILED"

# Test Starship:
echo $STARSHIP_SHELL  # Should show "zsh"

# Test basic completion:
ls <TAB>  # Should show file completions
```

### Test Main Configuration (Debugging)
```bash
# Enable debug mode:
DEBUG_LOAD_FRAGMENTS=1 ZDOTDIR="$PWD" zsh -i

# This will show detailed loading information and identify problems
```

## 🚨 Troubleshooting

### If Emergency Mode Fails
```bash
# Use absolute minimal ZSH:
env -i HOME="$HOME" USER="$USER" TERM="$TERM" PATH="$PATH" zsh

# Or use system default:
zsh -f  # Start with no configuration files
```

### If You Get Locked Out
```bash
# Use bash as fallback:
bash

# Or force clean ZSH:
ZDOTDIR="" zsh -f
```

### Recovery Commands
```bash
# Reset to emergency mode:
cd ~/dotfiles/dot-config/zsh
cp .zshrc.emergency .zshrc

# Clear all caches:
rm -rf .zqs-zgenom/init.zsh .zqs-zgenom/init.zsh.zwc

# Start completely fresh:
mv .zshrc .zshrc.broken
cp .zshrc.emergency .zshrc
```

## 📋 Daily Usage in Emergency Mode

### Essential Commands Available
```bash
# Navigation
cd, ls, pwd, find

# File operations  
cp, mv, rm, mkdir, touch

# Text processing
cat, less, grep, sed, awk

# Development
git, vim, code

# System
ps, top, df, du, which
```

### Missing Conveniences
- No syntax highlighting while typing
- No autosuggestions from history
- Limited tab completion enhancements
- No custom aliases (can add manually to .zshrc.emergency)
- No advanced prompt features beyond Starship basics

### Temporary Workarounds
```bash
# Add temporary aliases to .zshrc.emergency:
echo "alias ll='ls -la'" >> .zshrc.emergency
echo "alias la='ls -A'" >> .zshrc.emergency

# Source changes:
source .zshrc.emergency
```

## 🔍 Debug Mode Usage

### Enable Debug Hook
```bash
# Set environment variable:
export DEBUG_LOAD_FRAGMENTS=1

# Start ZSH - will show detailed loading info:
ZDOTDIR="$PWD" zsh -i
```

### Debug Output Interpretation
- **✅ ZLE: OK** - ZLE working at this point
- **❌ ZLE: BROKEN** - ZLE failed at this point  
- **🚨 CULPRIT IDENTIFIED** - Found the problematic file
- **📂 Loading fragments** - Shows which directory is being processed
- **📄 Loading: filename** - Shows individual file being loaded

## ⚠️ Important Notes

### Do Not Modify
- **`.zshrc.emergency`** - Keep this as stable fallback
- **`.zshenv.local`** - Debug hook, needed for investigation
- **Backup files** - May need for recovery

### Safe to Modify
- **`.zshrc`** - Will be restored anyway
- **Custom configuration files** - Part of debugging process
- **Cache files** - Can be regenerated

### Before Making Changes
1. Ensure emergency mode is working
2. Create additional backups if needed
3. Document what you're testing
4. Have rollback plan ready

## 🎯 Success Indicators

### Emergency Mode Working
- New ZSH sessions start without errors
- Starship prompt appears correctly
- Basic commands work normally
- Tab completion functions

### Ready to Test Main Config
- Emergency mode stable
- Debug tools in place
- Investigation plan ready
- Backup procedures confirmed
