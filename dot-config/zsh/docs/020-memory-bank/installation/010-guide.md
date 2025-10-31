# Kilocode Memory Bank Installation Guide

<details>
<summary>Table of Contents</summary>

- [1. Introduction](#1-introduction)
- [2. Prerequisites](#2-prerequisites)
- [3. Installation on macOS (with Homebrew)](#3-installation-on-macos-with-homebrew)
- [4. Installation on Linux](#4-installation-on-linux)
- [5. Manual Installation](#5-manual-installation)
- [6. Verification](#6-verification)

</details>

## 1. Introduction

This guide provides step-by-step instructions for installing the Kilocode Memory Bank on your system.

## 2. Prerequisites

Before you begin, ensure you have the following installed:

- **Zsh**: The primary requirement for running the Memory Bank.
- **Git**: Required for version control features.
- **Homebrew** (macOS): Recommended for easy installation of dependencies.

## 3. Installation on macOS (with Homebrew)

1.  **Install Dependencies**:

    ```sh
    brew install zsh git bats-core
    ```

2.  **Clone the Repository**:

    ```sh
    git clone <repository_url> ~/.config/kilocode/020-memory-bank
    ```

3.  **Source the Initialization Script**:

    Add the following line to your `.zshrc` file to load the Memory Bank on startup:

    ```sh
    source ~/.config/kilocode/020-memory-bank/init.zsh
    ```

## 4. Installation on Linux

1.  **Install Dependencies** (using `apt` on Debian/Ubuntu):

    ```sh
    sudo apt-get update
    sudo apt-get install zsh git bats
    ```

2.  **Clone the Repository**:

    ```sh
    git clone <repository_url> ~/.config/kilocode/020-memory-bank
    ```

3.  **Source the Initialization Script**:

    Add the following line to your `.zshrc`:

    ```sh
    source ~/.config/kilocode/020-memory-bank/init.zsh
    ```

## 5. Manual Installation

If you prefer not to use a package manager, you can install the dependencies manually from their official sources. Once the dependencies are in place, follow the steps for cloning the repository and sourcing the `init.zsh` script as described above.

## 6. Verification

After installation, open a new terminal session and run the following command to verify that the Memory Bank is working correctly:

```sh
kilocode memory --version
```

This should display the current version of the Kilocode Memory Bank.

---
[Previous](./000-index.md) | [Next](./000-index.md) | [Top](./000-index.md)
