# Vendored Files Policy for ZSH Configuration

## Overview

This document establishes a strict policy regarding vendored files in the ZSH configuration. Vendored files are third-party components that we import but do not own or maintain directly.

## Vendored Files and Directories

The following are considered vendored and MUST NOT be modified directly:

1. **zsh-quickstart-kit/** - The entire quickstart kit directory and all its contents
   - `zsh-quickstart-kit/zsh/.zshrc` - The main ZSH configuration file
   - `zsh-quickstart-kit/zsh/.zshrc.d/` - Configuration fragments included in the kit
   - Any other files within the quickstart kit directory

2. **Plugin Managers and Their Components**
   - `.zgenom/` or `zgenom/` - The zgenom plugin manager
   - `.zqs-zgenom/` - Quickstart-specific zgenom files

3. **Plugin Directories**
   - Any directories or files installed by zgenom in `${ZDOTDIR:-$HOME}/.zgenom/`
   - Any plugin code loaded from external repositories

## The Golden Rule

**DO NOT MODIFY VENDORED FILES DIRECTLY**

Instead:
1. Use the extension mechanism provided by zsh-quickstart-kit
2. Follow the symlink principle for the main `.zshrc` file
3. Keep all customizations in the appropriate extension directories

## Proper Extension Mechanism

The correct way to customize your ZSH environment is through:

1. **Pre-Plugin Extensions**: `~/.zshrc.pre-plugins.d/`
   - For code that runs before plugins are loaded
   - Useful for setting environment variables that affect plugin behavior

2. **Post-Plugin Extensions**: `~/.zshrc.d/`
   - For code that runs after plugins are loaded
   - The primary place for your customizations

3. **OS-Specific Extensions**:
   - `~/.zshrc.pre-plugins.$(uname).d/` - OS-specific pre-plugin code
   - `~/.zshrc.$(uname).d/` - OS-specific post-plugin code

4. **Work-Specific Extensions**: `~/.zshrc.work.d/`
   - For work-specific customizations

## Symlink Management

- The main `.zshrc` file should be a symlink to `zsh-quickstart-kit/zsh/.zshrc`
- Never replace this symlink with a modified copy
- The quickstart kit tests this symlink to provide proper updates

## How to Make Changes

If you need functionality that would normally require modifying a vendored file:

1. **Create an Extension File**
   - Place your customizations in the appropriate extension directory
   - Use a descriptive filename with a numerical prefix to control load order
   - Example: `~/.zshrc.d/800-custom-feature.zsh`

2. **Override Functions**
   - If you need to modify existing functions, create a new function that calls the original
   - Example:
     ```zsh
     # Store original function
     functions -c original_func my_original_func
     
     # Override with your version
     function original_func() {
       # Your code here
       my_original_func "$@"  # Call original if needed
     }
     ```

3. **Add Plugins**
   - To add plugins beyond the standard list, create files in `~/.zshrc.add-plugins.d/`
   - Each file should contain `zgenom load githubuser/pluginrepo` entries (one per line)
   - For complete plugin list replacement, create `~/.zsh-quickstart-local-plugins`

4. **Remove Unwanted Features**
   - Create a file like `~/.zshrc.d/999-reset-aliases.zsh` to remove unwanted aliases/functions
   - Use commands like `unalias xyzzy` or `unset -f abcd` to remove what you don't want

## Why This Policy Exists

1. **Updates**: Allows seamless updates to zsh-quickstart-kit without conflicts
2. **Maintenance**: Eliminates the need to maintain a separate fork 
3. **Compatibility**: Ensures compatibility with future updates
4. **Organization**: Keeps your customizations separate and maintainable

## Configuration Commands

The zsh-quickstart-kit provides the `zqs` command for configuring various behaviors:

- `zqs enable-omz-plugins` / `zqs disable-omz-plugins` - Toggle Oh-My-Zsh plugins
- `zqs enable-zmv-autoloading` / `zqs disable-zmv-autoloading` - Toggle zmv autoloading
- Many other toggles for various features

See the documentation or run `zqs help` for a complete list of options.

## Enforcement

- Pull requests that modify vendored files will not be accepted
- Regular audits will be performed to ensure compliance
- If modifications to vendored files are absolutely necessary, they should be submitted upstream to the original project