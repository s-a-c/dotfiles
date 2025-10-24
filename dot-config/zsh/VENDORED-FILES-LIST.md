# Vendored Files List

This document provides a definitive list of files and directories in the ZSH configuration that are considered "vendored" and **MUST NOT BE MODIFIED DIRECTLY**.

## Core Vendored Directories

| Directory | Description | Modification Policy |
|-----------|-------------|---------------------|
| `zsh-quickstart-kit/` | The entire quickstart kit directory | **DO NOT MODIFY** |
| `.zgenom/` or `zgenom/` | Plugin manager code | **DO NOT MODIFY** |
| `.zqs-zgenom/` | Quickstart-specific zgenom files | **DO NOT MODIFY** |
| Plugin directories in `${ZDOTDIR:-$HOME}/.zgenom/` | Any directories installed by zgenom | **DO NOT MODIFY** |

## Specific Vendored Files

| File | Description | Modification Policy |
|------|-------------|---------------------|
| `.zshrc` | Main ZSH configuration file | **MUST REMAIN A SYMLINK** to `zsh-quickstart-kit/zsh/.zshrc` |
| `zsh-quickstart-kit/zsh/.zshrc` | Original ZSH configuration | **DO NOT MODIFY** |
| `zsh-quickstart-kit/zsh/.zshrc.d/*` | Kit-provided configuration fragments | **DO NOT MODIFY** |
| `.zsh_aliases` (if symlinked from kit) | Aliases from the kit | **DO NOT MODIFY** |
| `.zgen-setup` (if symlinked from kit) | Zgenom setup from the kit | **DO NOT MODIFY** |
| `.zsh-functions` (if symlinked from kit) | Functions from the kit | **DO NOT MODIFY** |

## How to Customize Instead

Instead of modifying vendored files, use these extension mechanisms:

1. **Pre-Plugin Extensions**: `~/.zshrc.pre-plugins.d/`
2. **Post-Plugin Extensions**: `~/.zshrc.d/`
3. **OS-Specific Extensions**:
   - `~/.zshrc.pre-plugins.$(uname).d/`
   - `~/.zshrc.$(uname).d/`
4. **Work-Specific Extensions**: `~/.zshrc.work.d/`

## Plugin Customization

To add plugins beyond the standard list:
- Create files in `.zshrc.add-plugins.d/`
- For complete replacement: Create `~/.zsh-quickstart-local-plugins`

## Verification Command

To verify your .zshrc is properly symlinked:

```bash
ls -la ~/.config/zsh/.zshrc
```

Expected output should show it points to the kit's .zshrc:
```
lrwxr-xr-x 1 username staff 29 Oct 23 23:22 .zshrc -> zsh-quickstart-kit/zsh/.zshrc
```

## Rationale

This policy exists to:
1. Enable seamless updates to the kit
2. Eliminate the need to maintain a separate fork
3. Ensure compatibility with future updates
4. Keep customizations organized and maintainable

For complete policy details, see [VENDORED.md](./VENDORED.md).