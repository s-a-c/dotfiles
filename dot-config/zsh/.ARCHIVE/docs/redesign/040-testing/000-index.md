# Testing Strategy Index (000)

Return: [Root Index](../000-index.md) | Improvements: [../030-improvements/000-index.md](../030-improvements/000-index.md)

## Files
- [010-testing-strategy.md](010-testing-strategy.md) — Comprehensive testing & validation framework: categories, planned test files, metrics, harness patterns, phase mapping, exit criteria.

## Scope
Covers automated & manual tests ensuring:
- Single compinit invocation & stable completion system.
- Styling extraction, palette/API parity, variant correctness, snapshot diff invariants.
- PATH/env unification (dedup, guard, single exports).
- Performance budgets (cold/warm startup, finalizer timing, drift thresholds).
- Security & hygiene (scoped hook sanitization).
- Documentation synchronization (structure vs filesystem).

## Cross-Links
- Completion System Architecture: [../010-architecture/030-completion-system.md](../010-architecture/030-completion-system.md)
- Improvement Plan (task mapping): [../030-improvements/010-comprehensive-improvement-plan.md](../030-improvements/010-comprehensive-improvement-plan.md)
- Phases Index: [../030-improvements/phases/000-index.md](../030-improvements/030-phases/000-index.md)

## Conventions
Planned test file naming: `tests/<domain>/test-*.zsh` with strict `set -euo pipefail` and deterministic output suitable for CI integration.

Generated: 2025-08-24
