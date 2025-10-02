# Migration Plan: Refactor Around ZQS .zshrc

## Current State Analysis

Your current setup has a customized `.zshrc` that prevents ZQS auto-updates. We need to:

1. **Backup your current customizations**
2. **Symlink to ZQS .zshrc** (allows auto-updates)
3. **Move customizations to ZQS extension points**
4. **Preserve your redesign functionality**

## Migration Steps

### Step 1: Backup Current Configuration
- Backup current `.zshrc` as `.zshrc.CUSTOM.backup`
- Document all customizations that differ from ZQS baseline

### Step 2: Identify Customization Categories

From your current `.zshrc`, these customizations need to be preserved:

#### A. Redesign Toggle System (Lines 16-28)
```bash
# Early minimal harness short-circuit
if [[ "${ZSH_SKIP_FULL_INIT:-0}" == "1" ]]; then
  # ... redesign logic
fi
```

#### B. Enhanced PATH Management (Lines 192-222) 
- Consolidated PATH logic that works with .zshenv
- Homebrew sbin addition logic

#### C. Advanced SSH Key Management (Lines 300-327)
- Timeout protection for ssh-add
- Enhanced key loading logic

#### D. Emergency ZLE Fix (in compatibility module)
- The fix we just implemented

#### E. Performance Instrumentation (Lines 388-430)
- ZGENOM timing and segment logging
- PERF_SEGMENT_LOG integration

#### F. External Tool Additions (Lines 717-719)
- LM Studio PATH addition

### Step 3: ZQS Extension Points

ZQS provides these extension points for customizations:

1. **`.zshrc.pre-plugins.d/`** - Pre-plugin loading customizations
2. **`.zshrc.d/`** - Post-plugin loading customizations  
3. **`.zsh_aliases`** - Shell aliases
4. **`.zsh_functions`** - Custom functions
5. **`.zshrc.work.d/`** - Work-specific customizations

### Step 4: Migration Map

| Current Customization | Target Location | Notes |
|----------------------|-----------------|--------|
| Redesign toggles | `.zshrc.pre-plugins.d/00-redesign-toggles.zsh` | Early loading required |
| PATH enhancements | `.zshrc.pre-plugins.d/05-path-enhancements.zsh` | Before plugin loading |
| SSH key management | `.zshrc.pre-plugins.d/10-ssh-enhancements.zsh` | Override ZQS defaults |
| Performance instrumentation | `.zshrc.pre-plugins.d/15-performance-instrumentation.zsh` | Wrap ZQS zgenom loading |
| Emergency ZLE fix | `.zshrc.d/01-emergency-zle-fix.zsh` | Early post-plugin |
| External tools | `.zshrc.d/99-external-tools.zsh` | Final additions |

## Implementation Strategy

### Phase 1: Prepare Extension Files
1. Create all the extension files in their proper locations
2. Test each extension individually
3. Verify functionality matches current behavior

### Phase 2: Switch to Symlink  
1. Move current `.zshrc` to backup
2. Create symlink: `ln -sf zsh-quickstart-kit/zsh/.zshrc .zshrc`
3. Test startup and functionality

### Phase 3: Refinement
1. Remove any redundant customizations
2. Test ZQS auto-update functionality
3. Verify all redesign features work correctly

## Benefits After Migration

✅ **Auto-updates**: ZQS will auto-update the core .zshrc  
✅ **Cleaner separation**: Your customizations in designated extension points  
✅ **Better maintainability**: Easier to track your changes vs ZQS defaults  
✅ **Upgrade safety**: Your customizations won't be overwritten during ZQS updates  
✅ **Standard compliance**: Following ZQS best practices  

## Risk Mitigation

- Keep complete backup of current working configuration
- Test each migration step incrementally  
- Use bash test harnesses to verify functionality
- Maintain emergency fallback plan

## Next Steps

Ready to proceed with Phase 1? I'll create the extension files and test them before switching to the symlink.