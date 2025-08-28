# File Prefix Reorganization Plan

**Generated:** August 27, 2025  
**Purpose:** Systematic renaming for logical consistency with 10-increment spacing  
**Scope:** Both `.zshrc.d/` and `.zshrc.pre-plugins.d/` directories  

## 🎯 Reorganization Strategy

### Naming Convention Rules
1. **Primary increments**: Use `00`, `10`, `20`, `30`, etc. for major functional groups
2. **Sub-increments**: Use `01`, `02`, `03`, etc. for closely related or multi-part files
3. **Functional grouping**: Keep related functionality clustered together
4. **Loading order**: Ensure critical dependencies load first

## 📁 .zshrc.d/ Directory Reorganization

### Current Issues Identified
- Multiple `00_00-` prefixes (conflicts)
- Inconsistent spacing between functional groups
- Some related files scattered across different number ranges

### Proposed Renaming Plan

#### **00_xx - Foundation Layer (Environment & Core Functions)**
```
CURRENT → PROPOSED
00_00-standard-helpers.zsh → 00_00-standard-helpers.zsh ✓ (keep)
00_00-unified-logging.zsh → 00_01-unified-logging.zsh (closely related to helpers)
00_01-environment.zsh → 00_02-environment.zsh
00_01-source-execute-detection.zsh → 00_03-source-execute-detection.zsh
00_02-git-homebrew-priority.zsh → 00_04-git-homebrew-priority.zsh
00_03-completion-management.zsh → 00_05-completion-management.zsh
00_05-async-cache.zsh → 00_06-async-cache.zsh
00_05-completion-finalization.zsh → 00_07-completion-finalization.zsh
00_06-performance-monitoring.zsh → 00_08-performance-monitoring.zsh
00_07-review-cycles.zsh → 00_09-review-cycles.zsh
00_08-environment-sanitization.zsh → 00_90-environment-sanitization.zsh (security, near end)
00_10-environment.zsh → [MERGE] into 00_02-environment.zsh (duplicate functionality)
00_30-options.zsh → 00_10-options.zsh (foundational ZSH options)
00_40-functions-core.zsh → 00_20-functions-core.zsh
00_80-utility-functions.zsh → 00_30-utility-functions.zsh
00_90-security-check.zsh → 00_91-security-check.zsh
00_95-validation.zsh → 00_95-validation.zsh ✓ (keep)
```

#### **10_xx - Development Tools Layer**
```
CURRENT → PROPOSED
10_00-development-tools.zsh → 10_00-development-tools.zsh ✓ (keep)
10_10-path-tools.zsh → 10_10-path-tools.zsh ✓ (keep)
10_12-tool-environments.zsh → 10_11-tool-environments.zsh (closely related to path-tools)
10_13-git-vcs-config.zsh → 10_12-git-vcs-config.zsh (closely related)
10_15-atuin-init.zsh → 10_20-atuin-init.zsh (separate tool)
10_40-homebrew.zsh → 10_30-homebrew.zsh (major tool)
10_50-development.zsh → [MERGE] into 10_00-development-tools.zsh (duplicate functionality)
10_60-ssh-agent-macos.zsh → 10_40-ssh-agent-macos.zsh
10_70-completion.zsh → 10_50-completion.zsh
10_80-tool-functions.zsh → 10_60-tool-functions.zsh
```

#### **20_xx - Plugin Integration Layer**
```
CURRENT → PROPOSED
20_01-plugin-metadata.zsh → 20_00-plugin-metadata.zsh
20_10-plugin-environments.zsh → 20_10-plugin-environments.zsh ✓ (keep)
20_20-essential.zsh → 20_20-essential.zsh ✓ (keep)
20_30-plugin-integration.zsh → 20_30-plugin-integration.zsh ✓ (keep)
20_40-deferred.zsh → 20_40-deferred.zsh ✓ (keep)
20_41-plugin-deferred-core.zsh → 20_41-plugin-deferred-core.zsh ✓ (keep, multi-part)
20_42-plugin-deferred-utils.zsh → 20_42-plugin-deferred-utils.zsh ✓ (keep, multi-part)
```

