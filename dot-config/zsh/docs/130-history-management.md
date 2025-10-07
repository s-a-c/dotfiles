# 130 - History Management

## Top

Status: Draft

Last updated: 2025-10-07

This document covers history management strategies used by the configuration, with guarded integration for Atuin (optional), zsh native history settings, and migration guidance from older systems.

## Overview

History handling in interactive shells must balance convenience (searchability, cross-device sync) with privacy (sensitive command suppression). The configuration enables Atuin when present and guarded; otherwise it falls back to carefully configured zsh history variables.

## Atuin (optional)

- The configuration only enables Atuin if the `atuin` binary is present and the user has explicitly opted in via `ZSH_CONFIG_USE_ATUIN=1`.
- Provide example configuration flags and mention how to avoid leaking sensitive input.

```bash
# Enable Atuin only when present and opted-in
if command -v atuin >/dev/null 2>&1 && [[ "${ZSH_CONFIG_USE_ATUIN:-0}" == "1" ]]; then
  source "$ZSH_CONFIG_DIR/atuin-init.zsh"
fi
```

## History file locations & rotation

- Document the default `$HISTFILE` location and recommended rotation/size settings

Example recommended zsh settings:

```bash
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt append_history
setopt share_history
```

## Privacy & sensitive data handling

- Suggest using `HIST_IGNORE` patterns or filters to avoid recording commands that contain tokens or private data.
- Include a troubleshooting note for accidental leakage and how to remove entries from the history file.

## Migration notes

- Provide steps to migrate from legacy history systems to Atuin or to the current zsh history format

## Acceptance criteria

- Atuin usage documented and gated behind an opt-in
- Privacy guidance and example zsh settings present
- Migration steps included for users moving from older systems

## Related

- Return to [README](README.md) or [000-index](000-index.md)
