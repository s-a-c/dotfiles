# ZLE Fix - Manual Testing Suite

## 🚨 Current Status: MANUAL BISECTION TESTING READY

**Date**: 2025-09-29
**Status**: Manual testing suite complete, ready for execution
**Impact**: ZLE widget registration failures in full .zshenv configuration

## 📋 Executive Summary

The ZSH configuration has **ZLE (Zsh Line Editor) widget registration failures** when using the full `.zshenv.full.backup` (961 lines). The issue manifests as:
- ZLE widget creation failures (`zle -N` commands fail)
- Potential startup hangs with full configuration
- Interactive functionality degradation

**Approach**: Manual bisection testing to identify the exact problematic sections in `.zshenv.full.backup`.

## 🔍 Problem Analysis

### ✅ What We Know Works

1. **Complete Minimal Config**: `.zshenv.minimal.complete` + `.zshrc.minimal` - ZLE functions work perfectly
2. **ZSH Installation**: ✅ Working (clean environment tests pass)
3. **ZLE System**: ✅ Functional (works with minimal configuration)
4. **Essential Functions**: `zf::debug` and other required functions now available

### ❌ What's Broken

**Full configuration** (`.zshenv.full.backup` 961 lines) causes:

- ZLE widget registration failures (`zle -N` commands fail)
- Potential startup hangs or timeouts
- Interactive functionality degradation
- Unknown specific root cause within the 961 lines

### 🔧 Testing Infrastructure Created

1. **Complete minimal config** - Working baseline with all essential functions
2. **Manual testing suite** - Progressive bisection scripts
3. **Result tracking system** - Structured documentation of findings
4. **Automated test runner** - Streamlined execution workflow

## 📊 Testing Strategy

**Progressive Bisection Method**: Add `return 0` statements at strategic points in `.zshenv.full.backup` to test increasingly larger portions:

1. **Baseline Test**: Confirm minimal config works (should pass)
2. **Full Initial Test**: Test complete .zshenv (may hang/fail)
3. **Bisection Points**: Test sections progressively:
   - Point 1 (~line 50): Emergency setup only
   - Point 2 (~line 130): Basic environment
   - Point 3 (~line 260): Debug system
   - Point 4 (~line 400): All flags
   - Point 5 (~line 580): Variable safety
   - Additional points as needed

## 🎯 Current State

### ✅ Ready for Testing

- Complete minimal configuration working
- All test scripts created and verified
- Result templates prepared
- Documentation complete

## 📁 Testing Files Structure

```text
docs/fix-zle/
├── README.md                    # This overview & current status
├── plan-of-attack.md           # Detailed testing strategy
├── test-setup.sh               # Initial setup and verification
├── test-baseline.sh            # Test minimal config (should work)
├── test-full-initial.sh        # Test full config (may hang)
├── test-bisect-point-1.sh      # Test emergency setup (~line 50)
├── test-bisect-point-2.sh      # Test basic environment (~line 130)
├── test-bisect-point-3.sh      # Test debug system (~line 260)
├── test-bisect-point-4.sh      # Test flags (~line 400)
├── test-bisect-point-5.sh      # Test variable safety (~line 580)
├── test-results-template.sh    # Create result recording templates
├── run-all-tests.sh           # Master test runner
└── results/                   # Test results directory
    ├── baseline-results.txt
    ├── full-initial-results.txt
    └── bisect-point-*-results.txt
```

## 🚀 How to Execute Testing

### Quick Start
```bash
cd /Users/s-a-c/dotfiles/dot-config/zsh
bash docs/fix-zle/run-all-tests.sh
```

### Step by Step
```bash
cd /Users/s-a-c/dotfiles/dot-config/zsh

# 1. Setup
bash docs/fix-zle/test-setup.sh
bash docs/fix-zle/test-results-template.sh

# 2. Test baseline (should work)
bash docs/fix-zle/test-baseline.sh

# 3. Test full config (may hang)
bash docs/fix-zle/test-full-initial.sh

# 4. If full config fails, run bisection tests
bash docs/fix-zle/test-bisect-point-1.sh
bash docs/fix-zle/test-bisect-point-2.sh
# Continue until you find the problematic section
```

## 🎯 Expected Outcomes

