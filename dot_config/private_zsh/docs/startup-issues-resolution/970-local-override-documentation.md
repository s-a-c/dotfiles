# Local Override System - Final Customization Layer

## Overview

The `999-zshrc-local.zsh` file provides the ultimate customization layer for your ZSH configuration, allowing machine-specific or user-specific overrides that load after all other configuration files.

## File Structure

### Location: `.config/zsh/.zshrc.d.00/999-zshrc-local.zsh`

```zsh
#!/usr/bin/env zsh
# ==============================================================================
# 999-zshrc-local.zsh — Optional final local override hook
# ==============================================================================
# Phase: 5 (post-plugin, last fragment)
# Purpose: If a .zshrc.local exists, source it for machine/user-specific late tweaks.
#          Keep this fragment minimal and idempotent.
# Ordering: 999- prefix ensures execution after other 9xx cleanup/override fragments.
# Notes:
#   - Prefer earlier fragment layers for structured changes:
#       .zshrc.pre-plugins.d.00/*    (early env/path tweaks)
#       .zshrc.add-plugins.d.00/*    (plugin declarations)
#       .zshrc.d.00/*                (post-plugin augmentations)
#   - This file should remain tiny; re-sourcing must be harmless.
#
# Behavior: Silently skips if no local file found.

# Resolve candidate local override path (honor ZDOTDIR; fall back to $HOME)
local _local_rc="${ZDOTDIR:-$HOME}/.zshrc.local"

# Source if present (use builtin to avoid alias/function shadowing)
if [[ -f $_local_rc ]]; then
    # shellcheck disable=SC1090 (dynamic path by design)
    builtin source "$_local_rc"
fi

unset _local_rc
return 0
```

## Usage Examples

### Example `~/.zshrc.local` for Bun Preference

```zsh
#!/usr/bin/env zsh
# ~/.zshrc.local - Machine-specific ZSH customizations

# =============================================================================
# PACKAGE MANAGER PREFERENCES
# =============================================================================

# Set preferred package manager to Bun for this machine
export ZF_PREFERRED_PKG_MANAGER="bun"

# Bun-specific optimizations
export ZF_BUN_CMD="/opt/homebrew/bin/bun"

# =============================================================================
# MACHINE-SPECIFIC PATHS
# =============================================================================

# Local development paths
export PATH="$HOME/Projects:$PATH"

# Machine-specific tools
if [[ -d "/usr/local/go/bin" ]]; then
    export PATH="/usr/local/go/bin:$PATH"
fi

# =============================================================================
# ENVIRONMENT VARIABLES
# =============================================================================

# Editor preferences
export EDITOR="nvim"
export VISUAL="nvim"

# Development preferences
export NODE_OPTIONS="--max-old-space-size=8192"

# =============================================================================
# LOCAL ALIASES (Optional)
# =============================================================================

# Machine-specific shortcuts
alias work="cd ~/Projects"
alias personal="cd ~/Personal"

# =============================================================================
# STARTUP NOTIFICATIONS
# =============================================================================

# Comment and safely execute pm-bun() with notification
echo "🐘 Setting Bun as preferred package manager..."
pm-bun
echo "✅ Package manager set to: $(pm-info | head -1)"
```

## Best Practices

### 1. Keep It Minimal
- Use this file only for machine-specific customizations
- Avoid complex logic that should be in the main config
- Ensure re-sourcing is harmless

### 2. Use Proper Layering
- **Prefer earlier layers** for structured changes:
  - `.zshrc.pre-plugins.d.00/*` - Early environment tweaks
  - `.zshrc.add-plugins.d.00/*` - Plugin declarations  
  - `.zshrc.d.00/*` - Post-plugin augmentations
- **Use this layer** only for machine-specific overrides

### 3. Idempotent Design
- Functions should work correctly when re-sourced
- Avoid side effects that accumulate
- Use conditional logic for safety

### 4. Documentation
- Comment machine-specific customizations
- Explain why certain settings are needed
- Document any dependencies

## Integration with Consolidated System

The local override system integrates seamlessly with the consolidated alias system:

### Load Order
1. **Early Setup**: `.zshrc.pre-plugins.d.00/*` (NVM, paths, etc.)
2. **Plugin Loading**: `.zshrc.add-plugins.d.00/*` (plugin declarations)
3. **Core Functionality**: `.zshrc.d.00/*` (main configuration)
4. **Consolidated Aliases**: `900-catalogued-aliases.zsh` (all aliases)
5. **Local Overrides**: `999-zshrc-local.zsh` → `~/.zshrc.local` (machine-specific)

### Override Behavior
- Local overrides can override environment variables
- Local overrides can add new aliases
- Local overrides can modify existing behavior
- Local overrides are applied AFTER all safety systems are in place

## Example Use Cases

### 1. Development Machine Setup
```zsh
# ~/.zshrc.local
export ZF_PREFERRED_PKG_MANAGER="bun"
export NODE_OPTIONS="--max-old-space-size=16384"
alias work="cd ~/Development"
```

### 2. Production Machine Setup
```zsh
# ~/.zshrc.local  
export ZF_PREFERRED_PKG_MANAGER="npm"
export NODE_ENV="production"
alias deploy="cd ~/app && npm run build && npm run deploy"
```

### 3. Testing Machine Setup
```zsh
# ~/.zshrc.local
export ZF_PREFERRED_PKG_MANAGER="pnpm"
export NODE_OPTIONS="--inspect"
alias test-all="npm run test:unit && npm run test:integration"
```

## Benefits

### 1. Machine Flexibility
- Different machines can have different preferences
- No need to modify the main dotfiles repository
- Easy to maintain per-environment settings

### 2. Clean Separation
- Main configuration stays generic and portable
- Machine-specific concerns are isolated
- Easy to identify what's custom vs. standard

### 3. Safe Overrides
- Loads after all safety systems are in place
- Can't break core functionality
- Easy to disable by removing the local file

### 4. Version Control Friendly
- Local file is excluded from version control
- No risk of committing machine-specific settings
- Clean dotfiles repository

## Troubleshooting

### Local File Not Loading
```bash
# Check if file exists
ls -la ~/.zshrc.local

# Check ZDOTDIR
echo $ZDOTDIR

# Test loading manually
source ~/.zshrc.local
```

### Overrides Not Working
```bash
# Check load order
zsh -c 'echo "Load order:"; for f in ~/.zshrc.d/*.zsh; do echo $f; done'

# Test specific override
echo $ZF_PREFERRED_PKG_MANAGER
```

### Conflicts with Main Config
```bash
# Check if alias exists
type pm-bun

# Check function definition
which pm-bun

# Test in clean shell
zsh -f -c 'source ~/.zshrc && source ~/.zshrc.local && pm-info'
```

## Security Considerations

### 1. File Permissions
```bash
# Ensure only user can write
chmod 600 ~/.zshrc.local
```

### 2. Sensitive Data
- Avoid storing passwords or API keys
- Use environment variable files for secrets
- Consider using a secrets manager

### 3. Validation
- Test changes in a separate shell first
- Keep backups of working configurations
- Use version control for main dotfiles

## Conclusion

The local override system provides the perfect final layer for machine-specific customizations while maintaining the clean architecture of the consolidated ZSH configuration system. It allows for flexibility without compromising the safety and consistency achieved through the consolidation effort.

When combined with the `900-catalogued-aliases.zsh` system, it provides a complete, flexible, and maintainable ZSH configuration that works across different environments while preserving all the safety and intelligence features implemented.
