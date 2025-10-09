# Copilot Instructions – ZSH Refactor Configuration Repo

> Purpose: Provide a concise, enforced operating contract for AI assistants working in this dotfiles ZSH configuration repository.

## 1. Core Principles

- Minimize side effects; prefer additive, scoped diffs.
- Preserve user intent & layering architecture (pre-plugins → plugins → post-augmentation → OS-specific → local overrides).
- Avoid global behavioral changes unless explicitly requested.
- Always check for existing helpers (e.g. `zf::debug`, segment APIs, guards) before re‑implementing.
- Default to nounset-safe patterns: reference vars with `${VAR:-}` when uncertain.

## 2. Layering Model (Active Directories)

| Phase | Directory Pattern | Purpose | Notes |
|-------|-------------------|---------|-------|
| 1 | `.zshenv*`, `.zshrc.pre-plugins.d.00/` | Early env, safety, path shaping | No heavy I/O |
| 2 | `.zshrc.add-plugins.d.00/` | Plugin registration & core dev stacks | Use `zgenom` guards |
| 3 | `.zshrc.d.00/` | Post-plugin augmentation (nvm fixups, prompt init) | Avoid duplicating stubs |
| 4 | `.zshrc.Darwin.d/` | Platform-specific | Keep macOS defaults fast |
| 5 | `.zshrc.local` / `.zshenv.local` | User overrides | Never overwrite automatically |

Symlinks like `.zshrc.d` → `.zshrc.d.live` represent the active layer set.

## 3. Prompt System

- Default: If `.p10k.zsh` is present, it can be loaded first; Starship will defer to a precmd hook and take over afterward.
- Starship is enabled by default; use `ZSH_DISABLE_STARSHIP=1` to hard-disable, or `ZSH_STARSHIP_SUPPRESS_AUTOINIT=1` to export functions without auto-init.
- Unified file: `520-prompt-starship.zsh` (wrapper removed).
- Guard var: `__ZF_PROMPT_INIT_DONE=1` prevents duplicate init.
- Deprecated: `ZF_ENABLE_STARSHIP` (do not use).

## 4. Node Tooling & NVM Policy

- Early runtime path enrichment: `035-early-node-runtimes.zsh` adds Bun/Deno/PNPM path segments only.
- Plugin load: `120-dev-node.zsh` loads `npm` then `nvm` (order clears `NPM_CONFIG_PREFIX`).
- Post augmentation: `450-nvm-post-augmentation.zsh` now injects fallback lazy `nvm()` if plugin failed but `NVM_DIR/nvm.sh` exists.
- Do NOT eagerly source `nvm.sh` in early phases; preserve lazy semantics.

## 5. Safety & Diagnostics

- Use `zf::debug` for conditional debug output (respects `ZSH_DEBUG=1`).
- Use timing metrics variables (e.g. `_ZF_STARSHIP_INIT_MS`) only when already scaffolded—don’t add ad‑hoc metrics logs outside `artifacts/metrics` without request.
- Redirection sentinel: `005-redirection-sentinel.zsh` warns on stray digit files (probable `> 2` typos). Do not remove without replacement.

## 6. File & Function Conventions

- Namespace internal helpers with `zf::` if part of framework; avoid polluting global space.
- New feature toggles: prefix env vars with `ZF_` (e.g. `ZF_DISABLE_METRICS`).
- Idempotency: Re-sourcing a fragment should be harmless (return early if guards are set).

## 7. Editing Rules

1. Never mass‑reformat entire files; target only necessary hunks.
2. Preserve comments explaining phase ordering.
3. When adding a new fragment: include header block with:

- Filename + concise purpose
- Phase classification
- Dependencies (PRE / POST)

4. If modifying startup ordering, update documentation under `docs/` (source of truth) and add a concise note in `docs/250-next-steps/` when workflow-impacting.
5. Prefer `return 0` at end of sourced fragments; do not `exit`.

## 8. Documentation Sync

- Source of truth: top-level `docs/` with current guides; add forward-looking breadcrumbs in `docs/250-next-steps/`.
- On adding env flags or guards: append a short bullet to the most relevant doc under `docs/`, and include an action item or summary in `docs/250-next-steps/` when appropriate.
- Archive large historical rationale to `docs/.ARCHIVE/` if superseded.

## 9. Testing & Validation

- Runtime tests belong under `tests/runtime/` and must:
  - Be shellcheck-friendly.
  - Exit non-zero on assertion failure.
  - Avoid external network usage.
- Quick pattern for assertions:

```zsh
_fail() { print -u2 "[FAIL] $1"; return 1 }
[[ condition ]] || _fail "message" || return 1
```

## 10. Git & Hooks

- Pre-commit hook location: `tools/git-hooks/pre-commit` (if missing, create executable script invoking redirection lint + simple shellcheck if available).
- Do not auto-install hooks; just provide file and optional instructions.

## 11. Performance Considerations

- Avoid spawning subshells in tight loops during init.
- Defer heavy operations with `add-zsh-hook precmd` or lazy functions.
- Only write metrics if directory exists & is writable.

## 12. Prohibited / Caution

| Action | Policy |
|--------|--------|
| Force reinstall of plugin manager | Never do automatically |
| Replace user’s `.zshrc.local` or `.zshenv.local` | Forbidden |
| Introduce unguarded `set -u` mid-pipeline | Must remain disabled until compatibility confirmed |
| Hard-code absolute user paths beyond `$HOME` | Use `$HOME` / `$ZDOTDIR` |
| Network calls in init path | Only on explicit request |

## 13. Minimal Checklist Before Submitting Changes

- [ ] Guards & namespaces added
- [ ] No unintended prompt override side effects
- [ ] Docs updated (if new env var / phase change)
- [ ] Lazy loading preserved where expected
- [ ] Metrics writes conditional
- [ ] Shell fragments end with `return 0`

## 14. Quick Reference (Cheat Sheet)

| Need | Solution |
|------|----------|
| Add new env toggle | Env var `ZF_<NAME>` + doc bullet |
| Add post-plugin tweak | Place in `.zshrc.d.00/` with numeric > existing related fragment |
| Force Starship | Prefer defaults. To hard-disable use `ZSH_DISABLE_STARSHIP=1`; to suppress auto-init use `ZSH_STARSHIP_SUPPRESS_AUTOINIT=1`. |
| Verify nvm fallback | `type -t nvm; nvm --version` (first call loads) |
| Detect redirection typos | Ensure sentinel + run `tools/lint-redirections.zsh` |

---
Last updated: 2025-10-08

Note: This repository integrates with Byterover MCP tools.

You are given two tools from Byterover MCP server, including

## 1. `byterover-store-knowledge`

You MUST always use this tool when:

- Learning new patterns, APIs, or architectural decisions from the codebase
- Encountering error solutions or debugging techniques
- Finding reusable code patterns or utility functions
- Completing any significant task or plan implementation

## 2. `byterover-retrieve-knowledge`

You MUST always use this tool when:

- Starting any new task or implementation to gather relevant context
- Before making architectural decisions to understand existing patterns
- When debugging issues to check for previous solutions
- Working with unfamiliar parts of the codebase
