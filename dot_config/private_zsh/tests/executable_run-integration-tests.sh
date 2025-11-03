#!/usr/bin/env zsh
# .config/zsh/tests/run-integration-tests.sh
# Integration test runner - runs the core integration checks used for the
# zsh redesign pre-push validation:
#   - compinit single-run (integration)
#   - post-plugin compinit single-run (redesign path)
#   - prompt single emission
#   - perf monotonic lifecycle (performance category - included for stage gating)
#
# The script is intentionally small and deterministic:
#   * Resolves ZDOTDIR the same way other test scripts do
#   * Ensures test files are executable
#   * Runs each test with a per-test timeout and emits a concise summary
#
# Usage:
#   ./dot-config/zsh/tests/run-integration-tests.sh [--timeout-secs N] [--verbose]
set -euo pipefail

# Resolve ZDOTDIR consistent with test scripts
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
[[ -f "${ZDOTDIR}/.zshenv" ]] && source "${ZDOTDIR}/.zshenv"

# Helpers
zsh_debug_echo() {
  if [[ "${ZSH_DEBUG:-0}" -ne 0 || "${verbose:-0}" -ne 0 ]]; then
    printf '%s\n' "$*" >&2
  fi
}

# Default timeout per test (seconds) can be overridden by env or CLI
DEFAULT_TIMEOUT_SECS="${INTEGRATION_TEST_TIMEOUT:-60}"
verbose=0
timeout_secs="$DEFAULT_TIMEOUT_SECS"

show_help() {
  cat <<EOF
run-integration-tests.sh - Run integration tests used for pre-push validation.

Usage:
  $0 [OPTIONS]

Options:
  --timeout-secs N   Per-test timeout in seconds (default: $DEFAULT_TIMEOUT_SECS)
  -v, --verbose      Enable verbose output
  -h, --help         Show this help
EOF
}

# Simple portable timeout runner
# Usage: run_with_timeout <seconds> <cmd> [args...]
run_with_timeout() {
  emulate -L zsh
  set -o nounset
  local seconds="$1"; shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$seconds" "$@"
    return $?
  fi
  if command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$seconds" "$@"
    return $?
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$seconds" "$@" <<'PY' 2>/dev/null
import sys, subprocess, time, os
t = int(sys.argv[1])
cmd = sys.argv[2:]
try:
    p = subprocess.Popen(cmd)
    p.wait(timeout=t)
    sys.exit(p.returncode)
except subprocess.TimeoutExpired:
    try:
        p.terminate()
        time.sleep(0.2)
    except Exception:
        pass
    try:
        p.kill()
    except Exception:
        pass
    sys.exit(124)
PY
    return $?
  fi

  # Fallback: naive background runner with sleep loop
  "$@" & local pid=$!
  local waited=0
  while kill -0 $pid 2>/dev/null; do
    sleep 1
    waited=$(( waited + 1 ))
    if (( waited >= seconds )); then
      kill -TERM $pid 2>/dev/null || true
      sleep 0.2
      kill -KILL $pid 2>/dev/null || true
      wait $pid 2>/dev/null || true
      return 124
    fi
  done
  wait $pid
  return $?
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --timeout-secs)
      timeout_secs="$2"; shift 2;;
    -v|--verbose)
      verbose=1; shift;;
    -h|--help)
      show_help; exit 0;;
    *)
      echo "Unknown option: $1" >&2; show_help; exit 2;;
  esac
done

# Define the tests to run (paths relative to ZDOTDIR)
tests=(
  "$ZDOTDIR/tests/integration/test-compinit-single-run.zsh"
  "$ZDOTDIR/tests/integration/test-postplugin-compinit-single-run.zsh"
  "$ZDOTDIR/tests/integration/test-prompt-ready-single-emission.zsh"
  "$ZDOTDIR/tests/performance/test-perf-monotonic-lifecycle.zsh"
)

zsh_debug_echo "ZDOTDIR = $ZDOTDIR"
zsh_debug_echo "Per-test timeout = ${timeout_secs}s"
zsh_debug_echo "Tests to run:"
for t in "${tests[@]}"; do zsh_debug_echo "  - $t"; done

# Ensure test files exist and are executable
for t in "${tests[@]}"; do
  if [[ ! -f "$t" ]]; then
    echo "ERROR: test file not found: $t" >&2
    exit 2
  fi
  chmod +x "$t" 2>/dev/null || true
done

# Run tests and collect results
total=0
passed=0
failed=0
skipped=0
results=()

for test_path in "${tests[@]}"; do
  total=$(( total + 1 ))
  test_name="$(basename "$test_path")"
  printf 'Running: %s ... ' "$test_name"
  zsh_debug_echo "Invoking: run_with_timeout ${timeout_secs}s $test_path"

  output_file="$(mktemp -t run-integ-output.XXXXX 2>/dev/null || mktemp)"
  if run_with_timeout "$timeout_secs" zsh "$test_path" >"$output_file" 2>&1; then
    printf 'PASS\n'
    zsh_debug_echo "Output for $test_name:"
    zsh_debug_echo "----------------------------------------"
    zsh_debug_echo "$(sed 's/^/    /' "$output_file" || true)"
    zsh_debug_echo "----------------------------------------"
    results+=("$test_name: PASS")
    passed=$(( passed + 1 ))
  else
    rc=$?
    if [[ $rc -eq 124 ]]; then
      printf 'FAIL (timeout)\n'
      zsh_debug_echo "Test timed out after ${timeout_secs}s: $test_name"
      results+=("$test_name: FAIL (timeout)")
    else
      printf 'FAIL (exit %d)\n' "$rc"
      zsh_debug_echo "Test failed ($rc): $test_name"
      results+=("$test_name: FAIL (exit $rc)")
    fi
    zsh_debug_echo "Captured output:"
    zsh_debug_echo "----------------------------------------"
    zsh_debug_echo "$(sed 's/^/    /' "$output_file" || true)"
    zsh_debug_echo "----------------------------------------"
    failed=$(( failed + 1 ))
  fi
  rm -f -- "$output_file" 2>/dev/null || true
done

# Summary
echo
echo "Integration test summary:"
echo "  Total:  $total"
echo "  Passed: $passed"
echo "  Failed: $failed"
if (( failed == 0 )); then
  echo "✅ All integration checks passed."
  exit 0
else
  echo "❌ Some tests failed. See entries below:"
  for r in "${results[@]}"; do
    [[ "$r" == *PASS* ]] || echo "  - $r"
  done
  exit 1
fi
