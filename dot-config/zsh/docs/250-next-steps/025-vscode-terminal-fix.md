# VSCode Insiders Terminal Integration Fix

**Date**: 2025-10-07  
**Issues**: 

1. VSCode launching bash instead of zsh (despite `chsh` setting)
2. Fish shell error: `Path to shell executable "opt/homebrew/bin/fish" does not exist`


---

## Root Causes

### Issue 1: VSCode Ignoring System Default Shell

VSCode has its own terminal profile settings that override the system default shell set by `chsh`.

### Issue 2: Invalid Fish Path

VSCode has a corrupted setting with path `opt/homebrew/bin/fish` (missing leading `/`).

---

## Fix Instructions

### Option 1: Fix via VSCode Settings UI (Recommended)

1. **Open VSCode Insiders**
2. **Open Settings**: `Cmd+,` or `Code > Settings > Settings`
3. **Search for**: `terminal.integrated.defaultProfile.osx`
4. **Set to**: `zsh`
5. **Search for**: `terminal.integrated.profiles.osx`
6. **Remove or fix the fish entry**


### Option 2: Fix via settings.json (Faster)

1. **Open Command Palette**: `Cmd+Shift+P`
2. **Type**: `Preferences: Open User Settings (JSON)`
3. **Add/Update these settings**:


```json
{
  "terminal.integrated.defaultProfile.osx": "zsh",
  "terminal.integrated.profiles.osx": {
    "zsh": {
      "path": "/bin/zsh",
      "args": ["-l"]
    },
    "bash": {
      "path": "/bin/bash",
      "args": ["-l"]
    },
    "fish": {
      "path": "/opt/homebrew/bin/fish",
      "args": ["-l"]
    }
  }
}
```

**Note**: If you don't use fish, you can remove the fish entry entirely:

```json
{
  "terminal.integrated.defaultProfile.osx": "zsh",
  "terminal.integrated.profiles.osx": {
    "zsh": {
      "path": "/bin/zsh",
      "args": ["-l"]
    },
    "bash": {
      "path": "/bin/bash",
      "args": ["-l"]
    }
  }
}
```

### Option 3: Remove Fish Profile Entirely

If you don't use fish in VSCode, search for and remove any fish-related terminal settings:

1. Open Settings (JSON)
2. Search for `fish`
3. Remove any lines containing `fish`
4. Save and reload VSCode


---

## Verification

After applying the fix:

1. **Reload VSCode**: `Cmd+Shift+P` → `Developer: Reload Window`
2. **Open new terminal**: `` Ctrl+` `` or `Terminal > New Terminal`
3. **Verify shell**: Run `echo $SHELL` (should show `/bin/zsh`)
4. **Check for errors**: No fish error should appear


---

## Additional Notes

### Why VSCode Doesn't Use `chsh` Default

VSCode maintains its own terminal profile system for cross-platform consistency and flexibility. The `chsh` command only sets the system default shell for login sessions, not for VSCode's integrated terminal.

### Finding VSCode Insiders Settings Location

VSCode Insiders settings are typically at:

- **macOS**: `~/Library/Application Support/Code - Insiders/User/settings.json`


You can open this directly:
```bash
code-insiders ~/Library/Application\ Support/Code\ -\ Insiders/User/settings.json
```

### Recommended Terminal Profile Setup

For optimal ZSH integration with your custom ZDOTDIR:

```json
{
  "terminal.integrated.defaultProfile.osx": "zsh",
  "terminal.integrated.profiles.osx": {
    "zsh": {
      "path": "/bin/zsh",
      "args": ["-l"],
      "env": {
        "ZDOTDIR": "${env:HOME}/dotfiles/dot-config/zsh"
      }
    }
  },
  "terminal.integrated.inheritEnv": true,
  "terminal.integrated.shellIntegration.enabled": true
}
```

This ensures:

- ✅ ZSH is the default shell
- ✅ Login shell behavior (`-l` flag)
- ✅ Custom ZDOTDIR is set
- ✅ Shell integration enabled (for features like command detection)


---

## Quick Fix Command

Run this to directly edit VSCode Insiders settings:

```bash
code-insiders ~/Library/Application\ Support/Code\ -\ Insiders/User/settings.json
```

Then add the settings from Option 2 above.

