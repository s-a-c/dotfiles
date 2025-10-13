# Starship Guard Changes (2025-10-09)

## Table of Contents

<details>
<summary>Click to expand</summary>

- [1. New Defaults](#1-new-defaults)
- [2. Behavior with Powerlevel10k](#2-behavior-with-powerlevel10k)
- [3. Deprecated](#3-deprecated)
- [4. Files touched](#4-files-touched)

</details>

---


## 1. New Defaults

- ZSH_DISABLE_STARSHIP=0 (enabled by default)
- ZSH_STARSHIP_SUPPRESS_AUTOINIT=0 (autoinit enabled by default)

Set these overrides in `~/.zshenv.local` if needed:

- Hard-disable Starship: `ZSH_DISABLE_STARSHIP=1`
- Export functions only (no auto-init): `ZSH_STARSHIP_SUPPRESS_AUTOINIT=1`

## 2. Behavior with Powerlevel10k

- If `.p10k.zsh` exists, it may load first; Starship defers and takes over via a precmd hook.
- If `.p10k.zsh` does not exist, Starship initializes immediately when available.

## 3. Deprecated

- `ZF_ENABLE_STARSHIP` is deprecated and ignored; use the variables above.

Wrapper removal:

- `starship-init-wrapper.zsh` has been removed; use `520-prompt-starship.zsh` exclusively.

## 4. Files touched

- `.zshenv`: added defaults for Starship guards
- `.zshrc.d.00/520-prompt-starship.zsh`: removed legacy mapping; clarified docs
- `starship-init-wrapper.zsh`: stops forcing suppression; emits deprecation debug

---

**Navigation:** [Top ↑](#starship-guard-changes-2025-10-09)

---

*Last updated: 2025-10-13*
