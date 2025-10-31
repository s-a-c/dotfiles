# ZSH Configuration - AI Assistant Context Guide

Version: 1.0
Date: 2025-10-30

## Table of Contents

<details>
<summary>Expand Table of Contents</summary>

- [ZSH Configuration - AI Assistant Context Guide](#zsh-configuration---ai-assistant-context-guide)
  - [Table of Contents](#table-of-contents)
  - [1. `byterover-store-knowledge`](#1-byterover-store-knowledge)
  - [2. `byterover-retrieve-knowledge`](#2-byterover-retrieve-knowledge)
  - [3. Introduction](#3-introduction)
  - [4. ZSH Configuration - AI Assistant Context Guide](#4-zsh-configuration---ai-assistant-context-guide)
  - [5. AI Guidelines Reference](#5-ai-guidelines-reference)
  - [6. AI Guidelines Documentation](#6-ai-guidelines-documentation)
  - [7. Usage Guidelines for AI Assistants](#7-usage-guidelines-for-ai-assistants)
  - [8. When Modifying ZSH Configuration](#8-when-modifying-zsh-configuration)
  - [9. When Creating New Scripts or Modules](#9-when-creating-new-scripts-or-modules)
  - [10. When Debugging or Troubleshooting](#10-when-debugging-or-troubleshooting)
  - [11. When Interacting with Version Control](#11-when-interacting-with-version-control)
  - [12. Integration with Development Workflow](#12-integration-with-development-workflow)
  - [13. Code Review Process](#13-code-review-process)
  - [14. Testing and Validation](#14-testing-and-validation)
  - [15. Documentation Updates](#15-documentation-updates)
  - [16. Key Principles from AI Guidelines](#16-key-principles-from-ai-guidelines)
  - [17. Development Standards](#17-development-standards)
  - [18. Documentation Standards](#18-documentation-standards)
  - [19. Quality Assurance](#19-quality-assurance)
  - [20. Practical Implementation](#20-practical-implementation)
  - [21. Before Making Changes](#21-before-making-changes)
  - [22. During Development](#22-during-development)
  - [23. After Implementation](#23-after-implementation)
  - [24. Framework Overview](#24-framework-overview)
    - [24.1. **Versioning and Symlink Schema**](#241-versioning-and-symlink-schema)
  - [25. Zsh Startup Sequence (Detailed Analysis)](#25-zsh-startup-sequence-detailed-analysis)
    - [25.1. **Phase 1: Pre-Zshrc Environment (`.zshenv`)**](#251-phase-1-pre-zshrc-environment-zshenv)
    - [25.2. **Phase 2: Interactive Shell Entrypoint (`.zshrc`)**](#252-phase-2-interactive-shell-entrypoint-zshrc)
    - [25.3. **Phase 3: Pre-Plugin Configuration (`.zshrc.pre-plugins.d`)**](#253-phase-3-pre-plugin-configuration-zshrcpre-pluginsd)
    - [25.4. **Phase 4: Plugin Activation (`.zgen-setup` \& `.zshrc.add-plugins.d`)**](#254-phase-4-plugin-activation-zgen-setup--zshrcadd-pluginsd)
    - [25.5. **Phase 5: Post-Plugin Configuration (`.zshrc.d`)**](#255-phase-5-post-plugin-configuration-zshrcd)
    - [25.6. **Phase 6: Finalization**](#256-phase-6-finalization)
    - [25.7. **Implications for Development (Key Rules)**](#257-implications-for-development-key-rules)
  - [26. Special Features](#26-special-features)
  - [27. Cursor Positioning System](#27-cursor-positioning-system)
  - [28. Splash Screen System](#28-splash-screen-system)
  - [29. Key Commands for AI Assistants](#29-key-commands-for-ai-assistants)
  - [30. Diagnostics](#30-diagnostics)
  - [31. Configuration Management](#31-configuration-management)

</details>

[byterover-mcp]

[byterover-mcp]

You are given two tools from Byterover MCP server, including

## 1. `byterover-store-knowledge`

You `MUST` always use this tool when:

- Learning new patterns, APIs, or architectural decisions from the codebase
- Encountering error solutions or debugging techniques
- Finding reusable code patterns or utility functions
- Completing any significant task or plan implementation

## 2. `byterover-retrieve-knowledge`

You `MUST` always use this tool when:

- Starting any new task or implementation to gather relevant context
- Before making architectural decisions to understand existing patterns
- When debugging issues to check for previous solutions
- Working with unfamiliar parts of the codebase

## 3. Introduction

This document provides comprehensive information and guidelines.

## 4. ZSH Configuration - AI Assistant Context Guide

This document provides comprehensive context for AI assistants working with the zsh configuration system. It explains the framework architecture, load sequences, module organization, and key scripts.

## 5. AI Guidelines Reference

## 6. AI Guidelines Documentation

- **Reference**: `/Users/s-a-c/nc/Documents/notes/obsidian/s-a-c/ai/AI-GUIDELINES.md` - [Comprehensive AI development guidelines](file:///Users/s-a-c/nc/Documents/notes/obsidian/s-a-c/ai/AI-GUIDELINES.md)
- **Location**: `/Users/s-a-c/nc/Documents/notes/obsidian/s-a-c/ai/AI-GUIDELINES/` - [Directory containing specific AI development standards](file:///Users/s-a-c/nc/Documents/notes/obsidian/s-a-c/ai/AI-GUIDELINES/000-index.md)
- **Purpose**: Provides standards, best practices, and conventions for AI-assisted development

## 7. Usage Guidelines for AI Assistants

## 8. When Modifying ZSH Configuration

1. **Reference AI-GUIDELINES.md First**: Before making any changes to the zsh configuration, consult the AI guidelines to ensure compliance with established standards
2. **Follow Development Standards**: Adhere to the coding standards, documentation requirements, and testing protocols outlined in the AI guidelines
3. **Maintain Compatibility**: Ensure any modifications preserve backward compatibility and follow the layered versioning system
4. **Document Changes**: Update appropriate documentation and commit messages following the guidelines

## 9. When Creating New Scripts or Modules

1. **Check Guidelines**: Review the AI guidelines for script creation, file organization, and naming conventions
2. **Follow Patterns**: Use established patterns from existing modules for consistency
3. **Include Documentation**: Add proper headers, comments, and usage examples as required by guidelines
4. **Test Thoroughly**: Follow testing procedures and include appropriate test files

## 10. When Debugging or Troubleshooting

1. **Use Standard Procedures**: Follow debugging and troubleshooting procedures outlined in both this document and the AI guidelines
2. **Document Findings**: Record findings and solutions in appropriate documentation following guidelines
3. **Provide Clear Explanations**: Explain root causes and solutions in clear, documented format

## 11. When Interacting with Version Control

1. **Follow Commit Standards**: Use the commit message formats and branching strategies defined in AI-GUIDELINES.md
2. **Document Changes**: Ensure all changes are properly documented and follow the established patterns
3. **Maintain History**: Preserve meaningful commit history and follow the guidelines for version control

## 12. Integration with Development Workflow

## 13. Code Review Process

- **Guidelines Reference**: Use AI-GUIDELINES.md as the authoritative source for code review standards
- **ZSH-Specific Considerations**: Apply zsh-specific best practices alongside general AI guidelines
- **Documentation Requirements**: Ensure all changes are properly documented according to both sets of guidelines

## 14. Testing and Validation

- **Testing Standards**: Follow testing procedures from both AI-GUIDELINES.md and zsh-specific testing requirements
- **Validation Criteria**: Use validation criteria defined in the guidelines to ensure quality and compatibility
- **Performance Considerations**: Apply performance testing standards from both guidelines

## 15. Documentation Updates

- **Consistency**: Maintain consistency between this AGENTS.md and AI-GUIDELINES.md
- **Cross-Reference**: Ensure proper cross-referencing between documentation files
- **Version Control**: Follow documentation version control procedures from the guidelines

## 16. Key Principles from AI Guidelines

## 17. Development Standards

- **Modular Design**: Maintain modular design principles when modifying zsh configuration
- **Backward Compatibility**: Preserve backward compatibility as required by guidelines
- **Performance Considerations**: Apply performance optimization standards from guidelines

## 18. Documentation Standards

- **Clear Documentation**: Maintain clear, comprehensive documentation for all changes
- **Consistent Formatting**: Use consistent formatting and organization as defined in guidelines
- **Version Control**: Follow proper version control and documentation practices

## 19. Quality Assurance

- **Testing Requirements**: Meet testing requirements from both general and zsh-specific guidelines
- **Code Review**: Participate in code review processes following established standards
- **Validation**: Ensure all changes meet validation criteria from guidelines

## 20. Practical Implementation

## 21. Before Making Changes

1. **Read AI-GUIDELINES.md**: Review relevant sections of the AI guidelines
2. **Check Existing Patterns**: Look for similar patterns in existing zsh configuration
3. **Plan Changes**: Plan changes following both zsh and AI guidelines
4. **Document Intent**: Document the intent and approach following guidelines

## 22. During Development

1. **Follow Standards**: Apply coding standards from both guidelines
2. **Test Incrementally**: Test changes incrementally following testing procedures
3. **Document Progress**: Document progress and findings according to guidelines
4. **Validate Compliance**: Ensure compliance with both sets of guidelines

## 23. After Implementation

1. **Final Testing**: Perform final testing following guidelines
2. **Documentation Updates**: Update all relevant documentation following guidelines
3. **Code Review**: Participate in code review following established standards
4. **Version Control**: Commit changes following version control procedures

This AGENTS.md should be used in conjunction with AI-GUIDELINES.md to ensure all zsh configuration modifications follow established standards and best practices for AI-assisted development.

## 24. Framework Overview

This Zsh configuration is built upon the **[Unixorn Zsh Quickstart Kit](https://github.com/unixorn/zsh-quickstart-kit)**. It uses a modular, directory-based approach to manage configuration files in distinct phases.

Plugin management is handled by **[zgenom](https://github.com/jandamm/zgenom)**, a fast, lightweight plugin manager. The Quickstart Kit provides the orchestration to load `zgenom` and the plugins it manages.

### 24.1. **Versioning and Symlink Schema**

A key feature of this configuration is a versioning system managed by symlinks. This allows for atomic updates and easy rollbacks of configuration sets. The pattern is consistent across all major components:

- A base file/directory (e.g., `.zshrc.d`) is a symlink to a `.live` version (e.g., `.zshrc.d.live`).
- The `.live` version is a symlink to a specific, numbered version (e.g., `.zshrc.d.01`).

**Example:** `zshrc.d` → `zshrc.d.live` → `zshrc.d.01`

This means the **effective directory** being sourced is the numbered one. When making changes, it's crucial to edit files in the correct, active, numbered directory.

## 25. Zsh Startup Sequence (Detailed Analysis)

The shell startup is a precise, multi-phase process orchestrated by the main `.zshrc` file. Understanding this sequence is critical for debugging and correctly placing new functionality.

### 25.1. **Phase 1: Pre-Zshrc Environment (`.zshenv`)**

This phase runs first for **all** shell sessions, both interactive and non-interactive.

- **Effective File:** `/Users/s-a-c/dotfiles/dot-config/zsh/.zshenv.01` (via `.zshenv` → `.zshenv.live`)
- **Purpose:**
  - Set critical, universal environment variables (`PATH`, `ZDOTDIR`, `XDG_` variables).
  - Define globally required helper functions (e.g., `zf::path_prepend`, `zf::debug`).
  - **NO** plugins are loaded here. This phase must be lightweight and dependency-free.

### 25.2. **Phase 2: Interactive Shell Entrypoint (`.zshrc`)**

The main `.zshrc` file, sourced from the Quickstart Kit, begins the interactive session setup. It acts as the central orchestrator for the following sub-phases.

- **Effective File:** `/Users/s-a-c/dotfiles/dot-config/zsh/zsh-quickstart-kit/zsh/.zshrc` (via `.zshrc` symlink)

### 25.3. **Phase 3: Pre-Plugin Configuration (`.zshrc.pre-plugins.d`)**

This is the first directory sourced by the `.zshrc` orchestrator.

- **Effective Directory:** `/Users/s-a-c/dotfiles/dot-config/zsh/.zshrc.pre-plugins.d.01`
- **Purpose:**
  - Load user-defined functions and settings that must exist *before* plugins are loaded.
  - Configure settings that influence how `zgenom` or specific plugins will behave.

### 25.4. **Phase 4: Plugin Activation (`.zgen-setup` & `.zshrc.add-plugins.d`)**

This is the core phase where `zgenom` loads all plugins.

1. **Plugin Definition (`.zshrc.add-plugins.d`)**:

- **Effective Directory:** `/Users/s-a-c/dotfiles/dot-config/zsh/.zshrc.add-plugins.d.00`
- **Purpose:** This directory's scripts contain the `zgenom load ...` commands that tell `zgenom` *which* plugins to manage. The plugins are declared here but are **not yet active**.

2. **Plugin Sourcing (`.zgen-setup`)**:

- **Effective File:** `/Users/s-a-c/dotfiles/dot-config/zsh/zsh-quickstart-kit/zsh/.zgen-setup`
- **Purpose:** This script runs `zgenom`. It takes the list of plugins from the previous step, generates a static `init.zsh` script, and then sources it. **After this script completes, all plugins are fully loaded and their functions are available in the shell.**

### 25.5. **Phase 5: Post-Plugin Configuration (`.zshrc.d`)**

This is the final major configuration directory sourced by `.zshrc`.

- **Effective Directory:** `/Users/s-a-c/dotfiles/dot-config/zsh/.zshrc.d.01`
- **Purpose:**
  - This is the correct location for any script that needs to **use functions or commands provided by plugins**.
  - Configure aliases, keybindings, and settings that depend on the plugin environment.
  - The startup errors you observed were caused by logic (like `herd-load-nvmrc`) being in this phase but called from an earlier one.

### 25.6. **Phase 6: Finalization**

The `.zshrc` orchestrator concludes by setting up the prompt (sourcing `.p10k.zsh`), running final health checks, and defining any last-minute shell options.

### 25.7. **Implications for Development (Key Rules)**

1. **To set a global environment variable:** Use `.zshenv.01`.
2. **To add a new plugin:** Add a `zgenom load ...` command in a file within `.zshrc.add-plugins.d.00`.
3. **To configure a plugin's behavior *before* it loads:** Use a file in `.zshrc.pre-plugins.d.01`.
4. **To *use* a command from a plugin:** Place your script in `.zshrc.d.01`.
5. **Execution Order:** Files within each `.d` directory are sourced in lexicographical (alphabetical) order. Use numbered prefixes (e.g., `000-`, `450-`, `999-`) to control the sequence precisely.

## 26. Special Features

## 27. Cursor Positioning System

Multi-layered approach:

1. `400-options.zsh` - Core zsh options (`unsetopt PROMPT_CR`, `setopt PROMPT_SP`)
2. `540-prompt-starship.zsh` - Starship-specific fixes
3. `560-user-interface.zsh` - Simplified splash timing

## 28. Splash Screen System

Immediate execution in `560-user-interface.zsh` before first prompt
Controls: `NO_SPLASH=1` environment variable

## 29. Key Commands for AI Assistants

## 30. Diagnostics

```bash
## Test cursor positioning
fix-starship-cursor

## Check loaded plugins
zgenom list
```

## 31. Configuration Management

```bash
## Reload configuration
source ~/.zshrc

## Test specific modules
zsh -i -c "source ~/.zshrc.d/540-prompt-starship.zsh"
```

This AGENTS.md provides comprehensive context for understanding and extending the zsh configuration system.

***Navigation*** [←  README](README.md) | [Top ↑](#zsh-configuration---ai-assistant-context-guide) |[AI Guidelines →](AI-GUIDELINES.md)