### Success Path
- **Baseline test**: ✅ Works perfectly (ZLE widgets: 300+, widget creation succeeds)
- **Full test**: ❌ Hangs or ZLE fails
- **Bisection**: Identifies exact problematic section for targeted fix

### Test Commands (run in each interactive zsh session)
```bash
echo 'Test description'
echo 'ZLE widgets available:' $(zle -la 2>/dev/null | wc -l || echo 0)
test_func() { echo 'test widget'; }
zle -N test_func && echo '✅ ZLE works' || echo '❌ ZLE broken'
realpath $(which grep) 2>/dev/null && echo '✅ grep works' || echo '❌ grep issue'
echo 'ZDOTDIR='$ZDOTDIR
exit
```

## 🔗 Key Files

- **Working baseline**: `.zshenv.minimal.complete` + `.zshrc.minimal`
- **Test subject**: `.zshenv.full.backup` (961 lines)
- **Working copy**: `.zshenv.full.bisect` (modified during testing)
- **Results**: `docs/fix-zle/results/*.txt`

---

**⚠️ READY TO PROCEED**: All testing infrastructure is complete. Execute the tests and report back results for analysis.

## ✅ Validation Snapshot (Updated 2025-10-01)

Purpose: Establish a traceable point-in-time record of core environment health, widget counts, and key feature markers after recent decision overrides (D3B, D6A, D8B, D10B, D11A, D18A).

### Summary Metrics
(Carapace styling decision & segment capture prototype integrated 2025-10-01)

Added Decisions (Condensed):
- Carapace styling retained (module `335-completion-styles.zsh`): manual cold timing delta ~ -10ms (no-style 0.89s vs with-style 0.88s), widgets stable at 417 (≥ baseline 416, historical acceptance ≥387). Harness fallback measurements: cold no-style 0.010828s, cold with-style 0.011227s (delta +0.000399s ≈ +0.40ms); warm no-style 0.010359s, warm with-style 0.010278s (delta -0.000081s ≈ -0.08ms) — all well within acceptance thresholds (|cold| ≤25ms, |warm| ≤10ms).
- Live segment capture prototype added (module `115-live-segment-capture.zsh`, opt-in via `ZF_SEGMENT_CAPTURE=1`) producing NDJSON at `${XDG_CACHE_HOME:-$HOME/.cache}/zsh/segments/live-segments.ndjson`.

Key New Markers:
- `_ZF_CARAPACE_STYLES=1` / `_ZF_CARAPACE_STYLE_MODE=default` (set unless disabled by `ZF_DISABLE_CARAPACE_STYLES=1`)
- `_ZF_SEGMENT_CAPTURE=1` / `_ZF_SEGMENT_CAPTURE_FILE=<path>` (only when capture enabled)

Operational Notes:
- Harness now falls back to synthetic timing line (`fallback=1`) if native `time` output is suppressed.
- Segment capture imposes near‑zero overhead when disabled (exports inert stubs).

- ZLE Widget Count (stabilized current baseline 416; historical min acceptance ≥387; prior snapshot 407)
- Completed Phases: 1–6
- Partial Phases: 7 (autopair enhanced test harness pending: D2)
- Performance Layer: Active (deferred & cached loading operational)
- Neovim Ecosystem: Active (profile-aware alias gating)

### Environment / Feature Markers (Expected States)

| Marker | Meaning | Expected Value | Notes |
|--------|---------|----------------|-------|
| `_ZF_PNPM` | pnpm detected (env or binary) | 1 or 0 | 1 if PNPM_HOME or pnpm found |
| `_ZF_PNPM_FLAGS` | Supplemental pnpm flags applied (D11) | 1 | 0 if user opt-out or pnpm absent |
| `_ZF_BOB_PATH` | Bob manager path integration active | 1 (if bob dir exists) | Path appended |
| `_ZF_BOB_ENV_SOURCED` | Bob env script sourced (D6) | 0/1 | Guarded; 1 only if env file present & not disabled |
| `_ZF_BOB_ALIAS_CLEARED` | Conflicting alias 'bob' removed (D18) | 0/1 | 1 only if alias existed and was cleared |
| `_ZF_ATUIN` | Atuin initialized | 1 (if atuin present) | Absent if atuin not installed |
| `_ZF_ATUIN_KEYBINDS` | Atuin keybindings enabled (D10) | 1 | 0 if user disabled via `ZF_HISTORY_ATUIN_DISABLE_KEYBINDS=1` |
 
