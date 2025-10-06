# Complete ZSH Startup Sequence

## Standard ZSH Startup Order

ZSH reads configuration files in this **exact order**:

### 1. `/etc/zshenv` (System-wide environment)
- **Always sourced** (login, non-login, interactive, non-interactive)
- System administrator controlled
- Sets system-wide environment variables

### 2. `$ZDOTDIR/.zshenv` or `$HOME/.zshenv` (User environment)
- **Always sourced** (login, non-login, interactive, non-interactive)
- **Your file**: `/Users/s-a-c/dotfiles/dot-config/zsh/.zshenv`
- Should contain:
  - Environment variables
  - PATH setup
  - Variables needed by all shells
  - **NO interactive shell features**

### 3. `/etc/zprofile` (System-wide profile - Login shells only)
- **Login shells only**
- System administrator controlled

### 4. `$ZDOTDIR/.zprofile` or `$HOME/.zprofile` (User profile - Login shells only)
- **Login shells only**
- **Your setup**: Not currently used
- Would contain login-specific setup

### 5. `/etc/zshrc` (System-wide interactive configuration)
- **Interactive shells only**
- System administrator controlled

### 6. `$ZDOTDIR/.zshrc` or `$HOME/.zshrc` (User interactive configuration)
- **Interactive shells only**
- **Your main file**: `/Users/s-a-c/dotfiles/dot-config/zsh/.zshrc`
- Contains all your interactive shell configuration

### 7. `/etc/zlogin` (System-wide login - Login shells only)
- **Login shells only**
- System administrator controlled

### 8. `$ZDOTDIR/.zlogin` or `$HOME/.zlogin` (User login - Login shells only)
- **Login shells only**
- **Your setup**: Not currently used
- Last file read during login

## Your Configuration's Internal Sequence

Within your `.zshrc` file, the order is:

### Phase 1: Early Setup (in .zshrc)
```bash
# 1. Early debug and safety
zsh_debug_echo "Starting ZSH configuration..."

# 2. Core functions and utilities
load-shell-fragments() { ... }
can_haz() { ... }
# ... other core functions
```

### Phase 2: Pre-Plugin Phase
```bash
# Controlled by ZSH_ENABLE_PREPLUGIN_REDESIGN flag

# If REDESIGN enabled (current default):
load-shell-fragments "$ZDOTDIR/.zshrc.pre-plugins.d.REDESIGN"
# Loads: 00-path-safety.zsh, 05-fzf-init.zsh, 10-lazy-framework.zsh, 
#        15-node-runtime-env.zsh, 20-macos-defaults-deferred.zsh, 
#        25-lazy-integrations.zsh, 30-ssh-agent.zsh, 40-pre-plugin-reserved.zsh

# If REDESIGN disabled:
load-shell-fragments "$ZDOTDIR/.zshrc.pre-plugins.d"
# Loads: 00_00-critical-path-fix.zsh, 00_01-path-resolution-fix.zsh, 
#        00_05-path-guarantee.zsh, 00_10-fzf-setup.zsh, etc.
```

### Phase 3: Plugin Loading (zgenom)
```bash
# Plugin manager initialization
if [[ -f "$ZGEN_INIT" ]]; then
    source "$ZGEN_INIT"
fi
```

### Phase 4: Plugin Loading Phase
- zgenom loads all registered plugins
- **This is where ZLE should naturally initialize**
- Plugins may include themes, syntax highlighting, etc.

### Phase 5: Post-Plugin Phase
```bash
# Controlled by ZSH_ENABLE_POSTPLUGIN_REDESIGN flag

# Current setup (POSTPLUGIN_REDESIGN=0):
load-shell-fragments "$ZDOTDIR/.zshrc.d"
# Loads symlinked consolidated modules:
# 01-core-infrastructure.zsh → consolidated-modules/01-core-infrastructure.zsh
# 02-performance-monitoring.zsh → consolidated-modules/02-performance-monitoring.zsh
# 03-security-integrity.zsh → consolidated-modules/03-security-integrity.zsh
# 04-environment-options.zsh → consolidated-modules/04-environment-options.zsh
# 05-completion-system.zsh → consolidated-modules/05-completion-system.zsh
# 05.5-zle-initialization.zsh → consolidated-modules/05.5-zle-initialization.zsh  ⚠️
# 06-user-interface.zsh → consolidated-modules/06-user-interface.zsh
# 07-development-tools.zsh → consolidated-modules/07-development-tools.zsh
# 08-legacy-compatibility.zsh → consolidated-modules/08-legacy-compatibility.zsh
# 09-external-integrations.zsh → consolidated-modules/09-external-integrations.zsh
# 99-post-initialization.zsh → consolidated-modules/99-post-initialization.zsh
```

### Phase 6: Platform-Specific Configuration
```bash
# macOS-specific
load-shell-fragments "$ZDOTDIR/.zshrc.Darwin.d"
# Loads: 025-iterm2-shell-integration.zsh, 100-macos-defaults.zsh
```

### Phase 7: Work-Specific Configuration
```bash
# Optional work configuration
if [[ -d "$ZDOTDIR/.zshrc.work.d" ]]; then
    load-shell-fragments "$ZDOTDIR/.zshrc.work.d"
fi
```

### Phase 8: Final Setup (in .zshrc)
```bash
# 1. PATH deduplication
typeset -aU path

# 2. Desk activation
[[ -n "$DESK_ENV" ]] && source "$DESK_ENV"

# 3. ZSH autosuggest fixes
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(bracketed-paste)

# 4. iTerm2 integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# 5. P10k configuration (CURRENTLY DISABLED)
# if [[ -f "$ZDOTDIR/.p10k.zsh" ]]; then
#     source "$ZDOTDIR/.p10k.zsh"
# fi

# 6. SSH key listing
# 7. Self-update checking
# 8. ZSH profiling output
```

## ZLE Initialization Timing Issue

**The Problem**: ZLE should automatically initialize during **Phase 4 (Plugin Loading)**, but your modules in **Phase 5** are trying to use ZLE before it's ready.

**Current Error Sequence**:
1. **Phase 5**: `05.5-zle-initialization.zsh` tries to create ZLE widgets
2. **Phase 5**: `06-user-interface.zsh` tries to use `bindkey` and `zle -N`
3. **But**: `ZLE_VERSION` is not set, meaning ZLE hasn't initialized
4. **Result**: `zle: function definition file not found` errors

## Why ZLE Isn't Initializing

**Possible causes**:
1. **Plugin interference**: A plugin is preventing ZLE initialization
2. **Option conflicts**: Some shell option is blocking ZLE
3. **Function namespace pollution**: Too many functions defined early
4. **Environment conflicts**: Something in your environment setup

## Recommended Fix Strategy

1. **Remove our ZLE modules**: Delete `05.5-zle-initialization.zsh` 
2. **Let ZLE initialize naturally**: Don't try to force it
3. **Move keybindings later**: Ensure `bindkey` commands happen after ZLE is ready
4. **Test with minimal config**: Strip down to essentials to isolate the issue

The key insight is that ZLE should "just work" in interactive ZSH - if it's not initializing, something fundamental is wrong with the startup sequence.