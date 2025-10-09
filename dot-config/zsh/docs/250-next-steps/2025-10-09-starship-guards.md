# Starship Guard Changes (2025-10-09)

Summary of prompt guard semantics and defaults after consolidation.

## New Defaults

- ZSH_DISABLE_STARSHIP=0 (enabled by default)
- ZSH_STARSHIP_SUPPRESS_AUTOINIT=0 (autoinit enabled by default)

Set these overrides in `~/.zshenv.local` if needed:

- Hard-disable Starship: `ZSH_DISABLE_STARSHIP=1`
- Export functions only (no auto-init): `ZSH_STARSHIP_SUPPRESS_AUTOINIT=1`

## Behavior with Powerlevel10k

- If `.p10k.zsh` exists, it may load first; Starship defers and takes over via a precmd hook.
- If `.p10k.zsh` does not exist, Starship initializes immediately when available.

## Deprecated

- `ZF_ENABLE_STARSHIP` is deprecated and ignored; use the variables above.

Wrapper removal:

- `starship-init-wrapper.zsh` has been removed; use `520-prompt-starship.zsh` exclusively.

## Files touched

- `.zshenv`: added defaults for Starship guards
- `.zshrc.d.00/520-prompt-starship.zsh`: removed legacy mapping; clarified docs
- `starship-init-wrapper.zsh`: stops forcing suppression; emits deprecation debug
