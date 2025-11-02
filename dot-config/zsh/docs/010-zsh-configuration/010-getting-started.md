# Getting Started with ZSH Configuration

**Quick Start Guide** | **Est. Time: 15-30 minutes**

---

## 📋 Table of Contents

<details>
<summary>Expand Table of Contents</summary>

- [1. ✅ Prerequisites](#1-prerequisites)
  - [1.1. Required](#11-required)
  - [1.2. Recommended](#12-recommended)
- [2. Understanding the Basics](#2-understanding-the-basics)
  - [2.1. What is This Configuration?](#21-what-is-this-configuration)
  - [2.2. Key Concepts](#22-key-concepts)
- [3. Your First Shell Session](#3-your-first-shell-session)
  - [1. Open a New Terminal](#1-open-a-new-terminal)
  - [2. Test Basic Commands](#2-test-basic-commands)
  - [3. Check System Health](#3-check-system-health)
- [4. Basic Customization](#4-basic-customization)
  - [4.1. Creating Your User-Local File](#41-creating-your-user-local-file)
  - [4.2. Example Customizations](#42-example-customizations)
  - [4.3. Testing Your Changes](#43-testing-your-changes)
- [5. Common Tasks](#5-common-tasks)
  - [5.1. Task 1: Add a New Plugin](#51-task-1-add-a-new-plugin)
  - [5.2. Task 2: Customize Terminal Integration](#52-task-2-customize-terminal-integration)
  - [5.3. Task 3: Add Development Tools](#53-task-3-add-development-tools)
  - [5.4. Task 4: Performance Tuning](#54-task-4-performance-tuning)
  - [5.5. Task 5: Disable Features](#55-task-5-disable-features)
- [6. ➡️ Next Steps](#6-next-steps)
  - [6.1. For Regular Users](#61-for-regular-users)
  - [6.2. For Developers](#62-for-developers)
  - [6.3. For Advanced Users](#63-for-advanced-users)
- [7. Troubleshooting](#7-troubleshooting)
  - [7.1. Common Issues](#71-common-issues)
  - [7.2. Getting More Help](#72-getting-more-help)
- [8. Pro Tips](#8-pro-tips)
  - [1. **Use Versioned Backups**](#1-use-versioned-backups)
  - [2. **Quick Reload**](#2-quick-reload)
  - [3. **Terminal-Specific Configs**](#3-terminal-specific-configs)
  - [4. **Disable Features Temporarily**](#4-disable-features-temporarily)
- [9. Learning Resources](#9-learning-resources)
  - [9.1. Internal Documentation](#91-internal-documentation)
  - [9.2. External Resources](#92-external-resources)
- [10. ✅ Quick Checklist](#10-quick-checklist)

</details>

---

## 1. ✅ Prerequisites

### 1.1. Required

- ✅ **ZSH Shell**: Version 5.0 or higher

```bash
  # Check your version
  zsh --version

```

- ✅ **macOS or Linux**: Primary support for macOS, compatible with Linux

### 1.2. Recommended

- 💡 **Homebrew** (macOS): Package manager

```bash
  # Install if needed
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

```

- 💡 **Git**: For version control and plugin management

```bash
  # Check if installed
  git --version

```

---

## 2. 🎯 Understanding the Basics

### 2.1. What is This Configuration?

This is a **sophisticated ZSH configuration system** that provides:

- 🏗️ **Modular Architecture**: Organized in six distinct loading phases
- 🔒 **Security Features**: Built-in safety mechanisms and integrity checks
- ⚡ **Performance Monitoring**: Real-time startup time tracking
- 🔗 **Plugin Management**: 40+ plugins managed by zgenom
- 🎨 **Modern Prompt**: Beautiful Starship prompt with customization
- 🔄 **Version Control**: Symlink-based configuration versioning

### 2.2. Key Concepts

#### 1. **Versioned Symlink System**

```text
.zshrc.d → .zshrc.d.live → .zshrc.d.01
   ↑            ↑              ↑
  You use    Current       Actual files
             version       (edit here!)

```

> ⚠️ **Important**: Always edit files in the numbered directories (.zshrc.d.01), never the symlinks!

#### 2. **Six Configuration Phases**

```text
Phase 1: Environment Setup (.zshenv)
         ↓
Phase 2: Shell Entry (.zshrc)
         ↓
Phase 3: Pre-Plugin Config
         ↓
Phase 4: Plugin Loading (zgenom)
         ↓
Phase 5: Post-Plugin Setup
         ↓
Phase 6: Platform-Specific & User Overrides

```

#### 3. **File Classification**

| Type | Can Edit? | Examples |
|------|-----------|----------|
| **User Local** | ⚠️ Explicit approval required | `.zshrc.local`, `.zshenv.local` |
| **Vendored** | ❌ Never edit | `.zshrc`, `.zgen-setup` |
| **Versioned** | ✅ Edit numbered version only | `.zshrc.d.01/*` |

---

## 3. 🚀 Your First Shell Session

### 1. Open a New Terminal

When you first open a terminal with this configuration:

```text
🎨 [Colorful splash screen appears]
⏱️  Shell loads in ~1.8 seconds
✨ Starship prompt ready

```

### 2. Test Basic Commands

```bash

# Navigate directories

cd ~                    # Home directory
pwd                     # Print working directory

# List files with modern tools

ls -la                  # Traditional list
eza -la                 # Modern alternative (if installed)

# Search with FZF (fuzzy finder)

Ctrl+R                  # Search history
Ctrl+T                  # Search files

# View configuration

echo $ZDOTDIR           # Configuration directory
echo $ZSH_VERSION       # ZSH version

```

### 3. Check System Health

```bash

# Run built-in health check

zsh-healthcheck

# View performance metrics

zsh-performance-baseline

# Check loaded plugins

zgenom list

```

---

## 4. 🎨 Basic Customization

### 4.1. Creating Your User-Local File

The safest way to customize is using `.zshrc.local`:

```bash

# Create user-local file (requires explicit approval for edits)

touch ~/.zshrc.local

# Edit with your preferred editor

nano ~/.zshrc.local   # or vim, code, etc.

```

### 4.2. Example Customizations

#### 1. **Add Personal Aliases**

```bash

# In ~/.zshrc.local

alias myproject='cd ~/projects/my-awesome-project'
alias gs='git status'
alias gp='git pull'

```

#### 2. **Set Environment Variables**

```bash

# In ~/.zshrc.local

export EDITOR=nvim
export VISUAL=nvim
export MY_API_KEY="your-key-here"  # For local development only!

```

#### 3. **Customize Prompt**

```bash

# In ~/.zshrc.local
# Starship is default, but you can configure it

export STARSHIP_CONFIG=~/.config/starship-custom.toml

```

#### 4. **Add Functions**

```bash

# In ~/.zshrc.local

function mkcd() {
    mkdir -p "$1" && cd "$1"
}

function backup() {
    cp "$1" "$1.backup.$(date +%Y%m%d-%H%M%S)"
}

```

### 4.3. Testing Your Changes

```bash

# Reload configuration

source ~/.zshrc

# Or open a new terminal to test fresh load


```

---

## 5. 📚 Common Tasks

### 5.1. Task 1: Add a New Plugin

1. Navigate to plugin directory:

```bash
   cd ~/.config/zsh/.zshrc.add-plugins.d.00

```

2. Create or edit a plugin file:

```bash
   vim 320-my-plugins.zsh

```

3. Add plugin declaration:

```bash
   # 320-my-plugins.zsh
   if (( $+functions[zgenom] )); then
       zgenom load zsh-users/zsh-syntax-highlighting
   fi

```

4. Reload and regenerate cache:

```bash
   zgenom reset
   source ~/.zshrc

```

### 5.2. Task 2: Customize Terminal Integration

```bash

# Edit terminal-specific settings

vim ~/.config/zsh/.zshrc.d.01/420-terminal-integration.zsh

```

### 5.3. Task 3: Add Development Tools

```bash

# For Node.js projects

vim ~/.config/zsh/.zshrc.d.01/450-node-environment.zsh

# For custom developer tools

vim ~/.config/zsh/.zshrc.d.01/510-developer-tools.zsh

```

### 5.4. Task 4: Performance Tuning

```bash

# View current performance

zsh-performance-baseline

# Enable performance logging

export PERF_SEGMENT_LOG=~/zsh-perf.log
export PERF_SEGMENT_TRACE=1

# Reload and check log

source ~/.zshrc
cat ~/zsh-perf.log

```

### 5.5. Task 5: Disable Features

```bash

# In ~/.zshenv.local (for early env variables)

export ZSH_DISABLE_SPLASH=1          # Disable splash screen
export ZSH_DISABLE_FASTFETCH=1       # Disable fastfetch
export ZSH_DISABLE_STARSHIP=0        # Keep Starship (default)
export ZSH_ENABLE_ABBR=1             # Enable abbreviations (default)

```

---

## 6. ➡️ Next Steps

### 6.1. For Regular Users

1. **Explore Features**
   - Try FZF with `Ctrl+R` (history) and `Ctrl+T` (files)
   - Use `Ctrl+G` for FZF git integration
   - Test abbreviations (if enabled)

2. **Customize Your Prompt**
   - Check Starship configuration: `~/.config/starship.toml`
   - See [Starship Documentation](https://starship.rs/)

3. **Learn Keybindings**
   - View: `~/.config/zsh/.zshrc.d.01/490-keybindings.zsh`

### 6.2. For Developers

1. **Read Architecture**
   - [Architecture Overview](020-architecture-overview.md)
   - [Startup Sequence](030-startup-sequence.md)
   - [Configuration Phases](040-configuration-phases.md)

2. **Study Structure**
   - [File Organization](070-file-organization.md)
   - [Naming Conventions](080-naming-conventions.md)

3. **Contribute**
   - [Development Guide](090-development-guide.md)
   - [Testing Guide](100-testing-guide.md)

### 6.3. For Advanced Users

1. **Master Versioning**
   - [Versioned Symlinks](050-versioned-symlinks.md)

2. **Optimize Performance**
   - [Performance Guide](110-performance-guide.md)

3. **Secure Your Setup**
   - [Security Guide](120-security-guide.md)

---

## 7. 🔧 Troubleshooting

### 7.1. Common Issues

#### Issue: Shell Loads Slowly

```bash

# Check performance

zsh-performance-baseline

# Enable detailed logging

export PERF_SEGMENT_LOG=~/perf.log
export PERF_SEGMENT_TRACE=1
source ~/.zshrc

# Review log

cat ~/perf.log | grep -E "start|end"

```

**Solution**: See [Performance Guide](110-performance-guide.md) for optimization tips.

#### Issue: Plugin Not Loading

```bash

# Verify plugin is declared

cat ~/.config/zsh/.zshrc.add-plugins.d.00/*.zsh | grep "zgenom load"

# Reset zgenom cache

zgenom reset

# Reload

source ~/.zshrc

# Check if plugin loaded

zgenom list

```

**Solution**: See [Plugin System](060-plugin-system.md) for details.

#### Issue: Command Not Found

```bash

# Check PATH

echo $PATH | tr ':' '\n'

# Verify command location

which command-name

# Check if in Homebrew

brew list | grep command-name

```

**Solution**: Add path in `.zshenv.local` or `.zshrc.local`

#### Issue: Variable Not Set Errors

```bash

# These are nounset-related errors
# Check safety system

cat ~/.config/zsh/.zshrc.pre-plugins.d.01/010-shell-safety.zsh

```

**Solution**: See [Security Guide](120-security-guide.md) for nounset safety system.

### 7.2. Getting More Help

1. **Check Comprehensive Troubleshooting**
   - [Troubleshooting Guide](130-troubleshooting.md)

2. **Review Diagnostics**

```bash
   zsh-healthcheck

```

3. **Check Logs**

```bash
   # Recent logs
   ls -lt ~/Library/Logs/zsh/

   # Or check custom log location
   echo $ZSH_LOG_DIR

```

---

## 8. 💡 Pro Tips

### 1. **Use Versioned Backups**

```bash

# Before major changes, current config is already versioned!
# To rollback:

cd ~/.config/zsh
ls -la .zshrc.d.*  # See available versions

# Repoint .zshrc.d.live to different version if needed


```

### 2. **Quick Reload**

```bash

# Add to your .zshrc.local

alias reload='source ~/.zshrc'
alias zedit='vim ~/.zshrc.local'

```

### 3. **Terminal-Specific Configs**

```bash

# Check which terminal you're using

echo $TERM_PROGRAM

# Terminal detection happens automatically
# See: ~/.config/zsh/.zshenv.01 (lines ~174-197)


```

### 4. **Disable Features Temporarily**

```bash

# Single session

ZSH_DISABLE_SPLASH=1 zsh

# Or export before starting

export ZSH_MINIMAL=1
zsh

```

---

## 9. 🎓 Learning Resources

### 9.1. Internal Documentation

- [Architecture Overview](020-architecture-overview.md) - System design
- [Visual Diagrams](150-diagrams/000-index.md) - Architecture visualizations
- [Reference](140-reference/000-index.md) - Quick lookup guides

### 9.2. External Resources

- [ZSH Documentation](https://zsh.sourceforge.io/Doc/)
- [zgenom Plugin Manager](https://github.com/jandamm/zgenom)
- [Starship Prompt](https://starship.rs/)
- [FZF Fuzzy Finder](https://github.com/junegunn/fzf)

---

## 10. ✅ Quick Checklist

After setup, verify:

- [ ] Shell loads without errors
- [ ] Starship prompt appears
- [ ] `zgenom list` shows plugins
- [ ] `Ctrl+R` opens FZF history search
- [ ] `zsh-healthcheck` runs successfully
- [ ] `.zshrc.local` created for personal customizations
- [ ] Performance is acceptable (`zsh-performance-baseline`)

---

**Navigation:** [← Index](000-index.md) | [Top ↑](#getting-started) | [Architecture →](020-architecture-overview.md)

---

*Compliant with AI-GUIDELINES.md (v1.0 2025-10-30)*
