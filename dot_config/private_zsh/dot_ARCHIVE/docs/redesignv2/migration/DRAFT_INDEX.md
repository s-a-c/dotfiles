# Draft Index: ZSH Redesign Migration Artifacts

_Compliant with [/Users/s-a-c/.config/ai/guidelines.md](/Users/s-a-c/.config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49_

## Overview

This index catalogs all read-only drafts generated for the ZSH redesign migration. These drafts require explicit approval before any implementation begins.

Canonicalization:
- The canonical sources are the draft-* files in this directory.
- Annotated duplicates under `drafts/*.md` are auxiliary references and should point back to the canonical drafts.
- After approval, auxiliary annotated copies may be removed to avoid duplication.

**Generated:** 2025-01-08  
**Migration Phase:** Step 1 - Draft Generation (Read-Only)  
**Status:** AWAITING APPROVAL  

---

## Draft Artifacts

### 1. Module Files

#### `draft-70-shim-removal.zsh`
- **Purpose:** Runtime-only shim disabling module
- **Location:** `$ZDOTDIR/.zshrc.d.REDESIGN/70-shim-removal.zsh` (target)
- **Type:** Non-destructive runtime guard
- **Features:**
  - Detects common shimmed commands
  - Runtime aliasing to original paths
  - Debug mode reporting
  - Performance timing
- **Safety:** No on-disk modifications

### 2. Tool Scripts

#### `draft-deactivate-redesign.sh`
- **Purpose:** Exact inverse of activate-redesign.sh
- **Location:** `$ZDOTDIR/tools/deactivate-redesign.sh` (target)
- **Type:** Configuration restoration script
- **Features:**
  - Restores original .zshenv from backup
  - Removes redesign environment variables
  - Verbose mode support
  - Verification checks
- **Safety:** Backs up before changes

#### `draft-migrate-to-redesign.sh`
- **Purpose:** User config migration with dry-run capability
- **Location:** `$ZDOTDIR/tools/migrate-to-redesign.sh` (target)
- **Type:** Migration automation script
- **Features:**
  - `--dry-run` and `--apply` modes
  - Automatic backup creation
  - Environment file generation
  - Migration logging
- **Safety:** Dry-run first, explicit apply required

### 3. CI Workflows

#### `draft-redesign-flagged.yml`
- **Purpose:** Run tests with ZSH_USE_REDESIGN=1
- **Location:** `$ZDOTDIR/.github/workflows/redesign-flagged.yml` (target)
- **Type:** Automated testing workflow
- **Features:**
  - Branch-based triggering (feature/zsh-refactor-configuration)
  - Matrix testing (unit, integration, design)
  - Manual dispatch with parameters
  - Security validation
  - Artifact upload (7-day retention)

#### `draft-perf-nightly.yml`
- **Purpose:** Nightly performance ledger collection
- **Location:** `$ZDOTDIR/.github/workflows/perf-nightly.yml` (target)
- **Type:** Performance monitoring workflow
- **Features:**
  - Scheduled runs (2 AM UTC daily)
  - Performance baseline capture
  - Startup time analysis
  - Memory usage tracking
  - Regression detection
  - 30-day artifact retention

#### `draft-bundle-ledgers.yml`
- **Purpose:** Package performance ledgers for PR evidence
- **Location:** `$ZDOTDIR/.github/workflows/bundle-ledgers.yml` (target)
- **Type:** Evidence bundling workflow
- **Features:**
  - Manual dispatch workflow
  - 7-day ledger collection
  - Regression analysis inclusion
  - Bundle validation
  - 90-day retention
  - Archive generation

### 4. Documentation

#### `draft-test-execution-plan.md`
- **Purpose:** Detailed local test execution guide
- **Location:** Standalone documentation
- **Type:** Testing procedures document
- **Features:**
  - Step-by-step test commands
  - Expected outputs for each test category
  - Troubleshooting guide
  - Success criteria definitions
  - Performance benchmarks

#### `draft-shim-inventory-summary.md`
- **Purpose:** Current shim audit analysis
- **Location:** Standalone documentation
- **Type:** Audit results summary
- **Features:**
  - Current state: 1 shim detected (`zf::script_dir`)
  - Migration impact assessment
  - Recommendations for resolution
  - JSON audit data included

---

## Approval Checklist

Each draft requires explicit approval for the following aspects:

### Module Files
- [ ] **70-shim-removal.zsh** - Runtime-only approach acceptable
- [ ] **70-shim-removal.zsh** - Shim detection logic sound
- [ ] **70-shim-removal.zsh** - Performance impact minimal

### Tool Scripts
- [ ] **deactivate-redesign.sh** - Inverse operations correct
- [ ] **deactivate-redesign.sh** - Backup restoration safe
- [ ] **migrate-to-redesign.sh** - Dry-run implementation adequate
- [ ] **migrate-to-redesign.sh** - Apply mode safeguards sufficient

### CI Workflows
- [ ] **redesign-flagged.yml** - Triggering conditions appropriate
- [ ] **redesign-flagged.yml** - Test matrix comprehensive
- [ ] **perf-nightly.yml** - Performance monitoring adequate
- [ ] **perf-nightly.yml** - Artifact retention policies correct
- [ ] **bundle-ledgers.yml** - Evidence collection complete

### Documentation
- [ ] **test-execution-plan.md** - Test commands accurate
- [ ] **test-execution-plan.md** - Success criteria appropriate
- [ ] **shim-inventory-summary.md** - Analysis conclusions sound

---

## Current Shim Status

**Summary:** 1 shim detected (`zf::script_dir`)
- **Impact:** Minimal (1-line function)
- **Status:** Requires investigation
- **Migration Readiness:** Conditional (pending shim resolution)

---

## Implementation Sequence

Once approved, implementation will proceed in this order:

1. **Add 70-shim-removal.zsh** (runtime guard)
2. **Add deactivate-redesign.sh** (restoration script)
3. **Add migrate-to-redesign.sh** (migration tool)
4. **Add CI workflows** (testing automation)
5. **Run local tests** (validation)
6. **Commit incrementally** (one feature per commit)

---

## Approval Commands

To proceed with implementation, reply with:

- **`Approve all drafts`** - Implement all artifacts as drafted
- **`Approve with changes: <details>`** - Specify modifications needed
- **`Approve partial: <list>`** - Specify which drafts to implement
- **`Request revisions: <details>`** - Request specific changes
- **`Abort migration`** - Cancel the migration process

---

## File Locations Summary

All draft files are located in:
`$ZDOTDIR/docs/redesignv2/migration/`

Canonical source of truth:
- Files named `draft-*` within this directory are canonical.
- Annotated copies under `$ZDOTDIR/docs/redesignv2/migration/drafts/*.md` are auxiliary and may be removed after approval to deduplicate content.

Target implementation locations:
- Modules: `$ZDOTDIR/.zshrc.d.REDESIGN/`
- Tools: `$ZDOTDIR/tools/`
- Workflows: `$ZDOTDIR/.github/workflows/`

**Ready for your approval decision.**
