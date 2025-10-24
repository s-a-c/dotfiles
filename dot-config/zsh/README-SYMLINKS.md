# ZSH Symlinks - Important Notice

## Critical Rule: Do Not Break Symlinks

The main `.zshrc` file is a symlink that points to the vendored file in the zsh-quickstart-kit:

```
.zshrc -> zsh-quickstart-kit/zsh/.zshrc
```

## ⚠️ WARNING ⚠️

**DO NOT MODIFY, REPLACE, OR BREAK THIS SYMLINK**

Breaking this symlink will:
1. Prevent you from getting upstream updates
2. Break the kit's ability to manage and update itself
3. Create conflicts when updating the zsh-quickstart-kit

## How to Check if the Symlink is Intact

```bash
ls -la ~/.config/zsh/.zshrc
```

You should see output similar to:
```
lrwxr-xr-x  1 username  staff  29 Oct 23 23:22 .zshrc -> zsh-quickstart-kit/zsh/.zshrc
```

## If the Symlink is Broken

If you've accidentally replaced the symlink with a regular file, here's how to fix it:

1. Backup your current .zshrc:
   ```bash
   mv ~/.config/zsh/.zshrc ~/.config/zsh/.zshrc.backup-$(date +%Y%m%d%H%M%S)
   ```

2. Recreate the symlink:
   ```bash
   ln -s zsh-quickstart-kit/zsh/.zshrc ~/.config/zsh/.zshrc
   ```

3. Migrate any customizations from your backup to the appropriate extension directories:
   - `.zshrc.pre-plugins.d/` - For code that runs before plugins
   - `.zshrc.d/` - For code that runs after plugins

## Remember

The correct way to customize your ZSH configuration is to add files to the extension directories, not by modifying the vendored .zshrc file directly.

See [VENDORED.md](./VENDORED.md) for complete details on the vendored files policy.