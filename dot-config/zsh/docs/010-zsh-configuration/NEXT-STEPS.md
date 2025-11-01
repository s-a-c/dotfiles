# Next Steps

**Prioritized Actions After P1/P2 Resolution** | **Updated: 2025-11-01**

---

<details>
<summary>Expand Table of Contents</summary>

- [Next Steps](#next-steps)
  - [1. Recent Completions](#1-recent-completions)
    - [1.1. P2.4 Terminal PATH Initialization Issues ✅](#11-p24-terminal-path-initialization-issues-)
    - [1.2. UX Improvements ✅](#12-ux-improvements-)
    - [1.3. Module Header Standardization (P3.1) ✅](#13-module-header-standardization-p31-)
    - [1.4. Environment Variable Organization (P3.3) ✅](#14-environment-variable-organization-p33-)
    - [1.5. Cache Permission Issues (P3.4) ✅](#15-cache-permission-issues-p34-)
    - [1.6. Debug Message Consistency (P3.2) ✅](#16-debug-message-consistency-p32-)
    - [1.7. Test Coverage Implementation (P2.2) ✅](#17-test-coverage-implementation-p22-)
  - [2. Short Term (November 2025)](#2-short-term-november-2025)
    - [2.1. Plugin Loading Optimization (P2.3) - Approval Required](#21-plugin-loading-optimization-p23---approval-required)
  - [3. Medium Term (December 2025)](#3-medium-term-december-2025)
  - [4. Long Term (Q1-Q2 2026)](#4-long-term-q1-q2-2026)
    - [4.1. Enhanced Error Messages (P4.1)](#41-enhanced-error-messages-p41)
    - [4.2. Interactive Setup Wizard (P4.2)](#42-interactive-setup-wizard-p42)
    - [4.3. Enhanced FZF Integration](#43-enhanced-fzf-integration)
  - [5. Prioritization Recommendation](#5-prioritization-recommendation)
  - [6. Quick Win Opportunities](#6-quick-win-opportunities)
  - [7. Related Documentation](#7-related-documentation)

</details>

---

## 1. Recent Completions

### 1.1. P2.4 Terminal PATH Initialization Issues ✅

**Status**: ✅ **COMPLETED** (2025-11-01)

**What Was Done**:

- Fixed "command not found" errors in Cursor/VSCode integrated terminals
- Implemented three-stage PATH setup to handle:
  - macOS `path_helper` corruption in login shells
  - VSCode shell integration PATH prepending
  - General terminal initialization
- Consolidated VSCode-specific workarounds into `470-user-interface.zsh`
- Added `keybinds-help()` function for better discoverability
- Improved `.gitignore` to exclude auto-generated files (`.stamp`, `saved_macos_defaults.plist`)

**User Testing**: ✅ Confirmed working in all terminals (Cursor, VSCode, WezTerm, Warp, Kitty, iTerm, Ghostty)

**Documentation**: [P2.4-RESOLUTION-SUMMARY.md](P2.4-RESOLUTION-SUMMARY.md)

---

### 1.2. UX Improvements ✅

**Status**: ✅ **COMPLETED** (2025-11-01)

**Features Added**:

- `keybinds-help` command - Displays comprehensive keybinding reference
- `aliases-help` command - Already existed, now has counterpart
- Welcome notifications for both features with emoji markers

**Benefits**:

- Users can discover keybindings via `keybinds-help` command
- Consistent help function pattern across modules
- Better discoverability of shell features

---

### 1.3. Module Header Standardization (P3.1) ✅

**Status**: ✅ **COMPLETED** (2025-11-01)

**What Was Done**:

- Created `bin/standardize-headers.py` automation script
- Standardized headers across 33 ZSH configuration files
- Applied consistent format: Filename, Purpose, Phase, Requires, Toggles
- Syntax-checked all files before committing

**Files Updated**:

- `.zshrc.add-plugins.d.00`: 12 files
- `.zshrc.pre-plugins.d.01`: 7 files
- `.zshrc.d.01`: 14 files

**Result**: 34 files changed, 292 insertions, 483 deletions (net cleanup)

**Commit**: `2cc17c986`

---

### 1.4. Environment Variable Organization (P3.3) ✅

**Status**: ✅ **COMPLETED** (2025-11-01)

**What Was Done**:

- Analyzed 1809-line `.zshenv.01` (67 exports, 40+ functions)
- Added comprehensive Table of Contents documenting 9 major sections
- Conservative approach: Document rather than reorganize (too complex to safely move code)
- Tested with `zsh -f` - sources cleanly ✅

**Sections Documented**:

1. Critical Startup (ZDOTDIR, XDG)
2. Terminal Detection & PATH
3. VSCode/Cursor Guards
4. Segment Management
5. Redesign Configuration
6. Splash Screen Control
7. zf:: Helper Functions
8. Readonly Protection
9. Additional Variables

**Result**: 2 files changed, 240 insertions

**Commit**: `55501c681`

---

### 1.5. Cache Permission Issues (P3.4) ✅

**Status**: ✅ **COMPLETED** (2025-11-01)

**What Was Done**:

- Added `chmod 700` for ZSH_CACHE_DIR and ZSH_LOG_DIR after creation
- Ensures secure, user-only access to cache and log directories
- Non-fatal (continues on error)

**Security Benefits**:

- Prevents other users from reading cache contents
- Protects potentially sensitive data in logs
- Aligns with security best practices

**Files Modified**: `.zshenv.01` (line 515)

**Commit**: `27080abf0`

---

### 1.6. Debug Message Consistency (P3.2) ✅

**Status**: ✅ **COMPLETED** (2025-11-01)

**Investigation Result**: **NO CHANGES REQUIRED**

**Findings**:

- Core configuration files already clean - all use `zf::debug()`
- No inconsistent debug messages found in `.zshrc.d.01/`
- No inconsistent debug messages found in `.zshrc.pre-plugins.d.01/`
- `.zshenv.01` uses `zf::debug` correctly (3 instances)

**Out of Scope** (Appropriate As-Is):

- `tools/` scripts use context-specific debug helpers (intentional)
- `tests/` use self-contained debug helpers (required for `zsh -f`)

**Result**: Core shell configuration already uses consistent `zf::debug()` helper

**Documentation**: [P3.2-RESOLUTION-SUMMARY.md](P3.2-RESOLUTION-SUMMARY.md)

**Commit**: `5a782dc58`

---

### 1.7. Test Coverage Implementation (P2.2) ✅

**Status**: ✅ **COMPLETED** (2025-11-01)

**What Was Done**:

- Created 19 comprehensive test files (14 unit + 5 integration)
- Added 3,167 lines of test code
- Achieved 90%+ overall coverage target
- All tests zsh -f compatible, self-contained

**Coverage Improvements**:

- Terminal Integration: 70% → 85% (+15%)
- Platform-Specific: 60% → 80% (+20%)
- Error Handling: 75% → 90% (+15%)
- **Overall: 85% → 90%** (+5%)

**Test Categories Created**:

1. **Terminal Integration** (8 tests) - Warp, WezTerm, Ghostty, Kitty, iTerm2, VSCode/Cursor, unknown terminals
2. **Platform-Specific** (6 tests) - macOS Homebrew, XDG directories, cross-platform compatibility, PATH priorities, fallback behaviors
3. **Error Handling** (5 tests) - Missing dependencies, permission errors, edge cases, graceful degradation, error recovery

**Documentation**: [P2.2-COMPLETION-SUMMARY.md](P2.2-COMPLETION-SUMMARY.md)

**PR**: #24 (merged to develop)

---

## 2. Short Term (November 2025)

### 2.1. Plugin Loading Optimization (P2.3) - Approval Required

**Priority**: MEDIUM (awaiting user approval)
**Effort**: 4 weeks (~12-16 hours)
**Status**: Analysis complete, implementation plan ready

**Goal**: Optimize shell startup time by 230ms through plugin lazy-loading

**Plan**: [PLUGIN-LAZY-ASYNC-PLAN.md](PLUGIN-LAZY-ASYNC-PLAN.md)

**Expected Improvements**:

- Phase 1: ZSH builtins + PHP wrapper (~90ms savings)
- Phase 2: GitHub CLI + Navigation deferring (~100ms savings)
- Phase 3: Autopair + Abbreviations deferring (~40ms savings)
- **Total**: 800ms → 570ms (29% improvement)

**⚠️ IMPORTANT**: This requires explicit user approval before implementation.

**Next Step**: User decision on whether to proceed with implementation.

---

## 4. Long Term (Q1-Q2 2026)

### 4.1. Enhanced Error Messages (P4.1)

**Effort**: Ongoing
**Priority**: LOW

Improve error messages with context and solution suggestions.

---

### 4.2. Interactive Setup Wizard (P4.2)

**Effort**: 4-6 weeks
**Priority**: LOW

Create first-run wizard for plugin selection and configuration.

---

### 4.3. Enhanced FZF Integration

**Effort**: 2-3 weeks
**Priority**: LOW

Advanced FZF features with previews and custom keybindings.

---

## 5. Prioritization Recommendation

**Recommended Order** (based on impact vs effort):

1. ✅ **P2.4 Terminal PATH fixes** - Completed (2025-11-01)
2. ✅ **UX improvements** (keybinds-help, consolidation) - Completed (2025-11-01)
3. ✅ **Module headers (P3.1)** - Completed (2025-11-01)
4. ✅ **Environment organization (P3.3)** - Completed (2025-11-01)
5. ✅ **Cache permissions (P3.4)** - Completed (2025-11-01)
6. ✅ **Debug consistency (P3.2)** - Completed (2025-11-01, no changes needed)
7. ✅ **Test coverage (P2.2)** - Completed (2025-11-01, 90%+ achieved)
8. **P2.3 Plugin optimization** - Awaiting approval (4 weeks, 29% speedup)
9. **Future enhancements** - As desired

---

## 6. Quick Win Opportunities

**All quick wins completed!** ✅

- ✅ Cache permissions (P3.4)
- ✅ Debug consistency (P3.2) - Investigation showed already clean

---

## 7. Related Documentation

- [Roadmap](900-roadmap.md) - Complete issue tracking
- [P2-RESOLUTION-SUMMARY.md](P2-RESOLUTION-SUMMARY.md) - All P2 issue resolutions
- [P2.4-RESOLUTION-SUMMARY.md](P2.4-RESOLUTION-SUMMARY.md) - Terminal PATH fix details
- [PLUGIN-LAZY-ASYNC-PLAN.md](PLUGIN-LAZY-ASYNC-PLAN.md) - P2.3 optimization plan (awaiting approval)
- [TEST-COVERAGE-IMPROVEMENT-PLAN.md](TEST-COVERAGE-IMPROVEMENT-PLAN.md) - Test plan for P2.2
- [Development Guide](090-development-guide.md) - How to extend configuration

---

**Navigation:** [← Roadmap](900-roadmap.md) | [Top ↑](#next-steps)

---

*Compliant with AI-GUIDELINES.md (v1.0 2025-10-31)*
*Updated: 2025-11-01 after completing P2.2, P2.4, P3.1, P3.2, P3.3, and P3.4*
