# - Completion System

## Table of Contents

<details>
<summary>Click to expand</summary>

- [1. Top](#1-top)
- [2. Overview](#2-overview)
- [3. Carapace integration (guarded)](#3-carapace-integration-guarded)
- [4. Loading order & fallbacks](#4-loading-order-fallbacks)
- [5. Example custom completion snippet](#5-example-custom-completion-snippet)
- [6. Troubleshooting](#6-troubleshooting)
- [7. Acceptance criteria](#7-acceptance-criteria)
- [8. Related](#8-related)

</details>

---


## 1. Top

Status: Draft

Last updated: 2025-10-07

This document describes how the configuration handles tab completion, Carapace integration, and completion loading order to maximise responsiveness and correctness.

## 2. Overview

Completion pipeline responsibilities:

- Detect optional completion frameworks (Carapace) and enable them in a guarded manner
- Provide ordered fallbacks so that native zsh completions remain available if a framework is not present
- Offer examples for authoring small, local completion definitions


## 3. Carapace integration (guarded)

- Only enable Carapace when the tool is present and when the user has opted in (example env guard: `ZSH_CONFIG_ENABLE_CARAPACE=1`).


Example guard:

```bash
if command -v carapace >/dev/null 2>&1 && [[ "${ZSH_CONFIG_ENABLE_CARAPACE:-0}" == "1" ]]; then
  source "$ZSH_CONFIG_DIR/320-fzf.zsh"  # guarded load example
fi
```

## 4. Loading order & fallbacks

- Prefer lightweight native `compinit` when Carapace is absent
- When Carapace is active, ensure its initialization occurs early enough to register high-level completions but deferred to avoid startup slowdown


## 5. Example custom completion snippet

```bash

# Minimal function completion for 'mycmd'

_mycmd() {
  _arguments '*: :->args'
}
compdef _mycmd mycmd
```

## 6. Troubleshooting

- Symptom: Completion suggestions missing for an installed tool

  - Run `autoload -Uz compinit && compinit -v` to check for init errors
  - Confirm `fpath` contains directories with completion definitions


## 7. Acceptance criteria

- Clear guidance for enabling Carapace and defensively falling back to `compinit`
- Example custom completion included
- Troubleshooting checklist for users


## 8. Related

- Return to [README](README.md) or [000-index](000-index.md)

---

**Navigation:** [← History Management](130-history-management.md) | [Top ↑](#completion-system) | [Troubleshooting Startup Warnings →](150-troubleshooting-startup-warnings.md)

---

*Last updated: 2025-10-13*
