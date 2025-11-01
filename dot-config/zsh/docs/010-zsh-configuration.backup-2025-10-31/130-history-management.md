# - History Management

## Table of Contents

<details>
<summary>Click to expand</summary>

- [1. Top](#1-top)
- [2. Overview](#2-overview)
- [3. Atuin (optional)](#3-atuin-optional)
- [4. History file locations & rotation](#4-history-file-locations-rotation)
- [5. Privacy & sensitive data handling](#5-privacy-sensitive-data-handling)
- [6. Migration notes](#6-migration-notes)
- [7. Acceptance criteria](#7-acceptance-criteria)
- [8. Related](#8-related)

</details>

---


## 1. Top

Status: Draft

Last updated: 2025-10-07

This document covers history management strategies used by the configuration, with guarded integration for Atuin (optional), zsh native history settings, and migration guidance from older systems.

## 2. Overview

History handling in interactive shells must balance convenience (searchability, cross-device sync) with privacy (sensitive command suppression). The configuration enables Atuin when present and guarded; otherwise it falls back to carefully configured zsh history variables.

## 3. Atuin (optional)

- The configuration only enables Atuin if the `atuin` binary is present and the user has explicitly opted in via `ZSH_CONFIG_USE_ATUIN=1`.
- Provide example configuration flags and mention how to avoid leaking sensitive input.


```bash

# Enable Atuin only when present and opted-in

if command -v atuin >/dev/null 2>&1 && [[ "${ZSH_CONFIG_USE_ATUIN:-0}" == "1" ]]; then
  source "$ZSH_CONFIG_DIR/atuin-init.zsh"
fi
```

## 4. History file locations & rotation

- Document the default `$HISTFILE` location and recommended rotation/size settings


Example recommended zsh settings:

```bash
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt append_history
setopt share_history
```

## 5. Privacy & sensitive data handling

- Suggest using `HIST_IGNORE` patterns or filters to avoid recording commands that contain tokens or private data.
- Include a troubleshooting note for accidental leakage and how to remove entries from the history file.


## 6. Migration notes

- Provide steps to migrate from legacy history systems to Atuin or to the current zsh history format


## 7. Acceptance criteria

- Atuin usage documented and gated behind an opt-in
- Privacy guidance and example zsh settings present
- Migration steps included for users moving from older systems


## 8. Related

- Return to [README](../README.md) or [000-index](000-index.md)

---

**Navigation:** [← Terminal Integration](120-terminal-integration.md) | [Top ↑](#history-management) | [Completion System →](140-completion-system.md)

---

*Last updated: 2025-10-13*
