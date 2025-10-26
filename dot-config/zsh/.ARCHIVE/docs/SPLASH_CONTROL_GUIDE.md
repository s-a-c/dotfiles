# ZSH Splash Screen & Visual Control Guide

## 🎛️ Control Options Overview

All splash and visual control options are defined in `.zshenv` with defaults of `0`. When all options are `0` (default), the splash screen displays with all visual elements enabled. You only need to set options to `1` to disable specific features.

## 📋 Available Control Variables

### 🚀 Splash Screen Control
```bash
export ZSH_DISABLE_SPLASH=0        # 1 = completely disable splash screen
export ZSH_ENABLE_HEALTH_CHECK=0   # 1 = show system health check in splash
export ZSH_DISABLE_TIPS=0          # 1 = disable performance tips
export ZSH_MINIMAL=0               # 1 = minimal startup mode
export FORCE_SPLASH=0              # 1 = force splash to show (bypass daily limit)
```

### 🎨 Visual Elements Control
```bash
export ZSH_DISABLE_FASTFETCH=0     # 1 = disable system info display
export ZSH_DISABLE_COLORSCRIPT=0   # 1 = disable colorful terminal art
export ZSH_DISABLE_LOLCAT=0        # 1 = disable rainbow text effects
```

### ⚡ Performance & Logging Control
```bash
export ZF_ASSERT_EXIT=0            # 1 = make zf:: assertions fatal
export ZF_WITH_TIMING_EMIT=auto    # auto/1/0 = segment emission control
export ZSH_PERF_TRACK=0            # 1 = enable performance tracking
export PERF_SEGMENT_LOG=""         # path for performance logs (auto-set if tracking enabled)
export PERF_SEGMENT_TRACE=0        # 1 = enable segment tracing
```

### 🔒 Security & Integration Control
```bash
export ZSH_SEC_DISABLE_AUTO_DEDUP=0        # 1 = disable PATH deduplication
export ZSH_INTERACTIVE_OPTIONS_STRICT=0    # 1 = enable strict shell options
export ZSH_AUTOSUGGEST_SSH_DISABLE=0       # 1 = disable autosuggestions in SSH
export ZSH_SUPPRESS_WELCOME=0              # 1 = suppress welcome messages
```

## 🔧 Usage Examples

### Default Behavior (All Options = 0)
```bash
# Default: Full splash with all visual elements
# - Colorful terminal art (colorscript + lolcat)
# - System information (fastfetch)
# - Welcome banner
# - Performance tips
# - Daily display limit (once per day)
```

### Disable Splash Completely
```bash
export ZSH_DISABLE_SPLASH=1
# Result: No splash screen at all
```

### Enable Health Checks
```bash
export ZSH_ENABLE_HEALTH_CHECK=1
# Result: Shows system health diagnostics in splash
```

### Disable Specific Visual Elements
```bash
export ZSH_DISABLE_FASTFETCH=1     # No system info
export ZSH_DISABLE_COLORSCRIPT=1   # No colorful art
export ZSH_DISABLE_LOLCAT=1        # No rainbow effects
# Result: Splash shows but without these specific elements
```

### Force Splash Every Time
```bash
export FORCE_SPLASH=1
# Result: Splash shows on every shell startup (ignores daily limit)
```

### Enable Performance Tracking
```bash
export ZSH_PERF_TRACK=1
# Result: Performance logs written to ${ZSH_LOG_DIR}/perf-segments-${ZSH_SESSION_ID}.log
```

### Minimal Startup Mode
```bash
export ZSH_MINIMAL=1
# Result: Skip splash and non-essential startup elements
```

## 🎨 Visual Elements Explained

### Fastfetch
- **Purpose**: Shows system information (OS, kernel, memory, etc.)
- **Control**: `ZSH_DISABLE_FASTFETCH=1` to disable
- **Requirement**: `fastfetch` command must be available

### Colorscript
- **Purpose**: Displays colorful terminal art patterns
- **Control**: `ZSH_DISABLE_COLORSCRIPT=1` to disable  
- **Requirement**: `colorscript` command must be available

