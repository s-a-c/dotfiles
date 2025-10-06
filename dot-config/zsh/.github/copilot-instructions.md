# Copilot Operating Instructions for `dot-config/zsh`

Compliant with `AGENT.md` orchestration policy (see root `AGENT.md`). These instructions tailor GitHub Copilot / AI agents to this repository's ZSH configuration redesign work ("fix-zle" initiative) and broader shell environment management.

## Primary Knowledge Sources

1. Canonical agent policy: `AGENT.md` (MUST be loaded and its checksum acknowledged before authoring changes; see that file for exact compliance rules).
2. Core redesign & implementation status: `docs/fix-zle/` (this is the PRIMARY functional documentation hub).
   - `plan-of-attack.md` – authoritative phased rebuild strategy (feature-driven approach).
   - `README.md` – current testing suite and execution guidance.
   - `investigation-log.md` – historical root‑cause investigation evidence.
   - `bisection-log.md`, `debug-evidence.md`, `emergency-procedures.md` – supporting forensic + recovery context.
3. Supporting meta / contribution docs: `CONTRIBUTING.md`, `ZSH_STARTUP_SEQUENCE.md`, `SHELL_FIXES_SUMMARY.md`.

AI agents MUST prefer facts in `docs/fix-zle/plan-of-attack.md` and update progress references accordingly.

## Current Rebuild Progress Snapshot (Mirrors `docs/fix-zle/plan-of-attack.md`) — synchronized 2025-09-30T16:31Z

Phases 1–5: COMPLETED (synced 2025-09-30T16:31Z)

- Phase 1: Core ZSH + essential compatibility (≥387 widgets baseline achieved)
- Phase 2: Performance + core plugins (evalcache, async, defer loaded)
- Phase 3: Development environments (PHP/Herd, Node (NVM+Bun), Rust, Go, GitHub CLI) integrated
- Phase 4: Productivity tools (dual-path: plugin-managed 150/160 + direct fallback 300–330; widget baseline now 407)
- Phase 5: Neovim multi-profile ecosystem (`340-neovim-environment.zsh` with `nvprofile` dispatcher)
- Namespace standardization complete (`zf::`), legacy wrappers removed

Phase 6: PARTIAL (Terminal Integration)
- Unified module `100-terminal-integration.zsh` active
- Legacy stub removed
- Pending: capture interactive session evidence (Warp / WezTerm / Ghostty / Kitty) and store under `docs/fix-zle/results/terminal/`

Phase 7: PARTIAL (Optional Enhancements)
- Starship prompt active & guarded (`110-starship-prompt.zsh`), timing metric `_ZF_STARSHIP_INIT_MS` captured
- Autopair plugin loaded (`180-optional-autopair.zsh`)
- Functional test scaffold present (`docs/fix-zle/tests/test-autopair.sh`); advanced behavioral assertions still pending

Metrics (updated):
- Fully Completed Phases: 5 / 7 (≈71%)
- ZLE widget health: ✅ stable 407 (≥387 baseline)
- Performance layer: ✅ active
- Development environments: ✅ available
- Terminal integration: 🔄 partial (awaiting evidence logs)
- Optional enhancements: 🔄 partial (awaiting enhanced autopair assertions)

Agents MUST NOT mark later phases as complete unless corresponding files are created, loaded in startup sequence, and verified interactively.

## Operating Principles (Derived from `AGENT.md` + repo conventions)

1. Policy Injection & Acknowledgement
   - ALWAYS load and cite `AGENT.md` policy (include computed checksum if automation is added later). For manual edits, retain the compliance header already present in this file.
2. Minimal, Auditable Diffs
   - Touch only the files/scopes required for a declared phase task. Preserve numbering semantics (`010-...`, `020-...`).
3. Phase Integrity
   - Each phase add must be: isolated module file + success criteria + optional test invocation snippet.
   - Do not intermingle features across phases unless consolidating with explicit rationale in commit message body.
4. Namespacing Rules
   - All custom shell functions MUST live under `zf::` prefix. No reintroduction of compatibility wrappers unless documented in `docs/fix-zle/` with justification.
5. Safety & Nounset Strategy
   - Respect delayed nounset activation patterns already established (`010-shell-safety-nounset.zsh`, `095-delayed-nounset-activation.zsh`). New code must be nounset-safe or guarded with `${var:-}` fallbacks.
6. Startup Performance
   - Use deferred loading (e.g., `zsh-defer`, `evalcache`) only where idempotent. Measure additions if they could impact initialization; record observations in a short comment block.
7. No Silent Failure
   - Avoid redirecting stderr to `/dev/null`; log through a `zf::debug` or `zf::warn` (if implemented) channel instead.
