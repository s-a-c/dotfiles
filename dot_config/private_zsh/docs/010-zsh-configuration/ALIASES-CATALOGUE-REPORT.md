# Aliases Catalogue Report

## Summary

I have comprehensively searched through your dotfiles repository and catalogued all aliases defined outside of your active zsh startup configuration. All aliases have been organized and commented out in `.config/zsh/.zshrc.d/900-catalogued-aliases.zsh` for your review and selective activation.

## Active vs Inactive Configuration Files

### Active ZSH Configuration (Currently Loaded)
- `.config/zsh/.zshrc.d/00-aliases.zsh` - Primary aliases file
- `.config/zsh/.zsh_aliases` - ZQS (Zsh Quickstart Kit) aliases

### Inactive Sources Catalogued
1. **Bash Configuration**: `dot-config/bash/dot-bashrc`
2. **Kitty Terminal**: `dot-config/kitty/kitty-control/ttys3/README.md`
3. **Nushell Configs**: `dot-config/nushell/config_aerospace.nu`, `config_zoxide.nu`
4. **Context Configs**: `dot-config/zsh/.context-configs/` (auto-loaded by context)
5. **Backup Archives**: Various `.backup/` and `.ARCHIVE/` directories
6. **Legacy Configs**: Historical zsh configurations
7. **Fish Config**: `dot-config/fish/config.fish` (Fish-specific syntax)

## Categories of Aliases Found

### 1. Bash-Specific Aliases
**File**: `dot-config/bash/dot-bashrc`
- `nvim=nvimvenv` - Neovim virtual environment wrapper
- **Status**: Not loaded in zsh, requires manual activation
- **Dependencies**: Neovim, Python virtual environments

### 2. Kitty Terminal Integration
**File**: `dot-config/kitty/kitty-control/ttys3/README.md`
- `icat="kitten icat"` - Image preview
- `s="kitten ssh"` - Enhanced SSH
- `d="kitten diff"` - Enhanced diff
- **Status**: Not loaded, requires Kitty terminal
- **Dependencies**: Kitty terminal with kittens enabled

### 3. Nushell-Specific Aliases
**Files**: `dot-config/nushell/config_aerospace.nu`, `config_zoxide.nu`
- `as="aerospace"` - Window manager alias
- `ff` - Interactive window selection function
- `z`, `zi` - Zoxide navigation (already available in zsh)
- **Status**: Nushell syntax, not directly usable in zsh
- **Dependencies**: Nushell, Aerospace window manager, Zoxide

### 4. Context-Aware Aliases
**Files**: `dot-config/zsh/.context-configs/`
- Node.js package manager aliases (`ni`, `nid`, `nr`, etc.)
- Development server aliases (`dev`, `serve`)
- **Status**: Automatically loaded when entering appropriate directories
- **Dependencies**: Node.js ecosystem tools

### 5. Legacy/Backup Aliases
**Source**: Various archived configurations
- Enhanced `ls` aliases with `eza`
- Extended Git aliases
- System monitoring aliases
- File operation safety aliases
- **Status**: Preserved for reference, not actively loaded
- **Dependencies**: Various (eza, htop, etc.)

### 6. Suffix Aliases (Zsh-Specific)
**Source**: Legacy configurations
- File extension-based opening (`-s txt='$EDITOR'`, etc.)
- **Status**: Zsh feature, requires manual activation
- **Dependencies**: `$EDITOR` variable set

## Software Requirements for Activation

### Already Available (No Installation Needed)
- Basic Unix commands (cd, ls, grep, etc.)
- Git (most aliases)
- Zsh built-in features

### Common Development Tools
```bash
# Install with Homebrew
brew install node      # Node.js ecosystem
brew install yarn      # Package manager
brew install pnpm      # Package manager
brew install docker    # Containerization
brew install kubectl   # Kubernetes
```

### Enhanced System Tools
```bash
# Modern alternatives
brew install eza       # Enhanced ls replacement
brew install htop      # Process monitor
brew install tree      # Directory tree visualization
```

### Specialized Tools
```bash
# Window management (macOS)
brew install aerospace  # Window manager

# Terminal
# Download from: https://sw.kovidgoyal.net/kitty/
```

## Recommendations for Activation

### High Priority
1. **Enhanced ls aliases** - If you prefer `eza` over standard `ls`
2. **Extended Git aliases** - Additional Git workflow shortcuts
3. **Development server aliases** - If you work with Node.js

### Medium Priority
1. **Safety aliases** - Interactive file operations (`cp -i`, `mv -i`, etc.)
2. **System monitoring aliases** - Enhanced process and system info
3. **Suffix aliases** - Convenient file opening by extension

### Low Priority / Conditional
1. **Kitty integration** - Only if you use Kitty terminal
2. **Aerospace aliases** - Only if you use this window manager
3. **Legacy aliases** - Review for potential duplicates with active config

## Potential Conflicts to Review

### Duplicates with Active Configuration
- Several aliases in catalog duplicates exist in `00-aliases.zsh`
- Git aliases may overlap or extend current set
- Navigation aliases might conflict with existing shortcuts

### Alias Override Behavior
- The catalog file uses prefix `900` to load last
- Uncommented aliases will override earlier definitions
- Test in isolation before bulk activation

## Activation Strategy

### Step 1: Review Current Active Aliases
```bash
# See what's currently active
alias | grep -E "^(ls|git|npm|cd)"
```

### Step 2: Test Individual Aliases
```bash
# Temporarily source specific sections
source <(sed -n '70,90p' ~/.zshrc.d/900-catalogued-aliases.zsh)
```

### Step 3: Incremental Activation
1. Start with non-conflicting aliases
2. Test Git workflow aliases
3. Activate system aliases
4. Add tool-specific aliases last

### Step 4: Validation
```bash
# Test key functionality
which ls
git status --help
npm --version
```

## Maintenance Notes

### File Organization
- Catalog file loads last (900 prefix) for override capability
- Commented structure allows selective activation
- Categories grouped by source and functionality

### Future Updates
- Add new discoveries to appropriate sections
- Update dependency requirements as tools evolve
- Remove duplicates as they're integrated into active config

### Backup Strategy
- Original aliases preserved in backup directories
- Current active config remains unchanged
- Safe to experiment without affecting existing setup

## Next Actions

1. **Review** the catalog file at `.zshrc.d/900-catalogued-aliases.zsh`
2. **Install** any required dependencies for desired aliases
3. **Test** individual aliases before bulk activation
4. **Uncomment** desired aliases in the catalog file
5. **Reload** zsh configuration: `source ~/.zshrc`
6. **Validate** that aliases work as expected

This catalog provides a comprehensive reference of all available aliases while maintaining the integrity of your active zsh configuration.