## 📝 Validation Snapshot Automation & jq-Based Usage (Added 2025-10-01)

A lightweight helper script was introduced to append standardized validation snapshot lines to `plan-of-attack.md`:

Script path:
- `zsh/tools/append-validation-snapshot.sh`

Purpose:
- Capture: widget baseline (enforced 417), segment validation status, autopair PTY test status, archive integrity, and emergency fallback widget count.
- Produce a ledger of snapshots under the “Validation Hooks” section.

Baseline Policy:
- Fails (exit 2) if `widgets < 417` unless `--force --reason "<justification>"` is provided.
- Historical thresholds (416 baseline, 387 floor) are preserved only for rollback narrative—NOT for new snapshots.

### Basic Usage
```bash
# Append using artifacts gathered by CI or local aggregator run
zsh/tools/append-validation-snapshot.sh
```

### Dry Run (No File Modification)
```bash
zsh/tools/append-validation-snapshot.sh --dry-run
```

### Force Append Below Baseline (Requires Justification)
```bash
zsh/tools/append-validation-snapshot.sh --force --reason "Investigating transient plugin removal impact"
```

### Line-Only Output (for piping or external tooling)
```bash
zsh/tools/append-validation-snapshot.sh --line-only --dry-run
```

### Environment Overrides (Optional)
You can override auto-detected values:
```bash
WIDGETS=417 SEG_VALID=true AUTOPAIR=true ARCHIVE_OK=1 EMERGENCY_WIDGETS=417 \
 zsh/tools/append-validation-snapshot.sh --dry-run
```

### jq-Enhanced Workflow (Optional)
If you prefer richer parsing (jq is now an allowed soft dependency):

```bash
# Derive key fields from aggregator JSON (pretty or compact)
jq '{widgets:.widget_count,
    autopair_pty_passed,
    segments_valid,
    emergency_widgets: .emergency_widgets // "NA"}' artifacts/pre-chsh.json

# Feed overrides into the snapshot script:
eval "$(
 jq -r '"WIDGETS=\(.widgets) SEG_VALID=\(.segments_valid) AUTOPAIR=\(.autopair_pty_passed)"' artifacts/pre-chsh.json
)"
zsh/tools/append-validation-snapshot.sh
```

### Integrating in CI (Already in Layer Health Workflow)
Layer health workflow copies `layer-health.json` into `artifacts/pre-chsh.json` (stand‑in) then calls:
```bash
zsh/tools/append-validation-snapshot.sh --line-only
```

### Snapshot Line Format
```
YYYY-MM-DDTHH:MMZ widgets=417 segments_valid=true autopair_pty_passed=true archive_ok=1 emergency_widgets=417
```
Optional fields (only when forced):
```
... force_reason="Justification text"
```

### Failure Modes & Guidance
| Condition | Script Behavior | Resolution |
|-----------|-----------------|------------|
| widgets < 417 (no --force) | Exit 2 | Investigate regression; rerun after fix |
| Missing artifacts JSON | Falls back to environment / NA | Provide `artifacts/pre-chsh.json` or set env vars |
| Segment file absent | segments_valid may be false/unknown | Enable capture or skip if intentionally disabled |
| Archive mismatch | archive_ok=0 (warn) | Reconcile `.ARCHIVE/tools` vs manifest |

### Rationale
- Ensures auditable, append-only health history.
- Avoids jq hard dependency while supporting enrichment when present.
- Prevents silent acceptance of regressions.

(End Validation Snapshot Automation Section)
| `_ZF_PNPM_FLAGS_DISABLE` | User opt-out toggle (input) | unset or 0 | Set to 1 to disable supplemental flags |
| `ALIAS_LS_EZA` | eza replaced ls (navigation module) | 1 (if eza installed & not disabled) | 0 if opt-out or absent |
| `_ZF_BOB_ENV_SOURCED` | Bob env sourcing succeeded | 0/1 | Mirrors decision D6A |
| `EDITOR` / `VISUAL` | Neovim default integration | nvim | Set in phase 5 env module |

