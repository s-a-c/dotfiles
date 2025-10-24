# ZSH Configuration

This directory contains the ZSH configuration files for dotfiles management.

## ⚠️ IMPORTANT: Vendored Files Policy ⚠️

**DO NOT MODIFY VENDORED FILES DIRECTLY**

The following are considered vendored and must not be modified:
- **zsh-quickstart-kit/** - The entire directory and all contents
- **`.zshrc`** - Must remain a symlink to `zsh-quickstart-kit/zsh/.zshrc`
- **Plugin directories** - Any directories installed by zgenom

See [VENDORED.md](./VENDORED.md) for the complete policy and [CONTRIBUTING.md](./CONTRIBUTING.md) for general contribution guidelines.

## Directory Structure

- `.zshrc` → Symlink to `zsh-quickstart-kit/zsh/.zshrc`
- `.zshrc.pre-plugins.d/` - Files loaded before plugins
- `.zshrc.d/` - Files loaded after plugins
- `zsh-quickstart-kit/` - Vendored quickstart kit (DO NOT MODIFY)

## Adding Customizations

Instead of modifying `.zshrc` directly:

1. For functionality that needs to run **before** plugins:
   - Add files to `.zshrc.pre-plugins.d/`
   - Use numerical prefixes for load order (e.g., `090-my-feature.zsh`)

2. For functionality that should run **after** plugins:
   - Add files to `.zshrc.d/`
   - Use numerical prefixes for load order (e.g., `800-my-feature.zsh`)

3. For OS-specific customizations:
   - `.zshrc.pre-plugins.$(uname).d/` - OS-specific pre-plugin code
   - `.zshrc.$(uname).d/` - OS-specific post-plugin code

4. For work-specific customizations:
   - `.zshrc.work.d/` - Work-specific settings

## Adding Plugins

To add plugins beyond the standard list:
- Create files in `.zshrc.add-plugins.d/`
- Each file should contain `zgenom load githubuser/pluginrepo` entries

For complete plugin list replacement:
- Create `~/.zsh-quickstart-local-plugins` (see examples in the kit)

## Configuration

Use the `zqs` command to configure kit behavior:
```zsh
# Get help on available commands
zqs help

# Examples:
zqs disable-omz-plugins    # Disable Oh-My-Zsh plugins
zqs enable-omz-plugins     # Enable Oh-My-Zsh plugins
zqs selfupdate             # Update the quickstart kit immediately
```

## Installation

This directory is designed to be deployed with GNU Stow:

```bash
# From ~/dotfiles
stow -t $HOME/.config dot-config
```

This will create symlinks from `~/.config/zsh` to `~/dotfiles/dot-config/zsh`.