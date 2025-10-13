# - Development Tools

## Table of Contents

<details>
<summary>Click to expand</summary>

- [1. Top](#1-top)
- [2. Overview](#2-overview)
- [3. Supported toolchains](#3-supported-toolchains)
- [4. Node.js guidance](#4-nodejs-guidance)
  - [4.1. Recommended workflow](#41-recommended-workflow)
  - [4.2. Common troubleshooting](#42-common-troubleshooting)
- [5. Python guidance](#5-python-guidance)
- [6. PHP (Herd)](#6-php-herd)
- [7. Helpers and utilities](#7-helpers-and-utilities)
- [8. Troubleshooting and recovery](#8-troubleshooting-and-recovery)
- [9. Acceptance criteria](#9-acceptance-criteria)
- [10. FAQ](#10-faq)
- [11. Related](#11-related)

</details>

---


## 1. Top

Status: Draft

Last updated: 2025-10-07

This document describes the developer toolchain(s) that this ZSH configuration supports and how the configuration discovers, prioritizes, and exposes runtime versions and helpers.

## 2. Overview

The configuration aims to be unopinionated while providing sensible defaults for common developer toolchains: Node.js (nvm/asdf), Python (pyenv/asdf), Ruby (rbenv/asdf), and language-agnostic version managers where applicable (asdf). When multiple managers are present the configuration follows an explicit discovery and prioritization strategy described below.

## 3. Supported toolchains

- Node.js: nvm and asdf shims (recommended: use asdf for global consistency)
- Python: pyenv and asdf
- Ruby: rbenv and asdf
- PHP: Herd (optional)
- Other: Any runtime exposed via asdf


## 4. Node.js guidance

### 4.1. Recommended workflow

- Prefer `asdf` for per-project versions when a `.tool-versions` file exists.
- Use `nvm` only for legacy projects that require it; the configuration will prefer asdf when available.


### 4.2. Common troubleshooting

- Wrong Node version shown:


```bash

# Re-evaluate shell initialization for asdf

export ASDF_DIR="${ASDF_DIR:-$HOME/.asdf}"
source "${ASDF_DIR}/asdf.sh" 2>/dev/null || true

# Rehash shims

asdf reshim nodejs || true
```

- Node binary still points to global install:


```bash

# Diagnose which node is being picked

command -v node && node -v
echo "$PATH" | tr ':' '\n' | nl -ba | sed -n '1,40p'
```

## 5. Python guidance

- Prefer `pyenv` or `asdf` for project-specific versions.
- Use `pipx` for isolated CLI tool installations where appropriate.


Example: ensure project venv activation

```bash

# Preferred: use poetry or pyenv-virtualenv

poetry shell || python -m venv .venv && source .venv/bin/activate
```

## 6. PHP (Herd)

- Herd is optional and only enabled when present; guard with `command -v herd` checks.
- Provide php.ini overrides via project-local configurations when necessary.


## 7. Helpers and utilities

- `zf::dev::which_node` — prefers asdf shims first and falls back to nvm/system
- `zf::dev::use_system_node` — environment switch to force system node for build scripts


## 8. Troubleshooting and recovery

- Reinitialize manager shims if versions are out of sync
- Check for `.tool-versions` / `.nvmrc` files in project root and ensure their contents are valid
- If runtime binaries unexpectedly change, run `asdf reshim` where applicable and confirm PATH order


## 9. Acceptance criteria

- Documented guidance for Node, Python, and PHP
- Practical troubleshooting commands for common mis-detections
- One worked example showing how to recover from a PATH ordering issue


## 10. FAQ

Q: I upgraded node but the shell still shows old version.

A: Run `asdf reshim nodejs` or re-source your manager initialization script; confirm `command -v node` order.

Q: How do I force the system node for a single command?

A: Use `ZF::dev::use_system_node=1 node -v` or call `env -u ASDF_DIR node` to run the system binary in a clean environment.

## 11. Related

- Return to [README](README.md) or [000-index](000-index.md)

---

**Navigation:** [← Layered System](070-layered-system.md) | [Top ↑](#development-tools) | [Productivity Features →](110-productivity-features.md)

---

*Last updated: 2025-10-13*