### Recommended One-Line Snapshot Command

Run in an interactive session after full init:

```/dev/null/snapshot.sh#L1-20
echo "=== fix-zle validation snapshot ($(date -u +%Y-%m-%dT%H:%M:%SZ)) ==="
echo "Widgets:" $(zle -la 2>/dev/null | wc -l || echo 0)
echo "Markers:"
for v in _ZF_PNPM _ZF_PNPM_FLAGS _ZF_BOB_PATH _ZF_BOB_ENV_SOURCED _ZF_BOB_ALIAS_CLEARED _ZF_ATUIN _ZF_ATUIN_KEYBINDS ALIAS_LS_EZA; do
  printf "  %-22s = %s\n" "$v" "${(P)v:-unset}"
done
echo "Core editors: EDITOR=$EDITOR VISUAL=$VISUAL"
echo "pnpm flags disable toggle: ${ZF_PNPM_FLAGS_DISABLE:-unset}"
command -v pnpm >/dev/null 2>&1 && echo "pnpm version: $(pnpm --version 2>/dev/null)" || echo "pnpm: not found"
command -v atuin >/dev/null 2>&1 && echo "atuin version: $(atuin --version 2>/dev/null | head -n1)" || echo "atuin: not found"
```

### Acceptance Criteria for This Snapshot

- Widget count remains ≥416 (no regression; historical guard still ≥387).
- `_ZF_PNPM_FLAGS=1` when pnpm present and user has not opted out.
- No unexpected unset errors under `set -u` (all guards are `${var:-}`).
- Marker exports visible to future CI / smoke harness (D15 fulfillment).

### Next Immediate Tasks (Post-Snapshot)

1. Enhance autopair behavioral test harness or formally accept heuristic (D2) for Phase 7 closure.
2. (Optional) Add `.nvimsbind` filter to suppress non-fatal `-c` lines in iTerm2 logs.

## 🛠 CI Workflow: Autopair & Widget Validation

A dedicated GitHub Actions workflow now validates the redesign’s optional Phase 7 autopair behavior and core widget stability.

**Workflow File**: `.github/workflows/fix-zle-autopair-ci.yml`  
**Triggers**: Push / PR changes touching `docs/fix-zle/**` or active redesign module directories.

### What It Does
- Runs the unified test aggregator (`docs/fix-zle/tests/aggregate-json-tests.sh`) with PTY harness enabled.
- Generates:
  - `autopair-report.json` (compact machine-readable)
  - `autopair-report.pretty.json` (human-friendly, pretty-printed)
  - `autopair-summary.txt` (key metrics)
- Captures (if enabled) widget post-run delta and placeholder instrumentation segment block (D14 future-ready).
- Fails the job only if aggregated status = `fail`.

### Key Metrics Captured
- `widget_count` (should remain ≥ current baseline 416)
- `widget_delta` (non-null only if post-smoke validation enabled)
- `autopair_present` (boolean)
- `autopair_pty_passed` (true/false/null depending on capability & result)
- Failure reasons array (`failures`) e.g. `["autopair_missing"]`

### Local Replication

Run full suite with PTY harness:
```bash
bash docs/fix-zle/tests/aggregate-json-tests.sh --run-pty --pretty
```

Require autopair (treat absence/failed PTY as failure):
```bash
bash docs/fix-zle/tests/aggregate-json-tests.sh --run-pty --require-autopair
```

Capture artifacts locally:
```bash
mkdir -p artifacts
bash docs/fix-zle/tests/aggregate-json-tests.sh \
  --run-pty \
  --output artifacts/autopair-report.json \
  --pretty
```

### Environment / Flags
| Variable | Effect |
|----------|--------|
| `RUN_AUTOPAIR_PTY=1` | Enables PTY harness inside `test-smoke.sh` |
| `AGG_REQUIRE_AUTOPAIR=1` | Forces failure if autopair absent/fails |
| `AGG_SEGMENT_FILE=path` | Embeds future segment instrumentation JSON (D14) |
| `AGG_RUN_POST_SMOKE=0` | Disable post-smoke widget delta capture |

