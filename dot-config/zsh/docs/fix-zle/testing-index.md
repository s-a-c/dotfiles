# Redesign Testing Index

Central reference for validation scripts supporting the ZSH redesign ("fix-zle" initiative). Each script is self-contained and safe to run from the repository root (or its own directory). All scripts avoid mutating user state beyond transient subshell environments.

## Scripts Overview

| Script | Mandatory | Purpose | Key Checks | Exit 0 Guarantees |
|--------|-----------|---------|-----------|-------------------|
| `test-smoke.sh` | Yes | Core redesign health snapshot | ZLE widget count, prompt guard, tool presence, terminal flags, autopair, starship timing | Widget baseline maintained (≥387) & sourcing succeeded |
| `test-phase4.sh` | No (phase historical) | Productivity layer regression check | Widgets, optional tool detection, alias state | Phase 4 modules still nounset & regression-free |
| `test-terminal-integration.sh` | No | Simulated terminal env exports | Warp/WezTerm/Ghostty/Kitty env flags | Each simulated profile exports expected variables |
| `test-all.sh` | Yes (wrapper) | Aggregated runner | Runs smoke + optional scripts | Prints `ALL_OK` token when all mandatory tests pass |

## 1. Smoke Test (`test-smoke.sh`)

```bash
./docs/fix-zle/test-smoke.sh
```

Outputs lines like:

```text
PASS: smoke (widgets=407 prompt_guard=1)
HAVE_nvim=1
HAVE_starship=1
STARSHIP_INIT_MS=42
HAVE_AUTOPAIR=1
AUTOPAIR_WIDGET=autopair-insert
```
Non-fatal warnings are emitted to stderr (e.g., unusually high starship init time).

## 2. Terminal Integration (`test-terminal-integration.sh`)

Simulates multiple `TERM_PROGRAM`/`TERM` combinations:

```bash
./docs/fix-zle/test-terminal-integration.sh
```

Sample output:

```text
CASE warp       -> WARP_IS_LOCAL_SHELL_SESSION=1
CASE wez        -> WEZTERM_SHELL_INTEGRATION=1
CASE ghost      -> GHOSTTY_SHELL_INTEGRATION=1
CASE kitty      -> KITTY_SHELL_INTEGRATION=enabled
CASE iterm      -> (no flags)
PASS: terminal integration flags behave as expected
```

## 3. Phase 4 Regression (`test-phase4.sh`)

Historical validation retained for targeted checks:

```bash
./docs/fix-zle/test-phase4.sh
```
Use when modifying any Phase 4 productivity module.

## 4. Aggregated Runner (`test-all.sh`)

```bash
./docs/fix-zle/test-all.sh            # Normal mode
./docs/fix-zle/test-all.sh --strict   # Treat optional tests as mandatory
./docs/fix-zle/test-all.sh --json     # JSON output (stdout)
./docs/fix-zle/test-all.sh --json --strict
```
Outputs a categorized summary and `ALL_OK` token if mandatory tests pass.

### JSON Output

Example:

```json
{"status":"OK","strict":false,"pass":["smoke","terminal"],"warn":[],"fail":[]}
```

Fields:
- `status`: `OK` or `FAIL`
- `strict`: boolean indicating `--strict` mode
- `pass` / `warn` / `fail`: arrays of labels

Intended for CI pipelines or machine parsing.

## Environment Variables

| Variable | Purpose | Effect |
|----------|---------|--------|
| `ZF_DISABLE_EZA_ALIAS=1` | Opt out of `ls -> eza` alias | Sets `ALIAS_LS_EZA=0` in tests |
| `ZF_DISABLE_NVIM=1` | Skip Neovim module | Removes profile aliases & dispatcher |
| `ZF_NEOVIM_DEBUG=1` | Emit debug info from Neovim env | Adds debug line (ignored by tests) |

## Metrics & Instrumentation

- `_ZF_STARSHIP_INIT_MS` captured on prompt init (exposed when starship present).
- Autopair widget export lines: `AUTOPAIR_WIDGET=...` for inspection.
- Starship timing persistent log (if metrics dir exists and not disabled via `ZF_DISABLE_METRICS=1`):
	- Appended to `artifacts/metrics/starship-init.log` as TSV: `ISO8601_UTC<TAB>starship_init_ms<TAB><value>`
	- Safe no-op if directory absent or unwritable.

## Failure Triage Tips

| Symptom | Likely Cause | Action |
|---------|--------------|--------|
| `FAIL: widget regression` | New module disrupted ZLE sequence | Reproduce interactively; isolate last added file |
| Missing `HAVE_*` tool unexpectedly | PATH not updated early enough | Check ordering / path exports in corresponding module |
| Starship timing unusually high (>5000ms warn) | Disk IO / network segment | Re-run; if persistent, profile starship config |
| Autopair reported present, no widgets | Plugin load race / plugin missing | Confirm plugin in plugin manager cache or re-run with verbose load |

## Adding New Tests

1. Create a script named `test-<feature>.sh` under `docs/fix-zle/`.
2. Ensure `#!/usr/bin/env bash` + `set -euo pipefail`.
3. Keep output concise; emit a single `PASS:` line on success.
4. Update this index and (optionally) wire into `test-all.sh`.

## Roadmap for Future Enhancements

- Optional coverage: prompt segment enumeration & timing histogram.
- Add JSON output mode for CI parsing.
- Integrate with potential `make test` alias wrapper.

---
Maintained as part of Phase 6+ validation hardening. Update when adding or modifying test scripts.
