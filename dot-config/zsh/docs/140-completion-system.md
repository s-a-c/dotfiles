# 140 - Completion System

## Top

Status: Draft

Last updated: 2025-10-07

This document describes how the configuration handles tab completion, Carapace integration, and completion loading order to maximise responsiveness and correctness.

## Overview

Completion pipeline responsibilities:

- Detect optional completion frameworks (Carapace) and enable them in a guarded manner
- Provide ordered fallbacks so that native zsh completions remain available if a framework is not present
- Offer examples for authoring small, local completion definitions

## Carapace integration (guarded)

- Only enable Carapace when the tool is present and when the user has opted in (example env guard: `ZSH_CONFIG_ENABLE_CARAPACE=1`).

Example guard:

```bash
if command -v carapace >/dev/null 2>&1 && [[ "${ZSH_CONFIG_ENABLE_CARAPACE:-0}" == "1" ]]; then
  source "$ZSH_CONFIG_DIR/320-fzf.zsh"  # guarded load example
fi
```

## Loading order & fallbacks

- Prefer lightweight native `compinit` when Carapace is absent
- When Carapace is active, ensure its initialization occurs early enough to register high-level completions but deferred to avoid startup slowdown

## Example custom completion snippet

```bash
# Minimal function completion for 'mycmd'
_mycmd() {
  _arguments '*: :->args'
}
compdef _mycmd mycmd
```

## Troubleshooting

- Symptom: Completion suggestions missing for an installed tool

  - Run `autoload -Uz compinit && compinit -v` to check for init errors
  - Confirm `fpath` contains directories with completion definitions

## Acceptance criteria

- Clear guidance for enabling Carapace and defensively falling back to `compinit`
- Example custom completion included
- Troubleshooting checklist for users

## Related

- Return to [README](README.md) or [000-index](000-index.md)
