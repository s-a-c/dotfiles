# Kilocode Memory Bank Configuration Reference

<details>
<summary>Table of Contents</summary>

- [1. Introduction](#1-introduction)
- [2. Environment Variables](#2-environment-variables)
  - [2.1. `KILOCODE_MEMORY_BANK_DIR`](#21-kilocode_memory_bank_dir)
  - [2.2. `KILOCODE_MEMORY_BANK_EDITOR`](#22-kilocode_memory_bank_editor)
- [3. Configuration File](#3-configuration-file)
  - [3.1. Example Configuration](#31-example-configuration)
  - [3.2. Configuration Options](#32-configuration-options)

</details>

## 1. Introduction

This document provides a comprehensive reference for all the configuration options available in the Kilocode Memory Bank.

## 2. Environment Variables

The following environment variables can be used to configure the system's behavior.

### 2.1. `KILOCODE_MEMORY_BANK_DIR`

-   **Description**: Specifies the root directory for the memory bank's data storage.
-   **Default**: `$XDG_DATA_HOME/kilocode/memory-bank`
-   **Example**:
    ```sh
    export KILOCODE_MEMORY_BANK_DIR="~/.local/share/my-memory-bank"
    ```

### 2.2. `KILOCODE_MEMORY_BANK_EDITOR`

-   **Description**: Sets the default editor for creating and editing memory entries.
-   **Default**: `$EDITOR` (or `vim` if `$EDITOR` is not set).
-   **Example**:
    ```sh
    export KILOCODE_MEMORY_BANK_EDITOR="nvim"
    ```

## 3. Configuration File

While environment variables are suitable for simple overrides, a configuration file is recommended for more permanent settings.

-   **Location**: `$XDG_CONFIG_HOME/kilocode/memory-bank/config.json`
-   **Format**: JSON

### 3.1. Example Configuration

```json
{
  "editor": "code",
  "search": {
    "default_operator": "AND",
    "case_sensitive": false
  },
  "git": {
    "auto_commit": true
  }
}
```

### 3.2. Configuration Options

-   **`editor`**: (string) The default text editor.
-   **`search.default_operator`**: (string) The default search operator (`AND`/`OR`).
-   **`search.case_sensitive`**: (boolean) Toggles case-sensitive searching.
-   **`git.auto_commit`**: (boolean) Enables or disables automatic Git commits after each operation.

---
[Previous](./000-index.md) | [Next](./000-index.md) | [Top](./000-index.md)
