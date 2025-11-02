# Kilocode Memory Bank Examples

<details>
<summary>Table of Contents</summary>

- [1. Introduction](#1-introduction)
- [2. Basic Usage](#2-basic-usage)
  - [2.1. Storing a Useful Command](#21-storing-a-useful-command)
  - [2.2. Saving a Code Snippet](#22-saving-a-code-snippet)
- [3. Searching](#3-searching)
  - [3.1. Finding a Command You Vaguely Remember](#31-finding-a-command-you-vaguely-remember)
  - [3.2. Combining Search with Tags](#32-combining-search-with-tags)
- [4. Advanced Usage](#4-advanced-usage)
  - [4.1. Chaining Commands](#41-chaining-commands)
  - [4.2. Scripting and Automation](#42-scripting-and-automation)
- [5. Tag Management](#5-tag-management)
  - [5.1. Adding Multiple Tags to an Entry](#51-adding-multiple-tags-to-an-entry)
  - [5.2. Cleaning Up Old Tags](#52-cleaning-up-old-tags)

</details>

## 1. Introduction

This document provides a collection of practical examples to help you get the most out of the Kilocode Memory Bank.

## 2. Basic Usage

### 2.1. Storing a Useful Command

```sh
kilocode memory add "Find all files modified in the last 24 hours: find . -mtime -1" --tags "cli,find,files"
```

### 2.2. Saving a Code Snippet

```sh
kilocode memory add '
function factorial(n) {
  if (n === 0) {
    return 1;
  }
  return n * factorial(n - 1);
}
' --tags "javascript,recursion,factorial"
```

## 3. Searching

### 3.1. Finding a Command You Vaguely Remember

```sh
# You remember it had something to do with "modified files"
kilocode memory search "modified files"
```

### 3.2. Combining Search with Tags

```sh
# You need a javascript snippet related to recursion
kilocode memory search "recursion" --tags "javascript"
```

## 4. Advanced Usage

### 4.1. Chaining Commands

You can use the output of the `get` command with other tools.

```sh
# Get a command and execute it immediately
eval "$(kilocode memory get <entry_id>)"
```

### 4.2. Scripting and Automation

The Memory Bank can be a powerful tool in your scripts.

```sh
#!/bin/zsh

# A script to run a stored command
COMMAND_ID="12345"
COMMAND=$(kilocode memory get "$COMMAND_ID")

if [[ -n "$COMMAND" ]]; then
  echo "Running command: $COMMAND"
  eval "$COMMAND"
else
  echo "Command with ID $COMMAND_ID not found."
fi
```

## 5. Tag Management

### 5.1. Adding Multiple Tags to an Entry

```sh
kilocode memory tag <entry_id> --add "refactor,optimization"
```

### 5.2. Cleaning Up Old Tags

```sh
kilocode memory tag <entry_id> --remove "obsolete-tag"
```

---
[Previous](./000-index.md) | [Next](./000-index.md) | [Top](./000-index.md)
