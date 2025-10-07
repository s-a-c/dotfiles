# 050 - Testing Framework

## Top

Status: Draft

Last updated: 2025-10-07

This document describes the testing framework for the ZSH REDESIGN project: layout, harnesses, and how to run smoke/unit/integration tests locally.

## Folder layout

The repository follows a minimal test layout:

- `tests/unit/` — small, fast tests for pure script logic
- `tests/integration/` — full-path validations that may touch filesystem symlinks and plugin loading
- `tests/smoke/` — quick verification scripts that ensure the core runtime pieces can boot

## Running tests

- Unit tests (example harness): `./tools/run-unit-tests.sh`
- Integration tests: `./tools/run-integration-tests.sh --target 400-redesign`
- Smoke tests: `./tools/run-smoke-tests.sh --target 400-redesign`

### Example smoke test (manual)

```bash
# Validate test harness presence
[ -d tests ] && echo "tests folder present" || echo "tests folder missing"
# Run a basic smoke test (manual)
./tools/run-smoke-tests.sh --target 400-redesign || true
```

## Example test expectations

A smoke test for the redesign should at minimum:

- Confirm the active symlink switches correctly
- Confirm the prompt initializes without duplicate widget errors
- Confirm guarded optional features do not error when missing

## Acceptance criteria

- Tests are runnable via top-level scripts described here
- Smoke/integration tests include environmental guards so they are safe to run locally
- Tests produce reproducible output suitable for CI gates

## Related

- Return to [000-index](000-index.md) or [Redesign Index](../000-index.md)