### Lolcat
- **Purpose**: Adds rainbow color effects to text
- **Control**: `ZSH_DISABLE_LOLCAT=1` to disable
- **Requirement**: `lolcat` command must be available
- **Behavior**: Used with colorscript if both are available

## 🔄 Daily Display Control

By default, the splash screen shows only once per day to avoid startup clutter. Daily markers are stored in:
```
${ZSH_CACHE_DIR}/.splash_shown_YYYY-MM-DD
```

To override daily limits:
```bash
export FORCE_SPLASH=1    # Show every time
# Or manually remove marker:
rm ~/.cache/zsh/.splash_shown_*
```

## 🏗️ Configuration Methods

### Method 1: Environment Variables (Temporary)
```bash
export ZSH_DISABLE_FASTFETCH=1
exec zsh  # Restart shell to apply
```

### Method 2: .zshenv.local (Persistent)
Create or edit `~/.config/zsh/.zshenv.local`:
```bash
# My custom splash settings
export ZSH_ENABLE_HEALTH_CHECK=1
export ZSH_DISABLE_FASTFETCH=1
export FORCE_SPLASH=1
```

### Method 3: Direct .zshenv Edit
Edit the defaults directly in `~/.config/zsh/.zshenv` around line 164-178.

## 🧪 Testing Commands

### Test Current Settings
```bash
echo "ZSH_DISABLE_SPLASH: ${ZSH_DISABLE_SPLASH:-0}"
echo "ZSH_DISABLE_FASTFETCH: ${ZSH_DISABLE_FASTFETCH:-0}"
echo "ZSH_ENABLE_HEALTH_CHECK: ${ZSH_ENABLE_HEALTH_CHECK:-0}"
```

### Force Splash Display
```bash
FORCE_SPLASH=1 zsh -i -c "echo 'Splash test complete'"
```

### Test With Different Settings
```bash
ZSH_DISABLE_FASTFETCH=1 ZSH_ENABLE_HEALTH_CHECK=1 FORCE_SPLASH=1 zsh -i
```

### Check Available Tools
```bash
command -v fastfetch && echo "✅ fastfetch available"
command -v colorscript && echo "✅ colorscript available" 
command -v lolcat && echo "✅ lolcat available"
```

## 🎯 Recommended Configurations

### For Daily Use
```bash
# Default settings work great - no changes needed!
# Shows beautiful splash once per day
```

### For Development/Testing
```bash
export FORCE_SPLASH=1              # Show every startup
export ZSH_ENABLE_HEALTH_CHECK=1   # Show system diagnostics
export ZSH_PERF_TRACK=1           # Track performance
```

### For Minimal/Fast Startup
```bash
export ZSH_DISABLE_SPLASH=1       # Skip splash entirely
# OR
export ZSH_MINIMAL=1              # Minimal mode
```

### For SSH/Remote Sessions  
```bash
export ZSH_DISABLE_SPLASH=1       # Usually best for remote work
# Note: SSH sessions are auto-detected and splash is skipped unless FORCE_SPLASH=1
```

### For Headless/CI Environments
```bash
export ZSH_DISABLE_SPLASH=1
export ZSH_MINIMAL=1
export CI=1                       # Also auto-detected
```

## 🔍 Troubleshooting

### Splash Not Showing
1. Check if disabled: `echo $ZSH_DISABLE_SPLASH`
2. Check daily marker: `ls ~/.cache/zsh/.splash_shown_*`
3. Force display: `FORCE_SPLASH=1 zsh -i`

### Visual Elements Missing
1. Check tool availability: `command -v fastfetch colorscript lolcat`
2. Check disable flags: `echo $ZSH_DISABLE_FASTFETCH $ZSH_DISABLE_COLORSCRIPT`
3. Install missing tools via homebrew/package manager

### Performance Issues
1. Enable tracking: `export ZSH_PERF_TRACK=1`
2. Check logs: `tail ~/.config/zsh/logs/perf-segments-*.log`
3. Disable heavy elements if needed

---

🎉 **Your splash screen is now fully controllable!** All defaults are set to show the beautiful visual startup experience, but you can customize every aspect to your preference.