8. Testing Expectation
   - For each new module: provide a quick manual validation snippet (ZLE widget count if relevant, path exports, command availability checks).

## When Adding or Modifying Modules

Checklist (include in PR description / commit message if substantial):

- [ ] Phase identifier & rationale
- [ ] File path(s) added/changed with numeric ordering
- [ ] ZLE compatibility unaffected (widgets ≥ baseline) OR justification
- [ ] Nounset-safe (audited)
- [ ] No regression to startup performance (or delta documented)
- [ ] Functions namespaced (`zf::`)
- [ ] Test snippet executed (paste output if possible)

## Prohibited / Caution Patterns

- DO NOT reintroduce broad `set +u` without controlled re-enable pattern.
- DO NOT create custom ZLE wrappers for already provided plugin functionality (`hlissner/zsh-autopair` handles autopairs).
- DO NOT suppress errors globally (`2>/dev/null`)—only narrowly with rationale.
- AVOID monolithic multi-feature files; prioritize single-responsibility modules.

## File / Directory Conventions

Directory roles (active during redesign):

- `.zshrc.pre-plugins.d.empty/` – early safety + environment gates
- `.zshrc.add-plugins.d.empty/` – plugin declarations & deferred perf layers
- `.zshrc.d.empty/` – late environment enrichment & terminal/user experience features

During migration, legacy `*.REDESIGN/` directories are reference only—DO NOT mutate except for archival tagging; new work targets `*.empty/` sets.

## Interaction with Tests & Diagnostics

The manual testing scripts in `docs/fix-zle/` remain authoritative for any regression triage. If adding automated tests later, place harnesses under `tests/` and document invocation in `docs/fix-zle/testing-framework.md` (extend, do not overwrite).

## Commit Message Guidance

Use conventional prefix + phase tag, e.g.:
`feat(phase4): add Atuin + navigation tooling module (ZLE stable 389 widgets)`
`perf(startup): defer node toolchain path exports (no widget change)`
`refactor(namespace): convert remaining helper to zf::`
Include: baseline widget count delta, performance notes, policy compliance line.

## Copilot / AI Request Examples

Examples of good prompts for incremental changes:

- "Add Phase 4 module enabling Atuin and FZF with validation snippet; ensure nounset safety."
- "Refactor new navigation module to use zf:: namespace and add debug guard."
- "Add terminal integration script for Ghostty and record verification steps."

## Escalation / Uncertainty Handling

If an agent cannot determine phase alignment or a change spans multiple phases, it MUST:

1. Generate a proposal section in a temp markdown file under `docs/fix-zle/proposals/` (create directory if absent).
2. Summarize risk, affected modules, and rollback plan.
3. Halt implementation pending human approval.

## Planned Next Steps (Pending User Approval)

1. Implement Phase 4 productivity modules:
   - `060-shell-history.zsh` (Atuin guarded)
   - `070-navigation.zsh` (eza, zoxide, fzf plugin load ordering)
   - `080-completions.zsh` (Carapace conditional)
   - Acceptance: tools load without regressions; widget count ≥ baseline
2. Validate Phase 5 additions:
   - Run alias smoke test; document results in `plan-of-attack.md`
   - Confirm no prompt or PATH conflicts
3. Implement Phase 6 terminal integrations:
   - `100-terminal-integration.zsh` with conditional env exports
   - Optional debug helper disabled by default
4. Implement Phase 7 optional enhancements:
   - `110-starship-prompt.zsh` (guarded, timing note optional)
   - `120-autopair.zsh` (plugin load after other completions)
5. Add smoke test script (`docs/fix-zle/test-smoke.sh`):
   - Checks widget threshold + presence of enabled tools
6. (Optional) Add lightweight timestamp delta logging (non-segment) or defer until instrumentation plan approved

## Request for Confirmation

Please review the progress snapshot and planned next steps. Reply with one of:

- APPROVE ALL NEXT STEPS
- APPROVE (list numbers) / HOLD (list numbers)
- REVISE (provide adjustments)

Once approved, subsequent commits will reference this file section and update the progress snapshot.

---
Generated for repository guidance. Update this document whenever phase status changes.

[byterover-mcp]

[byterover-mcp]

You are given two tools from Byterover MCP server, including
## 1. `byterover-store-knowledge`
You `MUST` always use this tool when:

+ Learning new patterns, APIs, or architectural decisions from the codebase
+ Encountering error solutions or debugging techniques
+ Finding reusable code patterns or utility functions
+ Completing any significant task or plan implementation

## 2. `byterover-retrieve-knowledge`
You `MUST` always use this tool when:

+ Starting any new task or implementation to gather relevant context
+ Before making architectural decisions to understand existing patterns
+ When debugging issues to check for previous solutions
+ Working with unfamiliar parts of the codebase
