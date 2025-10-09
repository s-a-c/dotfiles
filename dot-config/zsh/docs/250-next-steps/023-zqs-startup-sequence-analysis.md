# ZSH Quickstart Kit (ZQS) - Complete Startup Sequence Analysis

**Date**: 2025-10-07
**Purpose**: Verify complete ZSH startup sequence and identify when helper functions are available
**Source**: [Official zsh-quickstart-kit repository](https://github.com/unixorn/zsh-quickstart-kit)

---

## 1. Executive Summary

**Your understanding was CORRECT**. The issue is an **execution context problem** during `zgenom save`:

- ✅ `.zshrc.pre-plugins.d/` **IS** sourced before `.zgen-setup` during normal shell startup
- ❌ `.zshrc.pre-plugins.d/` **IS NOT** sourced during `zgenom save` (plugin cache regeneration)
- ✅ `zf::debug` is available (defined in `.zshenv`)
- ❌ `zf::add_segment` is NOT available during `zgenom save` (defined in `.zshrc.pre-plugins.d/030-segment-management.zsh`)

**Recommended Fix**: Add defensive guards to plugin files (Option 2 from your analysis)

---

## 2. Complete Startup Sequence

### 2.1 Scenario A: Normal Interactive Shell Startup (init.zsh exists)

```zsh
1. ZSH loads .zshenv (ALWAYS, for all shells)

   └─> Defines zf::debug (line 73)
   └─> Sets environment variables
   └─> Configures XDG directories
   └─> Sets up PATH basics

2. ZSH loads .zshrc (interactive shells only)

   ├─> Line 76: Defines load-shell-fragments function
   ├─> Line 432: Sources .zshrc.pre-plugins.d/
   │   └─> 030-segment-management.zsh defines zf::add_segment
   ├─> Line 456: Sources .zgen-setup
   │   ├─> Line 39: Sources zgenom.zsh
   │   ├─> Line 258: Checks if zgenom saved (init.zsh exists)
   │   └─> init.zsh EXISTS → Sources it (plugins load from cache)
   └─> Line 664: Sources .zshrc.d/

3. Plugins are loaded from cached init.zsh

   └─> All helper functions available ✅
```

**Helper Function Availability (Scenario A)**:

- ✅ `zf::debug` - Available (from `.zshenv`)
- ✅ `zf::add_segment` - Available (from `.zshrc.pre-plugins.d/030-segment-management.zsh`)

---

### 2.2 Scenario B: Plugin Cache Regeneration (`zgenom save` triggered)

```zsh
1. ZSH loads .zshenv (ALWAYS)

   └─> Defines zf::debug (line 73) ✅

2. ZSH loads .zshrc

   ├─> Line 76: Defines load-shell-fragments function
   ├─> Line 432: Sources .zshrc.pre-plugins.d/
   │   └─> 030-segment-management.zsh defines zf::add_segment ✅
   ├─> Line 456: Sources .zgen-setup
   │   ├─> Line 39: Sources zgenom.zsh
   │   ├─> Line 258: Checks if zgenom saved
   │   └─> init.zsh MISSING or STALE → Calls setup-zgen-repos (line 259)
   │       └─> Calls load-starter-plugin-list (line 232)
   │           ├─> Lines 66-138: Loads default plugins
   │           ├─> Line 141: Sources .zqs-add-plugins (if exists)
   │           ├─> Line 144: ⚠️ load-shell-fragments .zshrc.add-plugins.d/
   │           │   └─> PROBLEM: This is a NESTED shell execution
   │           │   └─> .zshrc.pre-plugins.d/ was sourced in PARENT shell
   │           │   └─> Helper functions NOT in current execution context!
   │           └─> Line 213: zgenom save (generates init.zsh)
   └─> Line 664: Sources .zshrc.d/
```

**Helper Function Availability (Scenario B - During zgenom save)**:

- ✅ `zf::debug` - Available (from `.zshenv`, always sourced)
- ❌ `zf::add_segment` - **NOT AVAILABLE** (defined in parent shell context)

---

## 3. The Problem Explained

### 3.1 Why `.zshrc.add-plugins.d/` files can call `zf::debug` but not `zf::add_segment`

**Call Stack During `zgenom save`**:

```zsh
.zshrc (line 456)
  └─> .zgen-setup (sourced)
      └─> setup-zgen-repos (line 259, function call)
          └─> load-starter-plugin-list (line 232, function call)
              └─> load-shell-fragments .zshrc.add-plugins.d/ (line 144)
                  └─> sources 100-perf-core.zsh
                      └─> calls zf::add_segment ← UNDEFINED!
```

**Why the difference?**:

1. **`zf::debug` works** because:
   - Defined in `.zshenv` (line 73)
   - `.zshenv` is sourced by ZSH **before** `.zshrc`
   - Available in ALL execution contexts (login, interactive, non-interactive)

2. **`zf::add_segment` fails** because:
   - Defined in `.zshrc.pre-plugins.d/030-segment-management.zsh` (line 102)
   - Sourced in `.zshrc` (line 432) in the **parent shell**
   - When `load-shell-fragments` is called from within `.zgen-setup` (line 144), it's in a **nested function call**
   - Functions defined in the parent shell are NOT automatically available in sourced files during function execution

---

## 4. Execution Context Difference

### 4.1 Normal Startup (Scenario A)

```zsh
Shell Process
├─> .zshenv (defines zf::debug)
└─> .zshrc
    ├─> .zshrc.pre-plugins.d/ (defines zf::add_segment) ← SAME SHELL
    ├─> .zgen-setup
    │   └─> Sources cached init.zsh (plugins already compiled)
    └─> .zshrc.d/
```

**Result**: All functions available in same shell context ✅

### 4.2 During zgenom save (Scenario B)

```zsh
Shell Process
├─> .zshenv (defines zf::debug) ← GLOBAL
└─> .zshrc
    ├─> .zshrc.pre-plugins.d/ (defines zf::add_segment) ← PARENT CONTEXT
    └─> .zgen-setup
        └─> load-starter-plugin-list() ← FUNCTION CONTEXT
            └─> load-shell-fragments .zshrc.add-plugins.d/ ← NESTED SOURCE
                └─> 100-perf-core.zsh tries to call zf::add_segment ← NOT IN SCOPE!
```

**Result**: Only `.zshenv` functions available ❌

---

## 5. Why This Happens

**ZSH Function Scoping**:

- Functions defined in the main shell are available to **sourced files**
- BUT when you source a file from **within a function**, the sourced file runs in a **sub-context**
- Functions defined in the parent shell are NOT automatically exported to this sub-context
- Only **environment variables** and functions defined in `.zshenv` are guaranteed to be available

**The Specific Issue**:

- `.zgen-setup` line 144 calls `load-shell-fragments ${ZDOTDIR:-$HOME}/.zshrc.add-plugins.d`
- This happens **inside** the `load-starter-plugin-list` function
- Which is called from **inside** the `setup-zgen-repos` function
- The plugin files are sourced in this **nested function context**
- `zf::add_segment` was defined in the **parent shell context** (`.zshrc` line 432)
- It's not available in the nested context

---

## 6. Recommended Fix

### 6.1  Option 1: Source segment management before loading plugins (Modifies upstream file)

**Location**: `.zgen-setup` line 144

```zsh
# In load-starter-plugin-list, BEFORE line 144:

if [[ -f ${ZDOTDIR:-$HOME}/.zshrc.pre-plugins.d/030-segment-management.zsh ]]; then
  source ${ZDOTDIR:-$HOME}/.zshrc.pre-plugins.d/030-segment-management.zsh
fi

if [[ -d ${ZDOTDIR:-$HOME}/.zshrc.add-plugins.d ]]; then
  load-shell-fragments ${ZDOTDIR:-$HOME}/.zshrc.add-plugins.d
fi
```

**Pros**:

- Ensures helper functions available during plugin loading
- Matches the intended loading order

**Cons**:

- Modifies upstream `.zgen-setup` file
- Will conflict with upstream updates
- Not following ZQS design pattern (customization should be in fragment files)

---

### 6.2 Option 2: Add defensive guards to plugin files (RECOMMENDED)

**Location**: Each file in `.zshrc.add-plugins.d/`

```zsh
#!/usr/bin/env zsh

# 100-perf-core.zsh - Core Performance Plugins

# ... header comments ...

# Defensive guard for zf::add_segment (may not be available during zgenom save)

typeset -f zf::add_segment >/dev/null 2>&1 || zf::add_segment() { : }

# Rest of file...

zf::add_segment "perf-core" "start"

# ...
```

**Pros**:

- ✅ Makes plugin files self-contained and defensive
- ✅ Doesn't modify upstream files (`.zgen-setup`)
- ✅ Follows ZQS design pattern (customization in user files)
- ✅ Same pattern already used in `030-segment-management.zsh` (line 28) for `zf::debug`
- ✅ No-op fallback is safe (segment tracking is optional/diagnostic)

**Cons**:

- Requires adding guards to all 11 plugin files
- Slightly more verbose

---

## 7. ZQS Design Patterns

Based on official source code review:

1. **Customization Philosophy**: Users should NOT fork the kit
2. **Fragment Files**: All customization via `.zshrc.d/`, `.zshrc.pre-plugins.d/`, `.zshrc.add-plugins.d/`
3. **Defensive Coding**: Plugins should be self-contained (see `030-segment-management.zsh` line 28)
4. **Upstream Compatibility**: Avoid modifying core files (`.zshrc`, `.zgen-setup`)

**Conclusion**: Option 2 (defensive guards) aligns with ZQS design patterns.

---

## 8. Implementation Plan

### 8.1 Step 1: Add defensive guard to all plugin files

Add after header comments, before any function calls:

```zsh
# Defensive guard for zf::add_segment (may not be available during zgenom save)

typeset -f zf::add_segment >/dev/null 2>&1 || zf::add_segment() { : }
```

### 8.2 Step 2: Test

```zsh
# Remove all caches

find . -name "*.zwc" -type f -delete
find . -name ".zcompdump*" -type f -delete
rm -f ~/.zcompdump*

# Regenerate

zgenom reset
zgenom save

# Verify

zgenom list | wc -l  # Should show >0
```

### 8.3 Step 3: Verify plugins loaded

```zsh
zgenom list  # Should show actual plugins, not empty arrays
```

---

## 9. Conclusion

Your analysis was **100% correct**. The issue is an execution context problem during `zgenom save`. The recommended fix is **Option 2** (defensive guards in plugin files) because it:

1. Aligns with ZQS design patterns
2. Doesn't modify upstream files
3. Makes plugin files self-contained
4. Follows existing patterns in the codebase
5. Is safe and non-breaking

The fix is simple, maintainable, and follows ZSH best practices.

---

## 10. FAQ

### 10.1 Why is nvm not in my PATH?

Short answer: nvm is implemented as a shell function that only exists after its initialization; this repo intentionally defers (lazy) initialization so nvm may not be available in early or nested execution contexts (for example during `zgenom save`).

Quick diagnostics (run these commands):

```zsh
echo "$NVM_DIR" || echo "NVM_DIR is unset"
type -t nvm || command -v nvm || echo "nvm not loaded in this shell"
[ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ] && echo "nvm.sh exists"
source "${NVM_DIR:-$HOME/.nvm}/nvm.sh" && nvm --version  # manual repro
```

Common root causes:

- nvm is a shell function (not a plain binary) and only modifies PATH after being sourced.
- The repository intentionally preserves lazy semantics: we avoid sourcing nvm.sh in early phases (see 035-early-node-runtimes.zsh / 450-nvm-post-augmentation.zsh).
- During nested sourcing (e.g. `zgenom save`), functions defined in the parent shell are not visible in the sub-context, so plugin fragments can run before nvm is initialized.

Recommended, repo-aligned fixes:

- Prefer defensive guards in plugin fragments instead of forcing early sourcing. Example pattern used elsewhere in this repo:

```zsh
typeset -f nvm >/dev/null 2>&1 || { [ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ] && source "${NVM_DIR:-$HOME/.nvm}/nvm.sh"; }
```

  This loads nvm only when needed and only if nvm.sh exists.

- Rely on the existing post-augmentation fallback (450-nvm-post-augmentation.zsh) which injects a lazy nvm() when appropriate rather than sourcing nvm eagerly during initial startup.

- If you need Node binaries on PATH for non-interactive tools, consider adding a conservative PATH enrichment in 035-early-node-runtimes.zsh that only exposes runtime bin dirs (e.g. $NVM_DIR/versions/node/*/bin) guarded by existence checks — avoid hardcoding and respect $HOME.

- For plugin authors: add noop fallbacks (typeset -f zf::add_segment >/dev/null 2>&1 || zf::add_segment() { : }) and check for `nvm` before calling it so zgenom cache/regeneration runs safely.

If you'd like, I can add one or more defensive guards to the affected plugin fragments or add a small diagnostic script under tests/runtime/ to validate nvm init behavior across phases.

---
