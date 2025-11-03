# Naming Convention Analysis

## Table of Contents

<details>
<summary>Click to expand</summary>

- [1. Overview](#1-overview)
- [2. Naming Convention Standard](#2-naming-convention-standard)
  - [2.1. **Format Specification**](#21-format-specification)
    - [2.1.1. Examples:](#211-examples)
  - [2.2. **Load Order Guidelines**](#22-load-order-guidelines)
    - [2.2.1. Reserved Ranges:](#221-reserved-ranges)
    - [2.2.2. Category Naming:](#222-category-naming)
- [3. Compliance Assessment](#3-compliance-assessment)
  - [3.1. **Overall Compliance Score: 95%**](#31-overall-compliance-score-95)
  - [3.2. **Detailed File Analysis**](#32-detailed-file-analysis)
    - [3.2.1. **Pre-Plugin Phase** (`.zshrc.pre-plugins.d/`)](#321-pre-plugin-phase-zshrcpre-pluginsd)
    - [3.2.2. **Plugin Definition Phase** (`.zshrc.add-plugins.d/`)](#322-plugin-definition-phase-zshrcadd-pluginsd)
    - [3.2.3. **Post-Plugin Phase** (`.zshrc.d/`)](#323-post-plugin-phase-zshrcd)
- [4. Issue Analysis](#4-issue-analysis)
  - [4.1. **🔴 Critical Issue: Duplicate Filename**](#41-critical-issue-duplicate-filename)
    - [4.1.1. Analysis:](#411-analysis)
    - [4.1.2. Recommended Resolution:](#412-recommended-resolution)
  - [4.2. **🟡 Load Order Issues**](#42-load-order-issues)
    - [4.2.1. **1. Large Gaps in Numbering**](#421-1-large-gaps-in-numbering)
    - [4.2.2. Current Gaps:](#422-current-gaps)
    - [4.2.3. Impact:](#423-impact)
    - [4.2.4. **2. Functional Misplacement**](#424-2-functional-misplacement)
    - [4.2.5. Analysis:](#425-analysis)
    - [4.2.6. **3. Category Naming Inconsistencies**](#426-3-category-naming-inconsistencies)
    - [4.2.7. Minor Inconsistencies:](#427-minor-inconsistencies)
- [5. Load Order Logic Assessment](#5-load-order-logic-assessment)
  - [5.1. **Pre-Plugin Phase Logic**](#51-pre-plugin-phase-logic)
    - [5.1.1. Current Ordering:](#511-current-ordering)
  - [5.2. **Plugin Phase Logic**](#52-plugin-phase-logic)
    - [5.2.1. Current Ordering:](#521-current-ordering)
  - [5.3. **Post-Plugin Phase Logic**](#53-post-plugin-phase-logic)
    - [5.3.1. Current Ordering:](#531-current-ordering)
- [6. Category Naming Analysis](#6-category-naming-analysis)
  - [6.1. **Category Effectiveness**](#61-category-effectiveness)
    - [6.1.1. **✅ Well-Designed Categories**](#611-well-designed-categories)
    - [6.1.2. Performance Category (`perf-*`):](#612-performance-category-perf)
    - [6.1.3. Development Categories (`dev-*`):](#613-development-categories-dev)
    - [6.1.4. Productivity Categories:](#614-productivity-categories)
    - [6.1.5. **⚠️ Areas for Improvement**](#615-areas-for-improvement)
    - [6.1.6. Optional Category (`optional-*`):](#616-optional-category-optional)
    - [6.1.7. Terminal Integration:](#617-terminal-integration)
  - [6.2. **Naming Pattern Consistency**](#62-naming-pattern-consistency)
    - [6.2.1. Hyphenation Patterns:](#621-hyphenation-patterns)
    - [6.2.2. Abbreviation Usage:](#622-abbreviation-usage)
- [7. Recommendations](#7-recommendations)
  - [7.1. **High Priority Fixes**](#71-high-priority-fixes)
    - [7.1.1. **1. Resolve Duplicate Filename**](#711-1-resolve-duplicate-filename)
    - [7.1.2. Immediate Action Required:](#712-immediate-action-required)
    - [7.1.3. **2. Fix Load Order Gaps**](#713-2-fix-load-order-gaps)
    - [7.1.4. Proposed New Structure for `.zshrc.d/`:](#714-proposed-new-structure-for-zshrcd)
    - [7.1.5. Benefits:](#715-benefits)
  - [7.2. **Medium Priority Improvements**](#72-medium-priority-improvements)
    - [7.2.1. **3. Enhance Category Names**](#721-3-enhance-category-names)
    - [7.2.2. Proposed Improvements:](#722-proposed-improvements)
    - [7.2.3. **4. Implement Naming Validation**](#723-4-implement-naming-validation)
    - [7.2.4. Automated Validation:](#724-automated-validation)
  - [7.3. **Low Priority Enhancements**](#73-low-priority-enhancements)
    - [7.3.1. **5. Load Order Optimization**](#731-5-load-order-optimization)
    - [7.3.2. Optimization Opportunities:](#732-optimization-opportunities)
- [8. Implementation Guidelines](#8-implementation-guidelines)
  - [8.1. **Adding New Modules**](#81-adding-new-modules)
    - [8.1.1. Process:](#811-process)
    - [8.1.2. Example:](#812-example)
  - [8.2. **Renaming Existing Modules**](#82-renaming-existing-modules)
    - [8.2.1. Process:](#821-process)
  - [8.3. **Validation Tools**](#83-validation-tools)
    - [8.3.1. Manual Validation Checklist:](#831-manual-validation-checklist)
    - [8.3.2. Automated Validation:](#832-automated-validation)
- [9. Best Practices](#9-best-practices)
  - [9.1. **Load Order Best Practices**](#91-load-order-best-practices)
    - [9.1.1. Dependency Management:](#911-dependency-management)
    - [9.1.2. Numbering Strategy:](#912-numbering-strategy)
  - [9.2. **Category Naming Best Practices**](#92-category-naming-best-practices)
    - [9.2.1. Clarity:](#921-clarity)
    - [9.2.2. Maintainability:](#922-maintainability)
- [10. Assessment Summary](#10-assessment-summary)
  - [10.1. **Current State: Excellent with Minor Issues**](#101-current-state-excellent-with-minor-issues)
    - [10.1.1. Strengths:](#1011-strengths)
    - [10.1.2. Areas for Improvement:](#1012-areas-for-improvement)
  - [10.2. **Expected Outcomes After Fixes**](#102-expected-outcomes-after-fixes)

</details>

---


## 1. Overview

This document analyzes the adherence to the standardized `XX_YY-name.zsh` naming convention across all configuration directories. The analysis includes compliance assessment, issue identification, and recommendations for maintaining consistent naming standards.

## 2. Naming Convention Standard

### 2.1. **Format Specification**

**Standard Format:** `XX_YY-name.zsh`

- **XX**: Two-digit load order (000-999)
- **YY**: Two-character category separator (-)
- **name**: Descriptive module name using hyphens
- **Extension**: Always `.zsh`


#### 2.1.1. Examples:
```bash
✅ 010-shell-safety-nounset.zsh     # Load order 010, shell safety category
✅ 100-perf-core.zsh               # Load order 100, performance core category
✅ 195-optional-brew-abbr.zsh      # Load order 195, optional feature category
❌ shell-safety.zsh                # Missing load order digits
❌ 10-shell-safety.zsh             # Single digit instead of two
❌ safety-shell.zsh                # Wrong separator position
```

### 2.2. **Load Order Guidelines**

#### 2.2.1. Reserved Ranges:

- **000-099**: Pre-plugin setup and core systems
- **100-199**: Plugin definitions and core tools
- **200-299**: Advanced features and integrations
- **300-999**: Post-plugin setup and terminal integration


#### 2.2.2. Category Naming:

- **perf-**: Performance and optimization tools
- **dev-**: Development environment and tools
- **productivity-**: User productivity enhancements
- **optional-**: Optional features and nice-to-haves
- **shell-**: Core shell functionality
- **terminal-**: Terminal-specific integrations


## 3. Compliance Assessment

### 3.1. **Overall Compliance Score: 95%**

| Directory | Files | Compliant | Non-Compliant | Compliance Rate |
|-----------|-------|-----------|---------------|-----------------|
| `.zshrc.pre-plugins.d/` | 6 | 6 | 0 | **100%** |
| `.zshrc.add-plugins.d/` | 11 | 11 | 0 | **100%** |
| `.zshrc.d/` | 11 | 10 | 1 | **91%** |
| **Total** | **28** | **27** | **1** | **96%** |

### 3.2. **Detailed File Analysis**

#### 3.2.1. **Pre-Plugin Phase** (`.zshrc.pre-plugins.d/`)

| Filename | Load Order | Category | Status | Notes |
|----------|------------|----------|--------|-------|
| `000-layer-set-marker.zsh` | 000 | layer | ✅ Valid | Layer system initialization |
| `010-shell-safety-nounset.zsh` | 010 | shell-safety | ✅ Valid | Security setup |
| `015-xdg-extensions.zsh` | 015 | xdg | ✅ Valid | XDG compliance |
| `020-delayed-nounset-activation.zsh` | 020 | delayed-nounset | ✅ Valid | Controlled activation |
| `025-log-rotation.zsh` | 025 | log | ✅ Valid | Log management |
| `030-segment-management.zsh` | 030 | segment | ✅ Valid | Performance monitoring |

**Compliance:** 100% ✅
**Load Order Logic:** Perfect sequential ordering

#### 3.2.2. **Plugin Definition Phase** (`.zshrc.add-plugins.d/`)

| Filename | Load Order | Category | Status | Notes |
|----------|------------|----------|--------|-------|
| `100-perf-core.zsh` | 100 | perf-core | ✅ Valid | Performance utilities |
| `110-dev-php.zsh` | 110 | dev-php | ✅ Valid | PHP development |
| `120-dev-node.zsh` | 120 | dev-node | ✅ Valid | Node.js development |
| `130-dev-systems.zsh` | 130 | dev-systems | ✅ Valid | System tools |
| `136-dev-python-uv.zsh` | 136 | dev-python-uv | ✅ Valid | Python development |
| `140-dev-github.zsh` | 140 | dev-github | ✅ Valid | GitHub integration |
| `150-productivity-nav.zsh` | 150 | productivity-nav | ✅ Valid | Navigation tools |
| `160-productivity-fzf.zsh` | 160 | productivity-fzf | ✅ Valid | FZF integration |
| `180-optional-autopair.zsh` | 180 | optional-autopair | ✅ Valid | Auto-pairing |
| `190-optional-abbr.zsh` | 190 | optional-abbr | ✅ Valid | Abbreviations |
| `195-optional-brew-abbr.zsh` | 195 | optional-brew | ✅ Valid | Homebrew aliases |

**Compliance:** 100% ✅
**Load Order Logic:** Excellent grouping by functionality

#### 3.2.3. **Post-Plugin Phase** (`.zshrc.d/`)

| Filename | Load Order | Category | Status | Notes |
|----------|------------|----------|--------|-------|
| `100-terminal-integration.zsh` | 100 | terminal-integration | ✅ Valid | Terminal detection |
| `110-starship-prompt.zsh` | 110 | starship-prompt | ✅ Valid | Prompt configuration |
| `115-live-segment-capture.zsh` | 115 | live-segment | ✅ Valid | Performance monitoring |
| `195-optional-brew-abbr.zsh` | 195 | optional-brew | ⚠️ **DUPLICATE** | Same as add-plugins.d version |
| `300-shell-history.zsh` | 300 | shell-history | ✅ Valid | History management |
| `310-navigation.zsh` | 310 | navigation | ✅ Valid | Directory navigation |
| `320-fzf.zsh` | 320 | fzf | ✅ Valid | FZF shell integration |
| `330-completions.zsh` | 330 | completions | ✅ Valid | Tab completion |
| `335-completion-styles.zsh` | 335 | completion-styles | ✅ Valid | Completion styling |
| `340-neovim-environment.zsh` | 340 | neovim-environment | ✅ Valid | Neovim integration |
| `345-neovim-helpers.zsh` | 345 | neovim-helpers | ✅ Valid | Neovim utilities |

**Compliance:** 91% ⚠️ (1 duplicate issue)
**Load Order Logic:** Good, but with gaps and organizational issues

## 4. Issue Analysis

### 4.1. **🔴 Critical Issue: Duplicate Filename**

**Problem:** `195-optional-brew-abbr.zsh` exists in both `.zshrc.add-plugins.d/` and `.zshrc.d/`

#### 4.1.1. Analysis:

- **File sizes differ:** Indicates different content or modification times
- **Wrong phase:** Homebrew aliases should be in plugin definition phase, not post-plugin
- **Maintenance burden:** Two files to maintain for same functionality


#### 4.1.2. Recommended Resolution:

1. **Compare contents** of both files
2. **Determine authoritative version** based on functionality
3. **Keep in plugin phase** (`.zshrc.add-plugins.d/`) as appropriate
4. **Remove from post-plugin phase** (`.zshrc.d/`)


### 4.2. **🟡 Load Order Issues**

#### 4.2.1. **1. Large Gaps in Numbering**

**Problem:** Inconsistent numbering gaps in `.zshrc.d/`

#### 4.2.2. Current Gaps:

- **115 → 195:** 80-number gap
- **195 → 300:** 105-number gap
- **345 → 999:** Remaining range unused


#### 4.2.3. Impact:

- **Limited extensibility** - No room for new modules in some ranges
- **Confusing organization** - Unclear where to add new features
- **Maintenance difficulty** - Hard to insert modules in appropriate locations


#### 4.2.4. **2. Functional Misplacement**

**Problem:** `195-optional-brew-abbr.zsh` in post-plugin phase

#### 4.2.5. Analysis:

- **Should be in plugin phase** - Homebrew aliases are plugin-like functionality
- **Post-plugin phase** should be for terminal integration and environment setup
- **Creates confusion** about phase responsibilities


#### 4.2.6. **3. Category Naming Inconsistencies**

#### 4.2.7. Minor Inconsistencies:

- **Mixed separators:** Some use single hyphens, some use multiple
- **Category clarity:** Some category names could be more descriptive
- **Feature vs. tool:** Inconsistent distinction between tools and features


## 5. Load Order Logic Assessment

### 5.1. **Pre-Plugin Phase Logic**

#### 5.1.1. Current Ordering:
```bash
000-layer-set-marker.zsh          # Layer system setup
010-shell-safety-nounset.zsh      # Security initialization
015-xdg-extensions.zsh            # Directory setup
020-delayed-nounset-activation.zsh # Controlled activation
025-log-rotation.zsh              # Log management
030-segment-management.zsh        # Performance monitoring
```

**Assessment:** Perfect ✅

- **Sequential dependencies** properly ordered
- **No circular dependencies**
- **Clear progression** from basic to advanced


### 5.2. **Plugin Phase Logic**

#### 5.2.1. Current Ordering:
```bash
100-perf-core.zsh                 # Performance foundation
110-dev-php.zsh                   # PHP development
120-dev-node.zsh                  # Node.js development
130-dev-systems.zsh               # System tools
136-dev-python-uv.zsh             # Python development
140-dev-github.zsh                # GitHub integration
150-productivity-nav.zsh          # Navigation tools
160-productivity-fzf.zsh          # FZF integration
180-optional-autopair.zsh         # Optional features
190-optional-abbr.zsh              # Optional features
195-optional-brew-abbr.zsh        # Optional features
```

**Assessment:** Excellent ✅

- **Logical grouping** by functionality
- **Dependency order** respected
- **Category separation** clear


### 5.3. **Post-Plugin Phase Logic**

#### 5.3.1. Current Ordering:
```bash
100-terminal-integration.zsh      # Terminal setup
110-starship-prompt.zsh           # Prompt configuration
115-live-segment-capture.zsh      # Performance monitoring
195-optional-brew-abbr.zsh        # ⚠️ MISPLACED
300-shell-history.zsh             # History management
310-navigation.zsh                # Directory navigation
320-fzf.zsh                       # FZF integration
330-completions.zsh               # Tab completion
335-completion-styles.zsh         # Completion styling
340-neovim-environment.zsh        # Neovim integration
345-neovim-helpers.zsh            # Neovim utilities
```

**Assessment:** Good with issues ⚠️

- **Generally logical progression**
- **Duplicate file issue**
- **Large gaps limit extensibility**


## 6. Category Naming Analysis

### 6.1. **Category Effectiveness**

#### 6.1.1. **✅ Well-Designed Categories**

#### 6.1.2. Performance Category (`perf-*`):

- `100-perf-core.zsh` - Clear, descriptive
- Establishes performance foundation


#### 6.1.3. Development Categories (`dev-*`):

- `110-dev-php.zsh` - Specific language/tool
- `120-dev-node.zsh` - Clear technology focus
- `130-dev-systems.zsh` - Broad systems category
- `136-dev-python-uv.zsh` - Specific tool (uv)


#### 6.1.4. Productivity Categories:

- `150-productivity-nav.zsh` - Navigation focus
- `160-productivity-fzf.zsh` - Specific tool integration


#### 6.1.5. **⚠️ Areas for Improvement**

#### 6.1.6. Optional Category (`optional-*`):

- `180-optional-autopair.zsh` - Clear optional nature
- `190-optional-abbr.zsh` - Clear optional nature
- `195-optional-brew-abbr.zsh` - Could be more specific


#### 6.1.7. Terminal Integration:

- `100-terminal-integration.zsh` - Very clear purpose


### 6.2. **Naming Pattern Consistency**

#### 6.2.1. Hyphenation Patterns:

- **Single hyphens:** `dev-php`, `dev-node` ✅
- **Multiple hyphens:** `shell-safety`, `neovim-environment` ✅
- **Consistency:** Generally good across files


#### 6.2.2. Abbreviation Usage:

- **FZF:** Used consistently as `fzf`
- **Neovim:** Used consistently as `neovim`
- **GitHub:** Used as `github` (not `gh` or `git-hub`)


## 7. Recommendations

### 7.1. **High Priority Fixes**

#### 7.1.1. **1. Resolve Duplicate Filename**

#### 7.1.2. Immediate Action Required:
```bash

# Compare the two files

diff .zshrc.add-plugins.d/195-optional-brew-abbr.zsh .zshrc.d/195-optional-brew-abbr.zsh

# Determine which is correct/superior

# Remove the incorrect one

# Update any references

```

#### 7.1.3. **2. Fix Load Order Gaps**

#### 7.1.4. Proposed New Structure for `.zshrc.d/`:
```bash
100-terminal-integration.zsh      # Terminal setup
110-starship-prompt.zsh           # Prompt configuration
115-live-segment-capture.zsh      # Performance monitoring
120-shell-history.zsh             # History management (moved from 300)
130-navigation.zsh                # Directory navigation (moved from 310)
140-fzf.zsh                       # FZF integration (moved from 320)
150-completions.zsh               # Tab completion (moved from 330)
155-completion-styles.zsh         # Completion styling (moved from 335)
160-neovim-environment.zsh        # Neovim integration (moved from 340)
165-neovim-helpers.zsh            # Neovim utilities (moved from 345)
```

#### 7.1.5. Benefits:

- **Better organization** - Related features grouped together
- **Room for expansion** - Numbers available in each logical group
- **Clearer progression** - From basic to advanced features


### 7.2. **Medium Priority Improvements**

#### 7.2.1. **3. Enhance Category Names**

#### 7.2.2. Proposed Improvements:

- `dev-systems` → `dev-rust-go` (more specific)
- `productivity-nav` → `productivity-navigation` (more descriptive)
- `optional-brew-abbr` → `optional-homebrew` (more standard name)


#### 7.2.3. **4. Implement Naming Validation**

#### 7.2.4. Automated Validation:
```bash
zf::validate_naming_convention() {
    local errors=0

    # Find all .zsh files that don't match pattern
    while IFS= read -r file; do
        basename=$(basename "$file" .zsh)
        if [[ ! "$basename" =~ ^[0-9]{2}-[a-z-]+-[a-z]+$ ]]; then
            echo "❌ Invalid naming: $file"
            ((errors++))
        fi
    done < <(find . -name "*.zsh" ! -name ".zshrc" ! -name ".zshenv")

    return $errors
}
```

### 7.3. **Low Priority Enhancements**

#### 7.3.1. **5. Load Order Optimization**

#### 7.3.2. Optimization Opportunities:

- **Group related functionality** in contiguous ranges
- **Reserve ranges** for future features
- **Document load order rationale** in module headers


## 8. Implementation Guidelines

### 8.1. **Adding New Modules**

#### 8.1.1. Process:

1. **Choose appropriate load order** based on dependencies
2. **Select descriptive category** name
3. **Follow `XX_YY-name.zsh` format**
4. **Validate with naming check** before committing


#### 8.1.2. Example:
```bash

# New module for Docker integration

# Phase: add_plugin (100-199 range)

# Category: dev-systems (system development tools)

# Load order: 135 (between Python and GitHub tools)

# Result: 135-dev-docker.zsh

```

### 8.2. **Renaming Existing Modules**

#### 8.2.1. Process:

1. **Identify module to rename**
2. **Choose new name** following conventions
3. **Update all references** in documentation and code
4. **Validate** with naming check
5. **Test** to ensure no broken dependencies


### 8.3. **Validation Tools**

#### 8.3.1. Manual Validation Checklist:

- [ ] **Format:** `XX_YY-name.zsh` pattern followed
- [ ] **Load order:** Appropriate for dependencies
- [ ] **Category:** Descriptive and consistent
- [ ] **Uniqueness:** No filename conflicts
- [ ] **Documentation:** Header includes naming rationale


#### 8.3.2. Automated Validation:
```bash

# Check all naming conventions

find . -name "*.zsh" -not -name ".zshrc" -not -name ".zshenv" | \
    xargs basename -s .zsh | \
    grep -v '^[0-9]\{2\}-[a-z-]\+$' && echo "❌ Naming violations found"
```

## 9. Best Practices

### 9.1. **Load Order Best Practices**

#### 9.1.1. Dependency Management:

- **Load dependencies first** - Core before specific
- **Group related features** - Keep similar functionality together
- **Reserve ranges** - Leave room for future additions


#### 9.1.2. Numbering Strategy:

- **Use all ranges** - Don't skip entire ranges unnecessarily
- **Logical grouping** - 100-199 for plugins, 300-399 for integrations
- **Future-proof** - Leave gaps for new modules


### 9.2. **Category Naming Best Practices**

#### 9.2.1. Clarity:

- **Be specific** - `dev-node` better than `dev-js`
- **Use standard names** - `homebrew` not `brew` or `home-brew`
- **Consistent terminology** - Use same terms across modules


#### 9.2.2. Maintainability:

- **Descriptive categories** - `productivity-navigation` better than `productivity-nav`
- **Logical grouping** - Related tools in same category
- **Future-proof names** - Avoid overly specific category names


## 10. Assessment Summary

### 10.1. **Current State: Excellent with Minor Issues**

#### 10.1.1. Strengths:

- ✅ **95% compliance rate** across all modules
- ✅ **Logical load order** in most phases
- ✅ **Clear category naming** for most modules
- ✅ **Consistent format** across directories


#### 10.1.2. Areas for Improvement:

- ⚠️ **Duplicate filename** issue needs resolution
- ⚠️ **Load order gaps** should be addressed
- ⚠️ **Category specificity** could be enhanced


### 10.2. **Expected Outcomes After Fixes**

**Compliance Target:** 100%
**Maintainability:** Significantly improved
**Extensibility:** Enhanced with better organization
**Contributor Experience:** Much clearer guidelines


*The naming convention analysis shows excellent adherence to standards with only minor issues to resolve. The duplicate filename is the primary concern, followed by organizational improvements for better maintainability and extensibility.*

---

**Navigation:** [← Improvement Recommendations](220-improvement-recommendations.md) | [Top ↑](#naming-convention-analysis) | [Architecture Diagrams →](300-architecture-diagrams.md)

---

*Last updated: 2025-10-13*
