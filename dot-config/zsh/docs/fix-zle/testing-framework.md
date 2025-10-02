# Testing Framework & Debug Tools

## 🧪 Available Debug Tools

### 1. ZLE Test Function
**Purpose**: Verify ZLE widget registration capability

```bash
test_zle() {
    local context="${1:-general}"
    local test_func="_zle_test_$$_$(date +%s)"

    # Create unique test function
    eval "${test_func}() { echo 'zle test'; }"

    # Try to register as ZLE widget
    if zle -N "$test_func" 2>/dev/null; then
        zle -D "$test_func" 2>/dev/null || true
        unfunction "$test_func" 2>/dev/null || true
        echo "✅ ZLE: OK ($context)"
        return 0
    else
        unfunction "$test_func" 2>/dev/null || true
        echo "❌ ZLE: BROKEN ($context)"
        return 1
    fi
}
```

### 2. Debug Hook (.zshenv.local)
**Purpose**: Intercept `load-shell-fragments` and test ZLE after each file

**Location**: `dot-config/zsh/.zshenv.local`

**Usage**:
```bash
DEBUG_LOAD_FRAGMENTS=1 ZDOTDIR="$PWD" zsh -i
```

**Features**:
- Tests ZLE before and after each directory
- Tests ZLE after each individual file
- Shows file loading success/failure
- Displays problematic file contents
- Provides detailed error context

### 3. Emergency Configuration
**Purpose**: Known working baseline for comparison

**Location**: `dot-config/zsh/.zshrc.emergency`

**Usage**:
```bash
ZDOTDIR="$PWD" zsh -c "source .zshrc.emergency; test_zle"
```

## 🔬 Testing Methodologies

### Binary Search Testing (Enhanced for Approach A)
**Purpose**: Isolate problematic sections systematically with PATH consolidation support

```bash
# Test sections of .zshenv individually
test_zshenv_section() {
    local section="$1"
    local start_line="$2"
    local end_line="$3"

    echo "Testing .zshenv lines $start_line-$end_line ($section)"

    # Create temporary minimal .zshenv with only this section
    head -n $start_line .zshenv > .zshenv.test
    sed -n "${start_line},${end_line}p" .zshenv >> .zshenv.test
    tail -n +$((end_line + 1)) .zshenv >> .zshenv.test

    # Test with this section
    ZDOTDIR="$PWD" zsh -c "source .zshenv.test; test_zle '$section'"

    rm .zshenv.test
}

# Test .zshenv with specific PATH sections disabled
test_zshenv_without_paths() {
    local test_name="$1"
    echo "Testing: $test_name"

    # Create .zshenv with PATH sections commented out
    sed -e '45,59s/^/# /' -e '90,92s/^/# /' -e '841,863s/^/# /' .zshenv > .zshenv.no_paths

    ZDOTDIR="$PWD" zsh -c "source .zshenv.no_paths; test_zle '$test_name'"

    rm .zshenv.no_paths
}

# Test .zshenv with only specific PATH section enabled
test_zshenv_with_path_section() {
    local test_name="$1"
    local start_line="$2"
    local end_line="$3"

    echo "Testing: $test_name (lines $start_line-$end_line)"

    # Create .zshenv with all PATH sections disabled except the specified one
    sed -e '45,59s/^/# /' -e '90,92s/^/# /' -e '841,863s/^/# /' .zshenv | \
    sed -e "${start_line},${end_line}s/^# //" > .zshenv.path_test

    ZDOTDIR="$PWD" zsh -c "source .zshenv.path_test; test_zle '$test_name'"

    rm .zshenv.path_test
}

# Test .zshenv with multiple PATH sections (comma-separated ranges)
test_zshenv_with_path_sections() {
    local test_name="$1"
    local ranges="$2"  # Format: "45-59,90-92,841-863"

    echo "Testing: $test_name (ranges: $ranges)"

    # Start with all PATH sections disabled
    sed -e '45,59s/^/# /' -e '90,92s/^/# /' -e '841,863s/^/# /' .zshenv > .zshenv.multi_path

    # Enable specified ranges
    IFS=',' read -ra RANGE_ARRAY <<< "$ranges"
    for range in "${RANGE_ARRAY[@]}"; do
        IFS='-' read -ra LINES <<< "$range"
        start_line="${LINES[0]}"
        end_line="${LINES[1]}"
        sed -i.bak -e "${start_line},${end_line}s/^# //" .zshenv.multi_path
        rm .zshenv.multi_path.bak 2>/dev/null || true
    done

    ZDOTDIR="$PWD" zsh -c "source .zshenv.multi_path; test_zle '$test_name'"

    rm .zshenv.multi_path
}
```

