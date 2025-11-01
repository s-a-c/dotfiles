# Naming Conventions

**Code Standards & Style Guide** | **Technical Level: Beginner-Intermediate**

---

## 📋 Table of Contents

<details>
<summary>Expand Table of Contents</summary>

- [1. Function Naming](#1-function-naming)
  - [1.1. Helper Functions (`zf::` prefix)](#11-helper-functions-zf-prefix)
  - [1.2. User-Facing Functions (no prefix)](#12-user-facing-functions-no-prefix)
  - [1.3. Pattern Examples](#13-pattern-examples)
- [2. ️ Variable Naming](#2-variable-naming)
  - [2.1. Feature Flags (`ZSH_*` or `ZF_*` prefix)](#21-feature-flags-zsh_-or-zf_-prefix)
  - [2.2. Internal State Variables (`_ZF_*` or `_ZQS_*` prefix)](#22-internal-state-variables-_zf_-or-_zqs_-prefix)
  - [2.3. XDG Variables](#23-xdg-variables)
- [3. File Naming](#3-file-naming)
  - [3.1. Format](#31-format)
  - [3.2. Examples](#32-examples)
  - [3.3. Category Guidelines](#33-category-guidelines)
- [4. Numbered Prefixes](#4-numbered-prefixes)
  - [4.1. Load Order Ranges](#41-load-order-ranges)
  - [4.2. Increment Strategy](#42-increment-strategy)
- [5. Code Style](#5-code-style)
  - [5.1. Indentation](#51-indentation)
  - [5.2. Variable Expansion](#52-variable-expansion)
  - [5.3. Nounset-Safe Variables](#53-nounset-safe-variables)
  - [5.4. Conditionals](#54-conditionals)
  - [5.5. Function Definitions](#55-function-definitions)
- [6. Module Headers](#6-module-headers)
  - [6.1. Standard Header Format](#61-standard-header-format)
  - [6.2. Header Fields](#62-header-fields)
- [7. Comments](#7-comments)
  - [7.1. Comment Style](#71-comment-style)
  - [7.2. Section Headers](#72-section-headers)
  - [7.3. Inline Comments](#73-inline-comments)
- [Related Documentation](#related-documentation)

</details>

---

## 1. 🔤 Function Naming

### 1.1. Helper Functions (`zf::` prefix)

All internal helper functions use the `zf::` namespace prefix:

```bash

# ✅ CORRECT - Namespaced

zf::path_prepend() { ... }
zf::debug() { ... }
zf::segment() { ... }
zf::has_command() { ... }

# ❌ WRONG - Pollutes global namespace

path_prepend() { ... }
debug() { ... }

```

**Why?**
Prevents conflicts with plugins, user functions, and external commands.

### 1.2. User-Facing Functions (no prefix)

Commands users interact with can be unprefixed:

```bash

# ✅ CORRECT - User commands

zsh-healthcheck() { ... }
zsh-performance-baseline() { ... }
fix-starship-cursor() { ... }

# ✅ CORRECT - Utility functions

mkcd() { ... }
backup() { ... }

```

### 1.3. Pattern Examples

```bash

# Internal helper (with prefix)

zf::segment() {
    local module_name="$1"
    local action="$2"
    # Implementation...
}

# User command (no prefix needed)

zsh-healthcheck() {
    echo "Running health check..."
    # Uses internal helpers
    zf::debug "Health check started"
}

```

---

## 2. 🏷️ Variable Naming

### 2.1. Feature Flags (`ZSH_*` or `ZF_*` prefix)

```bash

# ✅ CORRECT - Clear naming

export ZSH_DISABLE_SPLASH=0
export ZSH_PERF_TRACK=1
export ZF_DISABLE_AUTO_UPDATES=1
export ZSH_ENABLE_ABBR=1

# ❌ WRONG - No prefix

export DISABLE_SPLASH=0  # Too generic

```

### 2.2. Internal State Variables (`_ZF_*` or `_ZQS_*` prefix)

Private/internal variables use underscore prefix:

```bash

# ✅ CORRECT - Internal state

typeset -g _ZF_OPTIONS_LOADED=1
export _ZQS_NOUNSET_WAS_ON=1

# User-facing variables (no underscore)

export ZDOTDIR="${HOME}/.config/zsh"
export ZSH_LOG_DIR="${XDG_STATE_HOME}/zsh/logs"

```

### 2.3. XDG Variables

Standard XDG base directory variables:

```bash
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_STATE_HOME="${HOME}/.local/state"

# Extended XDG

export XDG_BIN_HOME="${HOME}/.local/bin"

```

---

## 3. 📄 File Naming

### 3.1. Format

```text
XXX-category-description.zsh

```

**Components**:
- `XXX` - Three-digit load order (000-999)
- `category` - Feature category
- `description` - Specific purpose
- `.zsh` - File extension

### 3.2. Examples

| Purpose | File Name |
|---------|-----------|
| Shell options | `400-options.zsh` |
| Completion system | `410-completions.zsh` |
| Terminal detection | `420-terminal-integration.zsh` |
| Navigation tools | `430-navigation-tools.zsh` |
| Node.js environment | `450-node-environment.zsh` |
| Developer utilities | `510-developer-tools.zsh` |

### 3.3. Category Guidelines

Common categories:

- `options` - Shell option configuration
- `completions` - Tab completion setup
- `terminal` - Terminal-specific features
- `navigation` - Directory/file navigation
- `dev-*` - Development tools (dev-php, dev-node)
- `productivity-*` - Productivity enhancements
- `perf-*` - Performance utilities

---

## 4. 🔢 Numbered Prefixes

### 4.1. Load Order Ranges

| Range | Phase | Purpose |
|-------|-------|---------|
| `000-099` | Pre-plugin | Infrastructure, markers |
| `100-199` | Plugin/Post | Core systems |
| `200-299` | Plugin | Plugin declarations |
| `300-399` | Post-plugin | Advanced features |
| `400-499` | Post-plugin | Integration, options |
| `500-599` | Post-plugin | User-facing features |
| `900-999` | Post-plugin | Final overrides |

### 4.2. Increment Strategy

**Use multiples of 10**:

```bash
400-options.zsh
410-completions.zsh
420-terminal-integration.zsh
430-navigation-tools.zsh

```

**Benefits**:

- Easy to insert new files: `405-new-feature.zsh`
- Clear spacing between modules
- Logical grouping

**Within-10 numbering** for related files:

```bash
440-neovim.zsh
441-neovim-helpers.zsh
442-neovim-integration.zsh

```

---

## 5. 🎨 Code Style

### 5.1. Indentation

```bash

# ✅ Use 4 spaces

function my_function() {
    if [[ condition ]]; then
        echo "Properly indented"
    fi
}

# ❌ Don't use tabs

function my_function() {
→   echo "Tab character - avoid!"
}

```

### 5.2. Variable Expansion

```bash

# ✅ CORRECT - Always quote

echo "$variable"
path="/some/path/$filename"

# ❌ WRONG - Unquoted (word splitting issues)

echo $variable
path=/some/path/$filename

```

### 5.3. Nounset-Safe Variables

```bash

# ✅ CORRECT - Safe default

value="${VARIABLE:-default}"
: "${VARIABLE:=default}"  # Set if unset

# ❌ WRONG - Breaks with nounset

value="$VARIABLE"  # Fails if VARIABLE unset

```

### 5.4. Conditionals

```bash

# ✅ CORRECT - Use [[ ]]

if [[ -f "$file" ]]; then
    echo "File exists"
fi

# ✅ CORRECT - Pattern matching

if [[ "$var" == *pattern* ]]; then
    echo "Matches pattern"
fi

# ❌ AVOID - Use [ ] only for POSIX compatibility

if [ -f "$file" ]; then
    echo "POSIX style"
fi

```

### 5.5. Function Definitions

```bash

# ✅ CORRECT - function keyword

function my_function() {
    local arg1="$1"
    # ...
}

# ✅ ALSO CORRECT - POSIX style

my_function() {
    local arg1="$1"
    # ...
}

```

---

## 6. 📝 Module Headers

### 6.1. Standard Header Format

Every module file MUST include:

```bash

#!/usr/bin/env zsh
# Filename: 400-options.zsh
# Purpose:  Configure ZSH shell options
# Phase:    Post-plugin (.zshrc.d/)
# Requires: Plugins loaded (410-completions.zsh depends on this)
# Author:   [Optional]
# Updated:  2025-10-31

# Guard against multiple loads

if (( ${+_ZF_OPTIONS_LOADED} )); then
    return 0
fi
typeset -g _ZF_OPTIONS_LOADED=1

# Module implementation below
# ...


```

### 6.2. Header Fields

| Field | Required | Purpose |
|-------|----------|---------|
| Shebang | ✅ Yes | `#!/usr/bin/env zsh` |
| Filename | ✅ Yes | Actual filename |
| Purpose | ✅ Yes | What this module does |
| Phase | ✅ Yes | pre-plugin, plugin, post-plugin |
| Requires | 💡 Recommended | Dependencies |
| Author | ❌ Optional | Who wrote it |
| Updated | 💡 Recommended | Last modification date |

---

## 7. 💬 Comments

### 7.1. Comment Style

```bash

# ✅ CORRECT - Explain WHY, not WHAT
# Disable nounset during plugin loading to prevent errors
# Many OMZ plugins don't handle undefined variables properly

unsetopt nounset

# ❌ WRONG - Comments the obvious
# Set variable to 1

my_var=1

```

### 7.2. Section Headers

```bash

# ==============================================================================
# SECTION NAME
# Description of what this section does
# ==============================================================================

# Or simpler:
# ─────────────────────────────────────
# Section Name
# ─────────────────────────────────────


```

### 7.3. Inline Comments

```bash

# Keep inline comments brief

local var="value"  # Default value

# For longer explanations, use above-line comments
# This is a complex setting that affects XYZ behavior
# See documentation for more details

export COMPLEX_SETTING="value"

```

---

## 🔗 Related Documentation

- [File Organization](070-file-organization.md) - Directory structure
- [Development Guide](090-development-guide.md) - Creating new modules
- [Configuration Phases](040-configuration-phases.md) - Where to place files

---

**Navigation:** [← File Organization](070-file-organization.md) | [Top ↑](#naming-conventions) | [Development Guide →](090-development-guide.md)

---

*Compliant with AI-GUIDELINES.md (v1.0 2025-10-30)*
