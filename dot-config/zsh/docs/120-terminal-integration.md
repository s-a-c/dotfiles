# 120 - Terminal Integration

## Top

Status: Draft

Last updated: 2025-10-07

This document explains how the configuration interacts with different terminal emulators (iTerm2, Warp, WezTerm, Kitty, Alacritty) and how terminal-specific features are gated and applied.

## Overview

Terminal integration focuses on non-invasive detection and on providing optional integrations where the terminal supports advanced features (e.g., image display, hyperlink support, OSC sequences).

## Terminal detection

- Use `$TERM_PROGRAM` and terminal-specific environment variables (e.g., `TERM_PROGRAM=iTerm.app`, `WEZTERM`) to detect capabilities.
- Do not enable emulator-specific code unless a capability is positively detected.


## Example: conditional capability check

```bash

# Example guard: enable iTerm2 integration only when running inside iTerm

if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
  source "$ZSH_CONFIG_DIR/iterm2_shell_integration.zsh" 2>/dev/null || true
fi
```

## macOS-specific notes

- When running on macOS prefer Apple's build of certain utilities or provide guidance for Homebrew-managed alternatives.
- Provide guidance for installing integration helper scripts (iTerm shell integrations, Warp helper fragments).


## Troubleshooting

- Symptom: Links or images not rendering in the terminal

  - Verify the terminal supports the expected OSC/ESC sequences and is configured to allow them.


## Acceptance criteria

- Documented detection strategy per-terminal
- Simple guarded example code for enabling integration
- Explicit note that integrations are optional and non-fatal when tools are missing


## Related

- Return to [README](README.md) or [000-index](000-index.md)
