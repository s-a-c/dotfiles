# - Terminal Integration

## Table of Contents

<details>
<summary>Click to expand</summary>

- [1. Top](#1-top)
- [2. Overview](#2-overview)
- [3. Terminal detection](#3-terminal-detection)
- [4. Example: conditional capability check](#4-example-conditional-capability-check)
- [5. macOS-specific notes](#5-macos-specific-notes)
- [6. Troubleshooting](#6-troubleshooting)
- [7. Acceptance criteria](#7-acceptance-criteria)
- [8. Related](#8-related)

</details>

---


## 1. Top

Status: Draft

Last updated: 2025-10-07

This document explains how the configuration interacts with different terminal emulators (iTerm2, Warp, WezTerm, Kitty, Alacritty) and how terminal-specific features are gated and applied.

## 2. Overview

Terminal integration focuses on non-invasive detection and on providing optional integrations where the terminal supports advanced features (e.g., image display, hyperlink support, OSC sequences).

## 3. Terminal detection

- Use `$TERM_PROGRAM` and terminal-specific environment variables (e.g., `TERM_PROGRAM=iTerm.app`, `WEZTERM`) to detect capabilities.
- Do not enable emulator-specific code unless a capability is positively detected.


## 4. Example: conditional capability check

```bash

# Example guard: enable iTerm2 integration only when running inside iTerm

if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
  source "$ZSH_CONFIG_DIR/iterm2_shell_integration.zsh" 2>/dev/null || true
fi
```

## 5. macOS-specific notes

- When running on macOS prefer Apple's build of certain utilities or provide guidance for Homebrew-managed alternatives.
- Provide guidance for installing integration helper scripts (iTerm shell integrations, Warp helper fragments).


## 6. Troubleshooting

- Symptom: Links or images not rendering in the terminal

  - Verify the terminal supports the expected OSC/ESC sequences and is configured to allow them.


## 7. Acceptance criteria

- Documented detection strategy per-terminal
- Simple guarded example code for enabling integration
- Explicit note that integrations are optional and non-fatal when tools are missing


## 8. Related

- Return to [README](README.md) or [000-index](000-index.md)

---

**Navigation:** [← Productivity Features](110-productivity-features.md) | [Top ↑](#terminal-integration) | [History Management →](130-history-management.md)

---

*Last updated: 2025-10-13*