### Incremental Testing
**Purpose**: Add components one by one to find breaking point

```bash
# Start with minimal and add components
test_incremental() {
    local components=("xdg" "zdotdir" "path" "debug" "params" "zgenom")

    for component in "${components[@]}"; do
        echo "Testing with $component added..."
        # Implementation depends on component structure
        test_component "$component"
    done
}
```

### Environment Isolation Testing
**Purpose**: Test in various controlled environments

```bash
# Clean environment test
test_clean_env() {
    env -i HOME="$HOME" USER="$USER" TERM="$TERM" PATH="$PATH" \
        zsh -c "test_zle 'clean-env'"
}

# Minimal environment test
test_minimal_env() {
    ZDOTDIR="$PWD" zsh -c "
        unsetopt nounset 2>/dev/null || true
        test_zle 'minimal-env'
    "
}

# No-config test
test_no_config() {
    zsh -f -c "
        zmodload zsh/zle
        test_zle 'no-config'
    "
}
```

## 📊 Test Result Analysis

### Success Patterns
```bash
# Expected output for working ZLE:
✅ ZLE: OK (context)

# Expected for working emergency config:
[EMERGENCY] ✅ ZLE system working
[EMERGENCY] ✅ Starship loaded
[EMERGENCY] 🚀 Emergency configuration loaded successfully
```

### Failure Patterns
```bash
# ZLE failure:
❌ ZLE: BROKEN (context)

# Variable dump (corruption indicator):
!=0
'#'=1
'$'=85926
...

# Completion errors:
compinit:557: zle: function definition file not found

# Parameter errors:
zgenom-load:17: 2: parameter not set
```

## 🛠️ Diagnostic Scripts

### Quick ZLE Test
```bash
#!/usr/bin/env zsh
# quick-zle-test.zsh
echo "Quick ZLE Test"
test-func() { echo "test"; }
if zle -N test-func 2>/dev/null; then
    echo "✅ ZLE: Working"
    zle -D test-func 2>/dev/null
else
    echo "❌ ZLE: Broken"
fi
unfunction test-func 2>/dev/null || true
```

### Environment Dump
```bash
#!/usr/bin/env zsh
# env-dump.zsh
echo "=== Environment Diagnostic ==="
echo "ZSH Version: $ZSH_VERSION"
echo "ZDOTDIR: ${ZDOTDIR:-unset}"
echo "Shell Options:"
setopt | head -10
echo "Modules:"
zmodload -L | grep -E "(zle|complist)"
echo "Parameters:"
typeset | grep -E "^(ARGC|HISTSIZE|FUNCNEST)=" | head -5
```

### Module Test
```bash
#!/usr/bin/env zsh
# module-test.zsh
echo "=== Module Loading Test ==="
echo "Loading ZLE module..."
if zmodload zsh/zle 2>/dev/null; then
    echo "✅ ZLE module loaded"
else
    echo "❌ ZLE module failed"
fi

echo "Loading complist module..."
if zmodload zsh/complist 2>/dev/null; then
    echo "✅ complist module loaded"
else
    echo "❌ complist module failed"
fi
```

## 📋 Test Execution Framework

