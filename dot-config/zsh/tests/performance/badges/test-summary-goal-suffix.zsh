#!/usr/bin/env zsh
# dotfiles/dot-config/zsh/tests/performance/badges/test-summary-goal-suffix.zsh
# Compliant with ${HOME}/dotfiles/dot-config/ai/guidelines.md vb7f03a299a01b1b6d7c8be5a74646f0b5127cbc5b5d614c8b4c20fc99bc21620
#
# PURPOSE:
#   Validate that the summary-goal badge message composes compact suffixes
#   from existing perf drift and structure badges.
#
# SCOPE:
#   - Pure zsh, no external JSON tools.
#   - Writes temporary perf-drift.json and structure.json in redesignv2 badge dir.
#   - Generates summary-goal.json to a temporary output path.
#   - Asserts that suffix parts "drift:<msg>" and "struct:<msg>" are present.
#
# EXIT CODES:
#   - Non-zero if assertions fail; framework prints summary.

set -euo pipefail

# Bring in test framework
script_dir="${0:A:h}"
zsh_root="${script_dir:A}/../../.."
framework="${zsh_root}/tests/lib/test-framework.zsh"
if [[ ! -f "$framework" ]]; then
  print -r -- "[suffix-test][err] test framework not found: ${framework}" >&2
  exit 1
fi
source "$framework"

test_suite_start "summary-goal-suffix"

test_start "composes drift and struct suffix when badges exist"

# Paths
badge_dir="${zsh_root}/docs/redesignv2/artifacts/badges"
mkdir -p -- "$badge_dir"

perf_badge="${badge_dir}/perf-drift.json"
struct_badge="${badge_dir}/structure.json"

# Backup any existing files
tmpdir="$(mktemp -d 2>/dev/null || mktemp -d -t sgsuffix)"
pre_perf=""
pre_struct=""
if [[ -f "$perf_badge" ]]; then cp "$perf_badge" "${tmpdir}/perf-drift.pre.json"; pre_perf="${tmpdir}/perf-drift.pre.json"; fi
if [[ -f "$struct_badge" ]]; then cp "$struct_badge" "${tmpdir}/structure.pre.json"; pre_struct="${tmpdir}/structure.pre.json"; fi

cleanup() {
  # Restore or remove the test artifacts
  if [[ -n "${pre_perf}" && -f "${pre_perf}" ]]; then
    mv -f "${pre_perf}" "$perf_badge"
  else
    rm -f "$perf_badge"
  fi
  if [[ -n "${pre_struct}" && -f "${pre_struct}" ]]; then
    mv -f "${pre_struct}" "$struct_badge"
  else
    rm -f "$struct_badge"
  fi
  rm -rf "$tmpdir" 2>/dev/null || true
}
trap cleanup EXIT

# Seed controlled badge inputs
cat > "$perf_badge" <<'JSON'
{
  "schemaVersion": 1,
  "label": "perf-drift",
  "message": "2 warn (+7.1% max)",
  "color": "yellow"
}
JSON

cat > "$struct_badge" <<'JSON'
{
  "schemaVersion": 1,
  "label": "structure",
  "message": "2 violations",
  "color": "yellow"
}
JSON

# Generate summary-goal badge to a temporary path
generator="${zsh_root}/tools/generate-summary-goal-badge.zsh"
if [[ ! -x "$generator" ]]; then
  chmod +x "$generator" 2>/dev/null || true
fi
[[ -x "$generator" ]] || { test_fail "generator not executable: ${generator}"; test_suite_end; exit 1; }

summary_out="${tmpdir}/summary-goal.json"
run_with_timeout 10 -- "$generator" --output "$summary_out" --label goal --logo zsh --cache-seconds 60 || {
  test_fail "generator exited non-zero"
  test_suite_end
  exit 1
}

assert_file_exists "$summary_out"

# Extract fields
message="$(sed -nE 's/.*"message"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$summary_out" | head -n1)"

# Assertions: suffix parts included
if [[ "$message" != *"drift:2 warn (+7.1% max)"* ]]; then
  test_fail "missing drift suffix in message; got: ${message}"
else
  :
fi

if [[ "$message" != *"struct:2 violations"* ]]; then
  test_fail "missing struct suffix in message; got: ${message}"
else
  :
fi

# Optional informative output (non-fatal)
color="$(sed -nE 's/.*"color"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$summary_out" | head -n1)"
printf "[info] summary-goal color=%s message=%s\n" "${color:-<unset>}" "$message"

# Mark test pass if no failures recorded by the framework
if (( TF_FAILED == 0 )); then
  test_pass "suffixes composed correctly"
fi

test_suite_end
exit $?
