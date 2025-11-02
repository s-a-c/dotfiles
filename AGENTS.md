# AI Agent Instructions

**Version:** 1.0
**Last Updated:** 2025-11-02

<details>
<summary>Expand Table of Contents</summary>
- [AI Agent Instructions](#ai-agent-instructions)
  - [Purpose](#purpose)
  - [1. Core Compliance Requirements](#1-core-compliance-requirements)
    - [1.1. Mandatory Guidelines](#11-mandatory-guidelines)
    - [1.2. Core Principles from AI-GUIDELINES.md](#12-core-principles-from-ai-guidelinesmd)
  - [2. Knowledge Management (Byterover MCP)](#2-knowledge-management-byterover-mcp)
    - [2.1. `byterover-retrieve-knowledge`](#21-byterover-retrieve-knowledge)
    - [2.2. `byterover-store-knowledge`](#22-byterover-store-knowledge)
  - [3. Decision-Making Protocol](#3-decision-making-protocol)
    - [3.1. For Code Changes](#31-for-code-changes)
    - [3.2. For New Features](#32-for-new-features)
    - [3.3. For Documentation Tasks](#33-for-documentation-tasks)
  - [4. Project Context](#4-project-context)
    - [4.1. Repository Overview](#41-repository-overview)
    - [4.2. Key Directories](#42-key-directories)
    - [4.3. Git Submodules](#43-git-submodules)
    - [4.4. ZSH Redesign Status](#44-zsh-redesign-status)
  - [5. Security Requirements](#5-security-requirements)
    - [5.1. No Secrets in Repository](#51-no-secrets-in-repository)
    - [5.2. Path Policy](#52-path-policy)
    - [5.3. Secret Scanning Commands](#53-secret-scanning-commands)
  - [6. Development Workflow](#6-development-workflow)
    - [6.1. Pre-commit Workflow](#61-pre-commit-workflow)
    - [6.2. Performance Monitoring](#62-performance-monitoring)
    - [6.3. Maintenance Tasks](#63-maintenance-tasks)
  - [7. Technology-Specific Guidelines](#7-technology-specific-guidelines)
  - [8. Quick Reference](#8-quick-reference)
    - [8.1. File Paths](#81-file-paths)
    - [8.2. Important Make Targets](#82-important-make-targets)
    - [8.3. Environment Variables](#83-environment-variables)
  - [9. Enforcement](#9-enforcement)
  - [10. Navigation](#10-navigation)

</details>

## Purpose

This document provides instructions for AI agents working with this dotfiles repository. All AI agents **MUST** comply with the guidelines specified in [AI-GUIDELINES.md](AI-GUIDELINES.md), which takes preeminence over any other instructions.

## 1. Core Compliance Requirements

### 1.1. Mandatory Guidelines

AI agents working on this project **MUST**:

1. **Load and Follow AI-GUIDELINES.md**: Read and comply with [AI-GUIDELINES.md](AI-GUIDELINES.md) and all referenced documents within [`dot-config/ai/AI-GUIDELINES/`](dot-config/ai/AI-GUIDELINES/000-index.md) directory.

2. **Compute Checksums**: Generate a composite `guidelinesChecksum` (SHA256) over an ordered concatenation of all guideline sources for version tracking.

3. **Acknowledgment Headers**: Include compliance acknowledgment in all AI-authored artifacts:

   ```text
   Compliant with AI-GUIDELINES.md v<checksum>
   ```

4. **Rule Citation**: When performing sensitive actions (security changes, code execution, external access), cite the exact rule being followed with file reference:

   ```text
   rule AI-GUIDELINES.md:42
   ```

5. **Drift Detection**: Re-acknowledge guidelines if the `guidelinesChecksum` changes since the last recorded run.

### 1.2. Core Principles from AI-GUIDELINES.md

- **Clarity for Junior Developers**: All documents, code, and responses should be clear, actionable, and suitable for a junior developer to understand and implement.
- **General over Specific**: General principles take precedence over specific instructions.
- **Challenge Assumptions**: Ask clarifying questions, point out flaws, draw attention to inconsistencies.
- **No Sycophancy**: Be direct, objective, and use dry humor where appropriate.

## 2. Knowledge Management (Byterover MCP)

This project uses Byterover MCP server for knowledge management. AI agents **MUST** use the following tools appropriately:

### 2.1. `byterover-retrieve-knowledge`

**MUST** use this tool when:

- Starting any new task or implementation to gather relevant context
- Before making architectural decisions to understand existing patterns
- When debugging issues to check for previous solutions
- Working with unfamiliar parts of the codebase

### 2.2. `byterover-store-knowledge`

**MUST** use this tool when:

- Learning new patterns, APIs, or architectural decisions from the codebase
- Encountering error solutions or debugging techniques
- Finding reusable code patterns or utility functions
- Completing any significant task or plan implementation

## 3. Decision-Making Protocol

Before taking any action, follow the appropriate review process:

### 3.1. For Code Changes

1. **Review Guidelines**: Check relevant development standards in [`dot-config/ai/AI-GUIDELINES/`](dot-config/ai/AI-GUIDELINES/000-index.md)
2. **Security Assessment**: Apply security principles from AI-GUIDELINES.md §5.1-5.2
3. **Performance Impact**: Consider performance implications
4. **Testing Strategy**: Plan tests with 90% minimum coverage requirement
5. **Documentation Needs**: Identify required documentation changes

### 3.2. For New Features

1. **Architecture Review**: Ensure alignment with established architecture
2. **Framework Compliance**: Use established patterns and conventions
3. **Modern Practices**: Prioritize modern techniques and tools
4. **Comprehensive Testing**: Plan full testing suite with 90% minimum coverage

### 3.3. For Documentation Tasks

1. **Accessibility First**: Apply all accessibility standards
2. **Visual Learning**: Include color-coded, accessible Mermaid diagrams
3. **Junior Developer Focus**: Use clear, explicit language with concrete examples
4. **Technical Accuracy**: Verify all commands and technical information

## 4. Project Context

### 4.1. Repository Overview

This is a personal dotfiles repository with:

- **Primary Purpose**: Comprehensive management of `~/.config` directory structure
- **Scope**: Configurations for 60+ tools including ZSH, Neovim, Tmux, Emacs, Git, Docker, Kitty, Wezterm, Hammerspoon, Karabiner, and many more
- **Management**: GNU Stow for symlink-based configuration deployment
- **Active Development**: ZSH redesign (Stage 3 of 7) with performance monitoring and variance guard (3/3 streak)
- **Security**: Automated secret detection via Gitleaks (CI + pre-commit hooks)
- **Badge System**: Automated performance, structure, security, and hooks badges

### 4.2. Key Directories

- `dot-config/`: Root directory mirroring `~/.config` structure with 60+ tool configurations
  - `dot-config/zsh/`: ZSH configuration (staged redesign in progress - Stage 3 of 7)
  - `dot-config/ai/`: AI guidelines and project-specific documentation (symlink to external Obsidian vault)
  - `dot-config/nvim/`, `tmux/`, `git/`, `kitty/`, etc.: Individual tool configurations
- `tools/`: Maintenance and validation scripts
- `tests/`: Test suites (primarily for ZSH configuration)

### 4.3. Git Submodules

This repository uses git submodules for external dependencies:

| Submodule | Path | Repository | Version/Branch | Purpose |
|-----------|------|------------|----------------|---------|
| **tmux-starter** | `dot-config/alexandersix/tmux-starter` | [alexandersix/tmux-starter](https://github.com/alexandersix/tmux-starter.git) | v0.2.1 | Tmux starter configuration |
| **nix-darwin** | `dot-config/nix-darwin` | [s-a-c/nix-darwin](https://github.com/s-a-c/nix-darwin.git) | main | Personal Nix-darwin configuration fork |
| **zsh-quickstart-kit** | `dot-config/zsh/zsh-quickstart-kit` | [unixorn/zsh-quickstart-kit](https://github.com/unixorn/zsh-quickstart-kit) | 1.0.1-382-g1b1f14b | ZSH framework with plugins and configuration |

**Submodule Management Commands:**

```bash
# Initialize and update all submodules
git submodule update --init --recursive

# Update submodules to latest upstream commits
git submodule update --remote

# Check submodule status
git submodule status --recursive
```

**Note**: `dot-config/ai` is defined in `.gitmodules` but is tracked as a symlink to `../../nc/Documents/notes/obsidian/s-a-c/ai` rather than an initialized submodule.

### 4.4. ZSH Redesign Status

| Stage | Name | Status | Key Metrics |
|-------|------|--------|-------------|
| 1 | Foundation | ✅ Complete | Structure + perf scaffolding established |
| 2 | Pre-Plugin Migration | ✅ Complete | Baseline: mean=35ms stdev=11ms (N=5) |
| 3 | Post-Plugin Core | ⏳ In Progress | Security-integrity, interactive opts, core functions |
| 4-7 | Future Stages | 📋 Planned | Plugins, async, completion, promotion |

## 5. Security Requirements

### 5.1. No Secrets in Repository

**CRITICAL**: Never commit secrets, API keys, passwords, tokens, or bearer credentials.

- All secret-like patterns are scanned via Gitleaks
- CI blocks merges when secrets are detected
- Local pre-commit hook provides fast feedback

### 5.2. Path Policy

Disallow committing files matching sensitive patterns (e.g., `*.secrets.*`) unless explicitly exempted with documented risk acceptance.

### 5.3. Secret Scanning Commands

```bash
# Full repo scan
gitleaks detect --redact --config .github/gitleaks.toml

# Diff only (against main)
git fetch origin main
gitleaks detect --redact --config .github/gitleaks.toml --log-opts="origin/main..HEAD"
```

## 6. Development Workflow

### 6.1. Pre-commit Workflow

```bash
# Install pre-commit hooks
make precommit-install

# Run scoped pre-commit checks
make precommit-run

# Normalize executable bits and run checks
make precommit-normalize

# Shorthand aliases
make fmt    # Alias for precommit-normalize
make check  # Alias for precommit-run
```

### 6.2. Performance Monitoring

```bash
# Update performance badges (N=5 capture)
make perf-update

# Direct script execution
cd dot-config/zsh && ZDOTDIR=$(pwd) tools/update-variance-and-badges.zsh
```

### 6.3. Maintenance Tasks

```bash
# List broken symlinks
make broken-symlinks-list

# Remove broken symlinks
make broken-symlinks-remove

# Normalize executable bits
tools/maintenance/normalize-exec-bits.sh
```

## 7. Technology-Specific Guidelines

For detailed, technology-specific guidelines, refer to:

- **Documentation Standards**: `dot-config/ai/AI-GUIDELINES/Documentation/`
- **PHP & Laravel**: `dot-config/ai/AI-GUIDELINES/PHP-Laravel/`
- **JavaScript & TypeScript**: `dot-config/ai/AI-GUIDELINES/JavaScript-TypeScript/`
- **Shell & CLI**: `dot-config/ai/AI-GUIDELINES/Shell-CLI/`
- **Workflows**: `dot-config/ai/AI-GUIDELINES/Workflows/`
- **R&D Analysis**: `dot-config/ai/AI-GUIDELINES/RD-Analysis/`

## 8. Quick Reference

### 8.1. File Paths

- **Main Guidelines**: `/Users/s-a-c/dotfiles/AI-GUIDELINES.md`
- **Detailed Guidelines**: `/Users/s-a-c/dotfiles/dot-config/ai/AI-GUIDELINES/`
- **ZSH Config**: `/Users/s-a-c/dotfiles/dot-config/zsh/`
- **Tools**: `/Users/s-a-c/dotfiles/tools/`

### 8.2. Important Make Targets

| Target | Purpose |
|--------|---------|
| `make precommit-install` | Install pre-commit hooks |
| `make precommit-run` | Run scoped pre-commit checks |
| `make precommit-normalize` | Normalize exec bits and run checks |
| `make perf-update` | Update performance badges (N=5) |
| `make fmt` | Alias for `precommit-normalize` |
| `make check` | Alias for `precommit-run` |

### 8.3. Environment Variables

For secret scanning configuration:

- `SECRET_SCAN_VERBOSE=1`: Enable debug output
- `SECRET_SCAN_MAX_FINDINGS=20`: Raise finding limit
- `SECRET_SCAN_ALLOW_REGEXES='EXAMPLE,DUMMY'`: Suppression patterns
- `SECRET_SCAN_DISABLE_GITLEAKS=1`: Force fallback scanner
- `SKIP_SECRET_SCAN=1`: Bypass hook (discouraged)

For ZSH testing:

- `ZSH_KIT_RUN_FULL_TESTS=1`: Enable heavy tests during pre-commit

## 9. Enforcement

This orchestration policy is enforced by:

- **CLI Validators**: Pre-commit hooks validate compliance
- **GitHub Actions**: CI workflows enforce standards
- **Badge System**: Visual feedback on compliance status

Violations produce actionable, clickable output and non-zero exit status.

## 10. Navigation

- **Main Guidelines**: [AI-GUIDELINES.md](AI-GUIDELINES.md)
- **Detailed Index**: [AI-GUIDELINES/000-index.md](dot-config/ai/AI-GUIDELINES/000-index.md)
- **README**: [README.md](README.md)
- **License**: [LICENSE](LICENSE)

---

**Compliance Statement**: This document is compliant with [AI-GUIDELINES.md](AI-GUIDELINES.md) orchestration policy §4.