### Phase 1 Tests (Environment Isolation - Approach A)
```bash
# Run all Phase 1 tests with consolidated PATH testing
run_phase1_tests() {
    echo "=== Phase 1: Environment Isolation Tests (Approach A) ==="

    # Baseline tests
    test_clean_env
    test_minimal_env
    test_no_config

    echo "Testing .zshenv sections (preserving file structure)..."

    # Test individual sections with priority indicators
    test_zshenv_section "Critical Startup" 1 59        # Includes PATH #1
    test_zshenv_section "XDG & ZDOTDIR" 61 93          # Includes PATH #2
    test_zshenv_section "ZDOTDIR Canonicalization" 96 127
    test_zshenv_section "Debug Policy [HIGH]" 147 245  # HIGH PRIORITY
    test_zshenv_section "Environment & Tools" 246 408
    test_zshenv_section "Parameter Safety [CRITICAL]" 409 500  # HIGHEST PRIORITY
    test_zshenv_section "Zgenom Config" 794 840
    test_zshenv_section "Final PATH & History" 841 933 # Includes PATH #3

    # Special PATH consolidation tests
    echo "Testing PATH manipulation consolidation..."
    test_path_consolidation
}

# PATH-specific testing function
test_path_consolidation() {
    echo "--- PATH Consolidation Analysis ---"

    # Test 1: All PATH manipulations disabled
    test_zshenv_without_paths "No PATH manipulations"

    # Test 2: Only first PATH manipulation (lines 45-59)
    test_zshenv_with_path_section "PATH #1 only" 45 59

    # Test 3: First + second PATH (lines 45-59, 90-92)
    test_zshenv_with_path_sections "PATH #1+#2" "45-59,90-92"

    # Test 4: All PATH manipulations (cumulative effect)
    test_zshenv_with_path_sections "All PATH sections" "45-59,90-92,841-863"
}
```

### Phase 2 Tests (Binary Search)
```bash
# Systematic binary search
run_phase2_tests() {
    echo "=== Phase 2: Binary Search Tests ==="

    # Test halves of .zshenv
    local total_lines=$(wc -l < .zshenv)
    local mid=$((total_lines / 2))

    echo "Testing first half (1-$mid)..."
    test_zshenv_section "First Half" 1 $mid

    echo "Testing second half ($((mid+1))-$total_lines)..."
    test_zshenv_section "Second Half" $((mid+1)) $total_lines
}
```

### Automated Test Runner
```bash
#!/usr/bin/env bash
# run-zle-tests.sh

cd "$(dirname "$0")"
source testing-framework.md  # Source test functions

echo "🧪 ZLE Investigation Test Suite"
echo "==============================="

# Ensure emergency mode is available
if [[ ! -f .zshrc.emergency ]]; then
    echo "❌ Emergency config not found!"
    exit 1
fi

# Run test phases
run_phase1_tests 2>&1 | tee test-results-phase1.log
run_phase2_tests 2>&1 | tee test-results-phase2.log

echo "✅ Test suite complete. Check log files for results."
```

## 🎯 Test Interpretation Guide

### Positive Results
- **ZLE: OK** - System functioning at this point
- **Module loaded** - Core functionality available
- **No variable dump** - Environment not corrupted

### Negative Results
- **ZLE: BROKEN** - System failed at this point
- **Variable dump present** - Environment corruption detected
- **compinit errors** - Completion system compromised
- **Parameter errors** - Variable handling issues

### Next Steps Based on Results
- **If Phase 1 isolates issue** → Proceed to targeted fix
- **If binary search narrows down** → Focus on specific section
- **If no clear culprit** → Investigate interaction effects
- **If emergency mode fails** → Check ZSH installation

## 📝 Documentation Standards

### Test Result Format
```
Test: [test-name]
Environment: [conditions]
Result: [✅/❌]
Output: [relevant output]
Analysis: [interpretation]
Next: [recommended action]
```

### Log File Organization
- `test-results-phase1.log` - Environment isolation results
- `test-results-phase2.log` - Binary search results
- `debug-session-YYYYMMDD.log` - Interactive debug sessions
- `fix-attempts.log` - Record of fix attempts and results

## 🔧 Autopair Advanced Harness & Aggregator (Phase 7 / Decision D2)

To satisfy Decision D2 (enhanced autopair validation) the project now includes a tiered testing approach:

### Components
- `docs/fix-zle/tests/test-autopair.sh`  
  Basic presence + heuristic simulation (non‑PTY). Always fast; falls back to presence status.
- `docs/fix-zle/tests/test-autopair-pty.sh`  
  Advanced PTY harness using `pexpect` (if available) to exercise real ZLE editing behavior for:
  - Parenthesis insertion → expects `()`
  - Quote insertion → expects `""`
  - Backspace pair deletion heuristic
  Degrades gracefully (presence-only) if Python/pexpect unavailable.
