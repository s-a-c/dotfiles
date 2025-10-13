# 1. fix-zle Plan of Attack (Active Summary)
## 1.3. Phase Status (2025-10-08)

- Phase 1–3: COMPLETE (core, performance, dev environments)
- Phase 4: PARTIAL (productivity: history/nav/fzf/completions in place)
- Phase 5: PARTIAL (Neovim hybrid env present; prompt safety pending)
- Phase 6: PENDING (Terminal integrations)
- Phase 7: PENDING (Optional enhancements: Starship, autopair, etc.)

Widget baseline remains ≥387 (no regression expected from changes in this commit).

## 1.4. Newly Documented Controls (Prompt & NVM)

### 1.4.1. Starship Prompt Enablement & Coexistence Strategy

Starship is treated as a Phase 7 optional prompt enhancement. Powerlevel10k remains default until Starship is explicitly requested.

Mechanism:

1. File: `/.zshrc.d.00/410-starship-prompt.zsh` (Phase 7A placeholder numbering) now:

- Correctly sources wrapper at `$ZDOTDIR/starship-init-wrapper.zsh` (path bug fixed).
- Supports explicit opt-in via environment variable `ZF_ENABLE_STARSHIP=1` (set early: `~/.zshenv.local` or pre-plugin fragment).
- If p10k is present and Starship not forced, defers Starship initialization to a `precmd` hook so it can replace PROMPT cleanly after first prompt paint.
- Idempotent guard: `__ZF_PROMPT_INIT_DONE`.

Usage examples:

```sh
# 2. Force Starship immediately
export ZF_ENABLE_STARSHIP=1
```

Validation snippet:

```sh
ZF_ENABLE_STARSHIP=1 zsh -i -c 'echo STARSHIP_SHELL=${STARSHIP_SHELL:-unset}'
```

Expect `STARSHIP_SHELL=starship` when starship binary is installed.

### 2.1. Fallback NVM Lazy Stub Injection

File: `/.zshrc.d.00/450-nvm-post-augmentation.zsh` gained a safety block:

- After reporting plugin state, if `nvm` function is still absent but `NVM_DIR/nvm.sh` exists, injects a minimalist lazy loader function which:
  1. Unsets itself.
  2. Sources `nvm.sh` (and `bash_completion` if present).
  3. Re-dispatches the original arguments.

Rationale: Observed sessions where OMZ `plugins/nvm` was listed in `zgenom` init, yet `nvm` was not defined post-initialization. This prevents a confusing "nvm not found" scenario while retaining lazy characteristics.

Validation snippet:

```sh
zsh -i -c 'type -t nvm; echo NVM_DIR=$NVM_DIR; nvm --version 2>/dev/null || echo nvm_load_failed'
```

Expect first invocation to materialize real `nvm`.

### 2.2. Prompt Wrapper Notes

Wrapper: `starship-init-wrapper.zsh`

- Applies micro patching to Starship keymap widget line to avoid ZLE widget access errors under strict safety.
- Exposes internal metrics `_ZF_STARSHIP_INIT_MS` (written if metrics dir present) for future performance comparisons.

## 2.1. Early Redirection Sentinel

File: `/.zshrc.d.00/005-redirection-sentinel.zsh`

- Added to detect stray single-digit files (e.g. `2`) produced by malformed redirections like `> 2`.
- Emits debug lines only when `ZSH_DEBUG=1` to keep normal sessions quiet.

## 2.2. Phase 7 Preparation Checklist (Updated)

- [x] Path correctness for Starship wrapper
- [x] Guard & opt-in variable (`ZF_ENABLE_STARSHIP`)
- [x] Deferred init strategy when p10k present
- [x] Fallback nvm lazy stub
- [x] Redirection sentinel
- [ ] Measure Starship init timing vs p10k (attach metrics snippet)
- [ ] Document autopair activation ordering (pending actual Phase 7 file re-enable)
- [ ] Integrate test harness (see below) into CI or manual script collection

## 2.3. Minimal Automated Test Harness (Planned Additions)

Target file (created in this change set separately): `tests/runtime/test_nvm_prompt_env.zsh`

Purpose:

- Assert `type -t nvm` => function.
- When `ZF_ENABLE_STARSHIP=1`, assert `STARSHIP_SHELL=starship` and `__ZF_PROMPT_INIT_DONE=1`.
- Capture non-zero exit status if either check fails.

Run manually:

```sh
ZDOTDIR=$PWD zsh tests/runtime/test_nvm_prompt_env.zsh
```

## 2.4. Consolidated entrypoints (2025-10-09)

- .zshrc is now a symlink to vendored quickstart kit (`zsh-quickstart-kit/zsh/.zshrc`). We no longer duplicate the vendor file.
- .zshrc.local is reduced to a minimal late-override stub (keep tiny, idempotent). Prefer fragments:
  - `.zshrc.pre-plugins.d.00/*` (early env/path tweaks)
  - `.zshrc.add-plugins.d.00/*` (plugin declarations)
  - `.zshrc.d.00/*` (post-plugin augmentations)
- Rationale: eliminate drift, simplify upgrades, ensure local overrides remain last and optional.

## 2.5. Governance & Diff Policy Reminder

Changes remain within Phase 7 preparation scope; no cross-phase feature blending. Further expansion (Terminal integrations & Autopair) will reference this file and only mark phases complete after validation scripts pass and widget baseline confirmed.

(Generated update – future edits should append incremental evidence rather than overwrite prior rationale.)

---

**Navigation:** [Top ↑](#1-fix-zle-plan-of-attack-active-summary)

---

*Last updated: 2025-10-13*
