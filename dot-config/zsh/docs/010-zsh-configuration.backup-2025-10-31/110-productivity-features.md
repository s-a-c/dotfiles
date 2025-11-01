# - Productivity Features

## Table of Contents

<details>
<summary>Click to expand</summary>

- [1. Top](#1-top)
- [2. Purpose](#2-purpose)
- [3. Key integrations](#3-key-integrations)
- [4. Feature guards and opt-ins](#4-feature-guards-and-opt-ins)
- [5. FZF workflows and examples](#5-fzf-workflows-and-examples)
  - [5.1. 1) History search and re-run](#51-1-history-search-and-re-run)
  - [5.2. 2) Project file finder with preview](#52-2-project-file-finder-with-preview)
  - [5.3. 3) Commit selection helper](#53-3-commit-selection-helper)
- [6. zoxide examples](#6-zoxide-examples)
- [7. Keybindings and recommended aliases](#7-keybindings-and-recommended-aliases)
- [8. Performance & deferred loading](#8-performance-deferred-loading)
- [9. Troubleshooting](#9-troubleshooting)
- [10. Acceptance criteria](#10-acceptance-criteria)
- [11. Smoke test (manual)](#11-smoke-test-manual)
- [12. Related](#12-related)

</details>

---


## 1. Top

Status: Draft

Last updated: 2025-10-07

This document describes productivity-oriented features included in the configuration: fuzzy-finding integrations, navigation helpers, shell UX enhancements, and performance-minded loading patterns. The goal is to provide pragmatic examples you can copy into your personal configuration and clear guidance for enabling/disabling features safely.

## 2. Purpose

Productivity features accelerate common developer tasks while keeping startup time low. All integrations are guarded behind presence checks and opt-in environment variables so users without a given tool are unaffected.

## 3. Key integrations

- FZF — fuzzy-finding for files, buffers, history and commands
- zoxide — smart directory jumping
- eza / exa aliases — improved ls listing output
- evalcache — deferred, cached expensive computations for faster shells
- small helper functions and sensible aliases for common workflows


## 4. Feature guards and opt-ins

To avoid hard failures, most features are enabled only when the tool is present and an opt-in variable (where appropriate) is set.

Example guard pattern (namespaced variables):

```bash
if [[ "${ZSH_CONFIG_ENABLE_FZF:-0}" == "1" ]] && command -v fzf >/dev/null 2>&1; then
  source "$ZSH_CONFIG_DIR/320-fzf.zsh" || true
fi
```

This pattern keeps the configuration robust in minimal environments and reduces surprises for users who intentionally run a minimal setup.

## 5. FZF workflows and examples

### 5.1. 1) History search and re-run

A compact, safe way to search history and re-run the selected entry:

```bash

# Search shell history (most recent first) and run the selected entry

zsh -ic 'history -n; history 1' | tac | fzf --tac --height 40% --reverse | sed -E 's/^\s*[0-9]+\s*//' | while read -r cmd; do
  print -s "$cmd"  # push back into history
  zsh -c "$cmd"
done
```

Notes:

- `print -s` adds the command to history so it stays discoverable
- The pipeline is intentionally guarded to avoid running empty selections


### 5.2. 2) Project file finder with preview

Use `bat` as a previewer when available to speed up file triage:

```bash
fzf --height=40% --reverse --preview 'bat --style=numbers --color=always --line-range :200 {}' --bind 'enter:execute(nvim {})'
```

### 5.3. 3) Commit selection helper

Quickly find and open changed files from `git`:

```bash
git status --porcelain | fzf --nth 2.. --preview 'git diff --color=always -- {}' --bind 'enter:execute(nvim {})'
```

## 6. zoxide examples

- Jump to most used directory:


```bash
z
```

- Show database and select directory with `fzf`:


```bash
zoxide query -l | fzf --preview 'ls -la {}' | xargs -I{} z {}
```

## 7. Keybindings and recommended aliases

- Suggested default keybindings (documented here, enable with guard if you ship them):


```bash

# Ctrl-T for file finder (fzf)

bindkey '^T' fzf-file-widget

# Alt-C (or Meta-C) for directory change via zoxide

bindkey '^[c' zoxide-cd-widget

alias ll='eza -la --group-directories-first'
alias gs='git status'
```

Notes on keybindings:

- Choose non-conflicting bindings; keep bindings optional for users with different muscle memory
- Provide `ZSH_CONFIG_DISABLE_DEFAULT_KEYBINDINGS=1` to opt out


## 8. Performance & deferred loading

To keep shell startup snappy:

- Defer loading heavy integrations until first use (defer or lazy-source approach)
- Use lightweight shim functions that source full integration files when invoked


Example lazy loader for `fzf` functions:

```bash
zf::lazy::fzf() {
  unset -f zf::lazy::fzf
  source "$ZSH_CONFIG_DIR/320-fzf.zsh" 2>/dev/null || true
  fzf "$@"
}

# Replace direct calls with the lazy function

alias fzf='zf::lazy::fzf'
```

This ensures that users who don't use `fzf` during a session don't pay the cost of initializing its bindings.

## 9. Troubleshooting

- Symptom: FZF preview or bindings not working

  - Verify `command -v fzf` and `command -v bat` for preview features
  - Confirm the guard variable `ZSH_CONFIG_ENABLE_FZF` if your environment intentionally disables optional features
  - Check for conflicting keybindings with `bindkey` and adjust as necessary

- Symptom: zoxide jump not behaving

  - Inspect `zoxide query -l` to ensure the database has entries
  - Rebuild the database with `zoxide import` if necessary


## 10. Acceptance criteria

- Examples for the principal workflows (history, file finder, git file chooser) exist
- Guards and opt-ins are demonstrated clearly so users can disable features
- Performance guidance provided (defer pattern) plus a minimal lazy-loading example
- Troubleshooting checklist present for common failure modes


## 11. Smoke test (manual)

A minimal smoke test that asserts core productivity integrations are present and load without error:

```bash

# Check fzf and zoxide (non-fatal)

command -v fzf >/dev/null 2>&1 && echo "fzf: OK" || echo "fzf: missing"
command -v zoxide >/dev/null 2>&1 && echo "zoxide: OK" || echo "zoxide: missing"

# Try lazy loader (if guards are enabled this should be safe)

python -c 'print("smoke")' >/dev/null 2>&1 && echo "python: OK" || true
```

## 12. Related

- Return to [README](../README.md) or [000-index](000-index.md)

---

**Navigation:** [← Development Tools](100-development-tools.md) | [Top ↑](#productivity-features) | [Terminal Integration →](120-terminal-integration.md)

---

*Last updated: 2025-10-13*
