# ZSH Configuration Refactoring Plan

## Table of Contents

<details>
<summary>Click to expand</summary>

- [1. Objective](#1-objective)
- [2. Analysis of Legacy Configuration](#2-analysis-of-legacy-configuration)
- [3. Refactoring Plan](#3-refactoring-plan)
- [4. Verification](#4-verification)

</details>

---


## 1. Objective

The goal of this refactoring is to migrate the valuable UI features from the legacy configuration into the active configuration, ensuring that the changes are consistent with the existing modular structure and do not introduce any conflicts or duplications.

## 2. Analysis of Legacy Configuration

The legacy UI configuration files (`.backup/.zshrc.d.legacy/consolidated-modules/06-user-interface.zsh` and `.backup/.zshrc.d.legacy/consolidated-modules.backup-20250915-040555/07-user-interface.zsh`) contain a wealth of aliases, keybindings, and functions that are not present in the current configuration.

The following features have been identified as valuable and will be migrated:

*   **Aliases:** Over 130 aliases for git, file operations, directory navigation, development tools, and macOS-specific commands.
*   **Keybindings:** Over 60 keybindings for history navigation, line editing, word movement, and custom widgets.
*   **Functions:**
    *   `set_terminal_title`: A function to set the terminal title.
    *   `cd_with_ls`: A function that automatically runs `ls` after changing directories.
*   **Modern Tool Replacements:** Logic to automatically replace `ls` with `eza`, `cat` with `bat`, `find` with `fd`, and `grep` with `rg` if they are installed.

The following features will not be migrated at this time:

*   **Splash Screen:** The splash screen, health check, and performance tips functions are more complex and require more careful integration with the existing startup process. They will be considered for a future refactoring.

## 3. Refactoring Plan

The refactoring will be implemented as follows:

1.  **Create a new plugin file:** A new file, `310-user-interface.zsh`, has been created in the `.zshrc.add-plugins.d.00` directory. This file is reserved for any plugins that may be required by the new UI features in the future.

2.  **Create a new configuration file:** A new file, `530-user-interface.zsh`, has been created in the `.zshrc.d.00` directory. This file contains the consolidated UI features from the legacy files, including:
    *   All of the aliases.
    *   All of the keybindings, using the more robust ZLE widget registration system from `06-user-interface.zsh`.
    *   The `set_terminal_title` and `cd_with_ls` functions.
    *   The logic for modern tool replacements.

## 4. Verification

The new configuration has been designed to be consistent with the existing modular structure and should not introduce any conflicts or duplications. The new files have been added to the appropriate directories and will be loaded automatically by the existing startup process.

---

**Navigation:** [Top ↑](#zsh-configuration-refactoring-plan)

---

*Last updated: 2025-10-13*
