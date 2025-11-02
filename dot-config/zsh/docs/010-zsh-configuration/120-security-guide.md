# Security Guide

**Security Practices & Integrity Verification** | **Technical Level: Intermediate**

---

## 📋 Table of Contents

<details>
<summary>Expand Table of Contents</summary>

- [1. Security Overview](#1-security-overview)
- [2. ️ Nounset Safety System](#2-nounset-safety-system)
  - [2.1. The Problem](#21-the-problem)
  - [2.2. The Solution](#22-the-solution)
  - [2.3. Writing Nounset-Safe Code](#23-writing-nounset-safe-code)
- [3. ️ Path Security](#3-path-security)
  - [3.1. Path Validation](#31-path-validation)
  - [3.2. Path Deduplication](#32-path-deduplication)
  - [3.3. Dangerous Paths](#33-dangerous-paths)
- [4. Plugin Verification](#4-plugin-verification)
  - [4.1. Plugin Registry](#41-plugin-registry)
  - [4.2. Verification Process](#42-verification-process)
- [5. No Secrets Policy](#5-no-secrets-policy)
  - [5.1. Rule](#51-rule)
  - [5.2. Enforcement](#52-enforcement)
  - [5.3. Safe Alternatives](#53-safe-alternatives)
  - [5.4. Secret Scanning](#54-secret-scanning)
- [6. File Permissions](#6-file-permissions)
  - [6.1. Recommended Permissions](#61-recommended-permissions)
  - [6.2. XDG Directory Permissions](#62-xdg-directory-permissions)
  - [6.3. Check Permissions](#63-check-permissions)
- [7. ✅ Best Practices](#7-best-practices)
  - [1. Input Validation](#1-input-validation)
  - [2. Safe Command Execution](#2-safe-command-execution)
  - [3. Temporary File Security](#3-temporary-file-security)
  - [4. Error Handling](#4-error-handling)
- [8. Security Checklist](#8-security-checklist)
- [Related Documentation](#related-documentation)

</details>

---

## 1. 🔒 Security Overview

This configuration implements multiple security layers:

1. **Nounset Safety**: Prevent undefined variable errors
2. **Path Validation**: Only add existing, safe directories
3. **Plugin Verification**: Integrity checks for plugins
4. **No Secrets**: Never commit credentials
5. **XDG Compliance**: Proper file permissions and locations

---

## 2. 🛡️ Nounset Safety System

### 2.1. The Problem

```bash

# With nounset enabled (set -u)

echo "$UNDEFINED_VAR"

# Error: parameter not set

# Many plugins break with nounset!


```

### 2.2. The Solution

Multi-layered protection in Phase 3:

#### Layer 1: Early Variable Guards (`.zshenv.01`)

```bash

# Guard critical variables before any code runs

: "${ZSH_DEBUG:=0}"
: "${STARSHIP_CMD_STATUS:=0}"
: "${POWERLEVEL10K_DISABLE_CONFIGURATION_WIZARD:=1}"

```

#### Layer 2: Plugin Compatibility Mode

File: `.zshrc.pre-plugins.d.01/010-shell-safety.zsh`

```bash

# Disable nounset during plugin loading

if [[ -o nounset ]]; then
    export _ZQS_NOUNSET_WAS_ON=1
    unsetopt nounset
    export _ZQS_NOUNSET_DISABLED_FOR_OMZ=1
fi

```

#### Layer 3: Safe Re-enablement (Future)

```bash

# After plugins loaded, can safely re-enable
# (Currently disabled for maximum compatibility)

function zf::enable_nounset_safe() {
    if (( _ZQS_NOUNSET_WAS_ON )); then
        setopt nounset
    fi
}

```

### 2.3. Writing Nounset-Safe Code

```bash

# ✅ CORRECT - Always provide defaults

value="${VARIABLE:-default}"
: "${VARIABLE:=default}"  # Set if unset
count=${#array[@]:-0}

# ❌ WRONG - Will fail with nounset

value="$VARIABLE"
count=${#array[@]}

```

---

## 3. 🛣️ Path Security

### 3.1. Path Validation

Only existing directories are added to PATH:

```bash

# Helper function validates before adding

zf::path_prepend() {
    local dir="$1"

    # Validate directory exists
    if [[ ! -d "$dir" ]]; then
        return 1
    fi

    # Add if not already present
    if [[ ":$PATH:" != *":$dir:"* ]]; then
        export PATH="$dir:$PATH"
    fi
}

```

### 3.2. Path Deduplication

```bash

# Automatically removes duplicate PATH entries
# While preserving order
# See: .zshenv.01 path normalization


```

### 3.3. Dangerous Paths

```bash

# ❌ AVOID - Security risk

export PATH=".:$PATH"  # Current directory first!

# ✅ SAFE - System paths first

export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

```

---

## 4. 🔐 Plugin Verification

### 4.1. Plugin Registry

Location: `security/plugin-registry/`

**Purpose**: Track known-good plugin versions

### 4.2. Verification Process

1. **Plugin Source Verification**

```bash
   # Only load from trusted sources
   zgenom load zsh-users/zsh-syntax-highlighting  # Official repo

```

2. **Integrity Checks**

```bash
   # Zgenom verifies git commits
   # Checksums tracked in cache

```

3. **Review Before Adding**
   - Check plugin source code
   - Review recent commits
   - Check issue tracker
   - Verify maintenance status

---

## 5. 🚫 No Secrets Policy

### 5.1. Rule

> 🔴❌ **CRITICAL**: Never commit secrets, API keys, passwords, or tokens to the repository.

### 5.2. Enforcement

```bash

# Git pre-commit hook checks for secrets
# Scan patterns:
# - API_KEY=
# - PASSWORD=
# - Bearer tokens
# - Private keys


```

### 5.3. Safe Alternatives

```bash

# ❌ WRONG - Hardcoded secret

export API_KEY="sk-1234567890abcdef"

# ✅ CORRECT - Environment variable

export API_KEY="${API_KEY:-}"  # Set externally

# ✅ CORRECT - User local file
# In ~/.zshrc.local (not in repo):

export API_KEY="sk-1234567890abcdef"

# ✅ CORRECT - Secret management tool

export API_KEY="$(security find-generic-password -s myapp -w)"

```

### 5.4. Secret Scanning

```bash

# Check for potential secrets

grep -r "API_KEY\|PASSWORD\|SECRET" ~/.config/zsh/ \
    --exclude-dir=".git" \
    --exclude-dir=".zgenom"

```

---

## 6. 🔐 File Permissions

### 6.1. Recommended Permissions

```bash

# Configuration files

chmod 644 ~/.config/zsh/.zshrc.d.01/*.zsh

# Executable scripts

chmod 755 ~/.config/zsh/bin/*

# Sensitive files (user local)

chmod 600 ~/.zshrc.local
chmod 600 ~/.zshenv.local

```

### 6.2. XDG Directory Permissions

```bash

# Standard permissions

~/.config/      755 (rwxr-xr-x)
~/.local/share/ 755 (rwxr-xr-x)
~/.cache/       700 (rwx------) # More restrictive
~/.local/state/ 700 (rwx------)  # More restrictive

```

### 6.3. Check Permissions

```bash

# View current permissions

ls -la ~/.config/zsh/.zshrc.d.01/

# Fix if needed

chmod 644 ~/.config/zsh/.zshrc.d.01/*.zsh

```

---

## 7. ✅ Best Practices

### 1. Input Validation

```bash

# Validate function arguments

function my_function() {
    local input="$1"

    # Validate input provided
    if [[ -z "$input" ]]; then
        echo "Error: Input required" >&2
        return 1
    fi

    # Validate input format
    if [[ ! "$input" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: Invalid characters" >&2
        return 1
    fi

    # Safe to use
    process "$input"
}

```

### 2. Safe Command Execution

```bash

# ✅ CORRECT - Explicit command

command git status

# ❌ RISKY - Could be aliased

git status  # What if aliased to something dangerous?

```

### 3. Temporary File Security

```bash

# ✅ CORRECT - Secure temp directory

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT INT TERM

# Use temp directory

echo "data" > "$tmpdir/file"

# ❌ WRONG - Predictable path

echo "data" > /tmp/myapp-file  # Race condition!

```

### 4. Error Handling

```bash

# ✅ CORRECT - Check errors

if ! command-that-might-fail; then
    echo "Error: Command failed" >&2
    return 1
fi

# ❌ WRONG - Ignore errors

command-that-might-fail

# Continue anyway...


```

---

## 8. 🚨 Security Checklist

Before committing changes:

- [ ] No hardcoded secrets or credentials
- [ ] No `chmod 777` or overly permissive permissions
- [ ] Input validation for user-provided data
- [ ] Error handling for all critical operations
- [ ] Nounset-safe variable access
- [ ] No dangerous PATH modifications
- [ ] Plugin sources verified
- [ ] Temporary files use secure patterns
- [ ] No execution of untrusted code
- [ ] User local files require explicit approval

---

## 🔗 Related Documentation

- [Development Guide](090-development-guide.md) - Safe development practices
- [Testing Guide](100-testing-guide.md) - Security testing
- [.cursorrules](/.cursorrules) - Security principles section

---

**Navigation:** [← Performance Guide](110-performance-guide.md) | [Top ↑](#security-guide) | [Troubleshooting →](130-troubleshooting.md)

---

*Compliant with AI-GUIDELINES.md (v1.0 2025-10-30)*
