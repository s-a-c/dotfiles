# <a id="zsh-configuration---ai-assistant-context-guide"></a>ZSH Configuration - AI Assistant Context Guide

## Table of Contents

<details>
<summary>Expand Table of Contents</summary>

- [1. Introduction](#1-introduction)
- [2. ZSH Configuration - AI Assistant Context Guide](#2-zsh-configuration---ai-assistant-context-guide)
- [3. AI Guidelines Reference](#3-ai-guidelines-reference)
  - [4. AI Guidelines Documentation](#4-ai-guidelines-documentation)
  - [5. Usage Guidelines for AI Assistants](#5-usage-guidelines-for-ai-assistants)
    - [6. When Modifying ZSH Configuration](#6-when-modifying-zsh-configuration)
    - [7. When Creating New Scripts or Modules](#7-when-creating-new-scripts-or-modules)
    - [8. When Debugging or Troubleshooting](#8-when-debugging-or-troubleshooting)
    - [9. When Interacting with Version Control](#9-when-interacting-with-version-control)
  - [10. Integration with Development Workflow](#10-integration-with-development-workflow)
    - [11. Code Review Process](#11-code-review-process)
    - [12. Testing and Validation](#12-testing-and-validation)
    - [13. Documentation Updates](#13-documentation-updates)
  - [14. Key Principles from AI Guidelines](#14-key-principles-from-ai-guidelines)
    - [15. Development Standards](#15-development-standards)
    - [16. Documentation Standards](#16-documentation-standards)
    - [17. Quality Assurance](#17-quality-assurance)
  - [18. Practical Implementation](#18-practical-implementation)
    - [19. Before Making Changes](#19-before-making-changes)
    - [20. During Development](#20-during-development)
    - [21. After Implementation](#21-after-implementation)
- [22. Framework Overview](#22-framework-overview)
  - [23. Architecture Description](#23-architecture-description)
  - [24. Core Sources](#24-core-sources)
- [25. Module Load Sequence](#25-module-load-sequence)
  - [26. Phase 1: Early Environment (.zshenv)](#26-phase-1-early-environment-zshenv)
  - [27. Phase 2: Pre-Plugin Phase (.zshrc.pre-plugins.d/)](#27-phase-2-pre-plugin-phase-zshrcpre-pluginsd)
  - [28. Phase 4: Post-Plugin Phase (.zshrc.d/)](#28-phase-4-post-plugin-phase-zshrcd)
- [29. Special Features](#29-special-features)
  - [30. Cursor Positioning System](#30-cursor-positioning-system)
  - [31. Splash Screen System](#31-splash-screen-system)
- [32. Key Commands for AI Assistants](#32-key-commands-for-ai-assistants)
  - [33. Diagnostics](#33-diagnostics)
- [34. Test cursor positioning](#34-test-cursor-positioning)
- [35. Check loaded plugins](#35-check-loaded-plugins)
  - [36. Configuration Management](#36-configuration-management)
- [37. Reload configuration](#37-reload-configuration)
- [38. Test specific modules](#38-test-specific-modules)

</details>

## 1. Introduction

This document provides comprehensive information and guidelines.

## 2. ZSH Configuration - AI Assistant Context Guide


This document provides comprehensive context for AI assistants working with the zsh configuration system. It explains the framework architecture, load sequences, module organization, and key scripts.


## 3. AI Guidelines Reference



## 4. AI Guidelines Documentation

- **Reference**: `/Users/s-a-c/nc/Documents/notes/obsidian/s-a-c/ai/AI-GUIDELINES.md` - [Comprehensive AI development guidelines](/Users/s-a-c/nc/Documents/notes/obsidian/s-a-c/ai/AI-GUIDELINES.md)
- **Location**: `/Users/s-a-c/nc/Documents/notes/obsidian/s-a-c/ai/AI-GUIDELINES/` - [Directory containing specific AI development standards](/Users/s-a-c/nc/Documents/notes/obsidian/s-a-c/ai/AI-GUIDELINES/000-index.md)
- **Purpose**: Provides standards, best practices, and conventions for AI-assisted development


## 5. Usage Guidelines for AI Assistants



## 6. When Modifying ZSH Configuration

1. **Reference AI-GUIDELINES.md First**: Before making any changes to the zsh configuration, consult the AI guidelines to ensure compliance with established standards
2. **Follow Development Standards**: Adhere to the coding standards, documentation requirements, and testing protocols outlined in the AI guidelines
3. **Maintain Compatibility**: Ensure any modifications preserve backward compatibility and follow the layered versioning system
4. **Document Changes**: Update appropriate documentation and commit messages following the guidelines


## 7. When Creating New Scripts or Modules

1. **Check Guidelines**: Review the AI guidelines for script creation, file organization, and naming conventions
2. **Follow Patterns**: Use established patterns from existing modules for consistency
3. **Include Documentation**: Add proper headers, comments, and usage examples as required by guidelines
4. **Test Thoroughly**: Follow testing procedures and include appropriate test files


## 8. When Debugging or Troubleshooting

1. **Use Standard Procedures**: Follow debugging and troubleshooting procedures outlined in both this document and the AI guidelines
2. **Document Findings**: Record findings and solutions in appropriate documentation following guidelines
3. **Provide Clear Explanations**: Explain root causes and solutions in clear, documented format


## 9. When Interacting with Version Control

1. **Follow Commit Standards**: Use the commit message formats and branching strategies defined in AI-GUIDELINES.md
2. **Document Changes**: Ensure all changes are properly documented and follow the established patterns
3. **Maintain History**: Preserve meaningful commit history and follow the guidelines for version control


## 10. Integration with Development Workflow



## 11. Code Review Process

- **Guidelines Reference**: Use AI-GUIDELINES.md as the authoritative source for code review standards
- **ZSH-Specific Considerations**: Apply zsh-specific best practices alongside general AI guidelines
- **Documentation Requirements**: Ensure all changes are properly documented according to both sets of guidelines


## 12. Testing and Validation

- **Testing Standards**: Follow testing procedures from both AI-GUIDELINES.md and zsh-specific testing requirements
- **Validation Criteria**: Use validation criteria defined in the guidelines to ensure quality and compatibility
- **Performance Considerations**: Apply performance testing standards from both guidelines


## 13. Documentation Updates

- **Consistency**: Maintain consistency between this AGENTS.md and AI-GUIDELINES.md
- **Cross-Reference**: Ensure proper cross-referencing between documentation files
- **Version Control**: Follow documentation version control procedures from the guidelines


## 14. Key Principles from AI Guidelines



## 15. Development Standards

- **Modular Design**: Maintain modular design principles when modifying zsh configuration
- **Backward Compatibility**: Preserve backward compatibility as required by guidelines
- **Performance Considerations**: Apply performance optimization standards from guidelines


## 16. Documentation Standards

- **Clear Documentation**: Maintain clear, comprehensive documentation for all changes
- **Consistent Formatting**: Use consistent formatting and organization as defined in guidelines
- **Version Control**: Follow proper version control and documentation practices


## 17. Quality Assurance

- **Testing Requirements**: Meet testing requirements from both general and zsh-specific guidelines
- **Code Review**: Participate in code review processes following established standards
- **Validation**: Ensure all changes meet validation criteria from guidelines


## 18. Practical Implementation



## 19. Before Making Changes

1. **Read AI-GUIDELINES.md**: Review relevant sections of the AI guidelines
2. **Check Existing Patterns**: Look for similar patterns in existing zsh configuration
3. **Plan Changes**: Plan changes following both zsh and AI guidelines
4. **Document Intent**: Document the intent and approach following guidelines


## 20. During Development

1. **Follow Standards**: Apply coding standards from both guidelines
2. **Test Incrementally**: Test changes incrementally following testing procedures
3. **Document Progress**: Document progress and findings according to guidelines
4. **Validate Compliance**: Ensure compliance with both sets of guidelines


## 21. After Implementation

1. **Final Testing**: Perform final testing following guidelines
2. **Documentation Updates**: Update all relevant documentation following guidelines
3. **Code Review**: Participate in code review following established standards
4. **Version Control**: Commit changes following version control procedures

This AGENTS.md should be used in conjunction with AI-GUIDELINES.md to ensure all zsh configuration modifications follow established standards and best practices for AI-assisted development.


## 22. Framework Overview

This Zsh configuration is built upon the **[Unixorn Zsh Quickstart Kit](https://github.com/unixorn/zsh-quickstart-kit)**. It uses a modular, directory-based approach to manage configuration files in distinct phases.

Plugin management is handled by **[zgenom](https://github.com/jandamm/zgenom)**, a fast, lightweight plugin manager. The Quickstart Kit provides the orchestration to load `zgenom` and the plugins it manages.

---

### **Versioning and Symlink Schema**

A key feature of this configuration is a versioning system managed by symlinks. This allows for atomic updates and easy rollbacks of configuration sets. The pattern is consistent across all major components:

-   A base file/directory (e.g., `.zshrc.d`) is a symlink to a `.live` version (e.g., `.zshrc.d.live`).
-   The `.live` version is a symlink to a specific, numbered version (e.g., `.zshrc.d.01`).

**Example:** `zshrc.d` → `zshrc.d.live` → `zshrc.d.01`

This means the **effective directory** being sourced is the numbered one. When making changes, it's crucial to edit files in the correct, active, numbered directory.

---

## 25. Zsh Startup Sequence (Detailed Analysis)

The shell startup is a precise, multi-phase process orchestrated by the main `.zshrc` file. Understanding this sequence is critical for debugging and correctly placing new functionality.

### **Phase 1: Pre-Zshrc Environment (`.zshenv`)**

This phase runs first for **all** shell sessions, both interactive and non-interactive.

-   **Effective File:** `/Users/s-a-c/dotfiles/dot-config/zsh/.zshenv.01` (via `.zshenv` → `.zshenv.live`)
-   **Purpose:**
    -   Set critical, universal environment variables (`PATH`, `ZDOTDIR`, `XDG_` variables).
    -   Define globally required helper functions (e.g., `zf::path_prepend`, `zf::debug`).
    -   **NO** plugins are loaded here. This phase must be lightweight and dependency-free.

### **Phase 2: Interactive Shell Entrypoint (`.zshrc`)**

The main `.zshrc` file, sourced from the Quickstart Kit, begins the interactive session setup. It acts as the central orchestrator for the following sub-phases.

-   **Effective File:** `/Users/s-a-c/dotfiles/dot-config/zsh/zsh-quickstart-kit/zsh/.zshrc` (via `.zshrc` symlink)

### **Phase 3: Pre-Plugin Configuration (`.zshrc.pre-plugins.d`)**

This is the first directory sourced by the `.zshrc` orchestrator.

-   **Effective Directory:** `/Users/s-a-c/dotfiles/dot-config/zsh/.zshrc.pre-plugins.d.01`
-   **Purpose:**
    -   Load user-defined functions and settings that must exist *before* plugins are loaded.
    -   Configure settings that influence how `zgenom` or specific plugins will behave.

### **Phase 4: Plugin Activation (`.zgen-setup` & `.zshrc.add-plugins.d`)**

This is the core phase where `zgenom` loads all plugins.

1.  **Plugin Definition (`.zshrc.add-plugins.d`)**:
    -   **Effective Directory:** `/Users/s-a-c/dotfiles/dot-config/zsh/.zshrc.add-plugins.d.00`
    -   **Purpose:** This directory's scripts contain the `zgenom load ...` commands that tell `zgenom` *which* plugins to manage. The plugins are declared here but are **not yet active**.

2.  **Plugin Sourcing (`.zgen-setup`)**:
    -   **Effective File:** `/Users/s-a-c/dotfiles/dot-config/zsh/zsh-quickstart-kit/zsh/.zgen-setup`
    -   **Purpose:** This script runs `zgenom`. It takes the list of plugins from the previous step, generates a static `init.zsh` script, and then sources it. **After this script completes, all plugins are fully loaded and their functions are available in the shell.**

### **Phase 5: Post-Plugin Configuration (`.zshrc.d`)**

This is the final major configuration directory sourced by `.zshrc`.

-   **Effective Directory:** `/Users/s-a-c/dotfiles/dot-config/zsh/.zshrc.d.01`
-   **Purpose:**
    -   This is the correct location for any script that needs to **use functions or commands provided by plugins**.
    -   Configure aliases, keybindings, and settings that depend on the plugin environment.
    -   The startup errors you observed were caused by logic (like `herd-load-nvmrc`) being in this phase but called from an earlier one.

### **Phase 6: Finalization**

The `.zshrc` orchestrator concludes by setting up the prompt (sourcing `.p10k.zsh`), running final health checks, and defining any last-minute shell options.

---

### **Implications for Development (Key Rules)**

1.  **To set a global environment variable:** Use `.zshenv.01`.
2.  **To add a new plugin:** Add a `zgenom load ...` command in a file within `.zshrc.add-plugins.d.00`.
3.  **To configure a plugin's behavior *before* it loads:** Use a file in `.zshrc.pre-plugins.d.01`.
4.  **To *use* a command from a plugin:** Place your script in `.zshrc.d.01`.
5.  **Execution Order:** Files within each `.d` directory are sourced in lexicographical (alphabetical) order. Use numbered prefixes (e.g., `000-`, `450-`, `999-`) to control the sequence precisely.



## 29. Special Features



## 30. Cursor Positioning System

Multi-layered approach:
1. `400-options.zsh` - Core zsh options (`unsetopt PROMPT_CR`, `setopt PROMPT_SP`)
2. `540-prompt-starship.zsh` - Starship-specific fixes
3. `560-user-interface.zsh` - Simplified splash timing


## 31. Splash Screen System

Immediate execution in `560-user-interface.zsh` before first prompt
Controls: `NO_SPLASH=1` environment variable


## 32. Key Commands for AI Assistants



## 33. Diagnostics

```bash

## 34. Test cursor positioning

fix-starship-cursor


## 35. Check loaded plugins

zgenom list
```


## 36. Configuration Management

```bash

## 37. Reload configuration

source ~/.zshrc


## 38. Test specific modules

zsh -i -c "source ~/.zshrc.d/540-prompt-starship.zsh"
```

This AGENTS.md provides comprehensive context for understanding and extending the zsh configuration system.


## Navigation

**Previous:** [Previous Doc](path) | **Next:** [Next Doc](path) | **Top**

[byterover-mcp]

[byterover-mcp]

You are given two tools from Byterover MCP server, including
## 1. `byterover-store-knowledge`
You `MUST` always use this tool when:

+ Learning new patterns, APIs, or architectural decisions from the codebase
+ Encountering error solutions or debugging techniques
+ Finding reusable code patterns or utility functions
+ Completing any significant task or plan implementation

## 2. `byterover-retrieve-knowledge`
You `MUST` always use this tool when:

+ Starting any new task or implementation to gather relevant context
+ Before making architectural decisions to understand existing patterns
+ When debugging issues to check for previous solutions
+ Working with unfamiliar parts of the codebase
