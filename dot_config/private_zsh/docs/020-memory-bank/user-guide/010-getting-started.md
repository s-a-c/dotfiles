# Kilocode Memory Bank User Guide

<details>
<summary>Table of Contents</summary>

- [1. Introduction](#1-introduction)
- [2. Getting Started: Your First Entry](#2-getting-started-your-first-entry)
- [3. Searching for Entries](#3-searching-for-entries)
  - [3.1. Basic Search](#31-basic-search)
  - [3.2. Searching with Tags](#32-searching-with-tags)
- [4. Managing Entries](#4-managing-entries)
  - [4.1. Listing All Entries](#41-listing-all-entries)
  - [4.2. Retrieving a Specific Entry](#42-retrieving-a-specific-entry)
  - [4.3. Updating an Entry](#43-updating-an-entry)
  - [4.4. Deleting an Entry](#44-deleting-an-entry)
- [5. Organizing with Tags](#5-organizing-with-tags)
  - [5.1. Adding and Removing Tags](#51-adding-and-removing-tags)
- [6. Backing Up and Restoring](#6-backing-up-and-restoring)
  - [6.1. Exporting Your Data](#61-exporting-your-data)
  - [6.2. Importing Data](#62-importing-data)

</details>

## 1. Introduction

Welcome to the Kilocode Memory Bank! This guide will walk you through the essential features and commands to help you get started. Whether you're storing code snippets, project notes, or random ideas, the Memory Bank is designed to be your personal, searchable knowledge base.

## 2. Getting Started: Your First Entry

Adding an entry is the most fundamental operation. Let's add your first memory.

1.  **Open your terminal.**
2.  **Type the `add` command**, followed by the content you want to store.

    ```sh
    kilocode memory add "This is my first memory. #Welcome"
    ```

3.  **Add tags** to make it easier to find later using the `--tags` option.

    ```sh
    kilocode memory add "Store a complex shell command: find . -name '*.js' | xargs grep 'import'" --tags "cli,javascript,search"
    ```

## 3. Searching for Entries

The fuzzy search is designed to find what you're looking for, even if you don't remember the exact wording.

### 3.1. Basic Search

To search for an entry, use the `search` command:

```sh
kilocode memory search "shell command"
```

This will return a list of entries that match your query, ranked by relevance.

### 3.2. Searching with Tags

You can narrow down your search by filtering by tags:

```sh
kilocode memory search "import" --tags "javascript"
```

This will only search for "import" within entries that are tagged with "javascript".

## 4. Managing Entries

### 4.1. Listing All Entries

To see all the entries in your memory bank, use the `list` command:

```sh
kilocode memory list
```

You can also filter the list by tags:

```sh
kilocode memory list --tags "cli"
```

### 4.2. Retrieving a Specific Entry

Every entry has a unique ID. If you know the ID, you can retrieve the entry directly with the `get` command:

```sh
kilocode memory get <entry_id>
```

### 4.3. Updating an Entry

If you need to make changes to an existing entry, use the `update` command:

```sh
kilocode memory update <entry_id> "This is the new, updated content."
```

### 4.4. Deleting an Entry

To remove an entry, use the `delete` command. **Be careful, as this cannot be undone.**

```sh
kilocode memory delete <entry_id>
```

## 5. Organizing with Tags

Tags are a powerful way to categorize and organize your entries.

### 5.1. Adding and Removing Tags

You can manage the tags for a specific entry using the `tag` command:

```sh
# Add a new tag
kilocode memory tag <entry_id> --add "new-tag"

# Remove an existing tag
kilocode memory tag <entry_id> --remove "old-tag"
```

## 6. Backing Up and Restoring

### 6.1. Exporting Your Data

You can export your entire memory bank to a JSON file for backup or sharing:

```sh
kilocode memory export ./my_memory_bank_backup.json
```

### 6.2. Importing Data

To import entries from a file, use the `import` command:

```sh
kilocode memory import ./my_memory_bank_backup.json
```

---
[Previous](./000-index.md) | [Next](./000-index.md) | [Top](./000-index.md)
