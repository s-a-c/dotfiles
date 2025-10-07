# 110 - Productivity Features

## Top

Status: Draft

Last updated: 2025-10-07

This document describes productivity-oriented features included in the configuration: fuzzy-finding integrations, navigation helpers, and user experience optimisations that improve interactive shell workflows.

## Overview

The configuration provides curated defaults and guarded integrations for fast navigation and discovery. Integrations are guarded to avoid hard failures when optional tools are absent.

## Key features

- FZF integration with recommended keybindings and sample usage
- `zoxide`-based directory navigation with example `z` usage
- Enhanced `ls` and `exa` aliases (`eza`) for readable listings
- Deferred loading of heavy features (fzf, evalcache) to reduce startup latency

## Example FZF workflows

1. Command history search with `fzf`:

   ```bash
   # Search shell history and re-run selected entry
   history | fzf --tac | sed 's/^[ ]*[0-9]*[ ]*//' | xargs -I{} zsh -c '{}'
   ```

2. Quickly open files in the project with `fzf` + `nvim`:

   ```bash
   fzf --preview 'bat --style=numbers --color=always {}' | xargs -I{} nvim {}
   ```

## Keybindings and aliases

- `Ctrl-T` — file finder (fzf)
- `Alt-C` — `zoxide` change directory helper

  Example alias definitions:

  ```bash
  alias ll='eza -la --group-directories-first'
  ```

## Performance notes

- Defer heavy feature initialization (fzf bindings, evalcache) until the feature is first used.
- Provide environment variable guards such as `ZSH_CONFIG_ENABLE_FZF=1` for users to opt-in.

## Acceptance criteria

- Examples for the principal workflows are present
- Clear guidance for deferring feature initialization and guards for optional tools
- One troubleshooting example documenting how to disable an integration that causes performance issues

## Related

- Return to [README](README.md) or [000-index](000-index.md)
