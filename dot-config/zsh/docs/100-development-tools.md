# 100 - Development Tools

## Top

Status: Draft

Last updated: 2025-10-07

This document describes the developer toolchain(s) that this ZSH configuration supports and how the configuration discovers, prioritizes, and exposes runtime versions and helpers.

## Overview

The configuration aims to be unopinionated while providing sensible defaults for common developer toolchains: Node.js (nvm/asdf), Python (pyenv/asdf), Ruby (rbenv/asdf), and language-agnostic version managers where applicable (asdf). When multiple managers are present the configuration follows an explicit discovery and prioritization strategy described below.

## Supported toolchains

- Node.js: nvm and asdf shims (recommended: use asdf for global consistency)
- Python: pyenv and asdf
- Ruby: rbenv and asdf
- Other: Herd (PHP) where provided by the host system

## Discovery & prioritization

1. If `ASDF_DIR`/`asdf` is present and configured, prefer asdf-provided shims for versions declared in project `.tool-versions`.

2. If `nvm` or `pyenv` are present but asdf is not configured for a project, fall back to the manager detected in the current shell session.

3. The configuration exposes small helper functions and PATH ordering to prefer explicit project-local shims over system-wide installs.

### Example: prefer asdf when available

```bash
# Example: ensure asdf shims are earlier in PATH for interactive shells
export PATH="${ASDF_DIR:-$HOME/.asdf}/shims:$PATH"
```

## Recommended environment variables and helpers

- `ASDF_DIR` — path to asdf installation (default: `$HOME/.asdf`)
- `NVM_DIR` — nvm installation path
- `ZF::dev::use_system_node` (example helper) — a small exported variable used by the config to force system node when needed

Example helper function (namespaced to avoid collisions):

```bash
zf::dev::which_node() {
  # prefer asdf shims, then nvm, then system
  command -v node 2>/dev/null || echo "node-not-found"
}
```

## Troubleshooting & common workarounds

- Symptom: Wrong Node version in an interactive shell

  - Ensure project has a `.tool-versions` (for asdf) or `.nvmrc` (for nvm)
  - Restart the shell or manually source the manager initialization script for the session

- Symptom: PATH ordering unexpectedly picks a global binary

  - Inspect `echo $PATH` and confirm `${ASDF_DIR:-$HOME/.asdf}/shims` is earlier than `/usr/local/bin`.

## Acceptance criteria

- Documentation shows where each tool's shims are located and how the configuration prefers them
- Example snippets exist for common fixups and PATH manipulations
- At least one troubleshooting example covers overriding a misdetected runtime

## Related

- Return to [README](README.md) or [000-index](000-index.md)