- `docs/fix-zle/tests/aggregate-json-tests.sh`  
  Unified JSON aggregator for CI: runs smoke test (optionally with PTY), the basic harness, and the PTY harness, merging outputs into a single structured JSON document.

### Smoke Test Integration
`test-smoke.sh` now (baseline widgets=416) conditionally invokes the PTY harness when:
```
RUN_AUTOPAIR_PTY=1 test-smoke.sh --json
```
If executed, it appends a line beginning with:
```
#AUTOPAIR_PTY_JSON { ...raw JSON... }
```
The aggregator consumes this if a direct PTY run is skipped or as a redundancy check.

### Aggregator Usage
Run all (with PTY + basic) and pretty-print:
```
docs/fix-zle/tests/aggregate-json-tests.sh --run-pty --pretty
```
Require autopair (fail build if absent/failing):
```
docs/fix-zle/tests/aggregate-json-tests.sh --require-autopair --run-pty
```
Skip basic (only smoke + PTY):
```
docs/fix-zle/tests/aggregate-json-tests.sh --run-pty --no-basic-autopair
```
Write to file (quiet):
```
docs/fix-zle/tests/aggregate-json-tests.sh --run-pty --output artifacts/autopair-report.json --quiet
```

### Environment Flags
- `RUN_AUTOPAIR_PTY=1` (used by `test-smoke.sh`)
- `AGG_RUN_PTY=1` (equivalent to `--run-pty` for aggregator)
- `AGG_REQUIRE_AUTOPAIR=1` (equivalent to `--require-autopair`)

### PTY Harness Requirements
- `python3` (or `python`) in PATH
- `pexpect` importable (`pip install pexpect` if missing)
If unavailable: harness reports capability downgrade (`"capabilities":{"pty":false,"pexpect":false}`) and treats presence-only as pass (unless required).

### JSON Structures (Summaries)

Smoke test (excerpt):
```
{
  "status":"OK",
  "widgets":416,
  "autopair":1,
  "autopair_widgets":[ "...widget names..." ],
  "terminal": { "warp":0,"wezterm":0,"ghostty":0,"kitty":0 }
}
```

PTY harness:
```
{
  "status":"pass",
  "present":1,
  "detection":{"variant":"simple","widgets":["simple-autopair-insert", ...]},
  "capabilities":{"pty":true,"pexpect":true},
  "summary":{"total":3,"passed":3,"inconclusive":0},
  "tests":[
    {"name":"paren_pair_insert","attempted":true,"passed":true,...},
    {"name":"quote_pair_insert","attempted":true,"passed":true,...},
    {"name":"backspace_pair_delete","attempted":true,"passed":true,...}
  ]
}
```

Aggregator final (top-level):
```
{
  "status":"ok"|"fail",
  "timestamp":"<UTC>",
  "tests":{
    "smoke":{...},
    "autopair_basic":{...}|null,
    "autopair_pty":{...}|null
  },
  "summary":{
    "widget_count":416,
    "autopair_present":true,
    "autopair_pty_passed":true|false|null,
    "failures":[...]
  }
}
```

### Failure Semantics
- Missing autopair + `--require-autopair` → `autopair_missing` failure.
- Basic harness `"status":"fail"` when required → `autopair_basic_fail`.
- PTY harness `"status":"fail"` with `--run-pty` and required → `autopair_pty_fail`.
- Smoke hard failure or JSON absence → `smoke_fail`.

### Operational Guidance
Use the basic harness in fast CI lanes (low overhead) and enable PTY runs in nightly or pre‑merge validation to catch regressions in real widget behavior. Aggregator output can be archived or diffed between runs for longitudinal tracking (e.g., future D14 instrumentation integration).

### Future Extensions (Planned / Deferred)
- Segment startup instrumentation (D14) attachable under `tests.segment` subtree in aggregator JSON.
- Widget delta diff pre/post optional enhancements.
- Expanded multi-character autopair scenario set (braces, mixed quotes) once PTY reliability baseline is confirmed.

