# Kilocode Memory Bank Troubleshooting Guide

<details>
<summary>Table of Contents</summary>

- [1. Introduction](#1-introduction)
- [2. Common Issues](#2-common-issues)
  - [2.1. `kilocode: command not found`](#21-kilocode-command-not-found)
  - [2.2. Search is Slow or Unresponsive](#22-search-is-slow-or-unresponsive)
  - [2.3. Git Commits are Failing](#23-git-commits-are-failing)
- [3. Frequently Asked Questions (FAQ)](#3-frequently-asked-questions-faq)
  - [3.1. Where is my data stored?](#31-where-is-my-data-stored)
  - [3.2. Can I use a different editor?](#32-can-i-use-a-different-editor)
  - [3.3. How do I roll back to a previous version of an entry?](#33-how-do-i-roll-back-to-a-previous-version-of-an-entry)

</details>

## 1. Introduction

This guide provides solutions to common issues and answers to frequently asked questions. If you're experiencing a problem, check here first.

## 2. Common Issues

### 2.1. `kilocode: command not found`

-   **Symptom**: The `kilocode` command is not recognized in your terminal.
-   **Solution**:
    1.  Ensure that the initialization script is correctly sourced in your `.zshrc` file. See the [Installation Guide](../installation/010-guide.md) for details.
    2.  Restart your terminal session or run `source ~/.zshrc` to apply the changes.
    3.  Verify that the script's path is correct and the file is executable.

### 2.2. Search is Slow or Unresponsive

-   **Symptom**: The `search` command takes a long time to return results.
-   **Solution**:
    1.  **Re-index**: Although indexing is automatic, a manual re-index can sometimes resolve issues. A command for this may be provided in future versions.
    2.  **Check Data Size**: An extremely large number of entries can impact performance. Consider archiving old entries if performance degrades.

### 2.3. Git Commits are Failing

-   **Symptom**: You receive an error related to Git when adding or modifying entries.
-   **Solution**:
    1.  **Check Git Configuration**: Ensure that your Git user name and email are configured correctly:
        ```sh
        git config --global user.name "Your Name"
        git config --global user.email "you@example.com"
        ```
    2.  **Permissions**: Verify that you have write permissions for the memory bank's data directory.

## 3. Frequently Asked Questions (FAQ)

### 3.1. Where is my data stored?

By default, your data is stored in `$XDG_DATA_HOME/kilocode/memory-bank`. You can override this by setting the `KILOCODE_MEMORY_BANK_DIR` environment variable.

### 3.2. Can I use a different editor?

Yes. Set the `KILOCODE_MEMORY_BANK_EDITOR` or `$EDITOR` environment variables to your preferred editor. See the [Configuration Reference](../configuration/010-reference.md) for more details.

### 3.3. How do I roll back to a previous version of an entry?

Since the memory bank uses Git for version control, you can use standard Git commands to view the history and revert changes. Navigate to the data directory and use `git log` to find the commit you want to restore.

---
[Previous](./000-index.md) | [Next](./000-index.md) | [Top](./000-index.md)
