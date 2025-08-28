# ZSH Configuration Naming Conventions

**Date:** 2025-08-25  
**Status:** Standardized across all directories  
**Version:** 2.0

## Overview

All zsh configuration files now follow a consistent double-underscore naming convention to ensure proper loading order and clear organization.

## Naming Pattern

**Format:** `XX_YY-descriptive-name.zsh`

- `XX` = Major category (00, 10, 20, 30, etc.)
- `YY` = Minor sequence within category (10, 20, 30, etc.)
- `descriptive-name` = Clear, hyphenated description of functionality

## Category System

### Major Categories (XX)

| Category | Purpose | Examples |
|----------|---------|----------|
| **00** | Core System | Environment, completion, essential setup |
| **10** | Tools & Utilities | Tool integrations, lazy loading, development tools |
| **20** | Security & Safety | SSH agents, plugin integrity, security features |
| **30** | UI & Appearance | Themes, prompts, visual customizations |
| **90** | Final/Cleanup | Last-run items, cleanup, finalization |

### Minor Sequences (YY)

Within each major category, use increments of 10:
- `10` = First item in category
- `20` = Second item in category  
- `30` = Third item in category
- etc.

This allows for easy insertion of new files between existing ones.

## Directory-Specific Implementation

### .zshrc.pre-plugins.d/ (Before Plugin Loading)

**Current Structure:**
```
00_10-fzf-setup.zsh                    # Core: FZF integration
00_20-completion-init.zsh              # Core: Completion initialization
10_10-nvm-npm-fix.zsh                  # Tools: Node.js/npm setup
10_20-macos-defaults-deferred.zsh      # Tools: macOS-specific setup
10_30-lazy-direnv.zsh                  # Tools: Direnv lazy loading
10_40-lazy-git-config.zsh              # Tools: Git config caching
10_50-lazy-gh-copilot.zsh              # Tools: GitHub Copilot setup
20_10-ssh-agent-core.zsh               # Security: SSH agent core
20_11-ssh-agent-security.zsh           # Security: SSH agent advanced
20_20-plugin-integrity-core.zsh        # Security: Plugin verification core
20_21-plugin-integrity-advanced.zsh    # Security: Plugin verification advanced
```

### .zshrc.add-plugins.d/ (Plugin Definitions)

**Current Structure:**
```
010-add-plugins.zsh                    # Additional zgenom plugin loads
```

**Recommended Standardization:**
```
10_10-add-plugins.zsh                  # Tools: Additional plugins
20_10-security-plugins.zsh             # Security: Security-focused plugins
30_10-ui-plugins.zsh                   # UI: Appearance/theme plugins
```

### .zshrc.d/ (Post-Plugin Configuration)

**Current Structure:** Already follows `XX_YY-name.zsh` pattern
```
00_XX-* = Core configuration
10_XX-* = Tool integrations  
20_XX-* = Plugin configurations
30_XX-* = UI customizations
90_XX-* = Final setup
```

## Loading Order Guarantee

Files load in strict lexicographic order:
1. `00_10-*` loads before `00_20-*`
2. `00_XX-*` loads before `10_XX-*`
3. `10_XX-*` loads before `20_XX-*`
4. etc.

This ensures:
- Core systems initialize first
- Tools load after core systems
- Security systems load when appropriate
- UI customizations load last

## File Naming Best Practices

### ✅ Good Examples
- `00_10-environment-setup.zsh` - Clear category and purpose
- `10_20-docker-integration.zsh` - Specific tool integration
- `20_10-ssh-security-core.zsh` - Security with specificity
- `30_15-prompt-customization.zsh` - UI customization

### ❌ Bad Examples
- `01-setup.zsh` - Old single-digit system
- `misc-stuff.zsh` - No category, vague purpose
- `00_05-something.zsh` - Non-standard minor increment
- `plugin-config.zsh` - No category prefix

## Migration Guidelines

When adding new files:

1. **Determine category** - What major function does this serve?
2. **Find appropriate slot** - What minor sequence number fits?
3. **Use descriptive name** - Make the purpose immediately clear
4. **Check loading order** - Ensure dependencies load first

When renaming existing files:

1. **Backup first** - Always backup before renaming
2. **Update references** - Check for any hardcoded references
3. **Test loading** - Verify the new loading order works
4. **Document changes** - Update any documentation

## Benefits of This System

### ✅ **Advantages**
- **Predictable loading order** - No surprises about what loads when
- **Easy insertion** - Can add files between existing ones
- **Clear organization** - Purpose is immediately obvious
- **Consistent across directories** - Same pattern everywhere
- **Scalable** - Can grow without reorganization

### 📊 **Before vs After**
```
Before: 00-, 01-, 02-, 03-, 04-, 05-, 06-
After:  00_10-, 00_20-, 10_10-, 10_20-, 10_30-, 10_40-, 10_50-, 20_10-, 20_11-, 20_20-, 20_21-
```

## Maintenance

### Regular Tasks
- **Review naming** - Ensure new files follow conventions
- **Check gaps** - Look for opportunities to consolidate
- **Update documentation** - Keep this file current
- **Validate loading order** - Test that dependencies load correctly

### When to Renumber
- **Major reorganization** - Significant structural changes
- **Category changes** - When file purposes shift
- **Consolidation** - When merging multiple files
- **Performance optimization** - When loading order needs adjustment

---

**Last Updated:** 2025-08-25  
**Next Review:** When adding 5+ new files or major restructuring