### Interpreting Results
- `status: "ok"` with `autopair_present: true` and `autopair_pty_passed: true` indicates full behavioral validation passed.
- `widget_delta: 0` confirms no widget mutations during extended harness execution.
- Non-zero (positive) `widget_delta` should be investigated (possible transient widget registration side-effect).
- `autopair_pty_passed: null` usually means PTY prerequisites (python/pexpect) were missing; install `pexpect` to upgrade fidelity.

### Future (D14) Integration
Once segment instrumentation lands, provide a JSON file (e.g., `zsh/.performance/segments.json`) and pass:
```bash
bash docs/fix-zle/tests/aggregate-json-tests.sh --segment-file zsh/.performance/segments.json
```
The embedded result will appear under:
```
summary.instrumentation.segments
```

This section serves as the authoritative reference for CI-based autopair and widget regression validation.

## Performance & Instrumentation

High‑level goal: Provide measurable, reproducible, low‑overhead observability for shell startup and optional feature blocks, with auditable integrity of captured data and clear failure modes in CI.

### 1. Components Overview

| Component | Path / Tool | Purpose | Notes |
|-----------|-------------|---------|-------|
| Timing Harness | `docs/fix-zle/tests/carapace_timing_harness.sh` | Cold + warm startup timing & widget count deltas (with/without styling) | Emits `startup(<mode>,<pass>): ... fallback=1` synthetic lines when native reserved-word `time` output suppressed |
| Segment Capture (Live) | `.zshrc.d.00/115-live-segment-capture.zsh` | Opt‑in NDJSON event logging for init “segments” | Disabled by default; inert stubs when off |
| Aggregator | `docs/fix-zle/tests/aggregate-json-tests.sh` | Consolidates smoke + autopair + (optional) segment file into one JSON | Supports embedding + validation gating |
| Segment Validator | `docs/fix-zle/tests/validate-segments.sh` | Rule set R‑001..R‑016 (schema & semantic checks) | Uses `jq` if present; heuristic fallback otherwise |
| Integrity Canonicalizer | `zsh/tools/segment-canonicalize.sh` | Deterministic canonical JSON + sha256 digest + manifest | Supports JSON or NDJSON (`--ndjson`) |
| Autopair PTY Harness | `docs/fix-zle/tests/test-autopair-pty.sh` | Behavioral verification (pairs insertion) | Integrated via aggregator `--run-pty` |
| Abbreviation Packs | `190-optional-abbr.zsh`, `195-optional-brew-abbr.zsh` | Ergonomic expansion set (core + brew) | Core pack active unless disabled |

### 2. Environment Toggles & Markers

| Toggle / Env Var | Default | Effect | Exported Markers / Outcomes |
|------------------|---------|--------|-----------------------------|
| `ZF_DISABLE_CARAPACE_STYLES=1` | 0 | Skip Carapace styling module | `_ZF_CARAPACE_STYLES=0` |
| `ZF_SEGMENT_CAPTURE=1` | 0 | Enable live segment capture | `_ZF_SEGMENT_CAPTURE=1`, `_ZF_SEGMENT_CAPTURE_FILE` |
| `ZF_SEGMENT_CAPTURE_MIN_MS=<ms>` | 0 | Threshold: log only if elapsed ≥ value | Affects per-event inclusion |
| `ZF_SEGMENT_CAPTURE_DISABLE_RSS=1` | 0 | Disable RSS sampling | Omits `rss_*` keys |
| `ZF_SEGMENT_CAPTURE_ROTATE_MAX_BYTES` | 1048576 | Log rotation size (bytes) | Rotation triggers rename + numbered backups |
| `ZF_SEGMENT_CAPTURE_ROTATE_BACKUPS` | 3 | Retained rotated files | Suffix `.1`..`.N` |
| `ZF_SEGMENT_CAPTURE_DISABLE_TIME_FALLBACK=1` | 0 | Skip synthetic timing fallback | Elapsed may log as 0 if EPOCHREALTIME absent |
| `ZF_SEGMENT_CAPTURE_HOOKS=1` | 0 | Enable experimental pre/prompt hooks | May wrap starship & precmd |
| `RUN_AUTOPAIR_PTY=1` | 0 | Add PTY harness inside smoke | Aggregator autopair_pty JSON subtree |
| `AGG_REQUIRE_AUTOPAIR=1` | 0 | Hard fail if autopair missing/failing | Aggregator `status=fail` when unmet |
| `AGG_EMBED_SEGMENTS=1` | 0 | Allow segment embedding | Must also pass `--segment-file` |
| `AGG_REQUIRE_SEGMENTS=1` | 0 | Fail if embedded segments invalid | Adds `segments_validation_fail` failure |
| `ZF_HISTORY_ATUIN_DISABLE_KEYBINDS=1` | 0 | Skip Atuin keybindings | Atuin still loads if present |
| `ZF_DISABLE_ABBR=1` | 0 | Disable abbreviation system | `_ZF_ABBR=0` |
| `ZF_DISABLE_ABBR_PACK_CORE=1` | 0 | Skip core abbreviation pack | `_ZF_ABBR_PACK_CORE=0` |
| `ZF_DISABLE_ABBR_BREW=1` | 0 | Skip brew abbreviation pack | `_ZF_ABBR_BREW=0` |
| `ZF_SEGMENT_CAPTURE_DEBUG=1` | 0 | Verbose debug for capture module | Emits `[segment-capture]` lines |
| `ZF_ABBR_PACK_CORE=0` (legacy idea; replaced by skip var) | n/a | Legacy draft (do not use) | Use disable variable instead |

