# Next Steps

**Prioritized Actions After P1/P2 Resolution** | **Updated: 2025-10-31**

---

<details>
<summary>Expand Table of Contents</summary>

- [Next Steps](#next-steps)
  - [1. Immediate Actions (This Week)](#1-immediate-actions-this-week)
    - [1.1. Validate Performance Improvements ⏱️ 10 minutes](#11-validate-performance-improvements-️-10-minutes)
  - [2. Short Term (November 2025)](#2-short-term-november-2025)
    - [2.1. Module Header Standardization (P3.1)](#21-module-header-standardization-p31)
    - [2.2. Environment Variable Organization (P3.3)](#22-environment-variable-organization-p33)
  - [3. Medium Term (December 2025)](#3-medium-term-december-2025)
    - [3.1. Test Coverage Implementation (P2.2)](#31-test-coverage-implementation-p22)
    - [3.2. Debug Message Consistency (P3.2)](#32-debug-message-consistency-p32)
    - [3.3. Cache Permission Issues (P3.4)](#33-cache-permission-issues-p34)
  - [4. Long Term (Q1-Q2 2026)](#4-long-term-q1-q2-2026)
    - [4.1. Enhanced Error Messages (P4.1)](#41-enhanced-error-messages-p41)
    - [4.2. Interactive Setup Wizard (P4.2)](#42-interactive-setup-wizard-p42)
    - [4.3. Enhanced FZF Integration](#43-enhanced-fzf-integration)
  - [5. Prioritization Recommendation](#5-prioritization-recommendation)
  - [6. Quick Win Opportunities](#6-quick-win-opportunities)
  - [7. Related Documentation](#7-related-documentation)

</details>

---

## 1. Immediate Actions (This Week)

### 1.1. Validate Performance Improvements ⏱️ 10 minutes

**Priority**: 🔥 **CRITICAL** - User validation required
**Status**: Waiting for user testing

**What to Test**:

```bash
# 1. Measure startup time improvement
echo "Testing startup time (10 iterations)..."
for i in {1..10}; do
    time zsh -i -c "exit"
done 2>&1 | grep real | awk '{sum+=$2; n++} END {print "Average:", sum/n, "seconds"}'

# Expected: ~1.57s (down from 1.8s, ~230ms savings)
```

```bash
# 2. Test lazy-loaded PHP plugins
composer --version  # Should trigger on-demand load

# 3. Test deferred GitHub CLI (wait 2+ seconds)
sleep 3
gh --version  # Should work after 2s delay

# 4. Test deferred navigation (wait 1+ second)
sleep 2
z ~  # Should work after 1s delay

# 5. Test autopair (after first prompt)
echo "(  # Should auto-close parenthesis

# 6. Test abbreviations (after defer)
# Type: gs<SPACE>  # Should expand to 'git status -sb'
```

**If Issues Occur**: See [IMPLEMENTATION-SUMMARY.md](IMPLEMENTATION-SUMMARY.md) for:

- Feature toggle instructions
- Rollback procedures
- Troubleshooting guide

**Report Results**: Document actual startup time and any issues found

---

## 2. Short Term (November 2025)

### 2.1. Module Header Standardization (P3.1)

**Priority**: MEDIUM
**Effort**: 1-2 weeks (~10-12 hours)
**Status**: Ready to start

**Goal**: Add standard headers to ~66 files (~30% of modules)

**Header Template**:

```bash
#!/usr/bin/env zsh
# Filename: NNN-feature-name.zsh
# Purpose:  Brief description of what this file does
# Phase:    Which phase it loads in (.zshrc.d/, .zshrc.pre-plugins.d/, etc.)
# Requires: Dependencies (optional)
# Toggles:  Environment variables that control behavior (optional)
```

**Files Needing Headers**:

- Scan all `.zshrc.d.01/*.zsh` files
- Scan all `.zshrc.pre-plugins.d.01/*.zsh` files
- Scan all `.zshrc.add-plugins.d.00/*.zsh` files
- Identify missing or non-compliant headers

**Timeline**:

- Week 1: Audit files, create list (~2 hours)
- Week 2: Add headers to 30-40 files (~6-8 hours)
- Validation: Quick syntax check

---

### 2.2. Environment Variable Organization (P3.3)

**Priority**: MEDIUM
**Effort**: 3-4 days (~6-8 hours)
**Status**: Ready to start

**Goal**: Organize 70+ environment variables in `.zshenv.01` with clear section headers

**Current State**: Variables scattered without clear organization

**Proposed Organization**:

```bash
# === Core Shell Environment ===
# ZDOTDIR, XDG_ variables, PATH

# === Development Tools ===
# PHP, Node, Python, Go, Rust environments

# === Terminal & UI ===
# Terminal emulator settings, colors, prompt

# === Performance & Monitoring ===
# Log rotation, performance tracking

# === Security & Safety ===
# Permission settings, safety flags

# === Application Integration ===
# Tool-specific variables (Herd, LM Studio, etc.)
```

**Timeline**:

- Day 1-2: Create organization plan, draft sections (~4 hours)
- Day 3: Implement reorganization (~2 hours)
- Day 4: Test and validate (~2 hours)

---

## 3. Medium Term (December 2025)

### 3.1. Test Coverage Implementation (P2.2)

**Priority**: MEDIUM
**Effort**: 6 weeks (~18-20 hours)
**Status**: Comprehensive plan ready

**Plan**: [TEST-COVERAGE-IMPROVEMENT-PLAN.md](TEST-COVERAGE-IMPROVEMENT-PLAN.md)

**Schedule**:

- **Week 1-2**: Terminal integration tests (+15% coverage)
- **Week 3-4**: Platform-specific tests (+20% coverage)
- **Week 5-6**: Error handling tests (+10% coverage)
- **Result**: 85% → 90%+ coverage

**Start When**: After performance validation and module headers complete

---

### 3.2. Debug Message Consistency (P3.2)

**Priority**: LOW
**Effort**: 1 week (~4-6 hours)
**Status**: Ready to start

**Goal**: Standardize all debug messages to use `zf::debug` helper

**Current Inconsistencies**:

- `[DEBUG]message`
- `DEBUG: message`
- `# DEBUG: message`

**Target**: All messages use `zf::debug "message"`

---

### 3.3. Cache Permission Issues (P3.4)

**Priority**: LOW
**Effort**: 1-2 days (~2-4 hours)
**Status**: Ready to start

**Goal**: Standardize cache directory permissions to 700

```bash
# Add to appropriate module
mkdir -p "$ZSH_CACHE_DIR"
chmod 700 "$ZSH_CACHE_DIR"
```

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

1. ✅ **Validate performance** (10 min) - Do now
2. **Module headers** (1-2 weeks) - High value, clear improvement
3. **Environment organization** (3-4 days) - Medium value, easy win
4. **Test coverage** (6 weeks) - High value, larger commitment
5. **Debug consistency** (1 week) - Low value, polish item
6. **Future enhancements** - As desired

---

## 6. Quick Win Opportunities

**Can be done in <1 hour each**:

- Fix cache permissions (P3.4)
- Update 5-10 module headers (partial P3.1)
- Organize one category of env vars (partial P3.3)

---

## 7. Related Documentation

- [Roadmap](900-roadmap.md) - Complete issue tracking
- [IMPLEMENTATION-SUMMARY.md](IMPLEMENTATION-SUMMARY.md) - Testing guide for P2.3
- [TEST-COVERAGE-IMPROVEMENT-PLAN.md](TEST-COVERAGE-IMPROVEMENT-PLAN.md) - Test plan for P2.2
- [Development Guide](090-development-guide.md) - How to extend configuration

---

**Navigation:** [← Roadmap](900-roadmap.md) | [Top ↑](#next-steps)

---

*Compliant with AI-GUIDELINES.md (v1.0 2025-10-31)*
*Updated: 2025-10-31 after P1/P2 resolution*
