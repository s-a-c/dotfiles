# ZLE Investigation Log

## 🕐 Timeline of Investigation

### Phase 1: Initial Problem Report
**Symptoms reported**:
- `perms=` and `file_perms=` debug message spam
- Autopair functionality completely broken
- Starship prompt issues

### Phase 2: Surface-Level Fixes (Partially Successful)
**Actions taken**:
- ✅ Fixed debug message spam in security validation functions
- ✅ Applied comprehensive debug suppression with state preservation
- ❌ Attempted custom autopair fixes (failed due to ZLE issues)
- ✅ Re-enabled `hlissner/zsh-autopair` plugin

**Key discovery**: Widget registration was failing with `zle: function definition file not found`

### Phase 3: ZLE System Investigation
**Critical findings**:
- ZLE wrapper function was hiding errors with `2>/dev/null`
- After removing wrapper, revealed system-wide ZLE failure
- Multiple plugins showing widget registration errors
- Oh-My-Zsh key bindings completely broken

### Phase 4: Async Processing Investigation
**User's insight**: Suspected custom async processing conflicts
**Investigation results**:
- Custom async tools present but inactive
- `zsh-defer` plugin working correctly
- **Real discovery**: ZLE wrapper was masking fundamental errors

### Phase 5: Root Cause Discovery
**Breakthrough moment**: Clean environment testing
```bash
# This works perfectly:
env -i HOME="$HOME" USER="$USER" TERM="$TERM" PATH="$PATH" zsh -c "
    test-func() { echo works; }
    zmodload zsh/zle
    zle -N test-func 2>&1 && echo 'ZLE: SUCCESS'
"
```

**Conclusion**: ZSH installation and ZLE system are fine - configuration is corrupting the environment.

### Phase 6: Debug Hook Development
**Strategy**: Hook into `load-shell-fragments` to test ZLE after each file
**Implementation**: `.zshenv.local` with debug wrapper
**Result**: Successfully identified that corruption happens **before** custom files load

### Phase 7: Systematic Testing Results
**Key findings**:
```
❌ ZLE: BROKEN (before /Users/s-a-c/dotfiles/dot-config/zsh/.zshrc.d)
```

**Evidence of pre-corruption**:
- Variable dumps during startup
- `compinit:557: zle: function definition file not found`
- `zgenom-load:17: 2: parameter not set`
- Oh-My-Zsh lib files showing ZLE errors

### Phase 8: Oh-My-Zsh Elimination Test
**Test**: Disabled Oh-My-Zsh completely
**Result**: **Still broken** - corruption persists without Oh-My-Zsh
**Conclusion**: Problem is deeper than plugin system

## 🔍 Critical Evidence

### Variable Dump Pattern
Every failed test shows this mysterious output:
```
!=0
'#'=1
'$'=85926
'?'=0
ARGC=1
COLUMNS=90
...
```

This suggests something is triggering parameter expansion or variable listing inappropriately.

### ZLE Error Pattern
Consistent across all tests:
```
compinit:557: zle: function definition file not found
compinit:559: zle: function definition file not found
```

### Parameter Errors
```
zgenom-load:17: 2: parameter not set
```

## 🎯 Key Insights

1. **Custom files are innocent** - corruption happens before they load
2. **ZSH core is fine** - works perfectly in clean environments
3. **Something in early startup** is fundamentally corrupting the environment
4. **Not plugin-specific** - happens even without Oh-My-Zsh
5. **Environment-wide corruption** - affects completion, ZLE, and parameter expansion

## 🚨 Current Hypothesis (UPDATED - Phase 1 Results)

**BREAKTHROUGH**: The corruption is **NOT** in a single section, but in **section interactions**!

**Phase 1 Findings**:
1. **Parameter Safety (409-500)**: ✅ Works fine alone - NOT the direct culprit
2. **Debug Policy (147-245)**: ✅ Works fine in combination - NOT the culprit
3. **Environment & Tool Setup (246-408)**: ⚠️ **INTERACTION CULPRIT**
   - Works fine alone
   - Causes system hang/corruption when combined with earlier sections
   - **This is where the interaction corruption occurs**

**Confirmed Working Combinations**:
- ✅ Sections 1-127 + Debug Policy + Parameter Safety
- ✅ Environment & Tool Setup section alone

**Confirmed Breaking Combination**:
- ❌ Sections 1-127 + Debug Policy + Environment & Tool Setup + Parameter Safety

**Root Cause**: Complex interaction effect within Environment & Tool Setup section (lines 246-408) when combined with earlier initialization.

## ✅ Emergency Solution Implemented

Created minimal working configuration that bypasses all problematic components:
- Direct ZLE initialization
- Basic completion setup
- Starship integration
- Essential functionality only

**Result**: ✅ Fully functional ZSH environment