Widget baseline policy: treat `< 417` as regression (hard fail in CI). Historical acceptance floor (legacy): 387 (retained only for emergency rollback justification).

### Dual Baseline Context (Documented 2025-10-01)

| Context | Description | Typical Count | Enforcement Role | Notes |
|---------|-------------|---------------|------------------|-------|
| Core Harness (clean subshell) | Invoked with `zsh --no-rcs --no-globalrcs` and manual layer sourcing only (no plugin manager function inherited) | 409 | Informational only | Omits plugin-managed widgets (autopair, autosuggestions, fzf bindings, abbr). Not a regression criterion. |
| Full Interactive | Normal interactive shell with full plugin manager + all phase modules | ≥417 | Hard baseline (regression if <417) | Governs CI & Green Light acceptance. |
| Emergency Fallback | `.zshrc.emergency` safety profile | ≥387 | Rollback floor (historical floor only) | Used strictly for disaster recovery justification; never lowers forward baseline. |

Policy Summary:
- Only the Full Interactive baseline (≥417) is enforced for pass/fail gating.
- Core Harness count (409) reflects intentional “core-only” measurement when plugin manager is absent; never used as acceptance threshold.
- Emergency floor (387) remains for rollback narrative only and must not be used to justify forward regression.

### 3. Timing Harness Usage

Cold + warm measurement (with style vs no-style):
```/dev/null/timing-example.sh#L1-12
bash docs/fix-zle/tests/carapace_timing_harness.sh RUN_WARM=1 ITERATIONS=3 \
  | grep -E 'startup\\('
```
Result lines (fallback example):
```/dev/null/timing-output.txt#L1-3
startup(no-style,cold): 0.010828s ... fallback=1
startup(with-style,cold): 0.011227s ... fallback=1
startup(no-style,warm): 0.010359s ... fallback=1
```
Interpretation: Compare `with-style` vs `no-style` deltas; acceptance: |cold| ≤ 25ms, |warm| ≤ 10ms.

### 4. Enabling Segment Capture

Add to shell session:
```/dev/null/enable-seg.sh#L1-5
export ZF_SEGMENT_CAPTURE=1
export ZF_SEGMENT_CAPTURE_MIN_MS=0
zsh -ic 'echo SEG_FILE=$_ZF_SEGMENT_CAPTURE_FILE; sleep 0.05'
```
File path defaults to:
```
${XDG_CACHE_HOME:-$HOME/.cache}/zsh/segments/live-segments.ndjson
```

Typical NDJSON event structure:
```/dev/null/segment-sample.ndjson#L1-1
{"type":"segment","version":1,"segment":"init:starship","elapsed_ms":7.312,"ts":"2025-10-01T12:34:56Z","pid":12345,"shell":"zsh","layer_set":"00","rc":"0","rss_start_kb":25120,"rss_end_kb":25184,"rss_delta_kb":64}
```

### 5. Embedding & Validating Segments (Aggregator)

