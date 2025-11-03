# VSCode Insiders Terminal Integration Fix

## Table of Contents

<details>
<summary>Click to expand</summary>

- [1. Root Causes](#1-root-causes)
  - [1.1. Issue 1: VSCode Ignoring System Default Shell](#11-issue-1-vscode-ignoring-system-default-shell)
  - [1.2. Issue 2: Invalid Fish Path](#12-issue-2-invalid-fish-path)
- [2. Fix Instructions](#2-fix-instructions)
  - [2.1. Option 1: Fix via VSCode Settings UI (Recommended)](#21-option-1-fix-via-vscode-settings-ui-recommended)
  - [2.2. Option 2: Fix via settings.json (Faster)](#22-option-2-fix-via-settingsjson-faster)
  - [2.3. Option 3: Remove Fish Profile Entirely](#23-option-3-remove-fish-profile-entirely)
- [3. Verification](#3-verification)
- [4. Additional Notes](#4-additional-notes)
  - [4.1. Why VSCode Doesn't Use `chsh` Default](#41-why-vscode-doesnt-use-chsh-default)
  - [4.2. Finding VSCode Insiders Settings Location](#42-finding-vscode-insiders-settings-location)
  - [4.3. Recommended Terminal Profile Setup](#43-recommended-terminal-profile-setup)
- [5. Quick Fix Command](#5-quick-fix-command)

</details>

---


## 1. Root Causes

### 1.1. Issue 1: VSCode Ignoring System Default Shell

VSCode has its own terminal profile settings that override the system default shell set by `chsh`.

### 1.2. Issue 2: Invalid Fish Path

VSCode has a corrupted setting with path `opt/homebrew/bin/fish` (missing leading `/`).

---

## 2. Fix Instructions

### 2.1. Option 1: Fix via VSCode Settings UI (Recommended)

1. **Open VSCode Insiders**
2. **Open Settings**: `Cmd+,` or `Code > Settings > Settings`
3. **Search for**: `terminal.integrated.defaultProfile.osx`
4. **Set to**: `zsh`
5. **Search for**: `terminal.integrated.profiles.osx`
6. **Remove or fix the fish entry**


### 2.2. Option 2: Fix via settings.json (Faster)

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

### 2.3. Option 3: Remove Fish Profile Entirely

If you don't use fish in VSCode, search for and remove any fish-related terminal settings:

1. Open Settings (JSON)
2. Search for `fish`
3. Remove any lines containing `fish`
4. Save and reload VSCode


---

## 3. Verification

After applying the fix:

1. **Reload VSCode**: `Cmd+Shift+P` → `Developer: Reload Window`
2. **Open new terminal**: `` Ctrl+` `` or `Terminal > New Terminal`
3. **Verify shell**: Run `echo $SHELL` (should show `/bin/zsh`)
4. **Check for errors**: No fish error should appear


---

## 4. Additional Notes

### 4.1. Why VSCode Doesn't Use `chsh` Default

VSCode maintains its own terminal profile system for cross-platform consistency and flexibility. The `chsh` command only sets the system default shell for login sessions, not for VSCode's integrated terminal.

### 4.2. Finding VSCode Insiders Settings Location

VSCode Insiders settings are typically at:

- **macOS**: `~/Library/Application Support/Code - Insiders/User/settings.json`


You can open this directly:
```bash
code-insiders ~/Library/Application\ Support/Code\ -\ Insiders/User/settings.json
```

### 4.3. Recommended Terminal Profile Setup

For optimal ZSH integration with your custom ZDOTDIR:

```json
{
  "terminal.integrated.defaultProfile.osx": "zsh",
  "terminal.integrated.profiles.osx": {
    "zsh": {
      "path": "/bin/zsh",
      "args": ["-l"],
      "env": {
        "ZDOTDIR": "${env:HOME}/.config/zsh"
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


## 5. Quick Fix Command

Run this to directly edit VSCode Insiders settings:

```bash
code-insiders ~/Library/Application\ Support/Code\ -\ Insiders/User/settings.json
```

Then add the settings from Option 2 above.

---

**Navigation:** [Top ↑](#vscode-insiders-terminal-integration-fix)

---

*Last updated: 2025-10-13*
