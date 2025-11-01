# Troubleshooting Guide

**Common Issues & Solutions** | **Technical Level: All Levels**

---

## 📋 Table of Contents

<details>
<summary>Expand Table of Contents</summary>

- [Troubleshooting Guide](#troubleshooting-guide)
  - [📋 Table of Contents](#-table-of-contents)
  - [1. 🔍 Quick Diagnostics](#1--quick-diagnostics)
    - [1.1. First Steps](#11-first-steps)
    - [1.2. Enable Debug Mode](#12-enable-debug-mode)
  - [2. 🚨 Startup Issues](#2--startup-issues)
    - [2.1. Issue: Shell Won't Start](#21-issue-shell-wont-start)
    - [2.2. Issue: "Command Not Found" on Startup](#22-issue-command-not-found-on-startup)
      - [2.2.1. Special Case: VSCode/Cursor PATH Corruption](#221-special-case-vscodecursor-path-corruption)
    - [2.3. Issue: Slow Startup](#23-issue-slow-startup)
    - [2.4. Issue: Variable Not Set Errors](#24-issue-variable-not-set-errors)
  - [3. 🔌 Plugin Problems](#3--plugin-problems)
    - [3.1. Issue: Plugin Not Loading](#31-issue-plugin-not-loading)
    - [3.2. Issue: Plugin Conflicts](#32-issue-plugin-conflicts)
    - [3.3. Issue: Plugin Slow to Load](#33-issue-plugin-slow-to-load)
  - [4. ⚡ Performance Issues](#4--performance-issues)
  - [5. 🛣️ Path Problems](#5-️-path-problems)
    - [5.1. Issue: Command in PATH Not Found](#51-issue-command-in-path-not-found)
    - [5.2. Issue: Duplicate PATH Entries](#52-issue-duplicate-path-entries)
  - [6. 🎯 Completion Issues](#6--completion-issues)
    - [6.1. Issue: Completions Not Working](#61-issue-completions-not-working)
    - [6.2. Issue: Slow Tab Completion](#62-issue-slow-tab-completion)
  - [7. 💻 Terminal-Specific Issues](#7--terminal-specific-issues)
    - [7.1. Issue: Prompt Doesn't Appear](#71-issue-prompt-doesnt-appear)
    - [7.2. Issue: Colors Not Working](#72-issue-colors-not-working)
    - [7.3. Issue: iTerm2 Integration Not Working](#73-issue-iterm2-integration-not-working)
  - [8. 🆘 Emergency Recovery](#8--emergency-recovery)
    - [8.1. Nuclear Option 1: Minimal Shell](#81-nuclear-option-1-minimal-shell)
    - [8.2. Nuclear Option 2: Rebuild Plugin Cache](#82-nuclear-option-2-rebuild-plugin-cache)
    - [8.3. Nuclear Option 3: Rollback Version](#83-nuclear-option-3-rollback-version)
    - [8.4. Nuclear Option 4: Use Backup](#84-nuclear-option-4-use-backup)
  - [9. 📞 Getting Help](#9--getting-help)
    - [9.1. Information to Gather](#91-information-to-gather)
    - [9.2. Diagnostic Commands](#92-diagnostic-commands)
  - [10. 🔧 Advanced Troubleshooting](#10--advanced-troubleshooting)
    - [10.1. Trace Execution](#101-trace-execution)
    - [10.2. Binary Search for Problem](#102-binary-search-for-problem)
    - [10.3. Verify File Integrity](#103-verify-file-integrity)
  - [11. 💡 Prevention Tips](#11--prevention-tips)
    - [1. Test Before Committing](#1-test-before-committing)
    - [2. Use Version Control](#2-use-version-control)
    - [3. Keep Backups](#3-keep-backups)
    - [4. Monitor Performance](#4-monitor-performance)

</details>

---

## 1. 🔍 Quick Diagnostics

### 1.1. First Steps

```bash

# 1. Run health check

zsh-healthcheck

# 2. Check performance

zsh-performance-baseline

# 3. Verify symlinks

ls -la ~/.config/zsh/ | grep "^l"

# 4. Check plugin status

zgenom list

# 5. Look for errors in clean shell

zsh 2>&1 | grep -i "error\|warn\|fail"

```

### 1.2. Enable Debug Mode

```bash

# Detailed debug output

export ZSH_DEBUG=1
export PERF_SEGMENT_LOG=~/debug.log
export PERF_SEGMENT_TRACE=1

# Start new shell

zsh

# Review logs

cat ~/debug.log

```

---

## 2. 🚨 Startup Issues

### 2.1. Issue: Shell Won't Start

**Symptoms**: Terminal hangs or crashes on open

**Diagnosis**:

```bash

# Try minimal shell

zsh -f

# If that works, config is the problem
# Try loading incrementally

zsh -c "source ~/.zshenv && echo 'zshenv OK'"
zsh -i -c "echo 'zshrc OK'"

```

**Solutions**:

1. Check for syntax errors:

```bash
   zsh -n ~/.config/zsh/.zshenv.01
   zsh -n ~/.config/zsh/.zshrc.d.01/*.zsh

```

2. Rollback to previous version:

```bash
   cd ~/.config/zsh
   ln -snf .zshrc.d.00 .zshrc.d.live  # Or previous working version

```

3. Use emergency recovery (see below)

---

### 2.2. Issue: "Command Not Found" on Startup

**Symptoms**: Errors about missing commands during shell load

**Diagnosis**:

```bash

# Which command is missing?

zsh 2>&1 | grep "command not found"

```

**Solutions**:

1. Install missing command:

```bash
   brew install missing-command

```

2. Make command optional:

```bash
   # In the module causing the error
   if command -v missing-command &>/dev/null; then
       # Use command
   else
       zf::debug "missing-command not found, skipping"
   fi

```

#### 2.2.1. Special Case: VSCode/Cursor PATH Corruption

**Symptoms**: In Cursor or VSCode integrated terminal, basic utilities (`awk`, `sed`, `git`, `find`, `mkdir`) report "command not found" during startup, but work normally after shell initialization completes.

**Root Cause**: **Double PATH corruption** from two sources:

1. **macOS `path_helper`**: Runs in `/etc/zprofile` and reorders PATH
2. **VSCode Shell Integration**: Sourced during `.zshrc` startup, prepends extension directories

Both push system directories (`/usr/bin`, `/bin`) to position 15+, behind Cursor's extension directories (`.console-ninja/.bin`, `.lmstudio/bin`, etc.).

**Execution sequence**:

1. `/etc/zshenv` sets ZDOTDIR
2. `$ZDOTDIR/.zshenv` sets PATH correctly ✅
3. `/etc/zprofile` calls `path_helper` ❌ **← PATH corrupted (first time)**
4. `$ZDOTDIR/.zprofile` re-fixes PATH ✅
5. `$ZDOTDIR/.zshrc` starts
6. VSCode shell integration sourced ❌ **← PATH corrupted (second time)**
7. `420-terminal-integration.zsh` re-fixes PATH ✅

**Solution**: PATH is set in THREE places to handle both corruptions:

1. **`.zshenv.01`** (line 26) - for non-login shells and scripts:

```zsh
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH}"
```

2. **`$ZDOTDIR/.zprofile`** (line 16) - for login shells, runs AFTER `path_helper`:

```zsh
# Re-establish correct PATH after path_helper reorders it
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH}"
```

3. **`.zshrc.d.01/420-terminal-integration.zsh`** (line 54) - AFTER VSCode shell integration:

```zsh
# Re-fix PATH after VSCode integration corrupts it
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH}"
```

**Verification**:

```bash
# Check terminal is detected correctly
echo $TERM_PROGRAM  # Should show "vscode" in Cursor/VSCode

# Check PATH has system directories
echo $PATH | tr ':' '\n' | head -6
# Should show: /opt/homebrew/bin, /usr/local/bin, /usr/bin, /bin, etc.
```

**Manual Override** (if needed):

```bash
# Add to ~/.zshenv.local (sourced before other initialization)
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
```

**Note**: This fix is defensive and helps all environments, not just VSCode/Cursor. SSH sessions, tmux, screen, and GUI-launched terminals also benefit.

---

### 2.3. Issue: Slow Startup

**Symptoms**: Shell takes >3 seconds to load

**Diagnosis**:

```bash

# Enable performance logging

export PERF_SEGMENT_LOG=~/perf.log
export PERF_SEGMENT_TRACE=1
source ~/.zshrc

# Find slowest components

awk '/END/ {print $1, $NF}' ~/perf.log | sort -t'(' -k2 -rn | head -10

```

**Solutions**:

1. Lazy-load slow plugins (see [Performance Guide](110-performance-guide.md))
2. Reduce plugin count
3. Use minimal mode: `export ZSH_MINIMAL=1`

---

### 2.4. Issue: Variable Not Set Errors

**Symptoms**: `parameter not set` errors

**Example**:

```text
zsh: SOME_VAR: parameter not set

```

**Cause**: Nounset-unsafe code

**Solutions**:

1. Add variable guard in `.zshenv.01`:

```bash
   : "${SOME_VAR:=default}"

```

2. Fix code to be nounset-safe:

```bash
   # ❌ Unsafe
   value="$VAR"

   # ✅ Safe
   value="${VAR:-default}"

```

---

## 3. 🔌 Plugin Problems

### 3.1. Issue: Plugin Not Loading

**Diagnosis**:

```bash

# 1. Is plugin declared?

cat ~/.config/zsh/.zshrc.add-plugins.d.00/*.zsh | grep "plugin-name"

# 2. Is zgenom seeing it?

zgenom list | grep "plugin-name"

# 3. Any errors?

zsh -x -c "source ~/.zshrc" 2>&1 | grep -i "error.*plugin-name"

```

**Solutions**:

```bash

# 1. Regenerate cache

zgenom reset

# 2. Update plugins

zgenom update

# 3. Reinstall specific plugin

rm -rf ~/.config/zsh/.zgenom/author-plugin-name-*
zgenom reset

```

---

### 3.2. Issue: Plugin Conflicts

**Symptoms**: Functions not working, unexpected behavior

**Diagnosis**:

```bash

# Check for function conflicts

which function-name

# See all definitions

whence -va function-name

```

**Solutions**:

1. Load order matters - adjust file numbers
2. Disable conflicting plugin
3. Namespace your functions (`zf::`)

---

### 3.3. Issue: Plugin Slow to Load

**Diagnosis**:

```bash

# Profile plugin loading

export PERF_SEGMENT_LOG=~/perf.log
zgenom reset && source ~/.zshrc

# Find slow plugins

grep "plugin" ~/perf.log | grep "END"

```

**Solutions**:

```bash

# 1. Lazy-load plugin

zsh-defer zgenom load slow/plugin

# 2. Or lazy wrapper

slow-command() {
    unfunction slow-command
    zgenom load slow/plugin
    slow-command "$@"
}

```

---

## 4. ⚡ Performance Issues

**See**: [Performance Guide](110-performance-guide.md) for comprehensive performance troubleshooting.

Quick fixes:

```bash

# Disable splash

export ZSH_DISABLE_SPLASH=1

# Minimal mode

export ZSH_MINIMAL=1

# Disable performance tracking

export ZSH_PERF_TRACK=0

```

---

## 5. 🛣️ Path Problems

### 5.1. Issue: Command in PATH Not Found

**Diagnosis**:

```bash

# Check PATH

echo $PATH | tr ':' '\n'

# Find command

which command-name

# Search for it

find /usr/local /opt -name "command-name" 2>/dev/null

```

**Solutions**:

```bash

# Add to PATH in .zshenv.01 or .zshrc.local

export PATH="/new/path:$PATH"

# Or use helper

zf::path_prepend "/new/path"

```

---

### 5.2. Issue: Duplicate PATH Entries

**Diagnosis**:

```bash

# Check for duplicates

echo $PATH | tr ':' '\n' | sort | uniq -d

```

**Solutions**:

```bash

# Enable PATH cleanup (should be default)

export PATH_CLEANUP=1

# Manual deduplication

typeset -U path  # ZSH makes array unique

```

---

## 6. 🎯 Completion Issues

### 6.1. Issue: Completions Not Working

**Symptoms**: Tab completion doesn't show options

**Diagnosis**:

```bash

# Check compinit ran

which compinit

# Check completion system

echo $fpath | tr ' ' '\n'

# Test specific completion

compdef -d my-command

```

**Solutions**:

```bash

# 1. Regenerate completion cache

rm -f ~/.config/zsh/.zcompdump*
source ~/.zshrc

# 2. Rebuild plugin cache

zgenom reset
source ~/.zshrc

# 3. Check completion file exists

cat ~/.config/zsh/.zshrc.d.01/410-completions.zsh

```

---

### 6.2. Issue: Slow Tab Completion

**Symptoms**: Noticeable delay when pressing Tab

**Solutions**:

```bash

# 1. Cache completion results

autoload -Uz compinit
compinit -C  # Skip security check

# 2. Reduce completion sources
# Edit: ~/.config/zsh/.zshrc.d.01/410-completions.zsh
# Comment out expensive completions


```

---

## 7. 💻 Terminal-Specific Issues

### 7.1. Issue: Prompt Doesn't Appear

**Diagnosis**:

```bash

# Check terminal detection

echo $TERM_PROGRAM

# Check Starship status

which starship

# Test Starship manually

starship prompt

```

**Solutions**:

```bash

# 1. Ensure Starship installed

brew install starship

# 2. Check not disabled

export ZSH_DISABLE_STARSHIP=0

# 3. Reinitialize

eval "$(starship init zsh)"

```

---

### 7.2. Issue: Colors Not Working

**Diagnosis**:

```bash

# Check terminal supports colors

echo $TERM

# Test colors

print -P '%F{red}Red%f %F{green}Green%f %F{blue}Blue%f'

```

**Solutions**:

```bash

# Set TERM correctly

export TERM=xterm-256color

# Or in terminal preferences:
# Enable "Report Terminal Type" or similar


```

---

### 7.3. Issue: iTerm2 Integration Not Working

**Diagnosis**:

```bash

# Check integration file exists

ls -la ~/iterm2_shell_integration.zsh

# Check terminal detected as iTerm2

echo $TERM_PROGRAM

```

**Solutions**:

```bash

# 1. Download integration

curl -L https://iterm2.com/shell_integration/zsh \
    -o ~/.iterm2_shell_integration.zsh

# 2. Ensure terminal detected
# Check: ~/.config/zsh/.zshenv.01 terminal detection


```

---

## 8. 🆘 Emergency Recovery

### 8.1. Nuclear Option 1: Minimal Shell

```bash

# Start with no configuration

zsh -f

# Then manually source what you need

source ~/.zshenv

# etc.


```

### 8.2. Nuclear Option 2: Rebuild Plugin Cache

```bash

# Remove all caches

rm -rf ~/.config/zsh/.zgenom/

# Reload (will reinstall everything)

source ~/.zshrc

```

### 8.3. Nuclear Option 3: Rollback Version

```bash

# Check available versions

ls -ld ~/.config/zsh/.zshrc.d.*/

# Rollback to previous

cd ~/.config/zsh
ln -snf .zshrc.d.00 .zshrc.d.live  # Or another working version

# Test

zsh

```

### 8.4. Nuclear Option 4: Use Backup

```bash

# List backups

ls -lt docs/010-zsh-configuration.backup-*/

# Restore from backup

cp -R docs/010-zsh-configuration.backup-2025-10-31/* \
      ~/.config/zsh/.zshrc.d.01/

```

---

## 9. 📞 Getting Help

### 9.1. Information to Gather

Before asking for help, collect:

```bash

# System info

uname -a
zsh --version

# Configuration state

ls -la ~/.config/zsh/ | grep "^l"
zgenom list

# Performance metrics

zsh-performance-baseline

# Recent errors

zsh 2>&1 | head -50

```

### 9.2. Diagnostic Commands

```bash

# Health check

zsh-healthcheck

# Test configuration files

zsh -n ~/.config/zsh/.zshrc.d.01/*.zsh

# Check for common issues

./bin/consistency-checker.zsh

```

---

## 10. 🔧 Advanced Troubleshooting

### 10.1. Trace Execution

```bash

# Full execution trace

zsh -x -i -c "exit" 2>&1 | tee trace.log

# Grep for specific module

grep "520-my-module" trace.log

```

### 10.2. Binary Search for Problem

```bash

# Use bisection tool

./bin/bisect-zsh-startup.sh

```

### 10.3. Verify File Integrity

```bash

# Check for corrupted files

for file in ~/.config/zsh/.zshrc.d.01/*.zsh; do
    zsh -n "$file" || echo "Syntax error in: $file"
done

```

---

## 11. 💡 Prevention Tips

### 1. Test Before Committing

```bash

# Always test in fresh shell

zsh

# Run health check

zsh-healthcheck

```

### 2. Use Version Control

```bash

# Commit working states

git add ~/.config/zsh/.zshrc.d.01/
git commit -m "feat: working state before changes"

```

### 3. Keep Backups

```bash

# Versioned symlinks are your backup!
# Always keep at least 2 versions

ls ~/.config/zsh/.zshrc.d.*/

```

### 4. Monitor Performance

```bash

# Check baselines regularly

zsh-performance-baseline

```

---

**Navigation:** [← Security Guide](120-security-guide.md) | [Top ↑](#troubleshooting-guide) | [Reference →](140-reference/000-index.md)

---

*Compliant with AI-GUIDELINES.md (v1.0 2025-10-30)*
