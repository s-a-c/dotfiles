# Kilocode Memory Bank Developer Guide

<details>
<summary>Table of Contents</summary>

- [1. Introduction](#1-introduction)
- [2. Environment Setup](#2-environment-setup)
  - [2.1. Prerequisites](#21-prerequisites)
  - [2.2. Installation](#22-installation)
- [3. Running Tests](#3-running-tests)
  - [3.1. Running All Tests](#31-running-all-tests)
  - [3.2. Running a Specific Test File](#32-running-a-specific-test-file)
- [4. Contribution Guidelines](#4-contribution-guidelines)
  - [4.1. Code Style](#41-code-style)
  - [4.2. Git Workflow](#42-git-workflow)
  - [4.3. Documentation](#43-documentation)
- [5. Project Structure](#5-project-structure)

</details>

## 1. Introduction

This guide is for developers who want to contribute to the Kilocode Memory Bank project. It provides instructions for setting up a local development environment, running tests, and following our contribution guidelines.

## 2. Environment Setup

### 2.1. Prerequisites

- **Zsh**: The Memory Bank is a Zsh-based tool and requires Zsh to be installed.
- **Git**: For version control and contribution.
- **Bats**: Our testing framework for Zsh scripts.

### 2.2. Installation

1.  **Clone the repository**:

    ```sh
    git clone <repository_url>
    cd kilocode-020-memory-bank
    ```

2.  **Install dependencies**:

    Follow the instructions in the main [Installation Guide](../installation/010-guide.md) to set up the required dependencies.

3.  **Set up for local development**:

    Ensure your local configuration is sourced correctly. Refer to the project's main `.zshrc` for guidance on how local development scripts are loaded.

## 3. Running Tests

We use `bats-core` for testing. All tests are located in the `tests/` directory.

### 3.1. Running All Tests

To run the entire test suite, execute the following command from the project root:

```sh
bats tests/
```

### 3.2. Running a Specific Test File

To run a specific test file, provide the path to that file:

```sh
bats tests/commands/add.bats
```

## 4. Contribution Guidelines

### 4.1. Code Style

-   Follow the existing code style and conventions.
-   Use `shellcheck` to lint your shell scripts.
-   Ensure all new features are accompanied by corresponding tests.

### 4.2. Git Workflow

1.  **Create a new branch** for your feature or bug fix:

    ```sh
    git checkout -b feature/my-new-feature
    ```

2.  **Commit your changes** with a descriptive commit message:

    ```sh
    git commit -m "feat: Add new feature"
    ```

3.  **Push your branch** and open a pull request.

### 4.3. Documentation

-   All new features must be documented.
-   Update the relevant sections of the documentation, including the [API Reference](../api/010-specifications.md) and [User Guide](../user-guide/010-getting-started.md).

## 5. Project Structure

-   `bin/`: Main executable scripts.
-   `lib/`: Core logic and helper functions.
-   `tests/`: Test files.
-   `docs/`: Documentation.

---
[Previous](./000-index.md) | [Next](./000-index.md) | [Top](./000-index.md)