Run aggregator with segment embedding:
```/dev/null/agg-with-segments.sh#L1-10
export ZF_SEGMENT_CAPTURE=1
SEG_FILE="$HOME/.cache/zsh/segments/live-segments.ndjson"
bash docs/fix-zle/tests/aggregate-json-tests.sh \
  --run-pty \
  --segment-file "$SEG_FILE" \
  --embed-segments \
  --require-segments-valid \
  --pretty \
  --output artifacts/aggregate-with-segments.json
```
Result JSON `summary.instrumentation` block (excerpt):
```/dev/null/agg-summary.json#L1-8
{
  "segments_enabled":1,
  "segments_file":".../live-segments.ndjson",
  "segments_valid":true,
  "segments":[ { "type":"segment", "segment":"init:starship", ... } ]
}
```

### 6. Segment Validation (Direct)

Strict validation (fail on advisory warnings):
```/dev/null/validate-segments.sh#L1-3
bash docs/fix-zle/tests/validate-segments.sh --strict "$SEG_FILE"
```

### 7. Integrity / Canonicalization

Canonicalize & hash NDJSON:
```/dev/null/canonicalize.sh#L1-6
zsh/tools/segment-canonicalize.sh "$SEG_FILE" --ndjson --gzip
cat "$SEG_FILE.canonical.sha256" 2>/dev/null || cat "$SEG_FILE.canonical.json.sha256"
```

Manifest example:
```/dev/null/manifest-example.json#L1-10
{
  "canonical_file": "/abs/path/live-segments.ndjson.canonical.json",
  "gzip": true,
  "line_count": 42,
  "ndjson": true,
  "sha256": "sha256:2c3d...<64 hex>...",
  "source": "/abs/path/live-segments.ndjson",
  "timestamp": "2025-10-01T17:42:11Z",
  "tool": "segment-canonicalize.sh",
  "version": 1
}
```

### 8. Quick Diagnostic & Snapshot Commands

Single-line snapshot:
```/dev/null/snapshot-oneliner.sh#L1-6
zsh -ic 'echo W=$(zle -la | wc -l); \
  echo STYLE=$_ZF_CARAPACE_STYLES SEG=$_ZF_SEGMENT_CAPTURE ABR=${_ZF_ABBR:-0} CORE=${_ZF_ABBR_PACK_CORE:-0} BREW=${_ZF_ABBR_BREW:-0}; \
  echo AUTOPAIR_PTY=${RUN_AUTOPAIR_PTY:-0}'
```

Extended snapshot:
```/dev/null/snapshot-extended.sh#L1-14
zsh -ic '
echo "=== fix-zle snapshot $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
echo "Widgets: $(zle -la | wc -l)"
for v in _ZF_CARAPACE_STYLES _ZF_SEGMENT_CAPTURE _ZF_SEGMENT_CAPTURE_FILE _ZF_ABBR _ZF_ABBR_PACK_CORE _ZF_ABBR_BREW \
         _ZF_ABBR_BREW_COUNT _ZF_STARSHIP_INIT_MS; do
  printf "%-25s = %s\n" "$v" "${(P)v:-unset}"
done
'
```

### 9. Failure Modes & CI Gates

| Gate | Condition | Action |
|------|-----------|--------|
| Widget Baseline | `widget_count < 417` | Fail workflow |
| Segment Validity | `segments_enabled=1 && segments_valid != true` | Fail workflow |
| Autopair Required (opt) | `AGG_REQUIRE_AUTOPAIR=1` and autopair missing/fail | Fail workflow |

### 10. Future Expansion (D14 / Post Phase 7)

Planned (not yet active):
- Full vs Light capture modes (memory & nesting classification depth)
- Segment parent/child timing aggregation & budget enforcement
- Compression + archival policy for rotated segment logs
- Histogram of prompt assembly deltas across sessions

---

Reference Implementation Status:
- All components except “Full mode” instrumentation live.
- CI workflow extended to enforce widget baseline & segment validation.

This section is authoritative; update simultaneously with any new toggle, validator rule addition, or structural change to the aggregator JSON schema.

3. (Optional) Introduce widget baseline diff automation in CI.
4. (Optional) Segment instrumentation (D14) after Phase 7 finalization.

---
(Validation snapshot appended per Decision D15A.)
