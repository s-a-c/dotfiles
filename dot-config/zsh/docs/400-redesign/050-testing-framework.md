# 050 - Testing Framework

## Top

Status: Draft

Last updated: 2025-10-07

This document describes the testing framework and expectations for the ZSH REDESIGN project. It explains folder layout, test categories (unit, integration, smoke), how to run tests locally and in CI, and provides examples and acceptance criteria for tests used during development and release.

## Objectives

- Provide fast, reliable tests that validate configuration switching and core shell behaviour
- Offer smoke/integration checks that are safe to run locally and in CI
- Record reproducible test outputs suitable for gating promotions

## Folder layout and test types

Repository test layout (recommended):

- `tests/unit/` — fast, isolated tests for small helper functions and pure script logic
- `tests/integration/` — tests that exercise symlink switching, plugin loading, and environment interactions (may need temporary file system changes)
- `tests/smoke/` — minimal checks that confirm the configuration boots and critical features initialize
- `tools/` — test runner scripts and helpers (e.g., `run-smoke-tests.sh`, `run-unit-tests.sh`)

Naming conventions

- Unit tests: `tests/unit/*.test.zsh` or `tests/unit/test_*.sh`
- Integration tests: `tests/integration/*.test.zsh`
- Smoke tests: `tests/smoke/*.sh`

Prefix acceptance tests with `smoke-` to make them discoverable by simple runners.

## Test harnesses & example runners

Provide small, easy-to-run wrapper scripts that set minimal test environments and call underlying test scripts.

Example: `tools/run-smoke-tests.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
TEST_DIR="$ROOT_DIR/tests/smoke"

# Run each smoke script and stop on failure
for t in "$TEST_DIR"/*.sh; do
  echo "--- Running $t ---"
  bash "$t" || { echo "Smoke test failed: $t"; exit 1; }
done

echo "All smoke tests passed"
```

Example smoke test: `tests/smoke/smoke-switch-symlink.sh`

```bash
#!/usr/bin/env bash
# A safe smoke test: verify that the active symlink exists and points at a valid configuration
set -euo pipefail
if [[ -L ".zshenv.active" ]]; then
  target=$(readlink .zshenv.active)
  echo "active symlink -> $target"
  test -e "$target" || { echo "Target $target missing"; exit 2; }
  exit 0
else
  echo ".zshenv.active not present or not a symlink"
  exit 2
fi
```

Unit test example (zsh): `tests/unit/test_helpers.test.zsh`

```zsh
# Minimal zsh unit test for helper functions
autoload -U run-help
# ...setup test harness...

# simple assertion
expected="node-not-found"
result=$(zf::dev::which_node)
[[ "$result" == "$expected" ]] || { echo "Expected $expected, got $result"; return 1 }
```

## CI Integration

- Configure CI to run `tools/run-smoke-tests.sh` early (pre-deploy gate)
- Run unit tests in parallel for speed
- Keep integration tests optional (longer running) and gated behind an explicit CI stage
- Make tests idempotent and environment-cleaning — avoid persistent changes to the user's home or global state

CI sample pipeline stages:

- lint (markdown, shellcheck)
- unit-tests
- smoke-tests
- integration-tests (manual or nightly)

## Test data and fixtures

- Keep fixtures under `tests/fixtures/` and load them in tests using relative paths
- Use temporary directories (`mktemp -d`) for tests that mutate filesystem state
- Ensure cleanup in `trap 'rm -rf "$TMP"' EXIT` to avoid leaving state between runs

## Test acceptance criteria

- Unit tests: run in < 10s on developer machines; cover public helper behaviour
- Smoke tests: run in < 30s; assert critical symlinks and startup sequences
- Integration tests: provide deterministic checks for switching and plugin loading; may run in CI or as part of nightly runs

## Test output and reporting

- Tests should emit machine-readable summaries where possible (e.g., TAP, JUnit XML) so CI can surface failures
- Keep simple human-readable output for local runs

## Troubleshooting

- Failing to run tests locally:
  - Confirm required directories exist (e.g., `tests/smoke/`)
  - Ensure tests are executable: `chmod +x tests/smoke/*.sh`
  - Run a single test under `bash -x` to capture failure traces

- Tests interfering with user's configuration
  - Always run tests in isolated temporary directories and avoid touching real dotfiles unless explicitly running a migration script with prompts and backups

## Adding new tests

- Follow naming schemes and place tests in the appropriate `tests/` subfolder
- Keep tests small and focused (one assertion per test when practical)
- Add accompanying documentation in `tests/README.md` describing how to run and interpret tests

## Related

- Run smoke tests: `./tools/run-smoke-tests.sh --target 400-redesign`
- Return to [Redesign Index](../000-index.md) or [000-index](../000-index.md)