#### **30_xx - User Interface Layer**
```
CURRENT → PROPOSED
30_00-prompt-ui-config.zsh → 30_00-prompt-ui-config.zsh ✓ (keep)
30_10-prompt.zsh → 30_10-prompt.zsh ✓ (keep)
30_20-aliases.zsh → 30_20-aliases.zsh ✓ (keep)
30_30-ui-enhancements.zsh → 30_30-ui-enhancements.zsh ✓ (keep)
30_35-context-aware-config.zsh → 30_31-context-aware-config.zsh (closely related to ui-enhancements)
30_40-keybindings.zsh → 30_40-keybindings.zsh ✓ (keep)
30_50-ui-customization.zsh → 30_50-ui-customization.zsh ✓ (keep)
```

#### **90_xx - System Integration Layer**
```
CURRENT → PROPOSED
90_00-disable-zqs-autoupdate.zsh → 90_00-disable-zqs-autoupdate.zsh ✓ (keep)
90_10-.zshrc.zqs.zsh → 90_10-zshrc-zqs.zsh (remove leading dot for consistency)
```

#### **99_xx - Finalization Layer**
```
CURRENT → PROPOSED
99_90-splash.zsh → 99_90-splash.zsh ✓ (keep)
```

## 📁 .zshrc.pre-plugins.d/ Directory Reorganization

### Current Assessment
The pre-plugins directory is already well-organized but needs minor adjustments for consistency.

### Proposed Renaming Plan

#### **00_xx - Early Setup**
```
CURRENT → PROPOSED
00_05-path-guarantee.zsh → 00_00-path-guarantee.zsh (most critical, should be first)
00_10-fzf-setup.zsh → 00_10-fzf-setup.zsh ✓ (keep)
00_20-completion-init.zsh → 00_20-completion-init.zsh ✓ (keep)
00_30-lazy-loading-framework.zsh → 00_30-lazy-loading-framework.zsh ✓ (keep)
```

#### **10_xx - Tool Setup**
```
CURRENT → PROPOSED
10_10-nvm-npm-fix.zsh → 10_00-nvm-npm-fix.zsh
10_20-macos-defaults-deferred.zsh → 10_10-macos-defaults-deferred.zsh
10_30-lazy-direnv.zsh → 10_20-lazy-direnv.zsh
10_40-lazy-git-config.zsh → 10_30-lazy-git-config.zsh
10_50-lazy-gh-copilot.zsh → 10_40-lazy-gh-copilot.zsh
```

#### **20_xx - Security & Plugin Setup**
```
CURRENT → PROPOSED
20_10-ssh-agent-core.zsh → 20_00-ssh-agent-core.zsh
20_11-ssh-agent-security.zsh → 20_01-ssh-agent-security.zsh (closely related to core)
20_20-plugin-integrity-core.zsh → 20_10-plugin-integrity-core.zsh
20_21-plugin-integrity-advanced.zsh → 20_11-plugin-integrity-advanced.zsh (closely related to core)
```

## 🔧 Implementation Steps

### Phase 1: Create Renaming Script
Create an automated script to perform all renames safely with backup.

### Phase 2: Handle File Merges
Some files identified for merging:
- Merge `00_10-environment.zsh` into `00_02-environment.zsh`
- Merge `10_50-development.zsh` into `10_00-development-tools.zsh`

### Phase 3: Validate Dependencies
Ensure no scripts reference the old file names directly.

### Phase 4: Update Documentation
Update any documentation that references the old file names.

## 📝 Files Requiring Content Merging

### Environment Files Merge
**Target:** `00_02-environment.zsh`  
**Source:** `00_10-environment.zsh`  
**Action:** Combine environment variable definitions, remove duplicates

### Development Tools Merge
**Target:** `10_00-development-tools.zsh`  
**Source:** `10_50-development.zsh`  
**Action:** Combine development tool configurations, ensure no conflicts

## ✅ Expected Benefits

1. **Logical Ordering**: Clear 10-increment spacing for major functional groups
2. **Consistency**: Elimination of duplicate prefixes and scattered functionality
3. **Maintainability**: Related files grouped together with clear numbering
4. **Clarity**: Easier to understand loading order and dependencies
5. **Reduced Complexity**: Fewer total files through strategic merging

## 🎯 Next Steps

1. Review and approve this reorganization plan
2. Create automated renaming script with safety checks
3. Implement file merges with careful content review
4. Test the reorganized configuration
5. Update documentation and references

---

**Status:** Planned - Ready for Implementation  
**Estimated Effort:** 4-6 hours including testing  
**Risk Level:** Low (with proper backup and validation)
