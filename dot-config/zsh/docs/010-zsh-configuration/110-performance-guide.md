# Performance Guide

**Monitoring & Optimization** | **Technical Level: Intermediate-Advanced**

---

## 📋 Table of Contents

<details>
<summary>Expand Table of Contents</summary>

- [1. Performance Overview](#1-performance-overview)
  - [1.1. Current Performance](#11-current-performance)
  - [1.2. Performance Breakdown](#12-performance-breakdown)
- [2. Monitoring System](#2-monitoring-system)
  - [2.1. Segment Tracking](#21-segment-tracking)
  - [2.2. Enable Performance Logging](#22-enable-performance-logging)
  - [2.3. Log Output Format](#23-log-output-format)
  - [2.4. Built-in Performance Commands](#24-built-in-performance-commands)
- [3. Performance Targets](#3-performance-targets)
  - [3.1. Startup Time Goals](#31-startup-time-goals)
  - [3.2. Memory Targets](#32-memory-targets)
- [4. ⚡ Optimization Techniques](#4-optimization-techniques)
  - [1. Lazy Loading](#1-lazy-loading)
  - [2. Use ZSH Built-ins](#2-use-zsh-built-ins)
  - [3. Reduce Plugin Count](#3-reduce-plugin-count)
  - [4. Cache Expensive Evaluations](#4-cache-expensive-evaluations)
  - [5. Defer Non-Critical Operations](#5-defer-non-critical-operations)
  - [6. Minimize File Sourcing](#6-minimize-file-sourcing)
- [5. Profiling Tools](#5-profiling-tools)
  - [5.1. Built-in Profiling](#51-built-in-profiling)
  - [5.2. Detailed Profiling](#52-detailed-profiling)
  - [5.3. Segment Analysis](#53-segment-analysis)
- [6. Common Bottlenecks](#6-common-bottlenecks)
  - [1. Plugin Loading (800ms, 44%)](#1-plugin-loading-800ms-44)
  - [2. Completion Generation (200ms+)](#2-completion-generation-200ms)
  - [3. Node/NVM Initialization (150-300ms)](#3-nodenvm-initialization-150-300ms)
  - [4. External Commands in Loops](#4-external-commands-in-loops)
- [7. Performance Testing](#7-performance-testing)
  - [7.1. Baseline Capture](#71-baseline-capture)
  - [7.2. Before/After Comparison](#72-beforeafter-comparison)
  - [7.3. Regression Detection](#73-regression-detection)
- [8. Performance Tips](#8-performance-tips)
  - [8.1. DO ✅](#81-do)
  - [8.2. DON'T ❌](#82-dont)

</details>

---

## 1. 🎯 Performance Overview

### 1.1. Current Performance

**Target Startup Time**: ~1.8 seconds
**Actual Performance**: 1.5-2.0s depending on system

### 1.2. Performance Breakdown

```text
[████████████░░░░░░░░] Plugin Loading    800ms (44%)
[██████░░░░░░░░░░░░░░] Post-Plugin       400ms (22%)
[█████░░░░░░░░░░░░░░░] Finalization      300ms (17%)
[████░░░░░░░░░░░░░░░░] Pre-Plugin        150ms  (8%)
[██░░░░░░░░░░░░░░░░░░] Environment       100ms  (6%)
[█░░░░░░░░░░░░░░░░░░░] Orchestration      50ms  (3%)

```

**Optimization Priority**: Focus on plugin loading (44% of time)

---

## 2. 📊 Monitoring System

### 2.1. Segment Tracking

Built-in performance tracking using `zf::segment`:

```bash

# In any module

zf::segment "module-name" "start"

# ... module code ...

zf::segment "module-name" "end"

```

### 2.2. Enable Performance Logging

```bash

# In terminal or .zshenv.local

export PERF_SEGMENT_LOG=~/zsh-perf.log
export PERF_SEGMENT_TRACE=1
export ZSH_PERF_TRACK=1

# Start new shell

zsh

# View log

cat ~/zsh-perf.log

```

### 2.3. Log Output Format

```log
[pre-plugin] START 1699123456789
[pre-plugin:010-shell-safety] START 1699123456790
[pre-plugin:010-shell-safety] END 1699123456795 (5ms)
[pre-plugin] END 1699123456850 (61ms)
[plugin-load] START 1699123456850
[plugin-load] END 1699123457650 (800ms)
...

```

### 2.4. Built-in Performance Commands

```bash

# Show baseline metrics

zsh-performance-baseline

# Output:
# Startup Time: 1.85s
# Memory (RSS): 45MB
# Config Files: 220
# Loaded Plugins: 42


```

---

## 3. 🎯 Performance Targets

### 3.1. Startup Time Goals

| Category | Target | Current | Status |
|----------|--------|---------|--------|
| Environment | <150ms | ~100ms | ✅ Good |
| Pre-Plugin | <200ms | ~150ms | ✅ Good |
| Plugin Loading | <1000ms | ~800ms | ✅ Good |
| Post-Plugin | <500ms | ~400ms | ✅ Good |
| **Total** | **<2000ms** | **~1800ms** | ✅ **On Target** |

### 3.2. Memory Targets

| Metric | Target | Typical |
|--------|--------|---------|
| RSS Memory | <50MB | ~45MB |
| Virtual Memory | <200MB | ~180MB |

---

## 4. ⚡ Optimization Techniques

### 1. Lazy Loading

Defer expensive operations until first use:

```bash

# ❌ SLOW - Loads immediately

eval "$(nvm use 20)"  # Takes ~200ms

# ✅ FAST - Loads on first use

nvm() {
    unfunction nvm
    eval "$(nvm sh)"
    nvm "$@"
}

```

### 2. Use ZSH Built-ins

```bash

# ❌ SLOWER - External commands

date=$(command date +%s)
lines=$(echo "$text" | wc -l)

# ✅ FASTER - ZSH built-ins

zmodload zsh/datetime
date=$EPOCHSECONDS
lines=${#${(f)text}}

```

### 3. Reduce Plugin Count

```bash

# Audit which plugins you actually use

zgenom list

# Disable unused plugins
# Comment out in .zshrc.add-plugins.d.00/
# zgenom load unused/plugin  # Disabled


```

### 4. Cache Expensive Evaluations

```bash

# Use evalcache plugin

_evalcache nvm use 20    # Caches result

```

### 5. Defer Non-Critical Operations

```bash

# Use zsh-defer plugin

zsh-defer source expensive-config.zsh

# Or add-zsh-hook

autoload -Uz add-zsh-hook
add-zsh-hook precmd slow_function

```

### 6. Minimize File Sourcing

```bash

# ❌ SLOW - Multiple small files

source config/part1.zsh
source config/part2.zsh
source config/part3.zsh

# ✅ FASTER - Single consolidated file

source config/all-in-one.zsh

```

---

## 5. 🔍 Profiling Tools

### 5.1. Built-in Profiling

```bash

# Profile entire startup

time zsh -i -c exit

# Profile specific file

time zsh -i -c "source ~/.config/zsh/.zshrc.d.01/410-completions.zsh"

```

### 5.2. Detailed Profiling

```bash

# Enable zsh profiling

zmodload zsh/zprof

# Source your config

source ~/.zshrc

# Show profile

zprof

```

### 5.3. Segment Analysis

```bash

# Enable segment logging

export PERF_SEGMENT_LOG=~/perf.log
export PERF_SEGMENT_TRACE=1

# Reload

source ~/.zshrc

# Analyze timing

awk '/END/ {print $1, $NF}' ~/perf.log | sort -t'(' -k2 -rn | head -10

```

---

## 6. 🐌 Common Bottlenecks

### 1. Plugin Loading (800ms, 44%)

**Problem**: Too many plugins or slow plugins

**Solutions**:

```bash

# Identify slow plugins

export PERF_SEGMENT_LOG=~/perf.log
zgenom reset && source ~/.zshrc
grep "plugin" ~/perf.log

# Lazy-load infrequently used plugins

zsh-defer zgenom load slow/plugin

# Or remove unused plugins


```

### 2. Completion Generation (200ms+)

**Problem**: `compinit` is expensive

**Solutions**:

```bash

# Cache completion dump

autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C  # Skip security check
fi

```

### 3. Node/NVM Initialization (150-300ms)

**Problem**: nvm setup is slow

**Solutions**:

```bash

# Lazy-load nvm

nvm() {
    unfunction nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    nvm "$@"
}

# Or use evalcache

_evalcache nvm use 20

```

### 4. External Commands in Loops

**Problem**: Spawning subshells is expensive

**Solutions**:

```bash

# ❌ SLOW

for file in *.txt; do
    count=$(cat "$file" | wc -l)  # Spawns 2 processes per file!
done

# ✅ FAST

for file in *.txt; do
    count=${#${(f)"$(<$file)"}}  # Pure ZSH
done

```

---

## 7. 🧪 Performance Testing

### 7.1. Baseline Capture

```bash

# Capture current baseline

zsh-performance-baseline > logs/baseline_$(date +%Y%m%d).txt

```

### 7.2. Before/After Comparison

```bash

# Before changes

time zsh -i -c exit > before.txt 2>&1

# Make changes
# ...

# After changes

time zsh -i -c exit > after.txt 2>&1

# Compare

diff before.txt after.txt

```

### 7.3. Regression Detection

```bash

# Run performance test

./bin/test-performance.zsh

# Checks against baselines
# Fails if startup time increases >10%


```

---

## 8. 💡 Performance Tips

### 8.1. DO ✅

1. **Profile before optimizing**

```bash
   # Know where time is spent
   export PERF_SEGMENT_LOG=~/perf.log

```

2. **Use lazy loading**

```bash
   expensive_function() {
       unfunction expensive_function
       source expensive-module.zsh
       expensive_function "$@"
   }

```

3. **Cache results**

```bash
   _evalcache expensive_eval_command

```

4. **Use ZSH built-ins**

```bash
   # Not: $(date +%s)
   # Use: $EPOCHSECONDS

```

### 8.2. DON'T ❌

1. **Don't spawn unnecessary subshells**

```bash
   # ❌ Bad
   result=$(cat file | grep pattern | cut -d: -f1)

   # ✅ Better
   result=${${(M)${(f)"$(<file)"}:#*pattern*}%%:*}

```

2. **Don't load all plugins**

```bash
   # Question each plugin: "Do I actually use this?"

```

3. **Don't run network calls on startup**

```bash
   # ❌ Never
   api_status=$(curl https://api.example.com)

   # ✅ On-demand only
   function check_api() {
       curl https://api.example.com
   }

```

---

**Navigation:** [← Testing Guide](100-testing-guide.md) | [Top ↑](#performance-guide) | [Security Guide →](120-security-guide.md)

---

*Compliant with AI-GUIDELINES.md (v1.0 2025-10-30)*
