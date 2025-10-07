# 050 - Testing Framework

Status: STUB

This document will describe the testing framework for the ZSH REDESIGN project, including test structure, harnesses, and execution guidance.

Suggested content:

- Folder layout for tests (unit, integration, smoke)
- Test execution commands and expected outputs
- Example smoke test: verify symlink switching and basic prompt readiness

Quick manual validation snippet:

```bash
# Validate test harness presence
[ -d tests ] && echo "tests folder present" || echo "tests folder missing"
# Run a basic smoke test (manual)
./tools/run-smoke-tests.sh --target 400-redesign || true
```

Return to [000-index](000-index.md) or [Redesign Index](../000-index.md)
